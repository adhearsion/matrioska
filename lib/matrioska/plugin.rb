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
      timeout 2, desc: "Time (in seconds) to wait between each digit before trying to resolve match", transform: Proc.new { |v| v.to_i }
    end
  end
end
