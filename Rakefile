require 'rubygems'
require 'rake'

VC_NAME = 'cabar'

begin
  require 'echoe'
 
  $e = Echoe.new(VC_NAME, '1.0') do |p|
    p.rubyforge_name = 'cabar'
    p.summary = "Cabar - Component Backplane Manager."
    p.description = "For more info:

http://kurtstephens.com/cabar
http://github.com/kstephens/cabar/tree/master
http://rubyforge.org/projects/cabar
http://cabar.rubyforge.org/
"
    p.url = "http://git/"
    p.author = ['Kurt Stephens']
    p.email = "ruby-cabar@umleta.com"
    # p.dependencies = ["launchy"]
  end
 
rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
  puts "#{boom.to_s.capitalize}."
end

require "spec/rake/spectask"


task :tgz do
  sh "cd .. && tar -czvf cabar.tar.gz cabar"
end

desc "Generates example docs"
task :docs_example => :docs do
  sh "cd example && rake doc_graphs"
  sh "rm -rf doc/example/doc"
  sh "mkdir -p doc/example"
  sh "cp -rp example/doc doc/example/doc"
  sh "find doc -type d -name .svn | xargs rm -rf" 
end


######################################################################

# task :publish_docs => :docs_example

$: << 'lib/ruby'

desc "Run tests in example/"
task :test_example do
  sh "cd example && rake"
end
# task :test => :test_example

# add spec tasks, if you have rspec installed
begin
  require 'spec/rake/spectask'
 
  SPEC_RUBY_OPTS = [ '-I', 'lib/ruby' ]
  SPEC_FILES = FileList['test/**/*.spec']
  SPEC_OPTS = ['--color', '--backtrace']

  Spec::Rake::SpecTask.new("spec") do |t|
    t.ruby_opts = SPEC_RUBY_OPTS
    t.spec_files = SPEC_FILES
    t.spec_opts = SPEC_OPTS
  end
 
  task :test do
    Rake::Task['spec'].invoke
  end
 
  Spec::Rake::SpecTask.new("rcov_spec") do |t|
    t.spec_files = SPEC_FILES
    t.spec_opts = SPEC_OPTS
    t.rcov = true
    t.rcov_opts = ['--exclude', '^spec,/gems/']
  end
end

desc "run all comp/* tests"
task :test_comps
task :test => :test_comps

comp_dirs = [ ]
Dir["comp/*/Rakefile"].each do | rf |
  dir = File.dirname(rf)
  name = File.basename(dir)
  comp_dirs << [ dir, name ]
end

Dir["comp/*/*/Rakefile"].each do | rf |
  dir = File.dirname(rf)
  name = File.basename(File.dirname(dir))
  comp_dirs << [ dir, name ]
end

comp_dirs.each do | (dir, name) |
  desc "run tests in #{dir}"
  name = "test_comp_#{name}".to_sym
  task name do 
    sh "cd #{dir} && rake test"
  end
  task :test_comps => name
end


######################################################################

require 'lib/tasks/p4_git'
VC_OPTS[:manifest] = 'Manifest'

