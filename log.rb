require 'logger'

class Log
  def self.log
    if @logger.nil?
      @logger = Logger.new 'logs/eventstat.txt'
      @logger.progname = 'eventStat'
      @logger.level = Logger::DEBUG
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S '
    end
    @logger
  end
end
