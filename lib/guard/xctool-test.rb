require_relative './xctool_helper'
require 'guard/guard'
require 'guard'
module Guard
  class XctoolTest < ::Guard::Guard
    include XctoolHelper

    attr_reader :xctool, :test_paths, :target

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even if they are not in an active group!
    #
    # @param [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @param [Hash] options the custom Guard plugin options
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(watchers = [], options = {})
      super

      @test_paths = options[:test_paths] || "."
      @target = options[:target]
      @xctool = options[:xctool_command] || "xctool"
    end

    # Called once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    def start
      # required user having xctool to start
      unless system("which #{xctool}")
        UI.info "xcotool not found"
        throw :task_has_failed
      end

      unless target
        UI.info "Test :target missing"
        throw :task_has_failed
      end
    end

    # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard quits).
    #
    # @raise [:task_has_failed] when stop has failed
    # @return [Object] the task result
    #
    def stop
    end

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    #
    # @raise [:task_has_failed] when reload has failed
    # @return [Object] the task result
    #
    def reload
    end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    def run_all
      UI.info "Running all tests..."
      xctool_command("test")
    end

    def run_on_changes(paths)
      test_files = test_classes_with_paths(paths, test_paths)

      if test_files.size > 0
        filenames = test_files.join(",")

        UI.info "Running tests on classes: #{filenames}"
        xctool_command("test -only #{target}:#{filenames}")
      else
        run_all
      end
    end

    def xctool_command(command)
      system("#{xctool} #{command}")
    end
  end
end