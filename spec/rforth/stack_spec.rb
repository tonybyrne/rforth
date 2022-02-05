require_relative '../../lib/rforth'

RSpec.describe Rforth::Stack do
  subject(:stack) { described_class.new }

  describe '#to_a' do
    context 'when the stack is brand new' do

      it 'returns an empty array' do
        expect(stack.to_a).to be_empty
      end
    end

    context 'when the stack is not empty' do
      before do
        stack.push(1)
        stack.push(2)
        stack.push(3)
      end
      it 'returns the stacked items in an array' do
        expect(stack.to_a).to eql [1, 2, 3]
      end
    end
  end

  describe '#push' do
    it 'pushes an item on to the top of the stack' do
      stack.push(1)
      expect(stack.to_a).to eql [1]
      stack.push(2)
      expect(stack.to_a).to eql [1, 2]
    end
  end

  describe '#pop' do
    context 'when the stack has at least one item on it' do
      it 'pops an item off the top of the stack and returns it' do
        stack.push(1)
        stack.push(2)
        expect(stack.pop).to eql 2
        expect(stack.to_a).to eql [1]
        expect(stack.pop).to eql 1
        expect(stack.to_a).to be_empty
      end
    end

    context 'when the stack has no items' do
      it 'raises a StackUnderflowError' do
        expect { stack.pop }.to raise_error( Rforth::StackUnderflowError)
      end
    end
  end

  describe '#depth' do
    it 'returns the number of items on the stack' do
      expect(stack.depth).to be 0
      stack.push(100)
      expect(stack.depth).to be 1
    end
  end

  describe '#empty' do
    context 'when the stack is empty' do
      it 'returns true' do
        expect(stack.empty?).to be true
      end
    end

    context 'when the stack has items' do
      it 'returns false' do
        stack.push(1)
        expect(stack.empty?).to be false
      end
    end
  end

end
