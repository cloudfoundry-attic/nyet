require "spec_helper"
require "support/monitoring"

describe Monitoring do
  describe "#record_action" do
    before { subject.stub(:puts) }

    context "when block raises an error" do
      it "propagates raised error" do
        error = RuntimeError.new
        expect {
          subject.record_action(:action) { raise(error) }
        }.to raise_error(error)
      end
    end

    context "when block does not raise an error" do
      it "returns time" do
        subject.record_action(:action) { 123 }.should be_a(Float)
      end
    end
  end
end
