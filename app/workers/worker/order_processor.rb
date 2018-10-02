# encoding: UTF-8
# frozen_string_literal: true

module Worker
  class OrderProcessor
    def process(payload)
      order = Order.find_by_id(payload.dig('order', 'id'))
      return unless order.present?
      case payload['action']
        when 'cancel'
          cancel(order)
        when 'remote'
          remote(order)
      end
    end

  private

    def cancel(order)
      Ordering.new(order).cancel!
    rescue StandardError => e
      report_exception_to_screen(e)
    end

    def remote(order)
      Ordering.new(order).remote!
    rescue StandardError => e
      report_exception_to_screen(e)
    end
  end
end

