class Joyconf
  class UnrecognizedTriggerName < StandardError; end

  attr_accessor :mode_code

  VALID_TRIGGER_NAMES = [
    'F1', 'F2','F3', 'F4',
    'A1', 'A2', 'A3', 'A4',
    'S1', 'S2', 'S3', 'S4',
    'start', 'select'
  ]

  def self.compile(source)
    output = []
    next_number = 0
    modes = {}
    mode_code = 0
    remap_key = nil

    source.lines.each do |line|
      if line.split(' ').first == 'mode'
        mode_name = line.split(' ').last.delete("'")
        modes[mode_name] = next_number
        next_number += 1
      end
    end

    tokenize(source.lines).each do |definition|
      if definition.key?(:mode)
        mode_code = modes[definition[:mode]]
      elsif definition.key?(:remap_begin)
        remap_key = definition[:remap_begin]
      elsif definition.key?(:remap_end)
        remap_key = nil
      elsif definition.key?(:command)
        trigger = trigger_code(definition[:trigger_name])
        cmd = definition[:command]
        button = sanitized_button_name(definition[:trigger_name])
        cmd = build_switch_mode(cmd, modes) if cmd =~ /switch_to_mode/
        output << "#{remap_key}:=,#{mode_code}0" if remap_key
        output << "#{button}:#{cmd},#{mode_code}#{trigger}"
      elsif definition.key?(:macro)
        trigger = trigger_code(definition[:trigger_name])
        button = sanitized_button_name(definition[:trigger_name])
        definition[:macro].delete('"').split('').each do |char|
          output << "#{button}:#{char},#{mode_code}#{trigger}"
        end
      else
        raise 'I dont know what to do'
      end
    end

    result = output.join("\n")
    result << "\n"

    return result
  end

  def self.tokenize(lines)
    table = []
    lines.each do |line|
      sanitized = line.split('#').first.delete("\n")

      if sanitized.split(' ').first == 'mode'
        current_mode = line.split(' ').last.delete("'")
        table << { mode: current_mode }
      elsif sanitized.split(' ').first == 'remap'
        table << { remap_begin: sanitized.split(' ')[1] }
      elsif sanitized.delete(' ') == '}'
        table << { remap_end: '}' }
      elsif sanitized.delete(' ') == ''
      else
        splitted = sanitized.split(':')
        button_name = splitted[0].delete(' ')
        cmd = splitted[1].delete("\n").delete(' ')

        check_valid_trigger_name(button_name)

        if quoted?(cmd)
          table << {
            trigger_name: button_name,
            macro: cmd
          }
        else
          table << {
            trigger_name: button_name,
            command: cmd
          }
        end
      end
    end
    table
  end

  def self.check_valid_trigger_name(name)
    pure = sanitized_button_name(name)
    raise UnrecognizedTriggerName unless VALID_TRIGGER_NAMES.include?(pure)
  end

  def self.sanitized_button_name(name)
    name.delete('.').delete('<').delete('>').delete('*')
  end

  def self.quoted?(cmd)
    cmd =~ /"(.*?)"/
  end

  def self.build_switch_mode(cmd, modes)
    name_position = cmd =~ /\'.*?\'/
    mode_name = cmd[(name_position + 1)..(cmd.length - 2)]
    "switch_to_mode#{modes[mode_name]}"
  end

  def self.trigger_code(button_name)
    return '1' if button_name =~ /\./
    return '4' if button_name =~ /\</
    return '3' if button_name =~ /\>/
    return '2' if button_name =~ /\*/
    return '0'
  end
end
