class OrganisationValidator < ActiveModel::Validator
  include ActiveModel::Validations

  def initialize(options={})
    @validators = [
      PresenceValidator.new(attributes: [:organisation_name, :organisation_size, :organisation_sector, :organisation_type]),
      InclusionValidator.new(attributes: [:organisation_size], in: %w[<10 10-50 51-250 251-1000 >1000]),
      InclusionValidator.new(attributes: [:organisation_type], in: %w[commercial non_commercial])
    ]
  end

  def validate(record)
    @validators.each do |validator|
      validator.validate(record)
    end
    if record.new_record? && Organisation.exists?(name: record.organisation_name)
      record.errors.add(:organisation_name, "is already taken")
    end
  end

end
