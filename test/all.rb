
root_dir = File.dirname(File.absolute_path(__FILE__)) + '/'

Dir[root_dir + '{system,unit}/*.rb'].each do |file_name|
  relative_file_name = file_name[root_dir.length..-1]

  next if %w[all.rb test_helper.rb].include? relative_file_name

  require file_name
end
