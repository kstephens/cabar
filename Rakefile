

CURRENT_DIR = File.expand_path(File.dirname(__FILE__))

$:.unshift "#{CURRENT_DIR}/lib/ruby"

task :default => [ :test ]

task :test do 
  ENV['RUBYLIB'] = $:.join(':')
  sh "spec -f specdoc test/ruby/*.spec"
end

task :tgz do
  sh "cd .. && tar -czvf cabar.tar.gz cabar"
end
