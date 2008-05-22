class Create<%= class_name.pluralize %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.column :name, :string
    end
    add_index :<%= table_name %>, "name"
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
