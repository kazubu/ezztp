#!/usr/bin/env ruby

require 'ftpd'
require 'zlib'
require 'rest-client'
require 'logger'

URL = 'http://127.0.0.1/config/upload'

$log = Logger.new('/var/log/ezztp-ftp-server.log')
$log.level = Logger::INFO

class NullFileSystem
  #PathExpansion
  def set_data_dir(datadir)
  end

  def expand_ftp_path(ftp_path)
    $log.debug 'FS: called expand_ftp_path with '+ftp_path
    return '/'
  end

  #Accessors
  def accessible?(ftp_path)
    $log.debug 'FS: called accessible? with '+ftp_path
    return true
  end

  def exists?(ftp_path)
    $log.debug 'FS: called exists? with '+ftp_path
    return true
  end

  def directory?(ftp_path)
    $log.debug 'FS: called directory? with '+ftp_path
    return true if ftp_path == '/'
    return false
  end

  #FileWriting
  def write_file(ftp_path, stream, mode)
    # todo
    $log.debug 'FS: write_file: ' + ftp_path
  end

  def write(ftp_path, stream)
    $log.debug 'WRITE: called write with ' + ftp_path
    $log.info 'Receiving a file: ' + ftp_path
    file_name = File.basename(ftp_path)
    content = stream.read
    if content[0,4].unpack("H*")[0] == '1f8b0800'
      $log.debug 'WRITE: detect gziped' 
      begin
        content = Zlib::GzipReader.new(StringIO.new(content)).read
      rescue => e
        $log.info 'WRITE: zlib exception...' + e.to_s
        raise e
      end
      file_name.gsub!('.gz','')
    end
    $log.info 'Posting a configuration to ZTP Server...'
    $log.info 'File name: ' + file_name
    $log.debug 'Content: ' + content
    RestClient.post URL+'/'+file_name, content, :content_type => "text/plain"
    $log.info 'Posted.'
  end
end

class Driver
  def initialize()
    $log.debug 'called Driver.initialize'
  end

  def authenticate(user, pass)
    $log.debug 'called Driver.authenticate with ' + user
    true
  end

  def file_system(user)
    $log.debug 'called Driver.file_system with ' + user
    NullFileSystem.new
  end
end

driver = Driver.new()
server = Ftpd::FtpServer.new(driver)
server.interface ='0.0.0.0'
server.port = 21
server.log = $log
server.start
$log.info "Server listening on port #{server.bound_port}"

while true
  sleep 0.1
end
