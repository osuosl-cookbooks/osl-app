provides :osl_app_docker_wrapper
unified_mode true

default_action :create

property :container_name, String, name_property: true
property :command, String, default: 'sh'
property :user, String, required: true

action :create do
  template "/usr/local/bin/#{new_resource.container_name}-console" do
    source 'docker-console.erb'
    cookbook 'osl-app'
    mode '0750'
    variables(container_name: new_resource.container_name, command: new_resource.command)
  end

  template "/usr/local/bin/#{new_resource.container_name}-logs" do
    source 'docker-logs.erb'
    cookbook 'osl-app'
    mode '0750'
    variables(container_name: new_resource.container_name)
  end

  sudo new_resource.container_name do
    user new_resource.user
    commands [
      "/usr/local/bin/#{new_resource.container_name}-console",
      "/usr/local/bin/#{new_resource.container_name}-logs",
    ]
    nopasswd true
  end
end
