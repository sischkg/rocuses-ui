# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'rocuses/manager'

module Rocuses
  class UI < Sinatra::Base

    set :views, File.dirname(__FILE__) + '/../../views'

    get '/' do
      result = "Rocuses UI\n"
      manager = load_manager()
      manager.load_graph_templates()
      pp manager
      @graph_templates_of = Hash.new { |hash, key|
        hash[key] = Hash.new
      }
      graph_template = manager.graph_template_manager.each { |graph_template|
        @graph_templates_of[graph_template.nodenames.join( %q{,} )][graph_template.name] = graph_template
      }
      erb :index, :trim => '-'
    end

    get '/image/:nodename/:id' do
      nodename = params[:nodename]
      graph_name = params[:id]
      begin 
        manager = load_manager()
        manager.load_graph_templates()
        graph_template = manager.graph_template_manager.get_graph_template( graph_name, nodename )
        graph = graph_template.make_graph

        content_type 'image/png'
        response["Content_Disposition"] = sprintf( "%s_%s.png", nodename, graph_template.filename )

        graph.make_image( :begin_time => Time.now - 86400,
                          :end_time   => Time.now,
                          :width      => 500,
                          :height     => 120 )

      rescue ArgumentError => e
        pp "not found #{ e.to_s }: #{ e.backtrace }"
        content_type 'text/plain'
        "Not Found #{ e.to_s }: #{ e.backtrace }"
      rescue => e
        content_type 'text/plain'
        "Error #{ e.to_s }\n#{ e.backtrace }"
      end
    end

    def load_manager
      return Rocuses::Manager.new
    end

    run!
  end
end

