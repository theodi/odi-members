Given /^I am not currently a member$/ do
end

Given /^I am not currently an individual member$/ do
  @product_name = "individual"
end

Given /^I am already signed up$/ do
  @membership = FactoryGirl.create :current_active_member
  @old_description = @membership.organisation.description
end

Given(/^I am already signed up as an individual member$/) do
  @membership = FactoryGirl.create :current_active_individual_member
end

When /^I am set as a member in CapsuleCRM$/ do
  @active            = "true"
  @email             = Faker::Internet.email
  @product_name    ||= 'partner'
  @newsletter        = false
  @capsule_id        = 1234
end

When /^I am set as a member in CapsuleCRM without an email address$/ do
  @active            = "true"
  @email             = nil
  @product_name      = 'partner'
  @newsletter        = false
  @capsule_id        = 1234
end

When /^my information is changed in CapsuleCRM$/ do
  @capsule_id        = 1234
  @active            = "true"
  @email             = Faker::Internet.email
  @newsletter        = true
  @organisation_name = Faker::Company.name
  @description       = Faker::Company.bs
  @url               = Faker::Internet.url
  @product_name      = 'sponsor'
  @membership_number = @membership.membership_number
  @contact_name      = Faker::Name.name
  @contact_phone     = Faker::PhoneNumber.phone_number
  @contact_email     = Faker::Internet.email
  @twitter           = Faker::Internet.url
  @linkedin          = Faker::Internet.url
  @facebook          = Faker::Internet.url
  @tagline           = Faker::Company.bs
  @organisation_size = '>1000'
  @organisation_sector = "Other"
end

When /^the sync task runs$/ do
  membership = {
    'email'         => @email,
    'product_name'  => @product_name,
    'id'            => @membership_number,
    'newsletter'    => @newsletter,
    'size'          => @organisation_size,
    'sector'        => @organisation_sector,
  }.compact
  directory_entry = {
    'active'        => @active,
    'name'          => @organisation_name,
    'description'   => @description,
    'url'           => @url,
    'contact'       => @contact_name,
    'phone'         => @contact_phone,
    'email'         => @contact_email,
    'twitter'       => @twitter,
    'linkedin'      => @linkedin,
    'facebook'      => @facebook,
    'tagline'       => @tagline,
  }.compact
  CapsuleObserver.update(membership, directory_entry, @capsule_id)
end

When(/^the sync task runs it should raise an error$/) do
  membership = {
    'email'         => @email,
    'product_name'  => @product_name,
    'id'            => @membership_number,
    'newsletter'    => @newsletter,
    'size'          => @organisation_size,
    'sector'        => @organisation_sector,
  }.compact
  directory_entry = {
    'active'        => @active,
    'name'          => @organisation_name,
    'description'   => @description,
    'url'           => @url,
    'contact'       => @contact_name,
    'phone'         => @contact_phone,
    'email'         => @contact_email,
    'twitter'       => @twitter,
    'linkedin'      => @linkedin,
    'facebook'      => @facebook,
    'tagline'       => @tagline,
  }.compact

  expect { CapsuleObserver.update(membership, directory_entry, @capsule_id) }.to raise_error
end

Then /^a membership should be created for me$/ do
  @membership = Member.where(:email => @email).first
  expect(@membership).to be_present
  @membership_number = @membership.membership_number
  expect(@membership_number).to be_present
  @old_description = @membership.organisation.description
end

Then(/^an individual membership should be created for me$/) do
  @membership = Member.where(:email => @email).first
  expect(@membership).to be_present
  @membership_number = @membership.membership_number
  expect(@membership_number).to be_present
  expect(@membership.individual?).to eq(true)
end

Then(/^that membership should not be shown in the directory$/) do
  @active = false
  expect(@membership.cached_active).to eq(@active)
end

Then /^my details should be cached correctly$/ do
  @membership = Member.where(membership_number: @membership_number).first
  expect(@membership.cached_active).to                     eq (@active == "true")
  expect(@membership.product_name).to                      eq @product_name
  expect(@membership.cached_newsletter).to                 eq @newsletter
  expect(@membership.organisation_size).to                 eq @organisation_size
  expect(@membership.organisation_sector).to               eq @organisation_sector
  expect(@membership.organisation.name).to                 eq @organisation_name
  expect(@membership.organisation.description).to          eq @old_description # description should not change when synced
  expect(@membership.organisation.url).to                  eq @url
  expect(@membership.organisation.cached_contact_name).to  eq @contact_name
  expect(@membership.organisation.cached_contact_phone).to eq @contact_phone
  expect(@membership.organisation.cached_contact_email).to eq @contact_email
  expect(@membership.organisation.cached_twitter).to       eq @twitter
  expect(@membership.organisation.cached_linkedin).to      eq @linkedin
  expect(@membership.organisation.cached_facebook).to      eq @facebook
  expect(@membership.organisation.cached_tagline).to       eq @tagline
end

Then(/^my individual details should be cached correctly$/) do
  @membership = Member.where(membership_number: @membership_number).first
  expect(@membership.cached_active).to                     eq (@active == "true")
  expect(@membership.product_name).to                      eq @product_name
  expect(@membership.cached_newsletter).to                 eq @newsletter
end

Then /^nothing should be placed on the queue$/ do
  expect(Resque).not_to receive(:enqueue)
end

Then /^nothing should be placed on the signup queue$/ do
end

Then /^my membership number should be stored in CapsuleCRM$/ do
  expect(Resque).to receive(:enqueue) do |*args|
    expect(args[0]).to eql SaveMembershipIdInCapsule
    if @product_name == "individual"
      expect(args[1]).to eql nil
      expect(args[2]).to eql @email
    else
      expect(args[1]).to eql @organisation_name
      expect(args[2]).to eql nil
    end
    expect(args[3]).to eql Member.where(email: @email).first.membership_number
  end.once
end

Then /^a warning email should be sent to the commercial team$/ do
  steps %Q(
    Then "members@theodi.org" should receive an email
    When they open the email
    And they should see "Membership creation failure" in the email subject
    And they should see "http://ukoditech.capsulecrm.com/party/#{@capsule_id}" in the email body
    And they should see the email delivered from "members@theodi.org"
  )
end
