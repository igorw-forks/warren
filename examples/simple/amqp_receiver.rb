require "rubygems"
require File.expand_path(File.dirname(__FILE__) + "/../../lib/warren")
# Next line is the only one you need to change to use a different adapter
require File.expand_path(File.dirname(__FILE__) + "/../../lib/warren/adapters/amqp_adapter")

Signal.trap("INT") { AMQP.stop { EM.stop } }
Signal.trap("TERM") { AMQP.stop { EM.stop } }

# Listen to the main queue
q = "main"
puts "Listening to the #{q} queue."

Warren::Queue.connection = {"development" => {:user => "caius", :pass => "caius", :vhost => "/"}}

# And attach a block for new messages to fire
Warren::Queue.subscribe(q) do |msg|
  p [Time.now, msg]
end
