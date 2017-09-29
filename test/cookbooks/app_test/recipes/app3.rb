%w(production staging).each do |env|
  directory "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/streamwebs/media" do
    recursive true
  end

  file "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/streamwebs/media/index.html" do
    content "streamwebs-#{env}"
  end
end
