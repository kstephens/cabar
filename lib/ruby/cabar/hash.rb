class ::Hash
  def cabar_merge! h, path = [ ]
    case h
    when Hash
      h.each do | k, v |
        self[k] = v
        case v
        when Hash
          self[k].cabar_merge! v, path + [ k ]
        end
      end
    else
      raise ArgumentError, "Expected Hash at #{path.join('.')}"
    end
    self
  end
end

