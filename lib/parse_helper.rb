module ParseHelper
  def sanitized_button_name(name)
    name.delete('.').delete('<').delete('>').delete('*')
  end

  def build_switch_mode(cmd, modes)
    name_position = cmd =~ /\'.*?\'/
    raise 'Syntax error: switch_mode needs a taget' if name_position.nil?
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
