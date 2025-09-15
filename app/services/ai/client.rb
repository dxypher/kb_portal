module Ai
  class Client
    def self.chat(prompt:)
      new.chat(prompt: prompt)
    end

    def chat(prompt:)
      Timeout.timeout(5) do
        # temp fake summary
        "🤖 Fake summary for: #{prompt.truncate(40)}"
      end
    rescue Timeout::Error
        "⚠️ AI request timed out"
    end
  end
end
