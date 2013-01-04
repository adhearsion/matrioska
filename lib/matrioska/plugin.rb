module Matrioska
  class Plugin < Adhearsion::Plugin
    # Actions to perform when the plugin is loaded
    #
    init :matrioska do
      logger.warn "Matrioska has been loaded"
    end

    # Basic configuration for the plugin
    #
    config :matrioska do
      greeting "Hello", :desc => "What to use to greet users"
    end

    # Defining a Rake task is easy
    # The following can be invoked with:
    #   rake plugin_demo:info
    #
    tasks do
      namespace :matrioska do
        desc "Prints the PluginTemplate information"
        task :info do
          STDOUT.puts "Matrioska plugin v. #{VERSION}"
        end
      end
    end

  end
end
