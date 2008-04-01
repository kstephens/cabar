require 'cabar/base'

require 'cabar/version'
require 'cabar/version/requirement'


module Cabar

  ALWAYS_HASH = { :_always => true }.freeze
  NEVER_HASH = { :_never => true }.freeze

  # Represents a constraint by name and/or version.
  # Can handle basic hardware architectures.
  #
  # nil, true, '' ALWAYS MATCH
  # false         NEVER MATCHES
  # 'name/version' matches name and version
  # 'arch=i386'    matches only where arch == 'i386'
  # 'name*'        matches all name that start with 'name'
  #
  class Constraint < Base
    attr_accessor :name
    attr_accessor_type :version, Cabar::Version::Requirement

    # Converts:
    #
    def self.create x
      case x
      when self
        return x
      when nil, true, ''
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
      
      # Handle '<type>:<name>'
      if /^([^:]+):(.*)$/.match(x[:name])
        x[:component_type] = $1
        x[:name] = $2
      end

      # Handle options.
      if /(^|,)(([a-z_0-9]+=[^,]*(,|$))+)/i.match(x[:name])
        name_version = $`
        opts = $2
        x[:name] = name_version
        opts.scan(/([a-z_0-9]+)=([^,]+)(,|$)/) do | m |
          x[$1.to_sym] = $2
        end
        # $stderr.puts "x = #{x.inspect}"
      end

      # Handle '<name>/<version>' specifications.
      if /^([^\/]*)\/([^\/]+)$/.match(x[:name]) 
        x = x.dup
        x[:name] = $1
        x[:version] ||= $2
      end

      # Handle ''.
      x[:name] = nil if x[:name] && x[:name].empty?

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
    def self.string_to_matcher x
      return x unless String === x
      str = x

      case str
      when /^\/[^\/]+\/[a-z]*$/
        str = eval str # Yuck: use Regexp.new
      when /[\*\?\[\]]/
        str = str.gsub('*', "\001")
        str = str.gsub('?', "\002")
        str = str.gsub('.', "\003")
        str = str.gsub("\001", ".*")
        str = str.gsub("\002", ".")
        str = str.gsub("\003", "\\.")
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

      # Handle name glob.
      opts[:name] = Constraint.string_to_matcher opts[:name] if opts[:name]

      # Convert non-lambda matchers to
      # lambdas that take 
      opts.each do | slot_name, _slot_matcher |
        slot_matcher = _slot_matcher # close over binding
        
        unless Proc === slot_matcher
          slot_matcher = Constraint.string_to_matcher slot_matcher
          # $stderr.puts "opts[#{slot_name.inspect}] = #{slot_matcher.inspect} === ???"
          opts[slot_name] = lambda do | slot_val |
            slot_matcher === slot_val
          end 
        end
      end
     
      # Create a lambda that ANDs all the slot matchers
      # together.
      func =
        opts.inject(TRUE_PROC) do | _f, slot |
        f = _f # close over binding
        method, match = *slot
        lambda do | obj |
          # $stderr.puts "  #{match}.call(#{obj}.#{method} => #{obj.send(method)})"
          f.call(obj) && match.call(obj.send(method))
        end
      end
        
      func
    end
      

    def to_s
      s = ''
      o = _options.dup
      if x = o[:component_type]
        s << "#{o[:type]}:" unless x == Component::CABAR
        o.delete(:component_type)
      end
      s << "#{name}" if name
      s << "/#{version}" if version
      o.each do | k, v |
        s << ',' unless s.empty?
        s << "#{k}=#{v}"
      end
      s
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

