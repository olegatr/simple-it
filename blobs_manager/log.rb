require 'logger'
require 'fileutils'
class Log
  FileUtils.mkdir('log') if !File.exist? 'log'
  $LOG = Logger.new('log/blob_copier.log')

  def self.info(message)
    puts "INFO #{message}".green
    $LOG.info message
  end

  def self.error(message)
    puts "ERROR #{message}".red
    $LOG.error message
  end

end

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def light_blue
    colorize(36)
  end
end