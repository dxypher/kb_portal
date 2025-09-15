require "rails_helper"

RSpec.describe Ai::Client, type: :service do
  describe ".chat" do
    it "returns a fake summary string" do
      result = Ai::Client.chat(prompt: "Hello world")
      expect(result).to be_a(String)
      expect(result).to include("Fake summary")
      expect(result).to include("Hello world".truncate(40))
    end

    it "handles timeouts gracefully" do
      # temporarily monkey-patch Timeout to force it to raise
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

      result = Ai::Client.chat(prompt: "Hello world")

      expect(result).to eq("⚠️ AI request timed out")
    end
  end
end
