%w(production staging).each do |env|
  directory "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media" do
    recursive true
  end

  file "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media/index.html" do
    content "streamwebs-#{env}"
  end
end
