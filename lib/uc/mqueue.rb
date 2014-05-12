require 'posix_mq'
require 'uc/logger'
module Uc
  class Mqueue
    include ::Uc::Logger
 
    attr_reader :name 

    def initialize(name)
      @name = name
    end

    def setup
      attr = ::POSIX_MQ::Attr.new(0,100,100)       # o_readonly, maxmsg, msgsize
      ::POSIX_MQ.new("/#{name}", :rw, 0700, attr)
      make_empty
    end

    def reader
      @reader ||= ::POSIX_MQ.new("/#{name}", :r)
    end

    def nb_reader
      mq = ::POSIX_MQ.new("/#{name}", :r)
      mq.nonblock = true
      return mq
    end

    def writer
      POSIX_MQ.new("/#{name}", IO::WRONLY)
    end

    def nb_writer
      writer = POSIX_MQ.new("/#{name}", IO::WRONLY)
      writer.nonblock = true
      return writer
    end

    def watch(loglevel: :info, msg: "success", err_msg: "error", &block)
      setup
      make_empty
      yield
      wait_for_fin(msg, err_msg, loglevel)
    end

    def wait_for_fin(msg, err_msg, loglevel)
      message = ""
      while message != "fin"
        reader.receive(message, 30)
        logger.send(loglevel, message) if message != "fin"
      end
      logger.info msg
    rescue Errno::ETIMEDOUT
      raise ::Uc::Error, err_msg
    end

    def make_empty
      mq = nb_reader
      while true do
        mq.receive
      end
    rescue Errno::EAGAIN
      return
    end

  end
end
