# frozen_string_literal: true

require "rbs_activesupport_delegate"

RSpec.describe RbsActivesupportDelegate::Parser do
  include RbsActivesupportDelegate::AST

  describe "#parse" do
    subject { parser.parse(code) }

    let(:parser) { described_class.new }

    context "When the code contains class_attribute calls" do
      let(:code) do
        <<~RUBY
          class Foo
            class_attribute :foo, :bar
            class_attribute :baz, instance_accessor: false, instance_reader: false, instance_writer: false, instance_predicate: false, default: nil
          end

          class Bar
            private

            class_attribute :foo
          end
        RUBY
      end

      it "collects class_attribute calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 2
        expect(method_calls[0].name).to eq :class_attribute
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, nil]
        expect(method_calls[1].name).to eq :class_attribute
        expect(method_calls[1].private?).to be_falsey
        expect(eval_node(method_calls[1].args)).to eq [:baz,
                                                       { instance_accessor: false,
                                                         instance_reader: false,
                                                         instance_writer: false,
                                                         instance_predicate: false,
                                                         default: nil },
                                                       nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :class_attribute
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
      end
    end

    context "When the code contains delegate calls" do
      let(:code) do
        <<~RUBY
          class Foo
            delegate :foo, to: :bar
            delegate :baz, :qux, to: :quux, prefix: true
          end

          class Bar
            private

            delegate :foo, to: :bar
          end
        RUBY
      end

      it "collects delegate calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 2
        expect(method_calls[0].name).to eq :delegate
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, { to: :bar }, nil]
        expect(method_calls[1].name).to eq :delegate
        expect(method_calls[1].private?).to be_falsey
        expect(eval_node(method_calls[1].args)).to eq [:baz, :qux, { to: :quux, prefix: true }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :delegate
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, { to: :bar }, nil]
      end
    end
  end
end
