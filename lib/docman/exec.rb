module Docman

  class Exec

    def Exec.do(cmd)
      `#{cmd}`
      $?.exitstatus == 0
    end

  end

end