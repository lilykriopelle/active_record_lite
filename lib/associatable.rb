class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = (options[:foreign_key].nil? ? "#{name.to_s.underscore}_id".to_sym : options[:foreign_key])
    self.primary_key = (options[:primary_key].nil? ? "id".to_sym : options[:primary_key])
    self.class_name = (options[:class_name].nil? ? name.to_s.camelcase : options[:class_name])
  end

  def where_cond(klass, included_ids)
    <<-SQL
      #{klass.table_name}.#{options[:foreign_key]} IN #{included_ids}
    SQL
  end

  def match(associated, base)
    base.find do |obj|
      obj.send(options[:foreign_key]) == associated.send(options[:primary_key])
    end
  end

end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.foreign_key = (options[:foreign_key].nil? ? "#{self_class_name.to_s.underscore}_id".to_sym : options[:foreign_key])
    self.primary_key = (options[:primary_key].nil? ? "id".to_sym : options[:primary_key])
    self.class_name = (options[:class_name].nil? ? name.to_s.singularize.camelcase : options[:class_name])
  end

  def where_cond(klass, included_ids)
    <<-SQL
      #{table_name}.#{options[:foreign_key]} IN #{included_ids}
    SQL
  end

  def match(associated, base)
    base.find do |obj|
      obj.send(options[:primary_key]) == associated.send(options[:foreign_key])
    end
  end

end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      fk = self.send(options.foreign_key)
      options.model_class.where({ self.send(options.primary_key) => fk } ).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    assoc_options[name] = options

    define_method(name) do
      pk = self.send(options.primary_key)
      options.model_class.where({ options.foreign_key => pk })
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]

    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]

        query = <<-SQL
          SELECT
            #{source_options.table_name}.*
          FROM
            #{through_options.table_name}
          JOIN
            #{source_options.table_name}
          ON
            #{through_options.table_name}.#{source_options.foreign_key} = #{source_options.table_name}.#{through_options.primary_key}
          WHERE
            #{through_options.table_name}.#{through_options.primary_key} = ?
        SQL

      associated = DBConnection.execute(query, self.send(through_options.foreign_key))
      source_options.model_class.parse_all(associated).first
    end
  end

  def has_many_through(name, through_name, source_name)
    through_options = assoc_options[through_name]

    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]

        query = <<-SQL
          SELECT
            #{source_options.table_name}.*
          FROM
            #{through_options.table_name}
          JOIN
            #{source_options.table_name}
          ON
            #{through_options.table_name}.#{source_options.foreign_key} = #{source_options.table_name}.#{through_options.primary_key}
          WHERE
            #{through_options.table_name}.#{through_options.primary_key} = ? OR #{through_options.table_name}.#{through_options.foreign_key} = ?
        SQL

      associated = DBConnection.execute(query, self.send(through_options.foreign_key), self.send(through_options.primary_key))
      source_options.model_class.parse_all(associated).first
    end
  end
end

class SQLObject
  extend Associatable
end
