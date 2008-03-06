######################################################################

CURRENT_DIR = File.expand_path(File.dirname(__FILE__))

######################################################################

PKG_Name = 'Cabar'
PKG_Author = 'Kurt Stephens'
PKG_Email = 'ruby-cabar@umleta.com'
PKG_DESCRIPTION = %{Cabar - Component Backplane Manager

For more details, see:

http://rubyforge.org/projects/cabar
http://cabar.rubyforge.org/
http://cabar.rubyforge.org/files/README_txt.html

}
PKG_lib_ruby_dir = 'lib/ruby'

######################################################################


$:.unshift "#{CURRENT_DIR}/lib/ruby"

task :default => [ :test ]

task :test do 
  ENV['RUBYLIB'] = $:.join(':')
  sh "spec -f specdoc test/ruby/*.spec"
end

task :tgz do
  sh "cd .. && tar -czvf cabar.tar.gz cabar"
end

require "#{CURRENT_DIR}/rake_helper.rb"

