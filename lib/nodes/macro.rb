class Macro
  include ParseHelper

  def initialize(trigger_name:, macro:)
    @trigger = trigger_name
    @macro = macro
  end

  def build(_, mode_code, remap_trigger = nil)
    output = []
    trigger = trigger_code(@trigger)
    button = sanitized_button_name(@trigger)
    @macro.delete('"').split('').each do |char|
      output << "#{remap_trigger}:=,#{mode_code}0" if remap_trigger
      output << "#{button}:#{char},#{mode_code}#{trigger}"
    end
    output
  end
end
