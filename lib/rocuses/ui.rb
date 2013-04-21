# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'rocuses/manager'

module Rocuses
  class UI < Sinatra::Base
    
    #    set :views, File.dirname(__FILE__) + '/../../views'
    set :views, '/usr/share/rocuses-ui/views'

    get '/' do
      @result = "Rocuses UI\n"
      manager = load_manager()

      @graph_template_of = manager.each

      erb :index, :trim => '-'
    end

    get '/image/:id/:period' do
      display_graph_image( params )
    end

    get '/image/:id' do
      display_graph_image( params )
    end

    get '/node/:node' do
      list_graphs_of_node( params[:node] )
    end

    get '/node' do
      list_nodes()
    end

    private

    def load_manager
      manager = Rocuses::Manager.new
      manager.load_graph_templates()
      pp manager.graph_template_manager()
      return manager.graph_template_manager()
    end

    def display_graph_image( params )
      graph_name = params[:id]
      begin_time, end_time = parse_period( params[:period] )

      begin 
        manager = load_manager()
        graph_template = manager.get_graph_template( graph_name )
        if graph_template.nil?
          content_type 'text/plain'
          return "Not Found #{ graph_name }"
        end
        graph = graph_template.make_graph

        content_type 'image/png'
        response["Content_Disposition"] = sprintf( "%s_%s.png",
                                                   graph_template.nodenames.join( %q{,} ),
                                                   graph_template.filename )

        return graph.make_image( :begin_time => begin_time,
                                 :end_time   => end_time,
                                 :width      => 500,
                                 :height     => 120 )

      rescue => e
        content_type 'text/plain'
        "Error #{ e.to_s }\n#{ e.backtrace }"
      end

    end

    def parse_period( period )
      end_time   = Time.now
      begin_time = end_time - 24 * 60 * 60
      if period
        if period =~ /\A(\d+),(\d+)\z/
          begin_time = Time.at( $1.to_i )
          end_time   = Time.at( $2.to_i )
        else 
          case period
          when 'daily'
            begin_time = end_time - 24 * 60 * 60
          when 'weekly'
            begin_time = end_time - 24 * 60 * 60 * 7
          when 'monthly'
            begin_time = end_time - 24 * 60 * 60 * 31
          when 'yearly'
            begin_time = end_time - 24 * 60 * 60 * 365
          end
        end
      end

      return [ begin_time, end_time ]
    end

    def list_nodes
      manager = load_manager()
      @nodes = manager.list_nodes()
      erb :nodes, :trim => '-'
    end

    def list_graphs_of_node( node )
      manager = load_manager()

      @name = node
      @graphs = manager.find_graph_template_by_nodename( node ).map { |graph_template|
        {
          :name => graph_template.name,
          :path => sprintf( "/image/%s", graph_template.name ),
        }
      }
      erb :node, :trim => '-'      
    end

  end
end

