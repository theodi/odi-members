Given /^that I have signed up$/ do
  steps %Q{
    Given that I have signed up as a supporter
  }
end

Given /^that I have signed up as a (\w*)$/ do |product_name|
  @email = 'iain@foobar.com'
  @member = Member.new(
    :product_name => product_name,
    :organisation_name => 'FooBar Inc',
    :contact_name => 'Ian McIain',
    :email => @email,
    :telephone => '0121 123 446',
    :street_address => '123 Fake Street',
    :address_locality => 'Faketown',
    :address_region => 'Fakeshire',
    :address_country => 'United Kingdom',
    :postal_code => 'FAKE 123',
    :organisation_name => "Test Org",
    :organisation_size => "251-1000",
    :organisation_type => "commercial",
    :organisation_sector => "Energy",
    :organisation_vat_id => '213244343',
    :password => 'p4ssw0rd',
    :password_confirmation => 'p4ssw0rd',
    :agreed_to_terms => '1')
  # Skip Capsule and Xero Callback
  @member.remote!
  @member.save!
  @member.current!

  @membership_number = @member.membership_number
  @password = 'p4ssw0rd'

  steps %Q{
    When I visit the sign in page
    And I enter my membership number and password
    And the password is correct
    When I click sign in
  }
end

Then /^I am redirected to submit my organisation details$/ do
  expect(page).to have_content 'Edit your details'
end

Then /^I cannot see a logo upload$/ do
  expect(page).to_not have_content 'Logo'
end

Then /^the description field is limited to (\d+) characters$/ do |limit|
  expect(page).to have_content "Limit of #{limit} characters"
end

Then /^I can see a logo upload$/ do
  expect(page).to have_content 'Logo'
end

Then /^I enter my organisation details$/ do
  @organisation_name        = Faker::Company.name
  @organisation_description = Faker::Company.bs
  @organisation_url         = "iaintgotnohttp.com"
  @organisation_contact     = Faker::Name.name
  @organisation_phone       = Faker::PhoneNumber.phone_number
  @organisation_email       = Faker::Internet.email
  @organisation_twitter     = Faker::Internet.user_name
  @organisation_linkedin    = Faker::Internet.url
  @organisation_facebook    = Faker::Internet.url
  @organisation_tagline     = Faker::Company.bs

  fill_in('member_organisation_attributes_name',                 :with => @organisation_name)
  fill_in('member_organisation_attributes_description',          :with => @organisation_description)
  fill_in('member_organisation_attributes_url',                  :with => @organisation_url)
  fill_in('member_organisation_attributes_cached_contact_name',  :with => @organisation_contact)
  fill_in('member_organisation_attributes_cached_contact_phone', :with => @organisation_phone)
  fill_in('member_organisation_attributes_cached_contact_email', :with => @organisation_email)
  fill_in('member_organisation_attributes_cached_twitter',       :with => @organisation_twitter)
  fill_in('member_organisation_attributes_cached_linkedin',      :with => @organisation_linkedin)
  fill_in('member_organisation_attributes_cached_facebook',      :with => @organisation_facebook)
  fill_in('member_organisation_attributes_cached_tagline',       :with => @organisation_tagline)
end

Then /^I attach an image$/ do
  @organisation_logo = File.join(::Rails.root, "fixtures/image_object_uploader/acme-logo.png")

  # Store the urls for access earlier in the steps
  @fullsize_url = "#{ENV['RACKSPACE_DIRECTORY_ASSET_HOST']}/logos/<MEMBERSHIP_NUMBER>/original.png"
  @rectangular_url = "#{ENV['RACKSPACE_DIRECTORY_ASSET_HOST']}/logos/<MEMBERSHIP_NUMBER>/rectangular.png"
  @square_url = "#{ENV['RACKSPACE_DIRECTORY_ASSET_HOST']}/logos/<MEMBERSHIP_NUMBER>/square.png"

  attach_file('member_organisation_attributes_logo', @organisation_logo)
end

Then /^I enter the URL (.*?)$/ do |url|
  @organisation_url = url
  fill_in('member_organisation_attributes_url',          :with => @organisation_url)
end

Then /^I leave my organisation (.*?) blank$/ do |field|
  fill_in("member_organisation_attributes_#{field}", :with => nil)
end

Then /^I enter the organisation name '(.*?)'$/ do |org_name|
  fill_in("member_organisation_attributes_name", :with => org_name)
end

When /^I click submit$/ do
  fill_in("member_current_password", :with => @password || 'p4ssw0rd')
  click_button('Save')
end

When /^I save their details$/ do
  click_button('Save')
end

Then /^I should see a notice that my details were saved successfully$/ do
  expect(page).to have_content 'You updated your account successfully.'
end

Then /^I should see a notice that the profile was saved successfully$/ do
  expect(page).to have_content 'Account updated successfully.'
end

Then /^I should see my changed details when I revisit the edit page$/ do
  first(:link, "My Account").click
  expect(page).to have_content @changed_organisation_name
  expect(page).to have_content @changed_organisation_description
  expect(page).to have_content @changed_organisation_url
  expect(page).to have_content @changed_organisation_contact
  expect(page).to have_content @changed_organisation_phone
  expect(page).to have_content @changed_organisation_email
  expect(page).to have_content @changed_organisation_twitter
  expect(page).to have_content @changed_organisation_linkedin
  expect(page).to have_content @changed_organisation_facebook
  expect(page).to have_content @changed_organisation_tagline
end

Then /^my description is (\d+) characters long$/ do |length|
  fill_in('member_organisation_attributes_description',  :with => (0...length.to_i).map{ ('a'..'z').to_a[rand(26)] }.join)
end

When /^I should see an error telling me that my description should not be longer than (\d+) characters$/ do |characters|
  expect(page).to have_content "Your description cannot be longer than #{characters} characters"
end

Then /^the fullsize logo should be available at the correct URL$/ do
  @member = Member.find_by_email(@email)
  expect(@member.organisation.logo.url).to eq @fullsize_url.gsub(/<MEMBERSHIP_NUMBER>/, @member.membership_number)
end

Then /^the rectangular logo should be available at the correct URL$/ do
  expect(@member.organisation.logo.rectangular.url).to eq @rectangular_url.gsub(/<MEMBERSHIP_NUMBER>/, @member.membership_number)
end

Then /^the square logo should be available at the correct URL$/ do
  expect(@member.organisation.logo.square.url).to eq @square_url.gsub(/<MEMBERSHIP_NUMBER>/, @member.membership_number)
end

Then /^my organisation details should be queued for further processing$/ do
  @member = Member.find_by_email(@email)

  logo = @fullsize_url.gsub(/<MEMBERSHIP_NUMBER>/, @member.membership_number) rescue nil
  thumbnail = @square_url.gsub(/<MEMBERSHIP_NUMBER>/, @member.membership_number) rescue nil

  organisation = {
    :name => @organisation_name
  }

  directory_entry = {
    :active      => true,
    :description => @organisation_description,
    :homepage    => "http://#{@organisation_url}",
    :logo        => logo,
    :thumbnail   => thumbnail,
    :contact     => @organisation_contact,
    :phone       => @organisation_phone,
    :email       => @organisation_email,
    :twitter     => @organisation_twitter,
    :linkedin    => @organisation_linkedin,
    :facebook    => @organisation_facebook,
    :tagline     => @organisation_tagline,
  }

  date = @member.organisation.updated_at.to_s

  expect(Resque).to receive(:enqueue).with(SendDirectoryEntryToCapsule, @member.membership_number, organisation, directory_entry, date)
end

Then /^my organisation details should not be queued for further processing$/ do
  expect(Resque).to_not receive(:enqueue)
end

Then(/^I update my membership details$/) do
  @changed_email      = Faker::Internet.email
  @changed_newsletter = true
  @changed_share_with_third_parties = true

  fill_in('member_email', :with => @changed_email)
  if @changed_newsletter
    check('member_cached_newsletter')
  else
    uncheck('member_cached_newsletter')
  end

  if @changed_share_with_third_parties
    check('member_cached_share_with_third_parties')
  else
    uncheck('member_cached_share_with_third_parties')
  end
  
  @changed_size = ">1000"
  select("more than 1000", :from => "member_organisation_size")

  @changed_sector = "Other"
  select(@changed_sector, :from => "member_organisation_sector")
  
end

Then(/^my membership details should be queued for updating in CapsuleCRM$/) do
  @member = Member.find_by_email(@email)
  expect(Resque).to receive(:enqueue).with(SaveMembershipDetailsToCapsule, @member.membership_number, {
    'email'      => @changed_email,
    'newsletter' => @changed_newsletter,
    'share_with_third_parties' => @changed_share_with_third_parties,
    'size'       => @changed_size,
    'sector'     => @changed_sector,
  })
end

When(/^I should see my changed membership details when I revisit the edit page$/) do
  #expect(page).to have_content(@changed_email)
  expect(page.find('#member_email').value).to eq @changed_email
  expect(page.find('#member_cached_newsletter').checked? == 'checked').to eq @changed_newsletter
  expect(page.find('#member_organisation_size').value).to eq @changed_size
  expect(page.find('#member_organisation_sector').value).to eq @changed_sector
end

Given(/^there are (\d+) active partners in the directory$/) do |num|
  num.to_i.times do
    member = FactoryGirl.create :member, :product_name => 'partner', :cached_active => true
    member.organisation.description = Faker::Company.catch_phrase
    member.organisation.save
  end
end

Given(/^I am a founding partner$/) do
  @member = Member.find_by_email(@email)
  @member.membership_number = ENV['FOUNDING_PARTNER_ID']
  @member.save
end

When(/^I visit the members list$/) do
  visit("/members")
end

Then(/^I should be listed as a founding partner$/) do
  expect(all("h2").first.text).to match /Founding partner/
end

Given(/^I have entered my organisation details$/) do
  steps %{
    When I visit my account page
    And I am redirected to submit my organisation details
    And I enter my organisation details
    And I click submit
  }
end

Given(/^my listing is active$/) do
  @member.cached_active = true
  @member.save
end

Then(/^my listing should appear first in the list$/) do
  expect(all("h2").count).to eq 6
  expect(all("h2").first.text).to match /#{@organisation_name}/
end

Given(/^I am logged in as an administrator$/) do
  OmniAuth.config.test_mode = true
  hash = OmniAuth::AuthHash.new
  hash[:info] = { email: 'test@example.com' }
  OmniAuth.config.mock_auth[:google_oauth2] = hash
  visit admin_omniauth_authorize_path(:google_oauth2)
end

