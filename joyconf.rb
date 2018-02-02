class Joyconf
  attr_accessor :mode_code

  def self.compile(source)
    output = []
    next_number = 0
    modes = {}
    mode_code = 0
    remap_key = nil
    table_line = {}

    source.lines.each do |line|
      if line.split(' ').first == 'mode'
        mode_name = line.split(' ').last.delete("'")
        modes[mode_name] = next_number
        next_number = next_number + 1
      end
    end

    tokenize(source.lines).each do |tupple|
      if tupple.key?(:mode)
        mode_code = modes[tupple[:mode]]
      elsif tupple.key?(:remap_begin)
        remap_key = tupple[:remap_begin]
      elsif tupple.key?(:remap_end)
        remap_key = nil
      elsif tupple.key?(:command)
        sanitized_button_name = tupple[:trigger_name].delete('.')
                                  .delete('<').delete('>').delete('*')
        trigger = trigger_code(tupple[:trigger_name])
        cmd = tupple[:command]
        cmd = build_switch_mode(cmd, modes) if cmd =~ /switch_to_mode/
        output << "#{remap_key}:=,#{mode_code}0" if remap_key
        output << "#{sanitized_button_name}:#{cmd},#{mode_code}#{trigger}"
      elsif tupple.key?(:macro)
        trigger = trigger_code(tupple[:trigger_name])
        sanitized_button_name = tupple[:trigger_name].delete('.')
                                  .delete('<').delete('>').delete('*')
        tupple[:macro].delete('"').split('').each do |char|
          output << "#{sanitized_button_name}:#{char},#{mode_code}#{trigger}"
        end
      end

      table_line = {}
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
      elsif sanitized == '}'.delete(' ')
        table << { remap_end: '}' }
      elsif sanitized == ''.delete(' ')
      else
        splitted = sanitized.split(':')
        button_name = splitted[0].delete(' ')
        cmd = splitted[1].delete("\n").delete(' ')

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
