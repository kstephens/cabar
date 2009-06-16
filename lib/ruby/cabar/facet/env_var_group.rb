require 'cabar/facet'
require 'cabar/facet/env_var'

module Cabar
  class Facet

    # This represents a set of environment variables.
    #
    #   facet:
    #     env:
    #       NAME1: v1
    #       NAME2: v2
    #
    # This decomposes itself into EnvVar Facets in
    # attach_component! method.
    #
    # It's only purpose is to provide a short hand
    # for specifying many EnvVar facets.
    #
    class EnvVarGroup < self
      # Hash of environment variables.
      attr_accessor :vars

      def _reformat_options! opts
        opts = { :vars => opts }
        opts
      end

      def compose_facet! facet
        self
      end

      # Creates individual EnvVar facets for each
      # key/value pair in the option Hash.
      def attach_component! c, resolver
        vars.each do | n, v |
          # $stderr.puts "   env: #{n} #{v}" # FIXME LOGGING
          c.create_facet(:env_var, { :env_var => n, :value => v })
        end
      end
    end # class

  end # class

end # module



