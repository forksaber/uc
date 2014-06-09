module Uc
  class MqLogger

    attr_reader :queue_name

    def initialize(queue_name)
      @queue_name = queue_name
    end

    def mq
      @mq ||= ::Uc::Mqueue.new(queue_name)
    end

    def log(msg)
      @writer ||= mq.nb_writer
      @writer.send msg
    rescue Errno::ENOENT, Errno::EAGAIN, Errno::EACCES, Errno::EMSGSIZE => e
      puts "#{e.class} #{e.message}"
    end

  end
end
