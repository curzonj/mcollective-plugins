module MCollective
  module Agent
    # An agent to manage the Chef Daemon
    #
    # Many bits taken from the puppet agent from R.I. Pienaar
    #
    # Configuration Options:
    #    chef.client   - Where to find the chef client, defaults to /usr/sbin/chef-client
    #    chef.pidfile   - Where to find the chef client pid file
    class Chef<RPC::Agent
      metadata :name => 'Chef',
               :description => "run chef",
               :author      => "jc816a",
               :license     => "none",
               :version     => "", 
               :url         => "", 
               :timeout => 180 

      action "node_json" do
        reply.data = File.read("/var/tmp/chef_node.json")
      end

      action "deploy" do
        exit_code = run("/usr/local/sbin/chef-deploy")

        if exit_code != 0
          reply.fail "Deploy failed with code #{exit_code}"
        else
          reply[:status] = 0
        end
      end
    end
  end
end

