require 'active_record'

class Tag < ActiveRecord::Base # This is used only for the standard tag-definition
end

# TagsDoneRight
module TagsDoneRight
  
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  
  module SingletonMethods
    # No singletonmethods yet
  end

  module InstanceMethods
    # something that resembles to tag_names is defined in ClassMethods
    # def tag_names
    
    # something that resembles to tag_names= is defined in ClassMethods
    # def tag_names( string_with_tags, separator = /[,\.\s;]+/ )
  end

  module ClassMethods
    def acts_as_taggable( opts={ })
      opts = { :tag_class => Tag, :tag_names_name => "tag_names", :show_separator => ", ", :read_separator => /[,\.\s;]+/ }.merge opts
      
      
      # Link the Tag class to the current class, and vice-versa
      has_and_belongs_to_many opts[:tag_class].table_name

      # this might not work on older ruby-versions (pre 1.8.6)!
      opts[:tag_class].send! :has_and_belongs_to_many, self.class.to_s.tableize

      # Create the getter and setter for the list of tag_names
      TagsDoneRight::InstanceMethods.send! "define_method", opts[:tag_names_name] do ||
          self.send( opts[:tag_class].table_name).map{ |tag| tag.name }.join opts[:show_separator]
      end
      TagsDoneRight::InstanceMethods.send! "define_method", opts[:tag_names_name] + "=" do |*args|
        string = args[0]
        separator = args[1] || opts[:read_separator] 
        self.send! "#{opts[:tag_class].table_name}=",
        string.split( separator ).map{ |name| opts[:tag_class].find_or_create_by_name name.strip }
      end
      
      self.class.send! "define_method", "#{opts[:tag_class].to_s.tableize}_cloud" do |options|
        method_opts = { :items => 10 , :groups => nil }.merge options
        method_opts[:groups] ||= method_opts[:items]
        
        cloud = opts[:tag_class].find( :all,
                                       :select => "*, COUNT(*) AS tag_count",
                                       :joins =>  self.table_name.to_sym,
                                       :group =>  opts[:tag_class].to_s.table_name.singularize + "_id",
                                       :order => "tag_count DESC",
                                       :limit => method_opts[:items] )

        max = cloud.first.tag_count.to_i if cloud.first
        cloud.each do |tag|
          tag.tag_count = ((tag.tag_count.to_i * method_opts[:groups]) / max).to_i
        end
        
        cloud
      end
      
      extend TagsDoneRight::SingletonMethods
      include TagsDoneRight::InstanceMethods
    end
  end
end
