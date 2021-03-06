require_relative 'db_connection'

module Searchable
  def where(params)

    where_line = params.keys.map do |attr|
      "#{attr} = ?"
    end.join(" AND ")

    instance = DBConnection.execute(<<-SQL, *params.values)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      #{where_line}
    SQL

    self.parse_all(instance)
  end
end

class SQLObject
  extend Searchable
end
