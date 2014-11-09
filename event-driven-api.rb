require "coolio"

server = Coolio::TCPServer.new("0.0.0.0", 2929) do |client|
  n_read = 0
  client.on_read do |data|
    p data
    client.write(data)
    n_read += 1
    if n_read == 2
      client.on_write_complete do
        client.close
      end
    end
  end
end

loop = Coolio::Loop.default
loop.attach(server)
loop.run
