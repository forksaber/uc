require 'uc/ext/string'
require 'uc/mqueue'
require 'uc/event'

module Uc
  class EventStream

    attr_reader :queue_name
    attr_accessor :debug_output

    def initialize(queue_name)
      @queue_name = queue_name
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
      event = Event.new(type, msg)
      writer.send event.to_s(mq.msg_size)
    rescue Errno::ENOENT, Errno::EAGAIN, Errno::EACCES, Errno::EMSGSIZE => e
      puts "#{e.class} #{e.message}"
    end

    def expect(event_type, timeout: 30, recreate: true, &block)
      begin
        mq.recreate if recreate
        mq.clear
        t = wait_in_background(event_type, timeout, output: true, first_timeout: 50)
        yield
        t.join
        raise t[:error] if t[:error]
      rescue => e
        raise uc_error(e)
      ensure
        t.kill if t
      end
    end

    def wait(event_type, timeout, output: false, first_timeout: nil)
      event_type = event_type.to_s
      message = ""
      event = ""
      t = first_timeout || timeout
      mq.reader do |r|
        loop do
          r.receive(message, t)
          t = timeout
          event = Event.parse message
          print event if output
          break if event.type == event_type
        end
      end
      puts "#{"success".green.bold} #{event.msg}"
      true
    end

    def wait_in_background(event_type, timeout, **kwargs)
      Thread.new do
        begin
          wait(event_type, timeout, **kwargs)
        rescue => e
          Thread.current[:error] = e
          false
        end
      end
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

    def close_connections
      writer.close if writer
      @writer = nil
    end


    private  

    def mq
      @mq ||= ::Uc::Mqueue.new(@queue_name)
    end

    def writer
      @writer ||= mq.nb_writer
    end

    def uc_error(e)
      case e
      when Errno::EACCES
        msg = "unable to setup message queue"
      when Errno::ENOENT
        msg = "message queue deleted"
      when Errno::ETIMEDOUT
        msg = "timeout reached while waiting for server ready msg"
      else
        return e
      end

      return ::Uc::Error.new(msg)
    end

  end
end
