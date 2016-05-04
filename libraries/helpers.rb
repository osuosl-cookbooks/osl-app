def sudo_commands(services)
  services.reduce([]) { |total, service| total + systemctl_commands(service) }
end

def systemctl_commands(service)
  %w(enable disable stop start reload restart).collect do |x|
    "/usr/bin/systemctl #{x} #{service}"
  end
end
