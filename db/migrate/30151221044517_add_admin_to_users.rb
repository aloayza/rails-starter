class AddAdminToUsers < ActiveRecord::Migration
  def change
    add_column :users, :admin, :boolean, null: false, default: false

  	change_column_null :users, :name, false
  	change_column_null :users, :email, false
  end
end
