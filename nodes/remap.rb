class Remap
  attr_accessor :nested

  def initialize(remap_begin:)
    @nested = []
    @trigger = remap_begin
  end

  def build(modes, mode_code)
    nested.map { |n| n.build(modes, mode_code, @trigger) }
  end
end
