Kernel.require "#{File.dirname(__FILE__)}/models.rb"
Kernel.require "#{File.dirname(__FILE__)}/ruby_goto.rb"
Kernel.require "#{File.dirname(__FILE__)}/observer.rb"

# show warnings
#$VERBOSE = true

$args = []
ARGV.each do |arg|
  $args << arg
end
ARGV.clear

# auto-flushing
STDOUT.sync = true

@_file = $args.shift

# globals
$_data_queue = []
$_observer_queue = []

$_interrupt_time = -1
$_exec_status = :running
$_observer_started = false
$_current_rt = 0

@_command_thread = Thread.new { CommandThread.new.run }

$rt_adjust = 0

# Waits for roundtime and pauses for the duration.
#
# @param
# @return [void]
# @example Wait for the duration of round time before executing next command.
#   put "hide"
#   wait_for_roundtime
#   put "unhide"
def wait_for_roundtime
  (0..1000000).each do
    $_data_queue.each_index do |i|
      if $_data_queue.at(i).match(/Roundtime/)
        sleep_for_rt $_data_queue.at(i)[/\d+/].to_i + $rt_adjust
        $_data_queue.delete_at(i)
        return
      end
      $_data_queue.delete_at(i)
    end
    sleep 0.01
  end
end

# Pauses for current roundtime
#
# @param
# @return [void]
def pause_for_roundtime
  if $_current_rt > 0
    sleep_for_rt $_current_rt + $rt_adjust
  end
end

# Runs until match pattern is found in game text.
#
# @param [String] pattern regex pattern.
# @return [void]
def wait_for(pattern)
  (0..1000000).each do
    $_data_queue.each_index do |i|
      if $_data_queue.at(i).match(pattern)
        $_data_queue.delete_at(i)
        return
      end
      $_data_queue.delete_at(i)
    end
    sleep 0.01
  end
end

# Matches regex patterns and returns
# the name of the matching pattern.
#
# @param [Hash] pattern list of regex patterns and names
# @return [Symbol] pattern name
# @example Match for game text.
#   match = { :retry => [/\.\.\.wait/], :next => [/you open/] }
#   result = match_wait match
#   result #=> :retry or :next
#   if result = :next
#     echo "next"
#   end
def match_wait(pattern)
  $_exec_status = :match_wait
  match_found = false
  match = :not_found
  sleep = 0

  (0..1000000).each do
    $_data_queue.each_index do |i|
      unless match_found
        pattern.each_pair do |k, v|
          v.each do |m|
            if $_data_queue.at(i).match(m)
              match = k
              match_found = true
              break
            end
          end
          break if match_found
        end
      end

      if $_data_queue.at(i).match(/Roundtime/)
        sleep += $_data_queue.at(i)[/\d+/].to_i + $rt_adjust
      end

      if match_found
        $_exec_status = :running

        if $_data_queue.at(i).match(/>$/)
          sleep_for_rt sleep
          $_data_queue.delete_at(i)
          return match
        end
      end

      $_data_queue.delete_at(i)
    end
    sleep 0.01
  end
end

# Matches regex patterns and returns the matched line.
#
# @param [Hash] pattern list of regex patterns and names
# @return [String] line of text
# @example Retrieve the text from a matching pattern.
#   match = { :m => [/you open/i] }
#   result = match_get match
#   result #=> You open the steel trunk...
def match_get(pattern)
  $_exec_status = :match_get
  match_found = false
  match = :not_found
  sleep = 0

  (0..1000000).each do
    $_data_queue.each_index do |i|
      unless match_found
        pattern.each_pair do |k, v|
          v.each do |m|
            if $_data_queue.at(i).match(m)
              match = $_data_queue.at(i)
              match_found = true
              break
            end
          end
          break if match_found
        end
      end

      if $_data_queue.at(i).match(/Roundtime/)
        sleep += $_data_queue.at(i)[/\d+/].to_i + $rt_adjust
      end

      if match_found
        $_exec_status = :running

        if $_data_queue.at(i).match(/>$/)
          sleep_for_rt sleep
          $_data_queue.delete_at(i)
          return match
        end
      end

      $_data_queue.delete_at(i)
    end
    sleep 0.01
  end
end

# Match verbose.
#
# Matches regex patterns and returns
# verbouse match data.
#
# @param [Hash] pattern list of regex patterns and names
# @return [Hash] line of text
# @example Finding a match for a pattern with verbouse results.
#   match = { :m => [/you open/i] }
#   result = match_v match
#   result #=> { :key => :loot, :match => "You open the steel trunk..." }
def match_v(pattern)
  $_exec_status = :match_v
  match_found = false
  match = :not_found
  sleep = 0

  (0..1000000).each do
    $_data_queue.each_index do |i|
      unless match_found
        pattern.each_pair do |k, v|
          v.each do |m|
            if $_data_queue.at(i).match(m)
              match = {:key => k, :match => $_data_queue.at(i)}
              match_found = true
              break
            end
          end
          break if match_found
        end
      end

      if $_data_queue.at(i).match(/Roundtime/)
        sleep += $_data_queue.at(i)[/\d+/].to_i + $rt_adjust
      end

      if match_found
        $_exec_status = :running

        if $_data_queue.at(i).match(/>$/)
          sleep_for_rt sleep
          $_data_queue.delete_at(i)
          return match
        end
      end

      $_data_queue.delete_at(i)
    end
    sleep 0.01
  end
end

# Matches regex patterns
# and goes to defined label.
#
# @param [Hash] pattern list of regex patterns and names
# @return [Void]
# @example Using match patterns and jumping to labels on a successful match.
#   labels_start
#
#   label(:retry){
#     match = { :retry => [/\.\.\.wait/], :next => [/you open/] }
#     match_wait_goto match
#   }
#
#   label(:next){
#     echo "next"
#   }
#
#   labels_end
def match_wait_goto(pattern)
  $_exec_status = :match_wait_goto
  match_found = false
  match = :not_found
  sleep = 0

  (0..1000000).each do
    $_data_queue.each_index do |i|
      unless match_found
        pattern.each_pair do |k, v|
          v.each do |m|
            if $_data_queue.at(i).match(m)
              match = k
              match_found = true
              break
            end
          end
          break if match_found
        end
      end

      if $_data_queue.at(i).match(/Roundtime/)
        sleep += $_data_queue.at(i)[/\d+/].to_i + $rt_adjust
      end

      if match_found
        $_exec_status = :running

        if $_data_queue.at(i).match(/>$/)
          sleep_for_rt sleep
          $_data_queue.delete_at(i)
          goto match
        end
      end

      $_data_queue.delete_at(i)
    end
    sleep 0.01
  end
end

# Sends a command to server.
#
# @param [String] value command.
# @return [void]
def put(value)
  $_data_queue.clear
  puts "put#" + value.to_s
  STDOUT.flush
end

# Sends a move command to client and
# waits for navigation message.
#
# @param [String] value command.
# @return [void]
# @example Using move command in script.
#   move "n"
#   move "e"
#   move "go gate"
def move(dir)
  puts "put#" + dir.to_s
  STDOUT.flush

  case match_wait({ :room => [/^\{nav\}$/],
                    :stand => [/sitting|kneeling|lying|must be standing/],
                    :retreat => [/if you first retreat|You are engaged|do that while engaged/],
                    :wait => [/\.\.\.wait|you may only type ahead/] })
    when :wait
      pause 0.5
      move dir
    when :stand
      pause 0.5
      put "stand"
      move dir
    when :retreat
      put "retreat"
      put "retreat"
      move dir
  end
end

# Waits for a prompt character.
#
# @param
# @return [void]
# @example Using wait in script to run consecutive commands.
#   put "remove my shield"
#   wait
#   put "wear my shield"
#   wait
#   put "remove my shield"
def wait
  $_data_queue.clear
  wait_for(/>$/)
end

# Sends a message to client main window.
#
# @param [#to_s] value message.
# @return [void]
# @example Echoing into client main window.
#   echo "hello"
#   echo 1
def echo(value)
  puts "echo#" + value.to_s
  STDOUT.flush
end

# Pauses for given time.
#
# @param [Integer, Float] value sleep time in seconds, default value = 1
# @return [Void]
def pause(value = 1)
  sleep value
end

# Load a script by name.
#
# @param [String] name name of the file
# @return [Void]
def load(name)
  Kernel.load "#{Dir.pwd}/scripts/#{name}.rb"
end

# Require a script by name. Only loads file once per script execution.
#
# @param [String] name name of the file
# @return [Void]
def require(name)
  Kernel.require "#{Dir.pwd}/scripts/#{name}.rb"
end

# Current match round time -- can be used in
# secondary threads while main thread is stuck in round time
#
# @param
# @return [Integer] current round time value
def get_match_rt
  $_current_rt
end

# @private
def end_command_thread
  puts "end#"
end

# @private
def exit
  end_command_thread
  Kernel::exit
end

# @private
def abort
  end_command_thread
  Kernel::abort
end

# @private
def sleep_for_rt(rt)
  $_current_rt = rt
  return if rt <= 0
  sleep 1
  if $_interrupt_time != -1
    rt = rt - $_interrupt_time
    $_interrupt_time = -1
  end
  sleep_for_rt rt - 1
end

# @private
at_exit do
  if defined? finally_do
    unless @_command_thread.alive?
      @_command_thread = Thread.new { CommandThread.new.run }
    end
    finally_do
    end_command_thread
  end
end

# wait for previous round time
# before executing script
sleep Rt::value

# run script file here
Kernel.require @_file

# end threads after finished
end_command_thread