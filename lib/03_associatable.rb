require_relative '02_searchable'
require 'active_support/inflector'

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
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.foreign_key = (options[:foreign_key].nil? ? "#{self_class_name.to_s.underscore}_id".to_sym : options[:foreign_key])
    self.primary_key = (options[:primary_key].nil? ? "id".to_sym : options[:primary_key])
    self.class_name = (options[:class_name].nil? ? name.to_s.singularize.camelcase : options[:class_name])
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
end

class SQLObject
  extend Associatable
end
