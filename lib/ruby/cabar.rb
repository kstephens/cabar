
# = Cabar
#
# Cabar is an extensible software component backplane.
# It can be used with Ruby or other software technologies.
#
# == Features:
#
# * Extensibility:
# Component Facets can be declared in components to glue components
# back together in.  Components can add plug-ins to Cabar.  Plugins can
# add facets, commands or observe internals.
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
#
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
# via API, protocols and contracts.
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
# configure components through other means, such as: 
# 
# * a global configuration file.
# * shared memory.
# * direct messaging between classes.
# * configuration database.
#
# === Component Specification
#
# Next, the component specifications must be
# created.  Cabar uses a simple YAML document
# to specify components.  By default, Cabar expects each
# component to reside in component repositories.
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
# a boc_config_path configuration file
# directory to be used by the "boc_config"
# component.
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
# of the component: lib/ruby/boc_config.rb
#
# repo/boc_config/cabar.rb:
#
#   Cabar::Plugin.new do
#     facet :boc_config_path, 
#       :var => :BOC_CONFIG_PATH,
#       :std_path => 'conf'
#   end
#
# === The cbr Command
#
# To get a list of commands from cbr, run:
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
# "cbr comp dot" generates dependency graphs to be rendered by
# the Dot graph toolkit.
#
# Graphs generated from the example directory are located here: http://cabar.rubyforge.org/example/doc
# 
# See example/Rakefile for examples on generating component graphs using cbr. 
#
# == Component Versioning
#
# == Component Plugins
#
# == Renderers
#
# == Rubygems plugin
#
# The rubygems plugin component, located under cabar/comp support
# the collection of rubygems into a cabar component.  The 'rubygems'
# facet can generate GEM_PATH directories for components with
# the 'rubygems'.  By default the gems component expects gems to
# installed in a 'gems' subdirectory under the component directory.
#
# == Installing gems into a rubygems platform component
#
#    cbr gems gem install rails - platform_gems/1.1
#    cbr gems gem list - platform_gems/1.1
#
module Cabar
  EMPTY_HASH = { }.freeze
  EMPTY_ARRAY = [ ].freeze
  EMPTY_STRING = ''.freeze

  # The Cabar version.
  def self.version
    Version.create '1.0'
  end

  SEMICOLON = ';'.freeze
  COLON = ':'.freeze

  # Returns the path separator for this platform.
  # UNIX: ':'
  # Windows: ';'
  def self.path_sep
    @@path_sep ||= (ENV['PATH'] =~ /;/ ? SEMICOLON : COLON)
  end

  # Split all the elements in a path.
  # Remove any empty elements.
  def self.path_split path, sep = nil
    sep ||= path_sep
    path = path.split(sep)
    path.reject{|x| x.nil? || x.empty?}
    path
  end
  
  # Joins directory elements into a path.
  # Removes any nil or empty elements.
  def self.path_join *args
    sep = path_sep
    path = args.flatten.reject{|x| x.nil? || x.empty?}
    path = path.uniq.join(path_sep)
    path
  end

  # Expand all the elements in a path,
  # while leaving '@' prefixes.
  def self.path_expand p, dir = nil
    case p
    when Array
      p.map { | p | path_expand(p, dir) }.cabar_uniq_return!
    else
      p = p.to_s.dup
      if p.sub!(/^@/, EMPTY_STRING)
        '@' + File.expand_path(p, dir)
      else
        File.expand_path(p, dir)
      end
    end
  end

  # The directory containing Cabar itself.
  def self.cabar_base_directory
    @@cabar_base_directory ||=
      path_expand(File.join(File.dirname(__FILE__), '..', '..'))
  end

  # Construct a cabar YAML header.
  def self.yaml_header str = nil
"---
cabar:
  version: #{Cabar.version.to_s.inspect}
" + (str ? "  #{str}:" : EMPTY_STRING)
  end
end

# require 'pp'

require 'cabar/array'
require 'cabar/hash'

require 'cabar/base'
require 'cabar/error'
require 'cabar/version'
require 'cabar/version/requirement'
require 'cabar/version/set'
require 'cabar/context'
require 'cabar/renderer'
require 'cabar/facet'
require 'cabar/facet/standard'
require 'cabar/relationship'
require 'cabar/component'
require 'cabar/component/set'


