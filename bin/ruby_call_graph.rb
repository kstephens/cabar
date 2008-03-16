require 'pp'

args = ARGV.dup

class ::Object
  def to_const_str
    to_s
  end
end

class ::Symbol
  def to_const_str
    @to_const_str ||= to_s.freeze
  end
end


C_CALL_str = 'c-call'.freeze
CALL_str = 'call'.freeze
LINE_str = 'line'.freeze
RETURN_str = 'return'.freeze
FALSE_str = 'false'.freeze


######################################################################


# Mapping of file:line to class#method
file_line_to_cls_meth = { }
cls_method_to_file_line_range = { }
file_line_sndr_rcvrs = { }

sndr_rcvrs = [ ]

input = $stdin
n_read = 0
n_processed = 0
until input.eof?
  n_read += 1
  $stderr.write '.' if n_read % 100 == 0

  record = input.readline
  record.chomp!
  event, file, line, meth, cls, *clrs = record.split('|')
  next unless event == C_CALL_str or event == CALL_str or event == LINE_str or event == RETURN_str
  next if clrs.empty?

  cls_meth = nil

  if event == C_CALL_str
    rcvr_file_line = "#{cls}:#{meth}".to_sym
  else
    rcvr_file_line = "#{file}:#{line}".to_sym
  end

  sndr_file_line = clrs.map{|clr| clr.split(':in `').first.to_sym}

  if (event == C_CALL_str or event == LINE_str or event == CALL_str) and ! meth.empty? and cls != FALSE_str
    # Save the class#method for this line number.
    cls_meth = file_line_to_cls_meth[rcvr_file_line] ||= ("#{cls}\##{meth}".to_sym)

    sndr_rcvrs << [ sndr_file_line, cls_meth ]

    $stderr.write '*' if n_processed % 100 == 0
    n_processed += 1
  end

  # puts "#{sndr_file_line.inspect} -> #{rcvr_file_line.inspect} #{cls_meth.inspect}"

end

# Prepare filter for Class#method.
allow = args.shift || '^Cabar::'
allow = allow ? Regexp.new(allow.to_s) : //

# Convert each:
#   [ [ file:line , ...], Class#method rcvr ]
# to:
#   [ [ Class#method senders, ... ], Class#method rcvr ]
# and
# Find first sender that matches the allow filter.
cls_meth_sndr_rcvrs = { }
sndr_rcvrs.each do | x |
  sndrs, rcvr = *x
  # Convert all file:line to class#method.
  sndrs.map!{ | file_line | file_line_to_cls_meth[file_line] || :MAIN }
  # Find first sender in the stack trace that matches the filter. 
  sndr = sndrs.find do | sndr | 
    allow.match(sndr.to_const_str)
  end

  # Ignore senders with no matching rcvr.
  next unless sndr

  # Keep track of each sndr -> rcvr as
  # sender[rcvr] = 1
  (cls_meth_sndr_rcvrs[sndr] ||= { })[rcvr] = true
end

# Convert to { sender Class#method => [ rcvr Class#method, ... ] }
cls_meth_sndr_rcvrs.each do | sndr, rcvrs |
  cls_meth_sndr_rcvrs[sndr] = rcvrs.keys.select{ | rcvr | allow.match(rcvr.to_const_str) }
end

$stderr.puts "\n"
$stderr.puts "#{n_read} lines read"
$stderr.puts "#{n_processed} lines processed"
$stderr.puts "File/line sites #{file_line_to_cls_meth.size}"
$stderr.puts "Unique Class#method senders #{cls_meth_sndr_rcvrs.keys.size}"

# pp file_line_to_cls_meth

# Convert file:line callers to class#method callers.
file_line_sndr_rcvrs.each do | sndr, rcvrs |
  sndr_cls_meth = file_line_to_cls_meth[sndr] || :MAIN
  cls_meth_sndr_rcvrs[sndr_cls_meth] = rcvrs.
    uniq
end


# Get a list of methods for each class.
cls_meths = { }
meth_cls = { }
(cls_meth_sndr_rcvrs.keys + cls_meth_sndr_rcvrs.values).
flatten.uniq.each do | cls_meth |
  cls, meth = *cls_meth.to_const_str.split('#', 2)
  # $stderr.puts "cls = #{cls.inspect} meth = #{meth.inspect}"
  cls = cls.nil? || cls.empty? ? nil : cls.to_sym
  meth = meth.nil? || meth.empty? ? nil : meth.to_sym
  (cls_meths[cls] ||= [ ]) << [ cls_meth, meth ]
  meth_cls[meth] ||= cls
  meth_cls[cls_meth] ||= cls
end


puts "digraph Cabar {"
puts "  overlap=false;"
puts "  splines=true;"

# Do subgraph for each class,
# Imbedd methods in each class subgraph.
cls_meths.each do | cls, meths |
  cls_s = cls.to_const_str.inspect
  puts "  subgraph #{cls_s} {"
  puts "    label=#{cls_s};"
  # puts "    node [ shape=box, style=dotted, label=#{cls_s}, tooltip=#{cls_s} ] #{cls_s};"
  meths.each do | meth |
    cls_meth, meth = *meth
    cls_meth_s = cls_meth.to_const_str.inspect
    meth_s = meth.to_const_str.inspect
    puts "    node [ shape=box, label=#{(cls.to_const_str + "\n#" + meth.to_const_str).inspect}, tooltip=#{cls_meth_s} ] #{cls_meth_s};"
    # puts "    #{cls_s} -> #{cls_meth_s} [ style=dotted, arrowhead=none ];"
  end
  puts "  }"
  puts ""
end
  
cls_meth_sndr_rcvrs.each do | sndr, rcvrs |
  rcvrs.each do | rcvr |
    tooltip = "#{sndr} -> #{rcvr}".inspect
    puts "  #{sndr.to_const_str.inspect} -> #{rcvr.to_const_str.inspect} [ edgetooltip=#{tooltip} ];"
    # puts "  #{sndr.to_const_str.inspect} -> #{meth_cls[rcvr].to_const_str.inspect} [ style=dotted, arrowhead=open, edgeURL="blank:", edgetooltip="#{tooltip"} ];"
  end
end
puts "}"

