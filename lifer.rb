require "erb"
require "open-uri"
require "rss"
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
      
      endpoint = eval('"' + unexpanded_endpoint + '"')

      @rss_content = get(endpoint)
    end
    
    def get(endpoint)
      rss_feed = ""
      open(endpoint) do |raw_feed|
        rss_feed = raw_feed.read
      end
      rss_content = RSS::Parser.parse(rss_feed, false)
      rss_content
    end
    
    def render
      items = @rss_content.items
      template = ""
      File.open(items_template_filename, "r").each do |line|
        template << line
      end
      erb = ERB.new(template)
      erb.result(binding)
    end
    
    def items_template_filename
      feed_specific_filename = File.join("templates", "#{@name}.rhtml")
      if File.exists?(feed_specific_filename)
        return feed_specific_filename
      else
        return File.join("templates", "default_items.rhtml")
      end
    end
    
  end
  
  class Lifer::Stream
   
    class << self 
      APP_CONFIG = YAML.load_file(File.join("config", "app_config.yml"))
      USER_CONFIG = YAML.load_file(File.join("config", "config.yml"))
      
      def generate
        content = ""
        
        APP_CONFIG.each do |feed_name, config|
          user_config = USER_CONFIG["feeds"][feed_name]
          feed = Lifer::Feed.new(feed_name, config["endpoint"], user_config)
          content << feed.render
        end
        
        template = ""
        File.open(File.join("templates", "default_wrapper.rhtml"), "r").each do |line|
          template << line
        end
        erb = ERB.new(template)
        output = erb.result(binding)

        string_to_file(output, "lifestream.html")
      end
      
      def string_to_file(str, filename)
        File.open(filename, "w") do |f|
          f.write(str)
        end
      end
    end

  end
  
end

Lifer::Stream.generate
