class Query
  def initialize
    @tables = {}
    @select_fields = {}
    @order = []
    @conditions = []
  end

  def execute(page=1)
    query = base_query

    # Add select fields
    @select_fields.values.each do |field|
      query = query.project(field)
    end

    # Evaluate cost
    cost = cost(query)
    if cost > CONFIG["maxcost"]
      raise "Operation cost (#{cost}) exceeds maximum cost of #{CONFIG["maxcost"]}"
    end
  
    # Apply pagination
    query = query.take(CONFIG["perpage"])
    query = query.skip((page.to_i - 1) * CONFIG["perpage"])

    ActiveRecord::Base.connection.execute(query.to_sql).each(:as => :hash)
  end

  def count
    query = base_query
    query = query.project("count(*)")
    ActiveRecord::Base.connection.execute(query.to_sql).first[0]
  end

  def add_table(table)
    @processed_requirements = false

    table = table.to_s

    if CONFIG["tables"][table] and not @tables.key? table
      @tables[table] = Arel::Table.new(table.to_sym)
    end
  end

  def add_order(order_string)
    field_string, direction = order_string.split(/\s/)

    if not ["asc", "desc"].include? direction
      raise "Direction must be either asc or desc"
    end

    fieldObject = parse_field_string(field_string)
    @order << fieldObject.send(direction) 
  end

  def add_condition(condition_string)
    left, operation, right = condition_string.split(/\s/)
    check_operation_permitted! operation
    
    leftOperand = parse_operand(left)
    rightOperand = parse_operand(right)

    @conditions << leftOperand.send(operation, rightOperand)
  end

  def add_select_field(field_string)
    table, column = field_string.split(".")
    fieldObject = parse_field_string(field_string)

    unless @select_fields.key? column
      @select_fields[column] = fieldObject
    end
  end

  private
  def base_query
    process_requirements

    query = @tables.values.inject { |q,table|
      q.join(table); q
    } 

    @conditions.each do |condition|
      query = query.where(condition)
    end

    @order.each do |order|
      query = query.order(order)
    end

    return query
  end

  def cost(query)
    ActiveRecord::Base.connection.execute("EXPLAIN #{query.to_sql}").each(:as => :hash).inject(0){ |sum,q|
      sum += q["rows"] if q["rows"]
    }.to_i
  end

  def process_requirements
    if not @processed_requirements
      @tables.keys.each do |table|
        requires = CONFIG["tables"][table]["require"]
        if requires
          requires.each do |condition|
            add_condition condition
          end
        end
      end

      @processed_requirements = true
    end
  end

  def check_operation_permitted!(op)
    unless PERMITTED_COMPARISON_OPERATIONS.include? op
      raise "Operation #{op} not permitted!"
    end
  end
  
  def parse_operand(operand)
    @operandParser ||= OperandParser.new
    parsedOperand = @operandParser.parse(operand)
    merge_operand_table_definitions(parsedOperand) 
    parsedOperand
  end

  def parse_field_string(field_string)
    table, column = field_string.split(".")
    add_table table
    
    if CONFIG["tables"][table].include?(column)
      @tables[table][column.to_sym]
    else
      raise "Cannot query over #{field_string}"
    end
  end

  def merge_operand_table_definitions(operand)
    if operand.is_a? Arel::Attribute and not @tables.has_key?(operand.relation.name.to_s)
      @tables[operand.relation.name.to_s] = operand.relation
    end
  end
end

