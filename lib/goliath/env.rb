module Goliath
  class Env < Hash
    def initialize
      self[:start_time] = Time.now.to_f
      self[:time] = Time.now.to_f
      self[:trace] = []
    end

    def trace(name)
      self[:trace].push([name, "%.2f" % ((Time.now.to_f - self[:time]) * 1000)])
      self[:time] = Time.now.to_f
    end

    def trace_stats
      self[:trace] + [['total', self[:trace].collect { |s| s[1].to_f }.inject(:+).to_s]]
    end

    def on_close(&blk)
      self[Goliath::Request::ASYNC_CLOSE].callback &blk
    end

    def stream_send(data)
      self[Goliath::Request::STREAM_SEND].call(data)
    end

    def stream_close
      self[Goliath::Request::STREAM_CLOSE].call
    end

    def respond_to?(name)
      return true if has_key?(name.to_s)
      return true if self['config'] && self['config'].has_key?(name.to_s)
      super
    end

    def method_missing(name, *args, &blk)
      return self[name.to_s] if has_key?(name.to_s)
      return self['config'][name.to_s] if self['config'] && self['config'].has_key?(name.to_s)
      super(name, *args, &blk)
    end
  end
end
