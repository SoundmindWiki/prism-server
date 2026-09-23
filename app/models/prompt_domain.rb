class PromptDomain < ApplicationRecord
  belongs_to :prompt
  belongs_to :domain

  validates :domain_id, uniqueness: { scope: :prompt_id }
end
