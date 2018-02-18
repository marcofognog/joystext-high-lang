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
end

