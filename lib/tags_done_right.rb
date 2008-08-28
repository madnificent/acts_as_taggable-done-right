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
    def acts_as_taggable( user_options={ })
      opts = { :tag_class => Tag, :tag_names_name => nil, :show_separator => ", ", :read_separator => /[,\.\s;]+/ }.merge user_options
      opts[:tag_names_name] ||= opts[:tag_class].table_name.singularize + "_names"

      connection_table_name = if self.table_name < opts[:tag_class].table_name
                                self.table_name + "_" + opts[:tag_class].table_name
                              else
                                opts[:tag_class].table_name + "_" + self.table_name
                              end

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

      # Object.find_by_tags
      self.class.send! "define_method", "find_by_#{opts[:tag_class].table_name}" do |tags|
        connect = ""
        conditions = ""
        tags.each do |tag|
          conditions += connect + "
EXISTS (SELECT *
        FROM #{connection_table_name} CONN
        WHERE CONN.#{opts[:tag_class].table_name.singularize}_id = '#{tag.id}'
          AND OBJECT.id = CONN.#{self.table_name.singularize}_id)"
          connect = " AND "
        end

        self.find( :all,
                   :select => "OBJECT.*",
                   :from => "#{self.table_name} OBJECT",
                   :conditions => "#{conditions}" )
      end

      # Object.find_by_tag_names
      self.class.send! "define_method", "find_by_#{opts[:tag_names_name]}" do |tags|
        connect = ""
        conditions = ""
        tags.each do |tag|
          conditions += connect + "
EXISTS (SELECT *
        FROM #{connection_table_name} CONN, #{opts[:tag_class].table_name} TAG
        WHERE TAG.name = '#{tag}'
          AND TAG.id = CONN.#{opts[:tag_class].table_name.singularize}_id
          AND OBJECT.id = CONN.#{self.table_name.singularize}_id)"
          connect = " AND "
        end
        
        self.find( :all,
                   :select => "OBJECT.*",
                   :from => "#{self.table_name} OBJECT",
                   :conditions => "#{conditions}" )
      end
                   
      # Object.tags_cloud :items :groups :tags
      self.class.send! "define_method", "#{opts[:tag_class].to_s.tableize}_cloud" do |options|
        method_opts = { :items => 10 , :groups => nil , :tags => [] }.merge options
        method_opts[:groups] ||= method_opts[:items]
        tags = method_opts[:tags]
        items = method_opts[:items]
        groups = method_opts[:groups]
        
        if tags and not tags.empty?
          # query contains an insane query that fetches the tag, and a count for that tag
          query = "
SELECT TAG.*, COUNT(*) AS tag_count
FROM (SELECT * 
      FROM #{connection_table_name} TAGS_MODELS
           JOIN #{self.table_name} MODEL
           ON MODEL.id = TAGS_MODELS.#{self.table_name.singularize + '_id'}
      WHERE "
          and_sql = "" # this is replaced by and after the first tag
          tags.each do |tag|
            query += and_sql + "
            EXISTS (SELECT * 
                    FROM #{connection_table_name} SHS, #{opts[:tag_class].table_name} TAG
                    WHERE MODEL.id = SHS.#{self.table_name.singularize + '_id'}
                          AND TAG.name = '#{tag.name}'
                          AND SHS.#{opts[:tag_class].table_name.singularize + '_id'} = TAG.id)"
            and_sql = " AND "
          end
          query +=                                         ") AS MEGA
     JOIN #{opts[:tag_class].table_name} TAG
     ON TAG.id = MEGA.#{opts[:tag_class].table_name.singularize + '_id'}
GROUP BY TAG.id
ORDER BY tag_count DESC
LIMIT #{items}"

          cloud = opts[:tag_class].find_by_sql( query )
          max = cloud.first.tag_count.to_i if cloud.first
          cloud.each do |tag|
            tag.tag_count = ((tag.tag_count.to_i * groups) / max).to_i
          end

          # remove the tags that are given
          # Note: this reduces the maximum amount of given tags for clouds to max - 1 (hooray for caching)
          tags.each do |tag|
            cloud.delete tag
          end
          cloud
        else
          cloud = opts[:tag_class].find( :all,
                                         :select => "*, COUNT(*) AS tag_count",
                                         :joins =>  self.table_name.to_sym,
                                         :group =>  opts[:tag_class].table_name.singularize + "_id",
                                         :order => "tag_count DESC",
                                         :limit => method_opts[:items] )
        end
      end
      
      extend TagsDoneRight::SingletonMethods
      include TagsDoneRight::InstanceMethods
    end
  end
end
