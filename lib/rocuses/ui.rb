# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'rocuses/manager'

module Rocuses
  class UI < Sinatra::Base

    #    set :views, File.dirname(__FILE__) + '/../../views'
    set :views, '/usr/share/rocuses-ui/views'

    get '/' do
      manager = load_manager()

      @all_nodes = manager.list_nodes()

      erb :index, :trim => '-'
    end

    get '/image/:id/:period' do
      node = params[:node]
      period = parse_period( params[:period] )

      display_graph_image( :id         => params[:id],
                           :begin_time => period[:begin_time],
                           :end_time   => period[:end_time] )
    end

    get '/image/:id' do
      node = params[:node]

      display_graph_image( :id         => params[:id] )
    end

    get '/node/:node' do
      list_graphs_of_node( params[:node] )
    end

    get '/node' do
      list_nodes()
    end

    get '/node_graph/:node/:period' do
      node = params[:node]
      period = parse_period( params[:period] )

      display_node_page( :node       => node,
                         :begin_time => period[:begin_time],
                         :end_time   => period[:end_time] )
    end

    get '/node_graph/:node' do
      node = params[:node]

      display_node_page( :node => node )
    end

    private

    def load_manager
      manager = Rocuses::Manager.new
      manager.load_graph_templates()
      return manager.graph_template_manager()
    end

    def display_graph_image( args )
      args = Rocuses::Utils::check_args( args,
                                         {
                                           :id         => :req,
                                           :begin_time => :op,
                                           :end_time   => :op,
                                         },
                                         {
                                           :begin_time => Time.now - 24 * 60 * 60,
                                           :end_time   => Time.now,
                                         } )

      begin 
        manager = load_manager()
        graph_name = args[:id]
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

        return graph.make_image( :begin_time => args[:begin_time],
                                 :end_time   => args[:end_time],
                                 :width      => 500,
                                 :height     => 120 )

      rescue => e
        content_type 'text/plain'
        "Error #{ e.to_s }\n#{ e.backtrace }"
      end
    end

    def display_node_page( args )
      args = Rocuses::Utils::check_args( args,
                                         {
                                           :node  => :req,
                                           :begin_time => :op,
                                           :end_time   => :op,
                                         },
                                         {
                                           :begin_time => Time.now - 24 * 60 * 60,
                                           :end_time   => Time.now,
                                         } )
      @node       = args[:node]
      @begin_time = args[:begin_time]
      @end_time   = args[:end_time]

      manager = load_manager()
      @all_nodes = manager.list_nodes()
      
      @graph_template_paths_of = Hash.new { |hash,key|
        hash[key] = Array.new
      }
      manager.find_graph_template_by_nodename( args[:node] ).each { |graph_id, graph_template|
        @graph_template_paths_of[graph_template.category] << graph_path( graph_template, @begin_time, @end_time )
      }

      erb :node_graph, :trim => '-'
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

      return { :begin_time => begin_time, :end_time => end_time }
    end

    def list_nodes
      manager = load_manager()
      @nodes = manager.list_nodes()
      erb :nodes, :trim => '-'
    end

    def list_graphs_of_node( node )
      manager = load_manager()

      @name = node
      @graphs = manager.find_graph_template_by_nodename( node ).map { |graph_id, graph_template|
        {
          :name => graph_template.name,
          :path => sprintf( "/image/%s", graph_template.graph_id ),
        }
      }
      erb :node, :trim => '-'      
    end

    def graph_path( graph_template, begin_time = Time.now - 24 * 60 * 60, end_time = Time.now )
      return sprintf( "/image/%s/%d,%d", graph_template.graph_id, begin_time.to_i, end_time.to_i )
    end

  end
end

