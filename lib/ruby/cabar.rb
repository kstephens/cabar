
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
end

require 'pp'

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


