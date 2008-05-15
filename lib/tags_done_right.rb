require 'active_record'

class Tag < ActiveRecord::Base
end

# TagsDoneRight
module TagsDoneRight
  
  def self.included(mod)
    mod.extend(ClassMethods)
  end
  
  module ClassMethods
    def acts_as_taggable
      # Link the Tag class to the current class, and vice-versa
      has_and_belongs_to_many :tags
      Tag.send :has_and_belongs_to_many, self.class.to_s.tableize
            
      extend TagsDoneRight::SingletonMethods
      include TagsDoneRight::InstanceMethods
    end
  end
  
  module SingletonMethods
    # No singletonmethods yet
  end
  
  module InstanceMethods
    # Easy setter to set a string that defines the used tags
    def tag_names= (string, separator = ",")
      tag_names = string.split(separator).map{ |tag_name_with_spaces| tag_name_with_spaces.strip }
      self.tags = tag_names.map{ |name| Tag.find_or_create_by_name name }
    end
    
    # Easy accessor to get a string that defines the currently used tags
    def tag_names
      tags.map{ |tag| tag.name }.join ", "
    end
  end
  
end
