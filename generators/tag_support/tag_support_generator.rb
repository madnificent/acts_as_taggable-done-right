class TagData
  attr_accessor :table_name, :class_name, :singular_name
  
  def initialize( base_name = "Tag" )
    @class_name = base_name.classify
    @table_name = base_name.tableize
    @singular_name = @table_name.singularize
  end
  
end

class TagSupportGenerator < Rails::Generator::NamedBase
  
  attr_accessor :tag
  
  def new_table_name
    if table_name < tag.table_name
      table_name + "_" + tag.table_name
    else
      tag.table_name + "_" + table_name
    end
  end

  def manifest
    @tag = @args[0] ? TagData.new( @args[0] ) : TagData.new( "Tag" )
    record do |m|
      m.migration_template 'migration.rb', "db/migrate", :migration_file_name => "create_#{new_table_name}"
    end
  end

end
