$LOAD_PATH << '.'
require 'joyconf'

describe Joyconf do
  it 'translates the trigger types' do
    snippet = <<END
F1:a
.F2: b
>F3:c
<F4:d
*A1:e
END
    expected = <<END
F1:a,00
F2:b,01
F3:c,03
F4:d,04
A1:e,02
END
    expect(Joyconf.new.compile(snippet)).to eq(expected)
  end

  it 'doesnt crop longer triger names' do
    snippet = <<END
start:a
select: b
.F2: c
END
    expected = <<END
start:a,00
select:b,00
F2:c,01
END
    expect(Joyconf.new.compile(snippet)).to eq(expected)
end

  it 'controls the modes' do
    snippet = <<END
mode 'text'

F1:a
F2:switch_to_mode 'macros'
F3:switch_to_mode 'nav'
mode 'macros'
F1:b
F2:switch_to_mode 'text'
F3:switch_to_mode 'nav'
mode 'nav'
F1:click_left
F2:switch_to_mode 'text'
F3:switch_to_mode 'macros'
END
    expected = <<END
F1:a,00
F2:switch_to_mode1,00
F3:switch_to_mode2,00
F1:b,10
F2:switch_to_mode0,10
F3:switch_to_mode2,10
F1:click_left,20
F2:switch_to_mode0,20
F3:switch_to_mode1,20
END
    expect(Joyconf.new.compile(snippet)).to eq(expected)
  end

  it 'supports spaces and comments' do
    snippet = <<END
mode 'text'

# this is a comment
F1:a
F2:b # inline comment
END
    expected = <<END
F1:a,00
F2:b,00
END
    expect(Joyconf.new.compile(snippet)).to eq(expected)
  end

  it 'remaps buttons' do
    snippet = <<END
remap S1 {
  F1:a
  F2:b
}
F3:c
END
    expected = <<END
S1:=,00
F1:a,00
S1:=,00
F2:b,00
F3:c,00
END
    expect(Joyconf.new.compile(snippet)).to eq(expected)
  end

  it 'deals well with spaces' do
    snippet = <<END
F1: shift + a
F2: b
END
    expected = <<END
F1:shift+a,00
F2:b,00
END
    expect(Joyconf.new.compile(snippet)).to eq(expected)
  end

  it 'defines macros' do
    snippet = <<END
F1: "thanks"
F2: b
END
    expected = <<END
F1:t,00
F1:h,00
F1:a,00
F1:n,00
F1:k,00
F1:s,00
F2:b,00
END
    expect(Joyconf.new.compile(snippet)).to eq(expected)
  end

  it 'throws error for unrecognized triggers' do
    snippet = <<END
F1: "thanks"
F5: b
END
    expect do
      Joyconf.new.compile(snippet)
    end.to raise_error Joyconf::UnrecognizedTriggerName, /Syntax error on line 2/
  end

  context 'throws error for unrecognized definitions' do
    it 'incomplete defintion' do
      snippet = <<END
mode
F5: b
END
      expect do
        Joyconf.new.compile(snippet)
      end.to raise_error Joyconf::UnnamedMode
    end

    it 'mode with empty quotes' do
      snippet = <<END
mode ''
F5: b
END
      expect do
        Joyconf.new.compile(snippet)
      end.to raise_error Joyconf::UnnamedMode
    end

    it 'lack of quotes in space definition' do
      snippet = <<END
mode sfa
F5: b
END
      expect { Joyconf.new.compile(snippet) }.to raise_error
    end

    it 'unrecognized identifier in spaced definition' do
      snippet = <<END
invalid 'name'
F5: b
END
      expect { Joyconf.new.compile(snippet) }.to raise_error
    end

    it 'unclosed remap' do
      snippet = <<END
remap S1 {
F5: b
END
      expect { Joyconf.new.compile(snippet) }.to raise_error
    end

    it 'extra remap end' do
      snippet = <<END
remap S2 {
  F3:k
}
F5: b
}
END
      expect { Joyconf.new.compile(snippet) }.to raise_error
    end
  end

  it 'defines macros inside remaps' do
    snippet = <<END
remap S1 {
  F1: "thanks"
  F2: b
}
END
    expected = <<END
S1:=,00
F1:t,00
S1:=,00
F1:h,00
S1:=,00
F1:a,00
S1:=,00
F1:n,00
S1:=,00
F1:k,00
S1:=,00
F1:s,00
S1:=,00
F2:b,00
END
    expect(Joyconf.new.compile(snippet)).to eq(expected)
  end
end
