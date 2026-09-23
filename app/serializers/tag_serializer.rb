module TagSerializer
  module_function

  def call(tag, prompts_count: nil)
    {
      id: tag.id,
      name: tag.name,
      slug: tag.slug,
      prompts_count: prompts_count
    }.compact
  end
end
