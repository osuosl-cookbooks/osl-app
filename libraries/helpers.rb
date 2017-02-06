def sudo_commands(*args)
  args.reduce([]) { |acc, elem| acc + systemctl_commands(elem) }
end

def systemctl_commands(service)
  %w(enable disable stop start status reload restart).collect do |x|
    "/usr/bin/systemctl #{x} #{service}"
  end
end
