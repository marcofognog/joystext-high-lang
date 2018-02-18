class Command
  include ParseHelper

  def initialize(trigger_name:, command:)
    @trigger = trigger_name
    @command = command
  end

  def build(modes, mode, remap_trigger = nil)
    out = []
    button = sanitized_button_name(@trigger)
    cmd = @command
    if quoted?(cmd)
      cmd.delete('"').split('').each do |char|
        out << "#{remap_trigger}:=,#{mode}0" if remap_trigger
        out << "#{button}:#{char},#{mode}#{trigger_code(@trigger)}"
      end
    else
      cmd = build_switch_mode(cmd, modes) if cmd =~ /switch_to_mode/
      out << "#{remap_trigger}:=,#{mode}0" if remap_trigger
      out << "#{button}:#{cmd},#{mode}#{trigger_code(@trigger)}"
    end

    out.join("\n")
  end

  def quoted?(cmd)
    cmd =~ /"(.*?)"/
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

