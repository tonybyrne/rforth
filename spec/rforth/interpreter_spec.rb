require_relative '../../lib/rforth'

RSpec.describe Rforth::Interpreter do
  subject(:interpreter) { described_class.new }

  let(:stack) { interpreter.stack }
  let(:dictionary) { interpreter.dictionary }

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
      before do
        interpreter.eval('100')
      end

      it 'pushes the value onto the stack' do
        expect(stack.to_a).to eql [100]
      end
    end

    context 'when passed an existing word' do
      before do
        stack.push(100)
        interpreter.eval('dup')
      end

      it 'executes the word' do
        expect(stack.to_a).to eql [100, 100]
      end
    end

    context 'when passed an non-existing word' do
      it 'returns false' do
        expect(interpreter.eval('a_non_existent_word')).to be false
      end

      it 'sets message to word not found error' do
        interpreter.eval('a_non_existent_word')
        expect(interpreter.message).to eql 'a_non_existent_word?'
      end
    end

    context 'when multiple valid words are passed' do
      before do
        interpreter.eval('100 dup')
      end

      it 'evaluates each word in sequence' do
        expect(stack.to_a).to eql [100, 100]
      end

      it 'sets message to ok' do
        expect(interpreter.message).to eql 'ok.'
      end
    end

    context 'when all words were evaluated successfully' do
      it 'returns true' do
        expect(interpreter.eval('100')).to be true
      end

      it 'sets message to ok' do
        interpreter.eval('100')
        expect(interpreter.message).to eql 'ok.'
      end
    end

    context 'when some words were not evaluated successfully' do
      let(:invalid) { '100 invalid_word 200' }

      it 'returns false' do
        expect(interpreter.eval(invalid)).to be false
      end

      it 'sets an error message' do
        interpreter.eval(invalid)
        expect(interpreter.message).to eql 'invalid_word?'
      end
    end

    context 'when the stack underflows' do
      it 'returns false' do
        expect(interpreter.eval('drop')).to be false
      end

      it 'sets the stack underflow error message' do
        interpreter.eval('drop')
        expect(interpreter.message).to eql 'Stack underflow!'
      end
    end

    describe 'forth primitives' do
      describe 'dup' do
        before do
          interpreter.eval('100')
        end

        it 'duplicates the top of the stack' do
          interpreter.eval('dup')
          expect(stack.to_a).to eql [100, 100]
        end
      end

      describe 'drop' do
        before do
          interpreter.eval('200 100')
        end

        it 'drops the top value of the stack' do
          interpreter.eval('drop')
          expect(stack.to_a).to eql [200]
        end
      end

      describe ':' do
        it 'puts the interpreter into compile mode' do
          interpreter.eval(':')
          expect(interpreter.compiling?).to be true
        end
      end

      describe ';' do
        before do
          interpreter.eval(': test')
        end

        it 'takes the interpreter out of compile mode' do
          expect(interpreter.compiling?).to be true
          interpreter.eval(';')
          expect(interpreter.compiling?).to be false
        end
      end
    end
  end
end
