# frozen_string_literal: true

require "logger"
require "fileutils"

module MapSpiderLogger
  class << self
    def logger
      @logger ||= create_logger
    end

    def log_info(message)
      logger.info(message)
    end

    def log_error(message)
      logger.error(message)
    end

    private

    def create_logger
      FileUtils.mkdir_p("logs")
      logger = Logger.new("logs/mapspider.log", "weekly")
      logger.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
        "[#{date_format}] #{severity}: #{msg}\n"
      end
      logger
    end
  end
end
