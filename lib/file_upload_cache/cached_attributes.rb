module FileUploadCache
  module CachedAttributes
    extend ActiveSupport::Concern

    module ClassMethods

      def cached_file_for(field)
        attr_accessor :"#{field}_cache_id", :"cached_#{field}"
        define_method "#{field}_with_cache=" do |value|
          instance_variable_set("@#{field}_original", value)
          self.send("#{field}_without_cache=", value)
        end

        alias_method_chain :"#{field}=", :cache

        before_validation lambda { 
          original = self.instance_variable_get("@#{field}_original")
          self.send("cached_#{field}=", CachedFile.store(original)) unless original.blank?
          if( ! self.send("#{field}_cache_id").blank? && original.blank? )
            puts "RESTORING FROM CACHE"
            puts "id: #{self.send("#{field}_cache_id")}"
            cached_file = CachedFile.find(self.send("#{field}_cache_id"))
            puts "cached file: #{cached_file.inspect}"

            tf = Tempfile.new("temp_file")
            tf.binmode
            tf.write(cached_file.read)

            # TODO: close & cleanup
            self.send("#{field}=", tf)
            puts "FETCHED FILE NOW: #{self.send(field).inspect}"
            self.send("cached_#{field}=", cached_file)
          end
        }
      end
    end
  end


=begin
  def restore_images
    [:product_image, :logo_image].each do |field|
    end
  end

=end
  
end

ActiveRecord::Base.send(:include, FileUploadCache::CachedAttributes)