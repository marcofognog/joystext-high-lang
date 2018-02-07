module ParseHelper
  def sanitized_button_name(name)
    name.delete('.').delete('<').delete('>').delete('*')
  end

  def build_switch_mode(cmd, modes)
    name_position = cmd =~ /\'.*?\'/
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

class Joyconf
  class UnrecognizedTriggerName < StandardError; end
  include ParseHelper

  VALID_TRIGGER_NAMES = %w[
    F1 F2 F3 F4
    A1 A2 A3 A4
    S1 S2 S3 S4
    start select
  ].freeze

  def compile(source)
    output = []
    mode_code = 0

    modes = discover_modes(source.lines)

    abstract_syntax_tree = parse(source)
    abstract_syntax_tree.each do |node|
      output << node.build(modes, mode_code)
    end

    result = output.join("\n")
    result << "\n"
  end

  def discover_modes(lines)
    modes = {}
    count = 0

    lines.each do |line|
      if line.split(' ').first == 'mode'
        mode_name = line.split(' ').last.delete("'")
        modes[mode_name] = count
        count += 1
      end
    end

    modes
  end

  def parse(source)
    ast = []
    remap_definition = false
    current_mode = nil

    tokenize(source.lines).each do |line|
      if line.key?(:remap_begin)
        ast << Remap.new(line)
        remap_definition = true
      elsif line.key?(:remap_end)
        remap_definition = false
      elsif line.key?(:mode)
        current_mode = line[:mode]
        ast << Mode.new(line)
      elsif line.key?(:command)
        if remap_definition || current_mode
          ast.last.nested << Command.new(line)
        else
          ast << Command.new(line)
        end
      elsif line.key?(:macro)
        ast << Macro.new(line)
      else
        ast << line
      end
    end
    ast
  end

  def tokenize(lines)
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
        check_valid_trigger_name(button_name)

        cmd = splitted[1].delete("\n").delete(' ')
        table << if quoted?(cmd)
                   { trigger_name: button_name, macro: cmd }
                 else
                   { trigger_name: button_name, command: cmd }
                 end
      end
    end
    table
  end

  def check_valid_trigger_name(name)
    pure = sanitized_button_name(name)
    raise UnrecognizedTriggerName unless VALID_TRIGGER_NAMES.include?(pure)
  end

  def quoted?(cmd)
    cmd =~ /"(.*?)"/
  end
end

class Remap
  attr_accessor :nested

  def initialize(remap_begin:)
    @nested = []
    @trigger = remap_begin
  end

  def build(modes, mode_code)
    nested.map { |n| n.build(modes, mode_code, @trigger) }
  end
end

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
    cmd = build_switch_mode(cmd, modes) if cmd =~ /switch_to_mode/
    out << "#{remap_trigger}:=,#{mode}0" if remap_trigger
    out << "#{button}:#{cmd},#{mode}#{trigger_code(@trigger)}"
    out.join("\n")
  end
end

class Macro
  include ParseHelper

  def initialize(trigger_name:, macro:)
    @trigger = trigger_name
    @macro = macro
  end

  def build(_, mode_code)
    output = []
    trigger = trigger_code(@trigger)
    button = sanitized_button_name(@trigger)
    @macro.delete('"').split('').each do |char|
      output << "#{button}:#{char},#{mode_code}#{trigger}"
    end
    output
  end
end

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
