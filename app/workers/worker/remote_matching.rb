# encoding: UTF-8
# frozen_string_literal: true

require "peatio/upstream/binance"

module Worker
  class RemoteMatching
    class DryrunError < StandardError
      attr :engine

      def initialize(engine)
        @engine = engine
      end

      def initialize(options = {})
        @options = options
        puts(@options)
        reload "all"
      end
    end
  end
end
