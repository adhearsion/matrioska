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
  end
end
