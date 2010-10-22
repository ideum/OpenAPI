class OperandParser
  def parse(operand)
    [:operand_as_field, :operand_as_integer, :operand_as_float,
      :operand_as_string].each do |op_test|
      if possible_result=self.send(op_test, operand)
        if operand == "wp_posts.status"
          raise 'wtf'
        end

        return possible_result 
      end
    end

    raise "Operand parse failure: #{operand}"
  end
 
  def operand_as_field(operand)
    if operand =~ /^(\S*)\.(\S*)$/
      if CONFIG["tables"][$1] and CONFIG["tables"][$1].include?($2)
        return Arel::Table.new($1.to_sym)[$2.to_sym]
      end 
    end

    false
  end

  def operand_as_float(operand)
    Float operand
  rescue
    false
  end

  def operand_as_integer(operand)
    Integer operand
  rescue
    false
  end

  def operand_as_string(operand)
    if(operand =~ /^("|')(.*)("|')$/)
      $2
    else
      false
    end
  end
end

