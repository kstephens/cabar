require 'cabar/base'


module Cabar

  # A Facet represents a slice of supplied information that
  # used to compose components together.
  #
  # Examples:
  #   search paths
  #   environment variables
  #   configuration settings
  #   dependencies
  #   build actions
  #   test actions
  #   packaging
  #   deployment
  #   version control
  # 
  class Facet < Base
    # The key for matching a component's configuration against.
    attr_accessor :key

    # The prototype used to create this object.
    attr_accessor :_proto

    # True if the facet is inferrable.
    attr_accessor :inferrable
    alias :inferrable? :inferrable

    # The owner of the facet, usu. the Component.
    attr_accessor :owner
    alias :component :owner

    # The Context object.
    attr_accessor :context
    # The configuration hash.
    attr_accessor :configuration

    def initialize *args
      @inferrable = false
      super
    end

    @@key_to_proto = { }

    # Returns all the current Facet prototype object.
    def self.prototypes
      @@key_to_proto.values
    end

    # Returns the Facet prototype by its key.
    def self.proto_by_key key
      key = key.to_s
      @@key_to_proto[key]
    end

    # Registers a Facet prototype by its key.
    def self.register_prototype facet_proto, key = nil
      case key
      when Array
        key.map { | t | register_prototype facet_proto, t }
      else
        key ||= facet_proto.key.to_s
        # $stderr.puts "register_prototype(#{facet_proto.inspect}) as #{key.inspect}"
        @@key_to_proto[key] ||= facet_proto
      end
    end

    # Returns true if the Facet is actually inferred.
    def infer?
      #result = 
      inferrable? && inferred?
      # $stderr.puts "#{key} inferrable? => #{inferrable?.inspect}"
      # $stderr.puts "#{key} inferred? => #{inferred?.inspect}"
      # $stderr.puts "#{component.inspect} #{key} infer? result => #{result.inspect}" if result
      # result
    end

    # Returns true if Facet is inferred by some component attribute.
    def inferred?
      false
    end

    def register_prototype!
      self.class.register_prototype self
      self
    end

    # Creates a new Facet instance by cloning a Facet prototype.
    def self.create proto_name, conf = EMPTY_HASH, opts = EMPTY_HASH
      # Get the prototype object.
      case proto_name
      when Facet 
        proto = proto_name
      else
        proto = @@key_to_proto[proto_name.to_s]
      end
      
      # Process early?
      if opts[:early] 
        return nil unless proto
        return nil unless proto.configure_early?
      else
        unless proto
          raise Error, "unknown Facet key #{proto_name.inspect}"
        end
        return nil if proto.configure_early?
      end

      # Ask prototype to reformat its configuration options.
      #$stderr.puts "\nopts = "; pp conf
      conf = proto._reformat_options! conf
      #$stderr.puts "\nopts = "; pp opts
      conf = proto._normalize_options! conf
      #$stderr.puts "\nopts = "; pp conf
      return conf unless conf

      # Clone the prototype.
      obj = proto.dup

      # Remember the object's prototype.
      obj._proto = proto

      # Final opts processing by caller.
      yield conf, obj if block_given?

      # Set the clone's configuration.
      obj._options = conf
      #$stderr.puts "\obj = "; pp obj

      obj
    end

    DISABLED_HASH = { :enabled => false }.freeze

    def _reformat_options! opts
      # Handle short-hand options.
      case opts
      when true
        opts = EMPTY_HASH
      when false
        opts = DISABLED_HASH
      end

      opts
    end


    def key= x
      @key = x.to_s
      x
    end

    # Returns true if the Facet is composable across components.
    def is_composable?
      true
    end

    # Returns true if the Facet can be configured early.
    def configure_early?
      false
    end

    # Returns true if the Facet is enabled.
    def enabled?
      o = _options
      o[:enabled].nil? || o[:enabled]
    end

    # Called when a Facet is going to be attached
    # to a Component.
    # Subclasses may override this.
    def attach_component! c
      c.attach_facet! self
    end

    # Called to compose Facets across Components.
    # For example: module search paths from each Component
    # might be concatenated.
    #
    # Subclasses must override this.
    def compose! facet
      raise "undefined"
    end

    # Render the Facet with the Renderer.
    #
    # Subclasses may override this.
    def render r
    end

    # Ask the Facet to selected any Components that
    # it constrains.
    #
    # Subclasses may override this.
    def select_component!
    end

    # Ask the Facet to resolve and Components that
    # it may depend on.
    #
    # Subclasses may override this.
    def resolve_component!
    end

    # Ask the Facet to require and any Components that
    # it may depend on.
    #
    # Subclasses may override this.
    def require_component!
    end

    # Used for YAML formatting and general inspection.
    #
    # Subclasses may override this.
    def to_a
      [
        [ :class,    self.class.to_s ],
        [ :key,      key ],
        # [ :_options,  _options ],
      ]
    end

  end # class

end # module


