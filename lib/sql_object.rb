require 'active_support/inflector'

class SQLObject
  def self.columns
    col_names = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{table_name}
    SQL

    col_names.first.each.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |attr|
      define_method(attr) { self.attributes[attr] }

      define_method("#{attr}=") do |val|
         self.attributes[attr] = val
       end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      @table_name = self.to_s.tableize
    end
    @table_name
  end

  def self.all
    instances = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL
    self.parse_all(instances)
  end

  def self.parse_all(results)
    results.map do |attr_hash|
      self.new(attr_hash)
    end
  end

  def self.find(id)
    instance = DBConnection.execute(<<-SQL, id)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      #{table_name}.id = ?
    SQL

    # ASK ABOUT NIL HERE
    self.parse_all(instance).first
  end

  def initialize(params = {})
    params.each do |attr, val|
      unless self.class.columns.include?(attr.to_sym)
        raise "unknown attribute '#{attr}'"
      end

      self.send("#{attr}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |col|
      self.send(col.to_sym)
    end
  end

  def insert
    columns = self.class.columns
    col_names = columns.join(", ")
    question_marks = (["?"] * columns.size).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} ( #{col_names} )
      VALUES
        ( #{question_marks} )
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    sets = self.class.columns[1..-1].reverse.map{|attr| "#{attr} = ?" }.join(", ")
    reversed_attrs = attribute_values[1..-1].reverse

    DBConnection.execute(<<-SQL, *reversed_attrs, id)

      UPDATE
        #{self.class.table_name}
      SET
        #{sets}
      WHERE
        id = ?
    SQL

  end

  def save
    id.nil? ? insert : update
  end
end
