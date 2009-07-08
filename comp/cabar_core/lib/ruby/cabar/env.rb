
module Cabar
  # ENV Environment variable support.
  module Env

    # Executes block while defining the global ENV with each element of env.
    # ENV is restored after completion of the block.
    # nil values are equivalent to deleting the ENV var.
    #
    # NOT THREAD-SAFE.
    def with_env env, dst = nil
      dst ||= ENV
      save_env = { }

      env.each do | k, v |
        k = k.to_s
        save_env[k] = dst[k]
        if v
          dst[k] = (v = v.to_s)
        else
          dst.delete(k)
        end
        # $stderr.puts "  #{k}=#{v.inspect}"
      end

      yield

    ensure
      env.keys do | k |
        k = k.to_s
        if v = save_env[k]
          dst[k] = v
        else
          dst.delete(k)
        end
      end
    end
    
  end # module

end # module

