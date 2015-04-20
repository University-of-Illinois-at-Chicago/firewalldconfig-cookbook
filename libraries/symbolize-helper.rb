# rubocop: disable FileName
# Adapted from
#  http://apidock.com/rails/v4.0.2/Hash/deep_symbolize_keys
module SymbolizeHelper
  def self.symbolize_recursive(hash)
    {}.tap do |h|
      hash.each { |key, value| h[key.to_sym] = map_value(value) }
    end
  end

  def self.map_value(thing)
    case thing
    when Hash
      symbolize_recursive(thing)
    when Array
      thing.map { |v| map_value(v) }
    else
      thing
    end
  end
end
