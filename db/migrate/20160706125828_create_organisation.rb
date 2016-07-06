class CreateOrganisation < ActiveRecord::Migration
  def change
    create_table :organisations do |t|
      t.string   "name"
      t.datetime "created_at",           :null => false
      t.datetime "updated_at",           :null => false
      t.integer  "member_id"
      t.string   "logo"
      t.text     "description"
      t.string   "url"
      t.string   "cached_contact_name"
      t.string   "cached_contact_phone"
      t.string   "cached_contact_email"
      t.string   "cached_twitter"
      t.string   "cached_facebook"
      t.string   "cached_linkedin"
      t.string   "cached_tagline"
    end
  end
end
