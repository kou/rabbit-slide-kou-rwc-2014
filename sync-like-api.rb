require "fiber"
require "coolio"

class Fiber
  class << self
    def run(*arguments, &block)
      fiber = new(&block)
      fiber.resume(*arguments)
    end
  end
end

module Synchronizable
  class << self
    def extended(object)
      super
      object.init_sync
    end
  end

  def init_sync
    @buffer = []
    @read_fiber = nil
    @close_fiber = nil
  end

  def read
    if @buffer.empty?
      @read_fiber = Fiber.current
      Fiber.yield
    else
      @buffer.shift
    end
  end

  def on_read(data)
    @buffer << data
    if @read_fiber
      @read_fiber.resume(@buffer.shift)
    end
  end

  def close
    unless output_buffer_size.zero?
      @close_fiber = Fiber.current
      Fiber.yield
    end
    super
  end

  def on_write_complete
    @close_fiber.resume if @close_fiber
  end
end

server = Coolio::TCPServer.new("0.0.0.0", 2929) do |client|
  Fiber.run do
    client.extend(Synchronizable)
    2.times do
      data = client.read
      p data
      client.write(data)
    end
    client.close
  end
end

loop = Coolio::Loop.default
loop.attach(server)
loop.run
