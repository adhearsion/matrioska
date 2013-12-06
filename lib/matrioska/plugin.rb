module Matrioska
  class Plugin < Adhearsion::Plugin
    tasks do
      namespace :matrioska do
        desc "Prints the Matrioska plugin version"
        task :version do
          STDOUT.puts "Matrioska plugin v. #{VERSION}"
        end
      end
    end

    config :matrioska do
      timeout 2, desc: "Seconds to wait between each digit before trying to resolve match"
    end
  end
end
