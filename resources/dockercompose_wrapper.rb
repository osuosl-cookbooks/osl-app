provides :osl_app_dockercompose_wrapper
unified_mode true

default_action :create

property :project_name, String, name_property: true
property :directory, String, required: true
property :config_files, Array, default: []
property :service, String, default: 'app'
property :command, String, default: 'sh'
property :user, String, required: true

action :create do
  config_flags = new_resource.config_files.map { |f| "-f #{f} " }.join

  template "/usr/local/bin/#{new_resource.project_name}-console" do
    source 'dockercompose-console.erb'
    cookbook 'osl-app'
    mode '0750'
    variables(directory: new_resource.directory, project_name: new_resource.project_name, config_flags: config_flags, service: new_resource.service, command: new_resource.command)
  end

  template "/usr/local/bin/#{new_resource.project_name}-logs" do
    source 'dockercompose-logs.erb'
    cookbook 'osl-app'
    mode '0750'
    variables(directory: new_resource.directory, project_name: new_resource.project_name, config_flags: config_flags, service: new_resource.service)
  end

  template "/usr/local/bin/#{new_resource.project_name}-ps" do
    source 'dockercompose-ps.erb'
    cookbook 'osl-app'
    mode '0750'
    variables(directory: new_resource.directory, project_name: new_resource.project_name, config_flags: config_flags)
  end

  sudo new_resource.project_name do
    user new_resource.user
    commands [
      "/usr/local/bin/#{new_resource.project_name}-console",
      "/usr/local/bin/#{new_resource.project_name}-logs",
      "/usr/local/bin/#{new_resource.project_name}-ps",
    ]
    nopasswd true
  end
end
