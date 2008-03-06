class ::Hash
  def merge! h, path = [ ]
    case h
    when Hash
      h.each do | k, v |
        self[k] = v
        case v
        when Hash
          self[k].merge! v, path + [ k ]
        end
      end
    else
      raise("Expected Hash at #{path.join('.')}")
    end
    self
  end
end

