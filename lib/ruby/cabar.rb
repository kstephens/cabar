
# == Cabar
#
# Cabar is a software component backplane.
# It can be used with Ruby or other software technologies.
#
# Features:
#
#   Extensibility:
#     Component "facets" can be added by components to glue components
#     together in.  Components can add plug-ins to Cabar.
#
#   Configurability:
#     User configuration can be used to override configurations
#     in the components.
#
#   Component Versioning:
#     Component versions can be specified and checked for conflicts.
#
#   Component Repository Overlays:
#     Component repositories are searched in a specific order.
#
#     For example, a development repository can override a specific
#     component version for testing.
#
# In a large software system, it becomes important to consider 
# refactoring it into smaller, testable and deployable parts -- 
# smaller parts are easier to debug, test, understand and reuse.
#
# Refactoring a large system requires determining how parts
# are interrelated so that they can be torn apart and reconnected
# via API, protocols and contracts.
#
# The breaking apart of components introduces the need for 
# establishing how components will communicate.  The questions
# of how to make that communication may not be realized until
# components are "cleaved" off from a large system.
#
# == Example
#
# Imagine a large software system as a multi-dimentional "blob".
# If a certain component can be "sliced" off, the axis of slicing
# leaves a unique shape, or "facet".  To reconnect to the original
# system or to reuse the new component requires that communication
# needs to be made explicit between the component and its consumers.
#
# For example: An application named "BOC" (Blob of Code)
# contains a "configuration" class
# that reads configuration from files and provides
# configuration information to the rest of BOC.
#
# BOC has a single
# directory where all the configuration files are located.
#
# If the "configuration" class is "sliced" off into a separate component,
# it will need to know where all the configuration files live.
#
# More importantly, if the "configuration" component is going
# to be reused by other components, it will need to know
# where those components' configuration files are located.
#
# A "facet" created by "slicing" off the "configuration" component
# could be a configuration search path.  Each component using
# the "configuration" component would communicate a configuration
# file directory to the "configuration search path."
#
#        --------
#    ---/        \   ----
#   (     BOC     \ /    |
#  /               -     |
#  |                     |
#  |                     |
#  \                     |   
#   -         --         |
#    (      _/  \       /
#     \    /     -------
#      ---/
# 
# After slicing of "config" from "BOC",
# two components are created:
# "config" and a top-level component
# "BOC", and a facet named 'config_path'.
#
#
#                    config_path Facet       
#        --------        /
#    ---/        \      /     ----
#   (     BOC     \    /    _/    |
#  /             //   /   //      |
#  |            //   /   //       |
#  |           //   /   //        |
#  \          //   /   // config  |   
#   -         /       -           |
#    (      _/        \          /
#     \    /           ----------
#      ---/
# 
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
    path.reject{|x| x.empty?}
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


