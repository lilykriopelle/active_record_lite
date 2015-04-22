class Relation

  attr_accessor :klass, :table, :loaded, :where_conditions

  def initialize(klass, table, where_conditions = {})
    @klass = klass
    @table = table
    @where_conditions = where_conditions
    @loaded = false
    @records = []
  end

  def where(new_where_conds)
    Relation.new(klass, table, where_conditions.merge(new_where_conds))
  end

  def includes(association)
    base = Relation.new(klass, table, where_conditions)
    opts = assoc_options[association]
    associated = Relation.new(opts.class_name,
                              opts.table_name,
                              klass.opts.where_cond(klass, included_ids)
    )

    base_objs = klass.parse_all(base)
    associated_objs = associated.klass.parse_all(associated)

    pairs = Hash.new { [] }
    associated_objs.each do |associated|
      match = association.match(associated, base)
      pairs[match] << associated
    end
  end

  def included_ids
    "(#{ @records.map(&:id).join(", ") })"
  end

  def where_clause
    if where_conditions.is_a?(Hash)
      where_conditions.map { |k,v| "#{table_name}.#{k} = #{v}" }.join(" AND ")
    else
      where_conditions
    end
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
    @loaded = true
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
