Bundler.require

class Joyconf
  attr_accessor :mode_code

  def self.compile(source)
    output = []
    next_number = 0
    modes = {}
    mode_code = 0
    remap_key = nil

    source.lines.each do |line|
      if line.split(' ').first == 'mode'
        mode_name = line.split(' ').last.gsub("'",'')
        modes.merge!({ mode_name => next_number })
        next_number = next_number + 1
      end
    end

    source.lines.each do |line|
      sanitized = line.split('#').first.gsub("\n",'')

      if sanitized.split(' ').first == 'mode'
        current_mode = line.split(' ').last.gsub("'",'')
        mode_code = modes[current_mode]
      elsif sanitized.split(' ').first == 'remap'
        remap_key = sanitized.split(' ')[1]
      elsif sanitized == '}'.gsub(' ','')
        inside_remap = nil
      elsif sanitized == "".gsub(' ','')
      else
        splitted = sanitized.split(':')
        button_name = splitted[0]
        sanitized_button_name = button_name.gsub('.','')
                        .gsub('<','').gsub('>','').gsub('*','')
        cmd = splitted[1].gsub("\n",'').gsub(' ','')
        trigger = trigger_code(button_name)

        if cmd =~ /"(.*?)"/ # has quotes, its a macro
          cmd.gsub('"','').split('').each do |char|
            output << "#{sanitized_button_name}:#{char},#{mode_code}#{trigger}"
          end
        else
          if cmd =~ /switch_to_mode/
            cmd = build_switch_mode(cmd, modes)
          end

          output << "#{remap_key}:=,#{mode_code}0" if remap_key
          output << "#{sanitized_button_name}:#{cmd},#{mode_code}#{trigger}"
        end

      end
    end

    result = output.join("\n")
    result << "\n"

    return result
  end

  def self.build_switch_mode(cmd, modes)
    name_position = cmd =~ /\'.*?\'/
    mode_name = cmd[(name_position + 1)..(cmd.length - 2)]
    return "switch_to_mode#{modes[mode_name]}"
  end

  def self.trigger_code(button_name)
    return '1' if button_name =~ /\./
    return '4' if button_name =~ /\</
    return '3' if button_name =~ /\>/
    return '2' if button_name =~ /\*/
    return '0'
  end
end
