module Rubor
  module Application
    IMAGE_DIR = 'public/images/'
    ORIGINAL = 'public/images/original.jpg'

    module_function

    # Metodo que recebe as requisicoes do Rack
    def call(env)
      @request = Rack::Request.new(env)
      return image_processor if @request.path == '/process' && @request.post?

      [404, {"Content-Type" => "text/plain"}, ["Sorry! not found."]]
    end

    def image_processor
      filename = save_post_data('image') || @request.params['url']

      image = MiniMagick::Image.open(filename)
      image.write(ORIGINAL)

      size = @request.params['size'].downcase.split('x').collect(&:to_i)

      recognizer = Rubor::FaceRecognizer.new(ORIGINAL)
      unless recognizer.matches.empty?
        crop_image 'smart_crop.jpg', region: calc_smart_crop(size, recognizer.best_match)
        crop_image 'center_crop.jpg', region: calc_center_crop(size), gravity: 'Center'

        recognizer.mark(ORIGINAL)
      end

      [301, {"Content-Type" => "text/html", "Location" => '/'}, [""]]
    end

    def save_post_data(name)
      tempfile = @request.params[name]
      return nil if tempfile.nil?

      File.join(IMAGE_DIR, tempfile[:filename]).tap do |filename|
        File.open(filename, 'w') { |file| file.write tempfile[:tempfile].read }
      end
    end

    def calc_smart_crop(size, region)
      half_x = size[0] / 2
      half_y = size[1] / 2

      point_x = (region.center.x - half_x).to_i
      point_y = (region.center.y - half_y).to_i

      "#{size[0]}x#{size[1]}+#{point_x}+#{point_y}"
    end

    def calc_center_crop(size)
      "#{size[0]}x#{size[1]}+1+1"
    end

    def crop_image(name, options = {})
      image = MiniMagick::Image.open ORIGINAL
      image.combine_options do |c|
        image.gravity options[:gravity] || 'SouthWest'
        image.crop options[:region]
      end
      image.write File.join(IMAGE_DIR, name)
    end

  end
end