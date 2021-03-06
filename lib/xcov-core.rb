require 'xcov-core/version'
require 'xcov'
require 'json'
require 'tempfile'
require 'fastlane_core'

module Xcov
  module Core

    ENV['XCOV_CORE_LIBRARY_PATH'] = File.expand_path("../xcov-core/bin", __FILE__) + "/xcov-core"

    class Parser

      def self.parse(file)
        report_output = Tempfile.new("report.json")
        command = "#{ENV['XCOV_CORE_LIBRARY_PATH'].shellescape} -s #{file.shellescape} -o #{report_output.path.shellescape}"
        description = [{ prefix: "Parsing .xccoverage file: " }]
        execute_command(command, description)
        output_file = File.read(report_output.path)
        JSON.parse(output_file)
      end

      def self.execute_command (command, description)
        FastlaneCore::CommandExecutor
            .execute(
                command: command,
                print_all: true,
                print_command: true,
                prefix: description,
                loading: "Loading...",
                error: proc do |error_output|
                  begin
                    Xcov::ErrorHandler.handle_error(error_output)
                  rescue => ex
                    Xcov::SlackPoster.new.run({
                      build_errors: 1
                    })
                    raise ex
                  end
                end
            )
      end
      
    end

  end
end
