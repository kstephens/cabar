# For release
"
rake make_manifest
rake update_version
svn status
rake package
rake release VERSION=x.x.x
rake svn_release
rake publish_docs
rake announce
"

#################################################################

require 'rubygems'
require 'hoe'

#################################################################
# Release notes
#

def get_release_notes(relfile = "Releases.txt")

  release = nil
  notes = [ ]

  File.open(relfile) do |f|
    while ! f.eof && line = f.readline
      if md = /^== Release ([\d\.]+)/i.match(line)
        release = md[1]
        notes << line
        break
      end
    end

    while ! f.eof && line = f.readline
      if md = /^== Release ([\d\.]+)/i.match(line)
        break
      end
      notes << line
    end
  end

  [ release, notes.join('') ]
end

#################################################################

PKG_NAME = PKG_Name.gsub(/[a-z][A-Z]/) {|x| "#{x[0,1]}_#{x[1,1]}"}.downcase

PKG_SVN_ROOT="svn+ssh://rubyforge.org/var/svn/#{PKG_NAME}/#{PKG_NAME}"

release, release_notes = get_release_notes

hoe = Hoe.new(PKG_Name.downcase, release) do |p|
  p.author = PKG_Author
  p.description = PKG_DESCRIPTION
  p.email = PKG_Email 
  p.summary = p.description
  p.changes = release_notes
  p.url = "http://rubyforge.org/projects/#{PKG_NAME}"
  p.remote_rdoc_dir = '.'
  
  p.test_globs = ['test/**/*.rb']
end

PKG_VERSION = hoe.version

task :test => :test_specs

desc "Runs all spec test"
task :test_specs do
  spec_files = Dir["test/**/*.spec"].sort
  unless spec_files.empty?
    ENV['RUBYLIB'] = ($:.dup << 'test/ruby').join(':')
    sh "spec -f specdoc #{spec_files.join(' ')}"
  end
end


#################################################################
# Version file
#

def announce(msg='')
  STDERR.puts msg
end

PKG_lib_ruby_dir = "lib" unless defined? PKG_lib_ruby_dir
version_rb = "#{PKG_lib_ruby_dir}/#{PKG_NAME}/#{PKG_NAME}_version.rb"

task :update_version do
  announce "Updating #{PKG_Name} version to #{PKG_VERSION}: #{version_rb}"
  open(version_rb, "w") do |f|
    f.puts "module #{PKG_Name}"
    f.puts "  #{PKG_Name}Version = '#{PKG_VERSION}'"
    f.puts "end"
    f.puts "# DO NOT EDIT"
    f.puts "# This file is auto-generated by build scripts."
    f.puts "# See:  rake update_version"
  end
  if ENV['RELTEST']
    announce "Release Task Testing, skipping commiting of new version"
  else
    sh %{svn commit -m "Updated to version #{PKG_VERSION}" #{version_rb} Releases.txt ChangeLog Rakefile Manifest.txt}
  end
end

task version_rb => :update_version

#################################################################
# SVN
#

task :svn_release do
  sh %{svn cp -m 'Release #{PKG_VERSION}' . #{PKG_SVN_ROOT}/release/#{PKG_VERSION}}
end

# task :test => :update_version


# Misc Tasks ---------------------------------------------------------

def egrep(pattern)
  Dir['**/*.rb'].each do |fn|
    count = 0
    open(fn) do |f|
      while line = f.gets
	count += 1
	if line =~ pattern
	  puts "#{fn}:#{count}:#{line}"
	end
      end
    end
  end
end

desc "Look for TODO and FIXME tags in the code"
task :todo do
  egrep /#.*(FIXME|TODO|TBD)/
end

desc "Look for Debugging print lines"
task :dbg do
  egrep /\bDBG|\bbreakpoint\b/
end

desc "List all ruby files"
task :rubyfiles do 
  puts Dir['**/*.rb'].reject { |fn| fn =~ /^pkg/ }
  puts Dir['bin/*'].reject { |fn| fn =~ /CVS|.svn|(~$)|(\.rb$)/ }
end

PKG_manifest_reject = nil unless defined? PKG_manifest_reject

task :make_manifest do 
  files = Dir['**/*'].reject { |fn| 
      fn == 'email.txt' ||
      ! test(?f, fn) || 
      fn =~ /CVS|.svn|([#~]$)|(.gem$)|(^pkg\/)|(^doc\/)/ ||
      (PKG_manifest_reject && (fn =~ PKG_manifest_reject))
    }.sort.join("\n") + "\n"

  open("Manifest.txt", "w") do |f|
    f.puts files
  end

  puts files
end


USER = ENV['USER'] || `id -un`.chomp
HOSTNAME = `hostname`.chomp

desc "p4 edit, svn update, p4 submit"
task :p4_submit do
  m = ENV['m'] || "From #{USER}@#{HOSTNAME}"
  c = ENV['c']

  # Open everything for edit.
  sh "p4 edit ..."

  # Get latest Manifest.txt.
  sh "svn update"

  # FIXME: Delete any files not in Manifest.txt.

  # Add any new files in Manifest.txt.
  sh "xargs p4 add < Manifest.txt"

  # Submit any pending changes.
  sh "svn ci -m #{m.inspect}"

  # Get the current svn rev.
  m = "cabar: from SVN #{`svn update`.chomp}"

  # Revert any unchanged files.
  sh "p4 revert -a ..."

  # Move everything to default changelist.
  sh "p4 reopen -c default ..."

  # Submit everything under here.
  sh "p4 submit -r -d #{m.inspect} ..."

  # Edit everything under here.
  sh "p4 edit ..."

  # Reopen in the original changelist.
  if c
    sh "p4 reopen -c #{c} ..."
  end
end


desc "p4 edit, svn ci"
task :p4_edit_svn_ci do
  m = ENV['m'] || "From #{USER}@#{HOSTNAME}"
  sh "p4 edit ..."
  sh "svn ci -m #{m.inspect}"
  sh "p4 revert -a ..."
end

