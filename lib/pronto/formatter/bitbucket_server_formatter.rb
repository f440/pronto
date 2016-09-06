module Pronto
  module Formatter
    class BitbucketServerFormatter < CommitFormatter
      def client_module
        BitbucketServer
      end

      def pretty_name
        'BitBucketServer'
      end

      def line_number(message, _)
        message.line.new_lineno
      end
    end
  end
end
