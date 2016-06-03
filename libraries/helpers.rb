def sudo_commands(*args)
  args.reduce([]) { |a, e| a + systemctl_commands(e) }
end

def systemctl_commands(service)
  %w(enable disable stop start status reload restart).collect do |x|
    "/usr/bin/systemctl #{x} #{service}"
  end
end
