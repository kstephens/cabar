require 'cabar'

module Cabar

  # Common error base class for Cabar.
  class Error < ::Exception

    # Format a Error in cabar YAML format.
    def self.cabar_format err
      msg = [ ]
      msg << Cabar.yaml_header(:error)
      msg << "    message: #{err.inspect.inspect}"
      msg << "    backtrace: "
      if err.respond_to? :backtrace
        err.backtrace.each do | x |
          msg << "    - #{x.to_s.inspect}"
        end
      end
      msg << ''
      msg.join("\n")
    end

  end # class

end # module


