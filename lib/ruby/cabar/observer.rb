
module Cabar
  module Observer
    class Manager
      attr_accessor :observed

      attr_reader :callback_by_action

      # Lock on each action during notify
      attr_reader :notifying

      EMPTY_ARRAY = [ ].freeze

      def initialize(observed = nil)
        super()
        @observed = observed
        @callback_by_action = { }
        @notifying = { }
      end

      def add_observer(observer, action = nil, callback = nil)
        callback ||= :update 
        callback = [ observer, callback ]
        (@callback_by_action[action] ||= [ ]).push callback
      end

      def delete_observer(observer, action = nil)
        action ||= @observers_by_action.keys
        action = [ action ] unless Array === action
        action.map{|x| @callback_by_action[x]}.each do | callbacks |
          callbacks.reject! do | callback |
            callback[0] == observer
          end
        end
      end

      def delete_observers
        @callback_by_action.clear
      end

      def notify_observers(action, args)
        action ||= @observers_by_action.keys
        action = [ action ] unless Array === action
        action = action.dup
        action.push nil # ALL ACTIONS

        callback_by_action = @callback_by_action.dup
        notifying = @notifying

        action.each do | action |
          next if notifying[action] && notifying[action] > 0
          begin
            notifying[action] ||= 0
            notifying[action] += 1

            (callback_by_action[action] || EMPTY_ARRAY).each do | callback |
              observer = callback[0]
              callback = callback[1]
              # $stderr.puts "notify #{observer} #{callback.inspect} #{args.inspect}"
              case callback
              when Proc
                callback.call(observer, *args)
              else
                observer.send(callback, *args)
              end
            end

          ensure
            notifying[action] -= 1
          end
        end
      end
    end

    module Observed
      def add_observer(observer, action = nil, callback = nil)
        @observed_manager ||= Manager.new(self)
        @observed_manager.add_observer(observer, action, callback)
      end

      def delete_observer(observer, action = nil)
        @observed_manager && @observed_manager.delete_observer(observer, action)
      end

      def delete_observers
        @observed_manager && @observed_manager.delete_observers
      end

      def notify_observers action = nil, *args
        @observed_manager && @observed_manager.notify_observers(action, args)
      end

    end
  end
end
