require 'posix_mq'
module Uc
  class Mqueue
 
    attr_reader :name, :max_msg, :msg_size

    def initialize(name, max_msg: 10, msg_size: 100)
      @name = name
      @max_msg = max_msg
      @msg_size = msg_size
    end

    def create
      ::POSIX_MQ.new("/#{name}", :rw, 0700, attr)
    end

    def recreate
      destroy
      create
    end

    def destroy
      ::POSIX_MQ.unlink("/#{name}")
    rescue
      return false
    end

    def attr
      ::POSIX_MQ::Attr.new(0,max_msg,msg_size)
    end
  
    def new_mq(io_mode, nonblock, &block)
      mq = ::POSIX_MQ.new("/#{name}", io_mode)
      mq.nonblock = true if nonblock
      return mq if not block_given?
       
      begin
          yield mq
      ensure
          mq.close if mq
      end
    end

    def reader(&block)
      new_mq(:r, false, &block)
    end

    def nb_reader(&block)
      new_mq(:r, true, &block)
    end

    def writer(&block)
      new_mq(IO::WRONLY, false, &block)
    end

    def nb_writer(&block)
      new_mq(IO::WRONLY, true, &block)
    end

    def wait(event, timeout, output: false)
      event = event.to_s
      message = ""
      reader do |r|
        while message != event do
          r.receive(message, timeout)
          puts "> #{message}" if output
        end
      end
      return message
    end

    def watch(event, timeout: 30, recreate: true, &block)
      self.recreate if recreate 
      clear
      yield
      wait(event, timeout, output: true)
    end

    def clear
      nb_reader do |mq|
        loop { mq.receive }
      end
    rescue Errno::EAGAIN
      return
    end

  end
end
