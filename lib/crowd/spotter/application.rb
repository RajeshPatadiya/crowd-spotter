require "sinatra"
require 'oj'
require 'pathname'
require 'sass'
require 'compass'
require 'jammit/sinatra'
require 'jammit'

module Crowd
  module Spotter
    class Application < Sinatra::Base

      register Jammit
      production_env = ENV["RACK_ENV"]=="production"

      configure do
        set :root, Pathname.new(__FILE__).dirname.join('../../../')
        Jammit.load_configuration(root.join('config','assets.yml'))
        Crowd::Spotter.startup
        Compass.configuration do |config|
          config.project_path = root
        end
      end

      helpers do
        # Needed for Jammit until
        # https://github.com/documentcloud/jammit/commit/dcc9b02c2b9254fc4e6e53ba4a2dbc36378540cd
        def javascript_include_tag(*sources,options)
          sources.map{ |source|
            "<script src=\"#{source}\" type=\"application/javascript\"></script>"
          }.join("\n")
        end
      end

      get '/' do
        Jammit.set_package_assets( production_env )
        erb :index
      end

      get '/statistics.json' do
        content_type 'application/json'
        Oj.dump(Spotter.statistics.all, mode: :compat)
      end

      get '/statistics/most-recent.json' do
        content_type 'application/json'
        Oj.dump(Spotter.statistics.most_recent, mode: :compat)
      end

      get '/css/:name.css' do
        content_type 'text/css', :charset => 'utf-8'
        scss(:"css/#{params[:name]}", Compass.sass_engine_options )
      end

    end
  end
end
