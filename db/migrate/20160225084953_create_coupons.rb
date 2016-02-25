class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :name
      t.integer :discount

      t.timestamps null: false
    end
  end
end
