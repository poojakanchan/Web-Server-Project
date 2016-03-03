require 'socket'
require_relative 'request'
require_relative 'response'
require_relative 'header_collection'
require_relative 'httpd_config'
require_relative 'mime_types'
require_relative 'resource'

class WebServer
  attr_reader :options

  DEFAULT_PORT = 56789
attr_accessor :request, :httpd_conf, :mimes

  def initialize(options={})
     @httpd_conf = HttpdConfig.new('config/httpd.conf')
     @mimes = MimeTypes.new('config/mime.types')
     @options = options
     @params = {}
  end

  def start

   @httpd_conf.load    
   @mimes.load
    loop do
         puts "Opening server socket to listen for connections"
         client = server.accept
   
         request_string = ""

          while next_line_readable?(client)
              line = client.gets
              #  puts line
              request_string <<  line.chop 
              request_string << "\n"
          end
       #  puts "Request received: " + request_string 
          
         request = Request.new(request_string)
         request.parse
         puts request
         puts request.uri

         resource = Resource.new(request.uri, @httpd_conf, @mimes)
         absolute_path = resource.resolve
         puts "------------ absolute path --------" + absolute_path
         #code to create a new request
         puts "Writing message"
      
         #create a response
         hc = HeaderCollections.new()
         hc.add("Content-Type","text/html")
         hc.add("Content-Length","37")
         hc.add("Content-Language","en")
         #                "WWW-Authenticate"  =>  "Basic"
         response = Response.new(:headers => hc,
                              :response_code => "200",
                              :http_version => "HTTP/1/1",
                              :body => "<html><body>My response</body></html>")   
        #      test_response = Response.new
        client.print response

        client.close
     end

  end

  def server
    @server ||= TCPServer.open(options.fetch(:port, DEFAULT_PORT))
  end

   # fd be nil if next line cannot be read
    def next_line_readable?(socket)
      readfds, writefds, exceptfds = select([socket], nil, nil, 0.1)
      readfds 
    end
end

webserver_test = WebServer.new
webserver_test.start
