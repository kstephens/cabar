
require 'cabar/env'

module Cabar
  # Environment variable manager.
  # Standin for global ENV.
  class Environment
    include Cabar::Env

    def initialize opts = nil
      @h = opts ? opts.dup : { }
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
      @h[key]
    end


    def []=(key, value)
      @h[check_read_only!(key)] = value
    end


    def check_read_only! key
      raise TypeError, "key must be String" unless String === key
      raise ArgumentError, "key #{key.inspect} is read-only" if @read_only[key]
      key
    end


    # Marks a key read-only.
    # Returns self.
    def read_only! key
      @read_only[key] = true
      self
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


    def delete *args
      args.each do | k |
        @h.delete(check_read_only!(k))
      end
    end


    def to_hash
      @h.dup
    end


    def from_hash! h
      h.each do | k, v |
        self[k] = v
      end
      self
    end


    # Executes block while setting dst with each element of env.
    # dst is restored after completion of the block.
    # nil values are equivalent to deleting the dst element
    #
    # dst defaults to the global ENV
    #
    # NOT THREAD-SAFE if dst == ENV
    def with dst = nil
      dst ||= ENV
      with_env(@h, dst) do
        yield
      end
    end

  end # module

end # module

