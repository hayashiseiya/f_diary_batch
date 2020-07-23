# --path vendor/bundle で bundle install したため
require 'bundler'
Bundler.require

require "nokogiri"
require "open-uri"
require "pry"
# require 'httparty'
require 'json'

class Scraping
  class Freitag
    class << self
      def run
        bags = bags_from_html

        {
          statusCode: 200,
          body: bags
        }.to_json
      end

      private

        def base_url_of_bags
          "https://www.freitag.ch/en/shop/bags"
        end

        def bags_from_html
          bags_dom = open(base_url_of_bags) do |f|
            charset = f.charset
            f.read
          end
  
          bags_page = Nokogiri::HTML.parse(bags_dom)
          bags = bags_page.search(".neo-unikat-model").map do |bag|
            name_with_type = bag.search(".content-wrapper h3").text
            type = name_with_type.split(" ")[0]
            name = name_with_type.split(" ")[1]
  
            price = bag.search(".content-wrapper .field-commerce-price").text.strip
            list_url = bag.search(".sector-model-unikat-pictures-json").attribute("data-model-url").value
            image_url = bag.search(".sector-model-unikat-pictures-json img").attribute("src").value
            # code = list_url の末尾のコード
  
            Bag.new({ type: type,
                      name: name,
                      price: price,
                      list_url: list_url,
                      image_url: image_url })
          end
        end
    end
  end
end

class Bag
  attr_accessor :type, :name, :price, :list_url, :image_url

  def initialize(params)
    @type = params[:type]
    @name = params[:name]
    @price = params[:price]
    @list_url = params[:list_url]
    @image_url = params[:image_url]
  end
end

def lambda_handler(event:, context:)
  Scraping::Freitag.run
end
