resource_name :osl_app
provides :osl_app

default_action :create

property :user, String, default: lazy { name }
property :service_after, Array, default: %w(network.target)
property :service_name, String, default: lazy { name }
property :service_type, String, default: 'forking'
property :start_cmd, String, required: true
property :reload_cmd, String, default: '/bin/kill -USR2 $MAINPID'
property :description, [String, nil]
property :environment, Hash, default: {}
property :pid_file, String, required: true
property :wanted_by, String, default: 'multi-user.target'
property :working_directory, [String, nil]
property :environment_file, [String, nil]

action :create do
  sudo new_resource.user do
    user new_resource.user
    commands sudo_commands(new_resource.service_name)
    nopasswd true
  end

  systemd_service new_resource.service_name do
    unit_description new_resource.description unless new_resource.description.nil?
    unit_after new_resource.service_after
    install_wanted_by new_resource.wanted_by
    service_type new_resource.service_type
    service_user new_resource.user
    service_environment new_resource.environment
    service_environment_file new_resource.environment_file unless new_resource.environment_file.nil?
    service_working_directory new_resource.working_directory unless new_resource.working_directory.nil?
    service_pid_file new_resource.pid_file
    service_exec_start new_resource.start_cmd
    service_exec_reload new_resource.reload_cmd
    verify false
    action [:create, :enable]
  end
end

action :delete do
  sudo new_resource.user do
    action :remove
  end

  systemd_service new_resource.service_name do
    action [:stop, :delete]
  end
end
