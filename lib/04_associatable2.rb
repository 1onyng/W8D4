require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do 
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      p through_options
      p source_options
      ttable = through_options.table_name  
      stable = source_options.table_name 

      p DBConnection.execute(<<-SQL, self.send(through_options.foreign_key))
    SELECT
      #{stable}.*
    FROM
      #{ttable}
    JOIN
      #{stable}
    ON
       #{stable}.#{source_options.primary_key} = #{ttable}.#{source_options.foreign_key} 
    WHERE
       #{ttable}.#{through_options.primary_key} = ? 
    SQL
    end
  end
end
