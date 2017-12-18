module Docman
  module Logging

    def logger
      Logging.logger
    end

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def properties_info(properties = [])
      arr = ["name=#{self.class.name}"]
      properties.each do |property|
        if self.is_a? Hash
          arr << "#{property}=#{self[property]}" if self.include?(property)
        else
          arr << "#{property}=#{self.send(property)}" if self.respond_to?(property)
        end
      end
      arr.join(', ')
    end

    def with_logging(message = nil, type = 'debug')
      # logger.send(type, "#{prefix} - #{message} - start") if @log
      log("#{message} - start", type)
      result = yield
      log("#{message} - finish", type)
      # logger.send(type, "#{prefix} - #{message} - finish") if @log
      result
    end

    def log(message, type = 'debug')
      if type == 'debug'
        if Application::instance.options.respond_to?('has_key') and Application::instance.options.has_key?('debug')
          logger.send(type, "#{prefix} - #{message}")
        end
      else
        logger.send(type, "#{prefix} - #{message}")
      end
    end

    def prefix
    end

  end
end