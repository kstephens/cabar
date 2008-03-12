
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
module Cabar
  EMPTY_HASH = { }.freeze
  EMPTY_ARRAY = [ ].freeze

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
    sep = path_sep
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
      if p.sub!(/^@/, '')
        '@' + File.expand_path(p, dir)
      else
        File.expand_path(p, dir)
      end
    end
  end

  # Construct a cabar YAML header.
  def self.yaml_header str = nil
"---
cabar:
  version: #{Cabar.version.to_s.inspect}
" + (str ? "  #{str}:" : '')
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


