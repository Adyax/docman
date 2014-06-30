module Docman

  class Exec

    def Exec.do(cmd, output = false)
      `#{cmd}`
      $?.exitstatus == 0
    end

  end

end