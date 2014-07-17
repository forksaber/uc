require 'uc/config'
require 'uc/ext/string'
require 'uc/mqueue'

module Uc
  Event = Struct.new(:type, :msg)
end

module Uc
  class EventStream

    attr_reader :queue_name
    attr_accessor :debug_output

    def initialize(queue_name)
      @queue_name = queue_name
      @debug_output = true
    end

    def info(msg)
      pub :info, msg
    end

    def debug(msg)
      pub :debug, msg
    end

    def warn(msg)
      pub :warn, msg
    end

    def fatal(msg)
      pub :fatal, msg
    end

    def pub(type, msg)
      tmsg = truncate "#{type}|#{msg}"
      writer.send tmsg
    rescue Errno::ENOENT, Errno::EAGAIN, Errno::EACCES, Errno::EMSGSIZE => e
      puts "#{e.class} #{e.message}"
    end

    def truncate(msg)
      if msg.size <= mq.msg_size
        return msg
      else
        msg = "#{msg[0, mq.msg_size - 3] }..."
      end
    end

    def watch(event_type, timeout: 30, recreate: true, &block)
      mq.recreate if recreate
      mq.clear
      yield
      wait(event_type, timeout, output: true)
    rescue Errno::EACCES
      raise ::Uc::Error, "unable to setup message queue"
    rescue Errno::ENOENT
      raise ::Uc::Error, "message queue deleted"
    rescue Errno::ETIMEDOUT
      raise ::Uc::Error, "timeout reached while waiting for server to restart"
    end

    def wait(event_type, timeout, output: false)
      event_type = event_type.to_s
      message = ""
      event = ""
      mq.reader do |r|
        loop do
          r.receive(message, timeout)
          event = parse message
          print event if output
          break if event.type == event_type
        end
      end
      puts "#{"success".green.bold} #{event.msg}"
      true
    end

    def print(event)
      case event.type
      when "info"
        puts event.msg
      when "warn"
        puts "#{"warn".yellow.bold} #{event.msg}"
      when "debug"
        puts "#{"debug".blue.bold} #{event.msg}" if debug_output
      when "fatal"
        raise ::Uc::Error, event.msg
      end
    end

    private  

    def read(timeout)
      event = ""
      reader do |r|
        r.receive(event, timeout)
        parse event
      end
    end
 
    def parse(event_str)
      arr = event_str.split("|",2)
      if arr.length == 2
        type, msg = arr[0], arr[1]
      else
        type, msg = "unknown", event
      end
      event = ::Uc::Event.new(type, msg)
    end

    def mq
      @mq ||= ::Uc::Mqueue.new(@queue_name)
    end

    def writer
      @writer ||= mq.nb_writer
    end

  end
end
