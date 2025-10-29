# frozen_string_literal: true

require 'socksify'
require 'socksify/http'

# agent = Mechanize.new
# agent.agent.set_socks('localhost', 9050) #Use Tor as proxy
#
class Mechanize::HTTP::Agent
  def set_socks(addr, port, user = nil, password = nil)
    set_http unless @http

    class << @http
      attr_accessor :socks_addr, :socks_port, :socks_username, :socks_password

      def http_class
        Net::HTTP.socks_proxy(socks_addr, socks_port, username: socks_username, password: socks_password)
      end
    end

    @http.socks_addr = addr
    @http.socks_port = port
    @http.socks_username = user
    @http.socks_password = password
  end
end
