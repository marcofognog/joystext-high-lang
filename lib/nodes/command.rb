class Command
  include ParseHelper

  attr_accessor :out, :remap_trigger, :mode

  def initialize(trigger_name:, command:)
    @trigger = trigger_name
    @command = command
    @out = []
  end

  def build(modes, mode, remap_trigger = nil)
    @remap_trigger = remap_trigger
    @mode = mode

    if text?
      text_chars.each { |char| add_action(char) }
    else
      cmd = switch_mode? ? build_switch_mode(@command, modes) : @command
      add_action(cmd)
    end

    out.join("\n")
  end

  def add_remap_flag
    out << "#{remap_trigger}:=,#{mode}0" if remap_trigger
  end

  def add_action(cmd)
    add_remap_flag
    button = sanitized_button_name(@trigger)
    out << "#{button}:#{cmd},#{mode}#{trigger_code(@trigger)}"
  end

  def text_chars
    @command.delete('"').split('')
  end

  def text?
    @command =~ /"(.*?)"/
  end

  def switch_mode?
    @command =~ /switch_to_mode/
  end

  def build_switch_mode(cmd, modes)
    name_position = cmd =~ /\'.*?\'/
    raise Joyconf::SwitchModeWithoutTarget,
          'Syntax error: switch_mode needs a taget' if name_position.nil?
    mode_name = cmd[(name_position + 1)..(cmd.length - 2)]
    "switch_to_mode#{modes[mode_name]}"
  end

  def trigger_code(button_name)
    return '1' if button_name =~ /\./
    return '4' if button_name =~ /\</
    return '3' if button_name =~ /\>/
    return '2' if button_name =~ /\*/
    return '0'
  end
end

