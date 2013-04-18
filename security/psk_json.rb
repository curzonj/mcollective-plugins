module MCollective
  module Security
    # Impliments message authentication using digests and shared keys
    #
    # You should configure a psk in the configuration file and all requests
    # will be validated for authenticity with this.
    #
    # Serialization uses Marshal, this is the default security module that is
    # supported out of the box.
    #
    # Validation is as default and is provided by MCollective::Security::Base
    #
    # You can configure the caller id being created, this can adjust how you
    # create authorization plugins.  For example you can use a unix group instead
    # of uid to do authorization.
    class PskJson < Base
      require 'etc'

      # JSON can handle strings just hashes and arrays
      def inbound(data)
        Log.debug(data.inspect)
        JSON.parse(data).first
      rescue
        Log.warn("Received invalid json data in message")

        {}
      end

      def outbound(*obj)
        Log.debug(obj.inspect)
        JSON.generate(obj)
      end

      # Decodes a message by unserializing all the bits etc, it also validates
      # it as valid using the psk etc
      def decodemsg(msg)
        body = inbound(msg.payload).inject({}) do |options, (key, value)|
          options[(key.to_sym rescue key) || key] = value
          options
        end

        Log.debug(body.inspect)

        should_process_msg?(msg, body[:requestid])

        if validrequest?(body)
          body[:body] = inbound(body[:body])
          return body
        else
          nil
        end
      end

      # Encodes a reply
      def encodereply(sender, msg, requestid, requestcallerid=nil)
        serialized  = outbound(msg)
        digest = makehash(serialized)

        req = create_reply(requestid, sender, serialized)
        req[:hash] = digest

        outbound(req)
      end

      # Encodes a request msg
      def encoderequest(sender, msg, requestid, filter, target_agent, target_collective, ttl=60)
        serialized = outbound(msg)
        digest = makehash(serialized)
        Log.debug("#{digest} -- #{serialized}")

        req = create_request(requestid, filter, serialized, @initiated_by, target_agent, target_collective, ttl)
        req[:hash] = digest

        outbound(req)
      end

      # Checks the md5 hash in the request body against our psk, the request sent for validation
      # should not have been deserialized already
      def validrequest?(req)
        digest = makehash(req[:body])
        Log.debug("#{req[:hash]}/#{digest} -- #{req[:body]}")

        if digest == req[:hash]
          @stats.validated

          return true
        else
          @stats.unvalidated

          raise(SecurityValidationFailed, "Received an invalid signature in message")
        end
      end

      def callerid
        if @config.pluginconf.include?("psk.callertype")
          callertype = @config.pluginconf["psk.callertype"].to_sym if @config.pluginconf.include?("psk.callertype")
        else
          callertype = :uid
        end

        case callertype
          when :gid
            id  = "gid=#{Process.gid}"

          when :group
            raise "Cannot use the 'group' callertype for the PSK security plugin on the Windows platform" if Util.windows?

            id = "group=#{Etc.getgrgid(Process.gid).name}"

          when :user
            id = "user=#{Etc.getlogin}"

          when :identity
            id = "identity=#{@config.identity}"

          else
            id ="uid=#{Process.uid}"
        end

        Log.debug("Setting callerid to #{id} based on callertype=#{callertype}")

        id
      end

      private
      # Retrieves the value of plugin.psk and builds a hash with it and the passed body
      def makehash(body)
        if ENV.include?("MCOLLECTIVE_PSK")
          psk = ENV["MCOLLECTIVE_PSK"]
        else
          raise("No plugin.psk configuration option specified") unless @config.pluginconf.include?("psk")
          psk = @config.pluginconf["psk"]
        end

        Digest::MD5.hexdigest(body.to_s + psk)
      end
    end
  end
end
