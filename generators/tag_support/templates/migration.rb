class Create<%= class_name.pluralize %><%= tag.class_name.pluralize %> < ActiveRecord::Migration
  def self.up
    create_table :<%= new_table_name %>, :id => false do |t|
      t.column :<%= singular_name %>_id, :integer
      t.column :<%= tag.singular_name %>_id, :integer
    end
    add_index :<%= new_table_name %>, "<%= singular_name %>_id"
    add_index :<%= new_table_name %>, "<%= tag.singular_name %>_id"
  end

  def self.down
    drop_table :<%= new_table_name %>
  end
end
