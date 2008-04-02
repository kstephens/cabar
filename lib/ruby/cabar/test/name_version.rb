# -*- ruby -*-

require 'cabar'
require 'cabar/component'
require 'cabar/version'


module Cabar::Test; end

class Cabar::Test::NameVersion
  attr_accessor :name
  attr_accessor :version
  attr_accessor :component_type
  attr_accessor :_opts

  def version= x
    @version = Cabar::Version.create_cabar x
  end

  def initialize opts = EMPTY_HASH
    @component_type = Cabar::Component::CABAR
    opts.each do | k, v |
      s = "#{k}="
      if respond_to? s
        send(s, v)
        opts.delete(k)
      end
    end
    @_opts = opts
    # $stderr.puts "#{self.inspect}"
  end

  def method_missing sel, *args
    # $stderr.puts "sel = #{sel.inspect} args = #{args.inspect}"
    if sel.to_s =~ /^[a-z_0-9]+/i && args.size == 0 && ! block_given?
      return @_opts[sel.to_sym]
    end
    super
  end

end

