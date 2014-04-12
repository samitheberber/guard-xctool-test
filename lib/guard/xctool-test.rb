require_relative './xctool_helper'
require 'guard/guard'
require 'guard'
module Guard
  class XctoolTest < ::Guard::Guard
    include XctoolHelper

    attr_reader :xctool, :test_paths, :test_target, :cli, :all_on_start, :notifier

    class Notifier

      TITLE = 'xctool results'

      def initialize(options = {})
      end

      def notify_success
        ::Guard::Notifier.notify('Success', title: TITLE, image: :success, priority: -2)
      end

      def notify_failure
        ::Guard::Notifier.notify('Failed', title: TITLE, image: :failed, priority: 2)
      end

    end

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

      @cli = options[:cli] || ""
      @test_paths = options[:test_paths]    || "."
      @test_target = options[:test_target]  || find_test_target
      @xctool = options[:xctool_command]    || "xctool"
      @all_on_start = options[:all_on_start] || false
      @notifier = Notifier.new(options)
    end

    # Called once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    def start
      # required user having xctool to start
      unless system("which #{xctool}")
        UI.error "xctool not found, please specify :xctool_command option"
        throw :task_has_failed
      end

      unless test_target
        UI.error "Cannot find test target, please specify :test_target option"
        throw :task_has_failed
      end

      run_all if all_on_start
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
        xctool_command("test -only #{test_target}:#{filenames}")
      else
        run_all
      end
    end

    def xctool_command(command)
      commands = []
      commands << xctool
      commands << cli if cli && cli.strip != ""
      commands << command
      if system(commands.join(" "))
        notifier.notify_success
      else
        notifier.notify_failure
        throw :task_has_failed
      end
    end
  end
end
