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
PKG_manifest_reject = %r{example/.*/gems/.*/gems|example/doc}

######################################################################


$:.unshift "#{CURRENT_DIR}/lib/ruby"

task :default => [ :test ]

desc "Run tests in example/"
task :test_example do
  sh "cd example && rake"
end
task :test => :test_example

task :tgz do
  sh "cd .. && tar -czvf cabar.tar.gz cabar"
end

require "#{CURRENT_DIR}/rake_helper.rb"

task :make_manifest => :make_p4ignore

task :make_p4ignore do
  sh "ls -d * | sort > .p4ignore"
end

desc "Generates example docs"
task :docs_example => :docs do
  sh "cd example && rake doc_graphs"
  sh "rm -rf doc/example/doc"
  sh "mkdir -p doc/example"
  sh "cp -rp example/doc doc/example/doc"
  sh "find doc -type d -name .svn | xargs rm -rf" 
end

task :publish_docs => :docs_example
