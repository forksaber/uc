module Uc
  module ShellHelper

    def cmd(command, error_msg: nil, return_output: false)
      puts "Running #{command}"
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

  end 
end
