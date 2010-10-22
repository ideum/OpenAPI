require 'rubygems'
require 'bundler/setup'

require 'arel'
require 'active_record'
require 'sinatra'
require 'erb'
require 'ruby_debug'
require 'xmlsimple'
require 'timeout'
require 'lib/operand-parser'
require 'lib/query-generator'

CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), "config.yml"))
PERMITTED_COMPARISON_OPERATIONS = %w(lt gt lteq gteq eq not_eq)

ActiveRecord::Base.establish_connection(CONFIG["database"])
Arel::Table.engine = ActiveRecord::Base

get "/doc" do
  erb :doc
end

get "/find" do
  params[:page] ||= 1
  query = Query.new

  raise "You must select a field" if not params[:select]

  params[:select].split(/,/m).each do |field_string|
    query.add_select_field field_string
  end

  # And now apply our conditions
  if params[:conditions]
    params[:conditions].split(/,/m).each do |condition_string|
      query.add_condition condition_string
    end
  end

  if params[:order]
    params[:order].split(/,/m).each do |order_string|
      query.add_order order_string
    end
  end

  Timeout::timeout(CONFIG["timeout"]) do
    results = query.execute(params[:page])
    count = query.count

    # Execute the query
    XmlSimple.xml_out({
      "results" => {
        "page" => params[:page],
        "count" => count,
        "pages" => (count.to_f / CONFIG["perpage"]).ceil,
        "result" => results
      }
    }, "rootname" => "response")
  end
end

get "/version" do
  XmlSimple.xml_out({
    "version" => "open-api-0.1"
  }, "rootname" => "response" )
end
