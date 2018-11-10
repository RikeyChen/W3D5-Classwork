require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns.first.map { |column| column.to_sym }
  end

  def self.finalize!
    columns.each do |col_name|
      define_method(col_name) do
        self.attributes[col_name]
      end

      define_method("#{col_name}=") do |value|
        self.attributes[col_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name || self.to_s.tableize
  end

  def self.all
    records = DBConnection.execute(<<-SQL)
      SELECT *
      FROM
        "#{self.table_name}"
    SQL
    parse_all(records)
  end

  def self.parse_all(results)
    data = results.map do |hash|
      self.new(hash)
    end
    data
  end

  def self.find(id)
    record = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM "#{self.table_name}"
      WHERE id = ?
    SQL
    self.new(record.first) unless record.empty?
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)

      send("#{attr_name}=", value)
    end

  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    values = self.class.columns.map do |col_name|
      send(col_name)
    end
    values
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * (attribute_values.length)).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    setter = self.class.columns.map { |name| "#{name} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{setter}
    WHERE
      id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
