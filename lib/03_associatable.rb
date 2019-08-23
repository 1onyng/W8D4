require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
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
    hash = { 
      :foreign_key => "#{name}_id".to_sym,
      :class_name => name.to_s.camelcase, 
      :primary_key => :id 
    }
    
    @foreign_key = options[:foreign_key] ||= hash[:foreign_key]
    @class_name = options[:class_name] ||= hash[:class_name]
    @primary_key = options[:primary_key] ||= hash[:primary_key]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    hash = { 
      :foreign_key => "#{self_class_name}_id".downcase.to_sym,
      :class_name => name.to_s.camelcase.singularize, 
      :primary_key => :id 
    }

    @foreign_key = options[:foreign_key] ||= hash[:foreign_key]
    @class_name = options[:class_name] ||= hash[:class_name]
    @primary_key = options[:primary_key] ||= hash[:primary_key]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
       # hash[name] = Belongs to object
                        #attrs ^
    define_method(name) do
        option = self.class.assoc_options[name]
        fkey = self.send(option.foreign_key)
        option.model_class
          .where(option.primary_key => fkey).first  
    end
  end

  def has_many(name, options = {})
    option = HasManyOptions.new(name, self.name, options)
        
    define_method(name) do
        pkey = self.send(option.primary_key)
        option.model_class
          .where(option.foreign_key => pkey)  
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    end
end

class SQLObject
  extend Associatable
end
