class PromptTag < ApplicationRecord
  belongs_to :prompt
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :prompt_id }
end
