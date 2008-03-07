class ::Array 
  def uniq_return!
    uniq!
    self
  end

  def flatten_return!
    flatten!
    self
  end

  def cabar_each! 
    until empty?
      yield shift
    end
  end
end

