class CreateGlobalSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :global_settings do |t|
      t.integer :user_id, null: false
      t.text :identifier, null: false, index: true
      t.boolean :value_boolean
      t.timestamps
    end
  end
end
