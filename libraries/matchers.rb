if defined?(ChefSpec)
  def create_sudo(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :sudo,
      :create,
      resource_name
    )
  end

  def create_osl_app(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :osl_app,
      :create,
      resource_name
    )
  end
end
