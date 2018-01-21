class Joyconf
  attr_accessor :mode_code

  def self.compile(source)
    output = []
    next_number = 0
    modes = {}
    mode_code = 0

    source.lines.each do |line|
      if line.split(' ').first == 'mode'
        mode_name = line.split(' ').last.gsub("'",'')
        modes.merge!({ mode_name => next_number })
        next_number = next_number + 1
      end
    end

    source.lines.each do |line|
      sanitized = line.split('#').first

      if sanitized.split(' ').first == 'mode'
        current_mode = line.split(' ').last.gsub("'",'')
        mode_code = modes[current_mode]
      elsif sanitized == "\n" || sanitized == ""
      else
        splitted = sanitized.split(':')
        button_name = splitted[0]
        cmd = splitted[1].gsub("\n",'').gsub(' ','')

        if cmd =~ /switch_to_mode/
          name_position = cmd =~ /\'.*?\'/
          mode_name = cmd[(name_position + 1)..(cmd.length - 2)]
          m_code = modes[mode_name]
          cmd = "switch_to_mode#{m_code}"
        end

        trigger = trigger_code(button_name)

        output << "#{button_name[-2..-1]}:#{cmd},#{mode_code}#{trigger}"
      end
    end

    result = output.join("\n")
    result << "\n"

    return result
  end

  def self.trigger_code(button_name)
    if button_name =~ /\./
      return '1'
    elsif button_name =~ /\</
      return '4'
    elsif button_name =~ /\>/
      return '3'
    elsif button_name =~ /\*/
      return '2'
    else
      return '0'
    end
  end
end
