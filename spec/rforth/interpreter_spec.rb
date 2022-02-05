require_relative '../../lib/rforth'

RSpec.describe Rforth::Interpreter do
  subject(:interpreter) { described_class.new }

  let(:stack) { interpreter.stack }

  context 'when newly initialised' do
    it 'has an empty stack' do
      expect(interpreter.stack).to be_instance_of(Rforth::Stack)
      expect(interpreter.stack).to be_empty
    end

    it 'has a dictionary' do
      expect(interpreter.dictionary).to be_instance_of(Rforth::Dictionary)
    end
  end

  describe '#eval' do
    context 'when passed a value literal' do
      it 'pushes the value onto the stack' do
        interpreter.eval('100')
        expect(stack.to_a).to eql [100]
      end
    end
  end
end
