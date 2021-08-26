provides :osl_app
unified_mode true

default_action :create

property :user, String, default: lazy { name }
property :service_after, String, default: 'network.target'
property :service_name, String, default: lazy { name }
property :service_type, String, default: 'forking'
property :service_wants, String
property :start_cmd, String, required: true
property :reload_cmd, String, default: '/bin/kill -USR2 $MAINPID'
property :description, String
property :environment, String
property :pid_file, String
property :wanted_by, String, default: 'multi-user.target'
property :working_directory, String
property :environment_file, String
property :verify, [true, false], default: false

action :create do
  sudo new_resource.user do
    user new_resource.user
    commands osl_sudo_commands(new_resource.service_name)
    nopasswd true
    action :nothing
  end

  systemd_unit "#{new_resource.service_name}.service" do
    content({
      'Unit' => {
        'Description' => new_resource.description,
        'After' => new_resource.service_after,
        'Wants' => new_resource.service_wants,
      },
      'Service' => {
        'Type' => new_resource.service_type,
        'User' => new_resource.user,
        'Environment' => new_resource.environment,
        'EnvironmentFile' => new_resource.environment_file,
        'WorkingDirectory' => new_resource.working_directory,
        'PIDFile' => new_resource.pid_file,
        'ExecStart' => new_resource.start_cmd,
        'ExecReload' => new_resource.reload_cmd,
      },
      'Install' => {
        'WantedBy' => new_resource.wanted_by,
      },
    }.transform_values(&:compact)) # Remove all keys from the hash that go to nil, these will cause a malformed ini
    action [:create, :enable]
    verify new_resource.verify
    notifies :create, "sudo[#{new_resource.user}]", :immediately
  end
end

action :delete do
  sudo new_resource.user do
    action :remove
  end

  systemd_unit "#{new_resource.service_name}.service" do
    action [:stop, :disable, :delete]
  end
end

action :stop do
  service new_resource.service_name do
    action :stop
  end
end

action :disable do
  service new_resource.service_name do
    action :disable
  end
end
