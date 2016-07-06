require 'spec_helper'

describe Organisation do

  context "validations" do

    it "should strip prefix from twitter handles before saving" do
      org = FactoryGirl.create :organisation, :cached_twitter => "@test1"
      expect(org.cached_twitter).to eq("test1")
      org = FactoryGirl.create :organisation, :cached_twitter => "test2"
      expect(org.cached_twitter).to eq("test2")
    end

    it "cannot create organisations with the same name" do
      name = Faker::Company.name
      FactoryGirl.create :organisation, :name => name
      expect {
        FactoryGirl.create :organisation, :name => name
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "can create two organisations with no name" do
      expect {
        FactoryGirl.create :organisation, :name => nil
        FactoryGirl.create :organisation, :name => nil
      }.to change{Organisation.count}.by(2)
    end
  end

  context "scopes" do

    context "filtering by alpha group" do
      it "returns organisations in a group" do
        a1 = FactoryGirl.create(:organisation, :name => "Alice")
        a2 = FactoryGirl.create(:organisation, :name => "Agile")
        FactoryGirl.create(:organisation, :name => "Eve")

        expect(Organisation.in_alpha_group("A")).to eq([a1, a2])
      end
    end
  end
end
