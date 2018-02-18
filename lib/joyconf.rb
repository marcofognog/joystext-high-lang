require 'lib/parse_helper'
require 'lib/nodes/remap'
require 'lib/nodes/command'
require 'lib/nodes/mode'

class Joyconf
  class UnrecognizedTriggerName < StandardError; end
  class UnnamedMode < StandardError; end
  class UnrecognizedDefinition < StandardError; end
  class SwitchModeWithoutTarget < StandardError; end
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
        if current_mode
          ast.last.nested << Remap.new(line)
          remap_definition = true
        else
          ast << Remap.new(line)
          remap_definition = true
        end
      elsif line.key?(:remap_end)
        remap_definition = false
      elsif line.key?(:mode)
        current_mode = line[:mode]
        ast << Mode.new(line)
      elsif line.key?(:command)
        if current_mode && remap_definition
          ast.last.nested.last.nested << Command.new(line)
        elsif current_mode || remap_definition
          ast.last.nested << Command.new(line)
        else
          ast << Command.new(line)
        end
      else
        ast << line # remove this?
      end
    end
    ast
  end

  def tokenize(lines)
    table = []
    lines.each_with_index do |line, line_num|
      sanitized = line.split('#').first.delete("\n")

      if mode_definition?(sanitized)
        current_mode = sanitized.split(' ').last.delete("'")
        unless sanitized =~ /mode\s'.+'/
          raise UnnamedMode, "I need a name for the mode on line #{line_num + 1}"
        else
          table << { mode: current_mode }
        end
      elsif open_remap_definition?(sanitized)
        table << { remap_begin: sanitized.split(' ')[1] }
      elsif close_remap_definition?(sanitized)
        table << { remap_end: '}' }
      elsif empty_line?(sanitized)
      elsif command_definition?(sanitized)
        splitted = sanitized.split(':')
        button_name = splitted[0].delete(' ')
        check_valid_trigger_name(button_name, line_num)

        cmd = splitted[1].delete("\n").delete(' ')
        table << { trigger_name: button_name, command: cmd }
      else
        raise UnrecognizedDefinition, "Sintax error in line #{line_num + 1}"
      end
    end
    table
  end

  def mode_definition?(sanitized)
    sanitized.split(' ').first == 'mode'
  end

  def open_remap_definition?(sanitized)
    sanitized.split(' ').first == 'remap'
  end

  def close_remap_definition?(sanitized)
    sanitized.delete(' ') == '}'
  end

  def empty_line?(sanitized)
    sanitized.delete(' ') == ''
  end

  def command_definition?(sanitized)
    sanitized =~ /.+\:.+/
  end

  def check_valid_trigger_name(name, line)
    pure = sanitized_button_name(name)
    line_offset = 1
    pure.split('+').each do |trigger_name|
      unless VALID_TRIGGER_NAMES.include?(trigger_name)
        error_msg = "Syntax error on line #{line + line_offset}:"
        raise UnrecognizedTriggerName, error_msg
      end
    end
  end
end
