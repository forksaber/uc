module Uc
  class Event < ::Struct.new(:type, :msg)

    def self.parse(event_str)
      arr = event_str.split("|", 2)
      if arr.length == 2
        type, msg = arr[0], arr[1]
      else
        type, msg = "unknown", event_str
      end
      new(type, msg)
    end

    def to_s(size = nil)
      str = "#{type}|#{msg}"
      size ? truncate(str, size) : str
    end

    private

    def truncate(str, size)
      if  str.size <= size
        str
      else
        "#{str[0, size - 3] }..."
      end
    end

  end
end
