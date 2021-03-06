require "rubygems"
require "mq"

class Warren::Queue::AMQPAdapter < Warren::Queue
  
  # 
  # Checks the connection details are correct for this adapter
  # 
  def self.check_connection_details opts
    # Check they've passed in the stuff without a default on it
    unless opts.has_key?(:user) && opts.has_key?(:pass) && opts.has_key?(:vhost)
      raise Warren::Connection::InvalidConnectionDetails, "Missing a username, password or vhost."
    end
    true
  end
  
  # 
  # Returns the default queue name or returns InvalidConnectionDetails
  # if no default queue is defined
  # 
  def self.queue_name
    unless self.connection.options.has_key?(:default_queue)
      raise Warren::Connection::InvalidConnectionDetails, "Missing a default queue name."
    end
    self.connection.options[:default_queue]
  end

  #
  # Sends a message to a queue. If successfully sent it returns
  # true, unless callback block is passed (see below)
  #
  #   Warren::Queue.publish(:queue_name, {:foo => "name"})
  #
  # Can also pass a block which is fired after the message
  # is sent. If a block is passed, then the return value of the block
  # is returned from this method.
  #
  #   Warren::Queue.publish(:queue_name, {:foo => "name"}) { puts "foo" }
  #
  def self.publish queue_name, payload, &blk
    queue_name = self.queue_name if queue_name == :default
    # Create a message object if it isn't one already
    msg = Warren::MessageFilter.pack(payload)

    do_connect(true, blk) do
      queue = MQ::Queue.new(MQ.new, queue_name)
      queue.publish msg.to_s
    end

  end
  
  #
  # Subscribes to a queue and runs the block
  # for each message received
  #
  #   Warren::Queue.subscribe("example") {|msg| puts msg }
  #
  # Expects a block and raises NoBlockGiven if no block is given.
  #
  def self.subscribe queue_name, &block
    raise NoBlockGiven unless block_given?
    queue_name = self.queue_name if queue_name == :default
    # todo: check if its a valid queue?
    do_connect(false) do
      queue = MQ::Queue.new(MQ.new, queue_name)
      queue.subscribe do |msg|
        msg = Warren::MessageFilter.unpack(msg)
        block.call(msg)
      end
    end
  end

  private

  #
  # Connects and does the stuff its told to!
  #
  def self.do_connect should_stop = true, callback = nil, &block
    AMQP.start(self.connection.options) do
      block.call
      AMQP.stop { EM.stop_event_loop } if should_stop
    end
    # Returns the block return value or true
    callback.nil? ? true : callback.call
  end

end