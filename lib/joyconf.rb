require 'lib/parse_helper'
require 'lib/nodes/macro'
require 'lib/nodes/remap'
require 'lib/nodes/command'
require 'lib/nodes/mode'

class Joyconf
  class UnrecognizedTriggerName < StandardError; end
  class UnnamedMode < StandardError; end

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
        if remap_definition || current_mode
          ast.last.nested << Macro.new(line)
        else
          ast << Macro.new(line)
        end
      else
        ast << line
      end
    end
    ast
  end

  def tokenize(lines)
    table = []
    lines.each_with_index do |line, line_num|
      sanitized = line.split('#').first.delete("\n")

      if sanitized.split(' ').first == 'mode'
        current_mode = line.split(' ').last.delete("'")
        if sanitized.split(' ').count == 1 || current_mode == ''
          raise UnnamedMode, "I need a name for the mode on line #{line_num + 1}"
        else
          table << { mode: current_mode }
        end
      elsif sanitized.split(' ').first == 'remap'
        table << { remap_begin: sanitized.split(' ')[1] }
      elsif sanitized.delete(' ') == '}'
        table << { remap_end: '}' }
      elsif sanitized.delete(' ') == ''
      else
        splitted = sanitized.split(':')
        button_name = splitted[0].delete(' ')
        check_valid_trigger_name(button_name, line_num)

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

  def check_valid_trigger_name(name, line)
    pure = sanitized_button_name(name)
    line_offset = 1
    unless VALID_TRIGGER_NAMES.include?(pure)
      error_msg = "Syntax error on line #{line + line_offset}:"
      raise UnrecognizedTriggerName, error_msg
    end
  end

  def quoted?(cmd)
    cmd =~ /"(.*?)"/
  end
end
