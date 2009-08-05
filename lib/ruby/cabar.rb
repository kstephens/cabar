require 'socket' # Socket.gethostname

# = Cabar
#
# Cabar is an extensible software component backplane for
# managing software components.
# It can be used with Ruby or other software technologies.
#
# == Licensing
#
# See LICENSE.txt
#
# == Features
#
# * Extensibility:
# Component Facets can be declared in components to glue components
# back together.  Components can add plug-ins to Cabar.  Plugins can
# add facets, commands or observe the internals of Cabar.
#
# * Configurability:
# User configuration can be used to override configurations
# in the components.
#
# * Component Versioning:
# Component versions can be specified and checked for conflicts.
#
# * Component Repository Overlays:
# Component repositories are searched in a specific order.
# For example, a development repository can override a specific
# component version for testing.
#
# == Credits
#
# Cabar was created by Kurt Stephens at CashNetUsa.com.
#
# == Concepts
#
# In a large software system, it becomes important to consider 
# refactoring it into smaller, testable and deployable parts -- 
# smaller parts are easier to debug, test, understand and reuse.
#
# Refactoring a large system requires determining how parts
# are interrelated so that they can be torn apart and reconnected
# via APIs, protocols and contracts.
#
# The breaking apart of components requires the introduction of
# how components will reassembled and communicate between each other.
# This is typically referred to "glue".
#
# The nature of the recomposition and communication between components
# may not be realized until many components are "cleaved" off
# from a large system.  This is because large systems have
# unique issues when dealing with configuration, testing,
# deployment, etc.  Thus any software backplane should be
# open-ended for extension.
#
# Imagine a large software system as a multi-dimentional "blob".
# If a component can be "sliced" off of a software "blob",
# the axis of slicing leaves a unique surface, or Facet, between
# the component and the remaining software system.
#
# To reconnect to the original
# system or to reuse the new component requires that communication
# that may have been implicit between tightly integrated code,
# needs to be made explicit between the new component and its consumers.
#
# == Example
#
# An application named "boc" (Blob Of Code)
# contains a "configuration" class
# that reads configuration from files and provides
# configuration information to the rest of BOC.
#
# BOC has a single directory where all the configuration files are located,
# this directory is hard-coded in the configuration class.
#
# We are creating a new application in which we want to reuse the
# "configuration" class from the "boc" application.
#
# If the "configuration" class is "sliced" off from "boc"
# into a separate component,
# the new configuration component will need to know where all
# the configuration files live.
#
# More importantly, if the "configuration" component is going
# to be reused by other components, it will need to know
# where those components' configuration files are located.
#
# === Slicing into Components and Facets
#
# A Facet is created by "slicing" off the "configuration" component.
# This could be a configuration directory search path.  Each component using
# the "configuration" component would communicate a configuration
# file directory to the "configuration search path."
#
# Below "boc" is represented as a blob:
#
#        --------
#    ---/        \   ----
#   (             \ /    |
#  /               -     |
#  |                     |
#  |         boc         |
#  \                     |   
#   -         --         |
#    (      _/  \       /
#     \    /     -------
#      ---/
# 
#
# A configuration component is isolated and sliced
# from "boc":
#
#
#        --------
#    ---/        \   -----
#   (             \ /     |
#  /              /-      |
#  |             //       |
#  |    boc     //   ???  |
#  \           //         |   
#   -         --          |
#    (      _/  \        /
#     \    /     --------
#      ---/
#
# After slicing of "boc_config" from "boc",
# two Components and a Facet are created:
#
# * A reusable component "boc_config",
# * A top-level component "boc", containing the rest of the application,
# * A facet named "boc_config_path", which is used to communicate 
# the location of the configuration files for the "boc_config" component.
#
#
#                    boc_config_path Facet       
#        --------       |
#    ---/        \     _|_     -----
#   (             \    /    _/     |
#  /             //   /   //       |
#  |            //   /   //        |
#  |    boc    //   /   //         |
#  \          //   /   //          |   
#   -         /       -            |
#    (      _/        \ boc_config /
#     \    /           ------------
#      ---/
# 
#
# At this point "boc_config" configuration component class must be
# changed -- the hard-coded
# path to the configuration file directory
# is replaced with a reference to an
# environment variable: BOC_CONFIG_PATH.
#
# === Facet Communication
#
# Cabar uses environment variables as a de-facto communication
# mechanism between components.  Environment variables were chosen 
# for their flexiblity and ubiquity.  Most components already use
# environment variables for configuration: Ruby uses RUBYLIB and Perl
# uses PERL5LIB to specify where they can load modules from.  Similarly
# the PATH environment variable specifies where programs can be located
# by command shells and other programs.
#
# However, there is no reason that Facets cannot be designed to
# communicate through other means, such as: 
# 
# * a global configuration file.
# * shared memory.
# * direct messaging between classes.
# * configuration database.
#
# === Component Specification
#
# Next, the component specifications must be
# created.  Cabar uses a simple YAML document format
# for component specification.
#
# Cabar expects each component to reside in a component repository.
# A component repository is simply a directory containing subdirectories
# that have "cabar.yml" files, searched by "*/cabar.yml" and "*/*/cabar.yml"
# in each component repository directory.
#
# Component repositories are specified by the CABAR_PATH environment
# variable.
#
# Each component has its own directory structure with
# a "cabar.yml" file:
#
#   repo/
#
#     boc/
#       cabar.yml
#       bin/
#         boc
#       lib/ruby/
#         boc1.rb
#         boc2.rb
#       conf/
#         *.yml
#
#     boc_config/
#       cabar.yml
#       cabar.rb
#       lib/ruby/
#         boc_config.rb
#
# === The boc_config Component
#
# repo/boc_config/cabar.yml:
#
#   ---
#   cabar:
#     version: v1.0
#     component:
#       name: boc_config
#     plugin: cabar.rb
#     facet:
#       lib/ruby: true
#     requires:
#       component:
#         ruby: true
#         
#
# "boc_config" has a cabar plugin, which defines the 
# "boc_config_path" facet and the actual Ruby code
# of the component: lib/ruby/boc_config.rb.
#
# === The boc_config_path Facet
#
# repo/boc_config/cabar.rb:
#
#   Cabar::Plugin.new do
#     facet :boc_config_path, 
#       :env_var => :BOC_CONFIG_PATH,
#       :std_path => 'conf'
#   end
#
# The 'boc_config_path' Facet will use 'conf' as the default
# directory.  The Facet will collect all the configuration directories
# of the components using the 'boc_config_path' facet into 
# the BOC_CONFIG_PATH environment variable.
#
# === The boc Component
#
# repo/boc/cabar.yml:
#
#   ---
#   cabar:
#     version: v1.0
#     component:
#       name: boc
#     facet:
#       bin: true
#       lib/ruby: true
#       boc_config_path: true
#     requires:
#       component:
#         boc_config: true
#         ruby: true
#
# This specifies "boc" as a component that
# has a "bin" directory with programs and
# a configuration file directory named 'conf',
# by default to be used by the "boc_config"
# component to locate "boc" configuration files.
# 
# === The cbr Command
#
# To get a list of commands availale in cbr, run:
#
#   > cbr help
#   > cbr help --verbose
#
# The output of most cbr commands is a YAML document, which makes
# programmatic parsing of output easier.
#
# The "cbr" command can set up the environment to
# tie "boc" and "boc_config" components together:
#
#   > export PATH=cabar/bin:$PATH
#   > cd repo && cbr env - boc
#   ...
#   PATH="repo/boc/bin:..."; export PATH;
#   BOC_CONFIG_PATH="repo/boc/conf:..."; export BOC_CONFIG_PATH;
#
# In the command line above: "- boc" means require "boc" as a top-level
# component.
#
# == Visualization of Components
#
# "cbr comp dot" generates component dependency graphs in the Dot
# lanugage for rendering with
# the Graphviz ( http://www.graphvis.org/ ) graph visualization toolkit.
#
# Graphs generated from the example directory are here: http://cabar.rubyforge.org/example/doc
# 
# See example/Rakefile for examples on generating component graphs using cbr. 
#
# == Specifying component name and version
#
# A component's name and versions are specified in two ways:
#
# * Explicitly in the component's cabar.yml file.
# * Implicitly as part of the component's directory name.
#
# If the component's name or version is not specified in its cabar.yml file it can be inferred from matching:
#
# * <<name>>/<<version>>/cabar.yml
# * <<name>>-<<version>>/cabar.yml
# * <<name>>/cabar.yml
#
# Cabar version strings follow the Debian version naming standard; see Cabar::Version for more details.
#
# == Requiring components
#
# To use a component in a environment, it must be "required" by the following mtethods, in order of precedence:
#
# * "- <<component-constraint>>" cbr command line option.
# * CABAR_REQUIRE environment variable.
# * require: component: section in a cabar_conf.yml file.
# 
# The "- <<component-constraint>>" command line option forces cbr to require
# a top-level component.  This option can occur anywhere before the end of the
# cbr command path.  This overrides any component requires specified in a cabar_conf.yml file or the CABAR_TOP_LEVEL environment variable.
#
# For example: 
#
#    > cbr comp dep
#
# Will show the default top-level component's dependencies.
#
#    > cbr comp dep - rubygems
#
# Will show only the "rubygems" component's dependencies.
#
# == Selecting components
#
# Cabar will find all available components residing in the component repositories specified in CABAR_PATH.  Component with the same name and version earlier in the CABAR_PATH are selected first, others are ignored.
#
# The set of available component versions is reduced by "selecting" versions based on constraints, in order of precedence:
#
# * "-S <<component-constraint>>" cbr command line option. (NOT IMPLEMENTED)
# * CABAR_SELECT environment variable.  (NOT IMPLEMENTED)
# * select: component: section in a cabar_conf.yml file.
#
# == Component Resolution
#
# Resolution of component version occurs in 3 phases.
#
# * Determine all available components.
# * Reducing the available component set into selected components by
# explicit selection, requiring or component interdependency.
# * Selecting the latest version of a component, if the remaining selected
# component versions is not singular.
#
# == Component Constraints
#
# Component constraints can be specified using the following patterns:
#
# * "name" - any version of a component named "name".
# * "name* - any version of a component with a name starting with "name".
# * "name/1.2" - The 1.2 version of component "name".
# * "name/>1.2" - Any version of component "name" greater than ">1.2".
#
# Unless a component has a dependency on a specific version, e.g.: because of
# required API or feature set, component dependencies are usually unversioned 
# or at most, version limits.
#
# It's recommended that dependency constraints listed in
# components should be as open as possible,
# to allow component versions to be varied at the system configuration level,
# usually in a CABAR_CONFIG file or with the CABAR_SELECT environment variable.
#
# == Component Plug-ins
#
# List of available plugins:
#
#    > cbr plugin list
#
# == Rubygems Plug-in
#
# The rubygems plugin component, located under cabar/comp supports
# the collection of rubygems into a cabar component.  This is useful
# for creating software "platforms" for multiple systems.  For example
# one might create two "Ruby on Rails" software platforms to test
# different versions of rails and other dependencies.
#  
# The 'rubygems'
# facet composes GEM_PATH directories for components with
# the 'rubygems' facet.  By default, the 'rubygems' facet expects gems to
# installed in a 'gems' subdirectory under the component directory.
#
# == Creating rubygems component
#
# Example: Create a directory named "platform_gems" somewhere under a
# CABAR_PATH repository.
#
# Create repo/platform_gems/cabar.yml:
#
#   cabar:
#     version: '1.0'
#     component:
#       name: platform_gems
#       version: '1.0'
#       description: 'Local gems repository'
#     provides:
#       rubygems: true
#     requires:
#       component:
#         rubygems: true
#
# == Installing gems into a rubygems platform component
#
#    > export CABAR_PATH=repo
#    > cbr - platform_gems gems gem install rails 
#    > cbr - platform_gems gems gem list 
#
# == Requiring a rubygems platform component
#
# TODO
#
# == Renderers
#
# TODO
#
# == Facet Design
#
# TODO
module Cabar
  # The Cabar version.
  def self.version
    Version.create '1.0'
  end

  # The directory containing Cabar itself.
  def self.cabar_base_directory
    @@cabar_base_directory ||=
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
  end

end


# Use to add comp/... directories to search path when its too early for
# cabar to require itself.
def cabar_comp_require name, version = nil
  path = File.expand_path(Cabar.cabar_base_directory + "/comp/#{name}/#{version}/lib/ruby")
  $:.insert(0, path) unless $:.include?(path)
  # $stderr.puts "#{$:.inspect} #{path.inspect}"
  require name
end


cabar_comp_require 'cabar_core'


