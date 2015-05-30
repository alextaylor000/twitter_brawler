require 'logging'

DEBUG = true

TwtfuLogger = Logging.logger['twtfu_logger']
TwtfuLogger.level = :info
TwtfuLogger.add_appenders Logging.appenders.file('twtfu.log')

def debug(msg)
	TwtfuLogger.info "#{Time.now}\t#{msg}"
end
