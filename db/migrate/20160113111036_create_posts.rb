class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.string :identifier
      t.text :content
      t.boolean :published
      t.datetime :created
      t.datetime :updated
      t.string :user
      t.string :pname

      t.timestamps null: false
    end

    add_index :posts, :identifier
    add_index :posts, :created
  end
end
