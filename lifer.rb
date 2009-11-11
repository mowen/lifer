require "erb"
require "open-uri"
require "simple-rss"
require "yaml"

module Lifer
 
  class Lifer::Feed
    
    def initialize(name, endpoint, user_config)
      @name, unexpanded_endpoint = name, endpoint

      assignments = ""
      user_config.each do |k,v|
        assignments << "#{k} = '#{v}'\n"
      end
      eval(assignments)
      
      @endpoint = eval('"' + unexpanded_endpoint + '"')
    end
    
    def get
      rss_feed = ""
      open(@endpoint) do |raw_feed|
        rss_feed = raw_feed.read
      end
      rss_content = SimpleRSS.parse(rss_feed)
      rss_content
    end
    
  end

  # TODO: Is there a better name for this class?
  class Lifer::Renderer

    OUTPUT_FILENAME = "lifestream.html"

    class << self
      def render(items)
        filename = File.join("templates", "default_items.rhtml")
        content = render_erb_template(filename, binding)
        wrap_feed(content)
      end
      
      def wrap_feed(content)
        filename = File.join("templates", "default_wrapper.rhtml")
        output = render_erb_template(filename, binding)
        string_to_file(output, OUTPUT_FILENAME)
      end
      
      def render_erb_template(filename, outer_binding)
        template = ""
        File.open(filename, "r").each do |line|
          template << line
        end
        erb = ERB.new(template)
        erb.result(outer_binding)
      end

      def string_to_file(str, filename)
        File.open(filename, "w") do |f|
          f.write(str)
        end
      end
    end

  end

  
  class Lifer::Stream

    NUM_OF_RESULTS = 20
   
    class << self 
      APP_CONFIG = YAML.load_file(File.join("config", "app_config.yml"))
      USER_CONFIG = YAML.load_file(File.join("config", "config.yml"))
      
      def generate
        content = ""
        stream = []
        
        APP_CONFIG.each do |feed_name, config|
          user_config = USER_CONFIG["feeds"][feed_name]
          unless user_config.nil?
            feed = Lifer::Feed.new(feed_name, config["endpoint"], user_config)
            stream.concat(feed.get.items)
          end
        end

        stream.sort!{ |a, b| a.pubDate <=> b.pubDate }
        stream.reverse!
        stream = stream.slice(0,NUM_OF_RESULTS) # stream.slice! only left 5 items for some reason?!

        Lifer::Renderer.render(stream)
      end
      
    end

  end
  
end

Lifer::Stream.generate
