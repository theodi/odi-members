object false

node(:version) {"0.1"}
node(:profile) {"http://schema.theodi.org/membership"}

node(:memberships) do
  @organisations.map do |org|
    partial 'members/membership', object: org, root: false
  end
end