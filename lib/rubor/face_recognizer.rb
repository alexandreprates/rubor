module Rubor
  # haarcascade_eye.xml                   haarcascade_lowerbody.xml          haarcascade_mcs_righteye.xml
  # haarcascade_eye_tree_eyeglasses.xml   haarcascade_mcs_eyepair_big.xml    haarcascade_mcs_upperbody.xml
  # haarcascade_frontalface_alt.xml       haarcascade_mcs_eyepair_small.xml  haarcascade_profileface.xml
  # haarcascade_frontalface_alt2.xml      haarcascade_mcs_leftear.xml        haarcascade_righteye_2splits.xml
  # haarcascade_frontalface_alt_tree.xml  haarcascade_mcs_lefteye.xml        haarcascade_smile.xml
  # haarcascade_frontalface_default.xml   haarcascade_mcs_mouth.xml          haarcascade_upperbody.xml
  # haarcascade_fullbody.xml              haarcascade_mcs_nose.xml
  # haarcascade_lefteye_2splits.xml       haarcascade_mcs_rightear.xml
  class FaceRecognizer

    module Recognizer
      module_function

      def frontal
        @frontal ||= OpenCV::CvHaarClassifierCascade::load('/usr/share/opencv/haarcascades/haarcascade_frontalface_default.xml')
      end

      def perfil
        @perfil ||= OpenCV::CvHaarClassifierCascade::load('/usr/share/opencv/haarcascades/haarcascade_profileface.xml')
      end

    end

    class ImageNotFound < Exception; end

    attr_reader :matches


    def initialize(image)
      raise ImageNotFound, "#{image} not found!", caller unless File.exist? image
      @image   = OpenCV::IplImage.load(image)
      @matches = track_faces
    end

    def info
      matches.collect { |region| "Face found at: #{region.top_left.x}x#{region.top_left.x} - (#{region.width}, #{region.height})" }
    end

    def mark(filename)
      Recognizer.frontal.detect_objects(@image).each do |region|
        @image.rectangle! region.top_left, region.bottom_right, :color => OpenCV::CvColor::Green
      end

      Recognizer.perfil.detect_objects(@image).each do |region|
        @image.rectangle! region.top_left, region.bottom_right, :color => OpenCV::CvColor::Red
      end

      @image.save_image(filename)
    end

    private

    def track_faces
      [].tap do |result|
        time = Benchmark.measure do
          result << Recognizer.perfil.detect_objects(@image).to_a
          result << Recognizer.frontal.detect_objects(@image).to_a
        end
        result.flatten!
        puts "Track completed in #{time}"
      end
    end

  end
end