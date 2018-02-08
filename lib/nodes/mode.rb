class Mode
  attr_accessor :nested

  def initialize(mode:)
    @nested = []
    @mode = mode
  end

  def build(modes, _)
    @mode_code = modes[@mode]
    nested.map { |n| n.build(modes, @mode_code) }
  end
end
