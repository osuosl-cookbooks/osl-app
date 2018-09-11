resource_name :osl_app

default_action :create

property :user, String, default: lazy { name }
property :service_after, Array, default: %w(network.target)
property :service_name, String, default: lazy { name }
property :service_type, String, default: 'forking'
property :start_cmd, String, required: true
property :reload_cmd, String, default: '/bin/kill -USR2 $MAINPID'
property :description, [String, nil], default: nil
property :environment, Hash, default: {}
property :pid_file, String, default: lazy { "/home/#{user}/tmp/pids/gunicorn.pid" }
property :wanted_by, String, default: 'multi-user.target'
property :working_directory, [String, nil], default: nil
property :environment_file, [String, nil], default: nil

action :create do
  sudo new_resource.user do
    user new_resource.user
    commands sudo_commands(new_resource.service_name)
    nopasswd true
  end

  systemd_service new_resource.service_name do
    description new_resource.description unless new_resource.description.nil?
    after new_resource.service_after
    install do
      wanted_by new_resource.wanted_by
    end

    service do
      type new_resource.service_type
      user new_resource.user
      environment new_resource.environment
      environment_file new_resource.environment_file unless new_resource.environment_file.nil?
      working_directory new_resource.working_directory unless new_resource.working_directory.nil?
      pid_file new_resource.pid_file
      exec_start new_resource.start_cmd
      exec_reload new_resource.reload_cmd
    end

    action [:create, :enable]
  end
end

action :delete do
  sudo new_resource.user do
    action :delete
  end

  systemd_service new_resource.service_name do
    action [:stop, :delete]
  end
end
