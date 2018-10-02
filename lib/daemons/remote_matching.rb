# encoding: UTF-8
# frozen_string_literal: true
require "amqp"
require File.join(ENV.fetch('RAILS_ROOT'), 'config', 'environment')

EM.run do
  logger = Rails.logger

  conn = Bunny.new AMQPConfig.connect
  conn.start
  ch = conn.create_channel
  id = $0.split(':')[2]
  prefetch = AMQPConfig.channel(id)[:prefetch] || 0
  ch.prefetch(prefetch) if prefetch > 0
  logger.info { "Connected to AMQP broker (prefetch: #{prefetch > 0 ? prefetch : 'default'})" }

  puts 'REMOTE MATCHING DAEMON'
  %w(INT TERM).each do |signal|
    Signal.trap(signal) do
      puts "Terminating threads .."
      ch.work_pool.kill
      EM.stop
      puts "Stopped."
    end
  end

  ARGV.each do |id|
    # worker = AMQPConfig.binding_worker(id)
    queue  = ch.queue *AMQPConfig.binding_queue(id)

    if args = AMQPConfig.binding_exchange(id)
      x = ch.send *args

      case args.first
      when 'direct'
        queue.bind x, routing_key: AMQPConfig.routing_key(id)
      when 'topic'
        AMQPConfig.topics(id).each do |topic|
          queue.bind x, routing_key: topic
        end
      else
        queue.bind x
      end
    end

    clean_start = AMQPConfig.data[:binding][id][:clean_start]
    queue.purge if clean_start

    binance = Peatio::Upstream::Binance.new

    queue.subscribe manual_ack: true do |delivery_info, metadata, payload|
      logger.info { "Received: #{payload}" }
      request = EM::HttpRequest.new("https://google.com").get()
      request.callback {
          puts("debug")
      }
      begin
        # order = JSON.parse(payload)["order"]


        # puts("THIS IS ORDER FOR BINANCE #{order}")

        # order = binance.trader.order(
        #   timeout: 5,
        #   symbol: order["market"].upcase,
        #   type: order["ord_type"].upcase,
        #   side: order["type"] == "bid" ? "BUY" : "SELL",
        #   quantity: order["volume"],
        #   price: order["price"],
        # )

        # order.on :error do |request|
        #   puts("order error: #{request.response}")
        # end

        # order.on :submitted do |id|
        #   puts("order submitted: #{id}")
        #   args =  [
        #     :order_processor,
        #     {action: "remote", order: order},
        #     {persistent: false}
        #   ]
        #   AMQPQueue.enqueue(*args)

        # end

        # order.on :partially_filled do |quantity, price|
        #   puts("order partially filled: #{quantity} #{price}")
        # end

        # order.on :filled do |quantity, price|
        #   puts("order filled: #{quantity} #{price}")
        # end

        # order.on :canceled do
        #   puts("order canceled: #{order.quantity} left")
        # end

        # Send confirmation to RabbitMQ that message has been successfully processed.
        # See http://rubybunny.info/articles/queues.html
        ch.ack(delivery_info.delivery_tag)

      rescue => e
        report_exception(e)

        # Ask RabbitMQ to deliver message once again later.
        # See http://rubybunny.info/articles/queues.html
        ch.nack(delivery_info.delivery_tag, false, true)
      end
    end
  end
  ch.work_pool.join
end
