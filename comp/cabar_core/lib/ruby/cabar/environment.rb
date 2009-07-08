
require 'cabar/env'

module Cabar
  # Environment variable manager.
  # Standin for global ENV.
  class Environment
    include Cabar::Env

    def initialize
      @h = { }
      @read_only = { }
    end


    def dup
      super.dup_deepen!(self)
    end


    def dup_deepen! src
      @h = @h.dup
      @read_only = @read_only.dup
      self
    end


    def [](key)
      raise TypeError, "key must be String" unless String === key
    end


    def []=(key, value)
      raise TypeError, "key must be String" unless String === key
      raise ArgumentError, "key #{key.inspect} is read-only" if @read_only[key]
      @h[key] = value
    end


    def read_only! key
      @read_only[key] = true
    end


    def read_only? key
      ! ! @read_only[key]
    end


    def each &blk
      @h.each &blk
    end


    def keys
      @h.keys
    end


    def values
      @h.values
    end


    # Executes block while defining the global ENV with each element of env.
    # ENV is restored after completion of the block.
    # nil values are equivalent to deleting the ENV var.
    #
    # NOT THREAD-SAFE.
    def with_env dst = nil
      dst ||= ENV
      with_env(@h, dst) do
        yield
      end
    end

  end # module

end # module

