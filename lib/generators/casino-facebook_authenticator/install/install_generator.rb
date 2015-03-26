module CASino
  class InitializerGenerator < Rails::Generators::Base

    # Explicit namespace needed for proper inflection.
    # Thor::Group does not use ActiveSupport's Inflector when programmatically
    # generating the namespace, so this would be to "c_a_sino" otherwise.
    namespace 'casino-facebook_authenticator:install'

    def install
      requirejs = "require 'casino-facebook_authenticator.js'"
      original_js = File.binread("app/assets/javascripts/application.js")
      if original_js.include?(requirejs)
        say_status("skipped", "insert into app/assets/javascripts/application.js", :yellow)
      else
        insert_into_file 'app/assets/javascripts/application.js', :after => %r{//= require +['"]?casino['"]?} do
          "\n//= #{requirejs}"
        end
      end
    end

  end
end
