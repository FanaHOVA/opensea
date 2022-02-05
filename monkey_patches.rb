class Array
  def median
    return nil if self.empty?
    sorted = self.compact.sort
    median_index = sorted.size / 2
    sorted.size % 2 == 1 ? sorted[median_index] : sorted[median_index - 1..median_index].mean
  end

  def mean
    return nil if self.empty?
    self.sum / self.size.to_f
  end

  def count_of_each
    Hash[self.group_by(&:itself).map { |k,v| [k, v.size] }].sort_by { |k,v| -v }.to_h
  end
end

class Numeric
  def percent_of(n, decimal_places = 2)
    return 0 if n&.zero?
    (self.to_f / n.to_f * 100.0).round(decimal_places)
  end
end

class String
  def dollars_to_numeric
    self.gsub(/[$,]/, '').to_f
  end
end
