module Pronto
  module Formatter
    class BitbucketServerPullRequestFormatter < PullRequestFormatter
      def client_module
        BitbucketServer
      end

      def pretty_name
        'BitBucketServer'
      end
    end
  end
end
