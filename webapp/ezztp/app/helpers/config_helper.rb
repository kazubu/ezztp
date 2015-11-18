# Helper methods defined here can be accessed in any controller or view in the application
require 'ipaddr'

module Ezztp
  class App
    module ConfigHelper
      # def simple_helper_method
      # ...
      # end
      def include_template _id
        begin
          tmpl = ConfigurationTemplate.find_by(:id => _id)
          return render :erb, tmpl.template
        rescue
        end
        return ""
      end
    end

    helpers ConfigHelper
  end
end
