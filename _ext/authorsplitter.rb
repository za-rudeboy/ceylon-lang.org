require 'mypaginator'

module Awestruct
  module Extensions
    class AuthorSplitter

      class AuthorStat
        attr_accessor :pages
        attr_accessor :group
        attr_accessor :primary_page
        def initialize(author, pages)
          @author   = author
          @pages = pages
        end

        def to_s
          @author
        end
      end

      def initialize(authored_items_property, input_path, output_path='authors', pagination_opts={})
        @authored_items_property = authored_items_property
        @input_path  = input_path
        @output_path = output_path
        @pagination_opts = pagination_opts
      end

      def execute(site)
        @authors ||= {}
        all = site.send( @authored_items_property )
        return if ( all.nil? || all.empty? ) 

        all.each do |page|
          author = page.author
          if ( author && ! author.empty? )
            author = author.to_s
            @authors[author] ||= AuthorStat.new( author, [] )
            @authors[author].pages << page
          end
        end

        all.each do |page|
          page.author = (page.author||[]).collect{|t| @authors[t]}
        end

        ordered_authors = @authors.values
        ordered_authors.sort!{|l,r| -(l.pages.size <=> r.pages.size)}
        #ordered_tags = ordered_tags[0,100]
        ordered_authors.sort!{|l,r| l.to_s <=> r.to_s}

        min = 9999
        max = 0

        ordered_authors.each do |author|
          min = author.pages.size if ( author.pages.size < min )
          max = author.pages.size if ( author.pages.size > max )
        end

        span = max - min
        
        if span > 0
          slice = span / 6
          if slice == 0
            slice = 1
          end
          ordered_authors.each do |author|
            adjusted_size = author.pages.size - min
            scaled_size = adjusted_size / slice
            author.group = ( author.pages.size - min ) / slice
          end
        else
          ordered_authors.each do |author|
            author.group = 0
          end
        end

        @authors.values.each do |author|
          paginator = Awestruct::Extensions::MyPaginator.new( @authored_items_property, @input_path, { :remove_input=>false, :output_prefix=>File.join( @output_path, author.to_s), :split_title=>author.to_s,:collection=>author.pages }.merge( @pagination_opts ) )
          primary_page = paginator.execute( site )
          #site.splitter_title = ''
          author.primary_page = primary_page
        end

        site.send( "#{@authored_items_property}_authors=", ordered_authors )
      end
    end
  end
end
