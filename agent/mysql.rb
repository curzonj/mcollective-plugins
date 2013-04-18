module MCollective
  module Agent
    class Mysql<RPC::Agent
      action "backup" do
        script = '/usr/local/sbin/mysql_backup.sh'
        reply.data = `#{script}` if File.executable?(script)
      end
    end
  end
end

