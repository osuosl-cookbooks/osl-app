if defined?(ChefSpec)
  def create_sudo(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :sudo,
      :create,
      resource_name
    )
  end
end
