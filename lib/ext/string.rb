require 'sentimental'

class String
  def sentiments
    Sentimental.load_defaults
    analyzer = Sentimental.new
    puts self
    analyzer.get_score(self).to_f
  end

  def add_punctuation
    text = self.rstrip
    return text + '.' if text[-1..-1] !~ /(\!|\.|\?)/
  end
end