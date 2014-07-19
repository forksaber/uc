module Uc
  module ShellHelper

    def cmd(command, error_msg: nil, return_output: false)
      puts "#{"Running".bold.green} #{command}"
      if return_output
        output = `#{command}`
      else
        output = ""
        system "#{command} 2>&1"
      end 
      return_value = $?.exitstatus
      error_msg ||= "Non zero exit for \"#{command}\""
      raise ::Uc::Error, error_msg if return_value !=0 
      return output
    end 

    def kill(pid, timeout)
      Process.kill(:TERM, pid)
      logger.debug "TERM signal sent to #{pid}"
      (1..timeout).each do
        if not process_running? pid
          logger.info "Stopped #{pid}"
          return
        end
        sleep 1
      end
      Process.kill(9, pid)
      sleep 1
      logger.info "Killed #{pid}"
    end

    def process_running?(pid)
      return false if pid <= 0
      Process.getpgid pid
      return true
    rescue Errno::ESRCH
        return false
    end


  end 
end
