class TagTableGenerator < Rails::Generator::NamedBase
  
  def new_table_name
    if table_name < "tags"
      table_name + "_tags"
    else
      "tags_" + table_name
    end
  end
  
  def manifest
    record do |m|
      m.migration_template 'migration.rb', "db/migrate", :migration_file_name => "create_#{table_name}"
      m.template "tag_class.rb", "app/models/#{class_name.tableize.singularize}.rb"
    end
  end

end
