class Relation

  attr_accessor :klass, :table, :loaded, :where_conditions

  def initialize(klass, table, where_conditions = {})
    @klass = klass
    @table = table
    @where_conditions = where_conditions
    @records = []
  end

  def table_name
    table
  end

  def load
    records = <<-SQL
      SELECT
        *
      FROM
        #{ table_name }
      WHERE
        #{ where_clause }
    SQL

    @records.concat(klass.parse_all(DBConnection.execute(records)))
  end

  def where(new_where_conds)
    self.new(klass, table, where_conditions.merge(new_where_conds))
  end

  def where_clause
    where_conditions.map{|k,v| "#{table_name}.#{k} = #{v}" }.join(" AND ")
  end

  def any?
    !empty?
  end

  def empty?
    @records.empty?
  end

end
