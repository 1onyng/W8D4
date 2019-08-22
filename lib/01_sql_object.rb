require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    cols = DBConnection::execute2(<<-SQL).first
    SELECT
      *
    FROM
      #{self.table_name}  
    SQL

    cols.map! { |col| col.to_sym }
    @columns = cols
  end

  def self.finalize!
    self.columns.each do |key|
      define_method(key) do 
        self.attributes[key]
      end

      define_method("#{key}=") do |value|
        self.attributes[key] = value 
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    hash = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{table_name} 
    SQL

    parse_all(hash)      
  end

  def self.parse_all(results)
    results.map { |row| self.new(row) }
  end

  def self.find(id)
    arr = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ? 
    SQL
    
    parse_all(arr).first
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{attr_name}=", val)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |k| self.send(k) }
  end

  def insert
    col_names = self.class.columns.join(",")
    question_marks = (["?"] * self.class.columns.length).join(",")
    

    DBConnection.execute(<<-SQL, *attribute_values) 
    INSERT INTO
      #{self.class.table_name}(#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.map { |name| "#{name} = ?" }.join(",")

    DBConnection.execute(<<-SQL, *attribute_values, id) 
      
    UPDATE
      #{self.class.table_name}
    SET
      #{col_names}
    WHERE
      #{self.class.table_name}.id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
