require 'cabar/base'

module Cabar

  ALWAYS_HASH = { :_always => true }.freeze
  NEVER_HASH = { :_never => true }.freeze

  # Represents a constraint by name and/or version.
  # Could be extended to handle hardware architectures, etc.
  class Constraint < Base
    attr_accessor :name
    attr_accessor_type :version, Cabar::Version::Requirement

    # Converts:
    #
    def self.create x
      return x if self === x

      case x
      when true
        x = ALWAYS_HASH
      when false
        x = NEVER_HASH
      when String, Symbol
        x = x.to_s
        x = { :name => x }
      when Regexp
        x = { :name => x }
      when Hash
        x
      end

      # Handle '<name>/<version>' specifications.
      if /^([^\/]+)\/([^\/]+)$/.match(x[:name]) || /^([^=]+)=([^=]+)$/.match(x[:name])
        x = x.dup
        x[:name] = $1
        x[:version] ||= $2
      end

      self.new x
    end
    
    def deepen_dup!
      super
      @_proc = nil
    end

    # Converts:
    #
    # "/name/" => Regexp.new(name)
    # "nam*" => Regexp.new("^nam.*$")
    #
    def _string_to_matcher x
      str = x
      return str unless str

      str = str.to_s
      case str
      when /^\/[^\/]+\/[a-z]*$/
        str = eval str # Yuck: use Regexp.new
      when /[\*\?\[\]]/
        str = str.gsub('*', "\001")
        str = str.gsub('?', "\002")
        str = str.gsub('.', "\\.")
        str = str.gsub("\001", ".*")
        str = str.gsub("\002", ".")
        str = Regexp.new("^#{str}$") 
      end
      # $stderr.puts "#{x.inspect} => #{str.inspect}"
      str
    end
    

    # Lambda taking one argument and returns true.
    TRUE_PROC = lambda { | obj | true }
    # Lambda taking one argument and returns false.
    FALSE_PROC = lambda { | obj | false }

    # Creates a Proc that takes one argument,
    # that returns true if
    # a component matches this constraint. 
    def to_proc
      @_proc ||=
      begin
        case 
        when _options[:_never]
          FALSE_PROC
        when _options[:_always]
          TRUE_PROC
        else
          _make_select_lambda to_hash
        end
      end
    end

    def call(obj)
      to_proc.call(obj)
    end


    # Returns true if object matches this constraint.
    def === obj
      ! ! to_proc.call(obj)
    end

    def _make_select_lambda opts
      # Remove annotations
      opts.delete(:_by)

      # Handle glob.
      opts[:name] = _string_to_matcher opts[:name] if opts[:name]

      # Convert non-lambda matchers to
      # lambdas that take 
      opts.each do | slot_name, _slot_matcher |
        slot_matcher = _slot_matcher # close over binding
        
        # if slot_name == :version && String === slot_matcher
        #  slot_matcher = Cabar::Version::Requirement.create_cabar slot_matcher
        # end

        opts[slot_name] = lambda do | slot_val |
            slot_matcher === slot_val
        end unless Proc === slot_matcher
      end
        
      # Create a lambda that ANDs all the slot matchers
      # together.
      func =
        opts.inject(TRUE_PROC) do | _f, slot |
        f = _f # close over binding
        method, match = *slot
        lambda do | obj |
          f.call(obj) && match.call(obj.send(method))
        end
      end
        
      func
    end
      

    def to_s
      opts = ''
      _options.each do | k, v |
        opts << ";#{k}=#{v}"
      end
      "#{name}/#{version}#{opts}"
    end

    def inspect
      to_s.inspect
    end

    def to_a
      [
       [ :name, name ],
       [ :version, version ],
      ] + _options.to_a
    end

    def to_hash
      opts = _options.dup
      opts[:name] = name if name
      opts[:version] = version if version
      opts
    end

  end # class

end # module

