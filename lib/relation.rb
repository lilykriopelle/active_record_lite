class Relation

  attr_accessor :klass, :table, :loaded, :where_conditions

  def initialize(klass, table, where_conditions = {})
    @klass = klass
    @table = table
    @where_conditions = where_conditions
    @records = []
  end

  def where(new_where_conds)
    self.new(klass, table, where_conditions.merge(new_where_conds))
  end

  def includes(association)
    self.load
    opts = klass.assoc_options[association]

    if opts.is_a?(BelongsToOptions)
      DBConnection.execute(belongs_to_query(opts))
    elsif opts.is_a?(HasManyOptions)
      DBConnection.execute(has_many_query(opts))
    end
  end

  def included_ids_string
    ids = @records.map{ |record| record.id }
    "(#{ids.join(", ")})"
  end

  def belongs_to_query(opts)
    <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      LEFT OUTER JOIN
        #{opts.table_name}
      ON
        #{opts.table_name}.id = #{table_name}.#{opts.foreign_key}
      WHERE
        #{table_name}.#{opts.foreign_key} IN #{included_ids_string}
    SQL
  end

  def has_many_query(opts, included_object_ids)
    <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      LEFT OUTER JOIN
        #{opts.table_name}
      ON
        #{table_name}.id = #{opts.table_name}.#{opts.foreign_key}
      WHERE
        #{opts.table_name}.#{opts.foreign_key} IN #{included_ids_string}
    SQL
  end

  def where_clause
    where_conditions.map{|k,v| "#{table_name}.#{k} = #{v}" }.join(" AND ")
  end

  def load
    records = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_clause}
    SQL

    @records.concat(DBConnection.execute(records))
  end

  def any?
    !empty?
  end

  def empty?
    @records.empty?
  end

  def table_name
    table
  end

end
