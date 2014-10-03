require 'sinatra'
require 'sinatra/advanced_routes'
require 'net/http'

module Varnish
  class Purger

    module ::Net
      class HTTP::Purge < HTTPRequest
        METHOD='PURGE'
        REQUEST_HAS_BODY = false
        RESPONSE_HAS_BODY = true
      end
    end

    def purge(url)
      if !(url =~ /^http:\/\//)
        url = "http://#{url}"
      end

      uri = URI(url)

      if uri.scheme != "http"
        puts "Not a HTTP URL! Try with http://....?"
        Process.exit(1)
      end

      puts "Purging: #{uri.to_s}"
      Net::HTTP.start(uri.host,uri.port) do |http|
        presp = http.request Net::HTTP::Purge.new uri.request_uri
        puts "#{presp.code}: #{presp.message}"
        unless (200...400).include?(presp.code.to_i)
          STDERR.puts "A problem occurred. PURGE was not performed."
        end
      end
    end
  end
  class App < Sinatra::Base
    register Sinatra::AdvancedRoutes

    configure do
      set :purger, Purger.new
      set :layout, true
    end


    get('/') { erb :images }

    get('/moviditas') { 'moviditas' }

    get('/moviditas/gatitos') { erb :images }

    get '/routes' do
      @routes = [
        {name: 'home', path: '/'},
        {name: 'moviditas', path: '/moviditas'},
        {name: 'rutas', path: '/routes'},
        {name: 'gatitos', path: '/moviditas/gatitos'}
      ]
      erb :routes
    end

    post '/purge'do
      settings.purger.purge(format_path(params[:path], params[:port]))
      redirect '/routes'
    end

    def format_path(path, port)
      "http://localhost:#{port ? port : 80}#{path}"
    end
  end
end
