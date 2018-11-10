require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map { |key| "#{key} = ?"}.join(" AND ")
    p where_line
    records = DBConnection.execute(<<-SQL, params.values)
    SELECT
      *
    FROM
      #{self.class.table_name}
    WHERE
      #{where_line}
    SQL
    records
  end
end

class SQLObject
  # Mixin Searchable here...
  include Searchable
end
