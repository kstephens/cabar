require 'cabar'


module Cabar

##
# Debian version string.
#
# See http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-f-Version
#
class Version::Debian
  include Comparable

  # The input string.
  attr_reader :version

  # This is a single (generally small) unsigned integer. It may be omitted, in which case zero is assumed. If it is omitted then the upstream_version may not contain any colons.
  #
  # It is provided to allow mistakes in the version numbers of older versions of a package, and also a package's previous version numbering schemes, to be left behind.
  #
  attr_reader :epoch

  # This is the main part of the version number. It is usually the version number of the original ("upstream") package from which the .deb file has been made, if this is applicable. Usually this will be in the same format as that specified by the upstream author(s); however, it may need to be reformatted to fit into the package management system's format and comparison scheme.
  #
  # The comparison behavior of the package management system with respect to the upstream_version is described below. The upstream_version portion of the version number is mandatory.
  #
  # The upstream_version may contain only alphanumerics[32] and the characters . + - : ~ (full stop, plus, hyphen, colon, tilde) and should start with a digit. If there is no debian_revision then hyphens are not allowed; if there is no epoch then colons are not allowed.
  #
  attr_reader :upstream_version

  # This part of the version number specifies the version of the Debian package based on the upstream version. It may contain only alphanumerics and the characters + . ~ (plus, full stop, tilde) and is compared in the same way as the upstream_version is.
  #
  # It is optional; if it isn't present then the upstream_version may not contain a hyphen. This format represents the case where a piece of software was written specifically to be turned into a Debian package, and so there is only one "debianisation" of it and therefore no revision indication is required.
  #
  # It is conventional to restart the debian_revision at 1 each time the upstream_version is increased.
  #
  # The package management system will break the version number apart at the last hyphen in the string (if there is one) to determine the upstream_version and debian_revision. The absence of a debian_revision compares earlier than the presence of one (but note that the debian_revision is the least significant part of the version number).
  #
  attr_reader :debian_revision

  EPOCH_RX            = '\d+'.freeze
  UPSTREAM_VERSION_RX = '[0-9][0-9A-Za-z\.\+\-\:\~]*'.freeze
  DEBIAN_REVISION_RX  = '[0-9][0-9A-Za-z\.\+\:\~]*'.freeze
  VERSION_RX = /\A(?:(#{EPOCH_RX}):)?(#{UPSTREAM_VERSION_RX}?)(?:-(#{DEBIAN_REVISION_RX}))?\Z/

  def self.correct?(version)
    case version
    when Integer, VERSION_RX
      true
    else 
      false
    end
  end

  # Compares by epoch, upstream_version, debian_revision.
  def <=> x
    case
    when (r = epoch <=> x.epoch) != 0
      r
    when (r = upstream_version <=> x.upstream_version) != 0
      r
    when (r = debian_revision <=> x.debian_revision) != 0
      r
    else
      0
    end
  end

  # Creates new instance.
  def self.create(x)
    return x unless x
    case 
    when self === x
      x
    when x.respond_to?(:version)
      create x.version
    else
      new x
    end
  end


  def initialize(version)
    raise ArgumentError, "Malformed version number string #{version.inspect}" unless
      self.class.correct?(version)

    self.version = version
  end

  def inspect # :nodoc:
    "#<#{self.class} #{@version.inspect}>"
  end

  # Dump only the raw version string, not the complete object.
  def marshal_dump
    [ @version ]
  end

  # Load custom marshal format
  def marshal_load(array)
    self.version = array[0]
  end

  # Decompose the @version string into epoch, upstream_version and debian_revision.
  def normalize!
    if VERSION_RX.match(@version)
      # $stderr.puts "@version = #{@version.inspect}"
      # $stderr.puts "$1 = #{$1.inspect}"
      # $stderr.puts "$2 = #{$2.inspect}"
      # $stderr.puts "$3 = #{$3.inspect}"

      @epoch = ($1 ? $1.to_i : 0)
      @upstream_version = Part.create($2)
      @debian_revision = Part.create($3 || EMPTY_STRING)
    end
    self
  end

  
  # return:: [String] version as string
  #
  def to_s
    @version
  end

  def to_a
    [ @epoch, @upstream_version, @debian_revision ]
  end

  def to_yaml_properties
    [ '@version' ]
  end

  def version=(version)
    version = version.to_s.strip.freeze
    if @version != version
      @version = version
      normalize!
    end
    version
  end

  def yaml_initialize(tag, values)
    self.version = values['version']
  end

  alias eql? == # :nodoc:

  def hash # :nodoc:
    to_a.inject(0) { |hash_code, n| hash_code + n.hash }
  end

  ################################################

  # Represents the comparable parts of Debian version
  # upstream_version and debian_revision.
  #
  class Part
    include Comparable
    
    def to_s
      @to_s
    end

    def to_a
      @to_a
    end

    def <=> x
      @to_a <=> x.to_a
    end

    def hash
      @to_a.hash
    end

    def self.create x
      case x
      when self
        x
      when String
        new x
      when Integer
        new x
      when Array
        new x
      when false, nil
        x
      else
        raise ArgumentError, "Bad format for #{self} #{x.inspect}"
      end
    end

    MIN_NUMBER = -99999

    def initialize x
      case x
      when Array
        @to_s = x.join('').freeze
        @to_a = x.dup.freeze
      when Integer
        @to_s = x.to_s.freeze
        @to_a = [ '', x ].freeze
      when String
        @to_s = x.dup.freeze
        @to_a = [ ]
        x.scan(/([^0-9]*)([0-9]*)/) do | x |
          unless $1.empty? && $2.empty?
            @to_a << $1.freeze
            @to_a << ($2.empty? ? MIN_NUMBER : $2.to_i)
          end
        end
        @to_a.freeze
      else
        raise ArgumentError, "Unexpected format for #{self.class} #{x.inspect}"
      end
    end
  end # class

  ########################################################

  def self.create_cabar x
    # $stderr.puts "V = #{x.inspect}"
    case x
    when nil, false, Cabar::Version::Debian
      x
    when Cabar::Version::Requirement
      Cabar::Version.create(x.to_s)
    else
      warn "Do not use Float #{x.inspect} for version" if Float === x
      Cabar::Version::Debian.create(x.to_s.sub(/^v/i, ''))
    end
  end
end # class

end # module


