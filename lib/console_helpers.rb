# Custom methods to be used as helpers in the irb console

# all console helper methods should have a description here, like this:
#  :method        => ["Description of method", "method required_params, [optional params] - usage info"]
@options = {
  :help           => ["Displays this output", "help [:command] - display help info, optionally for a specific command"],
  :start          => ["Starts a new task in the open workspace", "start - starts a new task"], 
  :switch         => ["Switches to an existing (or new) task", "switch [task_id] - switches to a new, or optionally existing, task"],
  :save           => ["Saves the current workspace to a file", "save [task_id] - save the current, or an optional other, task"],
  :resume         => ["Alias for :switch", "resume [task_id] - this is an alias for the `switch` command"],
  :task_list      => ["Displays tasks for the current workspace", "task_list - shows all known tasks (might display a lot of data)"],
  :tag            => ["Tags the current task", "tag <\"list of tags\"> - tags the current task with all tags in the string (comma or space separated)"],
  :note           => ["Adds a note to the current task", "note <\"a note\"> - adds a note to the current task"],
  :spent          => ["Allows you to specify how long you spent on this task", "spent <time> - pass an integer (for minutes) or a string in the form of \"/^[0-9]+[MmHhSs]$/\" \n\t\tto say how long you worked on the current task"],
  :report         => ["Generates a report of the last weeks tasks", "CURRENTLY NOT IMPLEMENTED!"],
  :reconcile      => ["Marks a task as being saved into a larger system (JIRA or SAGE)", "reconcile [task_id] - sets the boolean value of 'reconciled?' to true for the current, or optionally specific, task"]
}

@current_task = nil
@task_history = []

# This method is used for writing formatted logs...
def flog(string)
    puts "[#{Time.now.strftime('%Y/%m/%d %H:%M')}] #{string}"
end

def start
  @current_task.save if @current_task
  @current_task = Task.new
  @current_task.save
  @task_history << @current_task.id
  return @current_task.id
end

def switch(task_id = nil)
  if task_id
    @current_task.save if @current_task
    @current_task = Task.find task_id
    @task_history << @current_task.id
  else
    flog "No task id given... switching to a new task"
    start
  end
end

def save(task_id = nil)
  if task_id
    @current_task.save if @current_task
    @current_task = Task.find task_id
    @task_history << @current_task.id
    @current_task.save
  else
    if @current_task
      @current_task.save
    else
      flog "You don't currently have a task open... try `start` first"
    end
  end
end

def task_list(num = false)
  tasks = Task.where("created_at >= #{Date.today - 7}").order("created_at DESC")
  tasks = tasks.limit(num) if num
  tasks.each do |t|
    puts "Task: #{t.id}"
    puts "  started @ #{t.created_at}"
    puts "  time spent: #{t.time_spent / 60} minutes" if t.time_spent
    puts t.tags ? "  tags: #{t.tags.collect {|tag| tag.name}.join(', ')}" : "  tags: "
    puts t.details ? "  notes: \n\t#{t.details.collect {|d| "(#{d[1].to_s}) #{d[0]}"}.join("\n\t")}" : "  notes: "
  end
  puts ""
end

def resume(task_id = nil)
  switch task_id
end

def tag(tag_list)
  tags = tag_list.split(/,? /)
  tags.each do |tag_name|
    @current_task.tags << Tag.find_or_create_by_name(tag_name)
  end
end

def note(note_text)
  @current_task.describe note_text
end

def reconcile(task_id = nil)
  if task_id
    @current_task.save if @current_task
    @current_task = Task.find task_id
    @task_history << @current_task.id
    @current_task.reconciled = true
    @current_task.save
  else
    if @current_task
      @current_task.reconciled = true
      @current_task.save
    else
      flog "You don't currently have a task open... try `start` first"
    end
  end
end

def spent(time, options = {})
  new_time = nil
  if time.kind_of? Integer
    flog "Assuming you gave me time in minutes..."
    new_time = time * 60
  elsif time.kind_of? String
    if time.match(/^[0-9]+[MmHhSs]$/)
      case time.match(/^[0-9]+([MmHhSs])$/)[1]
      when /^[sS]$/
        new_time = time.match(/^([0-9]+)[MmHhSs]$/)[1]
      when /^[mM]$/
        new_time = Integer(time.match(/^([0-9]+)[MmHhSs]$/)[1]) * 60
      when /^[hH]$/
        new_time = Integer(time.match(/^([0-9]+)[MmHhSs]$/)[1]) * 3600
      end
    elsif time.match(/^[0-9]+$/)
      flog "Assuming you gave me time in minutes..."
      new_time = Integer(time)
    end
  end
  if new_time
    @current_task.time_spent = options[:add] ? @current_task.time_spent + new_time : new_time
    @current_task.save
  else
    flog "Invalid time object specified..."
  end
end

def report(options = {})
  report_period = nil
  if options[:since]
    report_period = Time.parse(options[:since])
  else
    if Time.now.day < 7
      report_period = (60 * 60 * 24 * (Time.now.day - 1)) + (60 * 60 * Time.now.hour) + (60 * Time.now.min)
    else
      report_period = (60 * 60 * 24 * 7)
    end
  end
  report_start = Time.now - report_period
  if options[:tag]
    tasks_to_report = Tag.find_by_name(options[:tag]).tasks.where('created_at >= ?', report_start)
  else
    tasks_to_report = Task.where('created_at >= ?', report_start)
  end
  if options[:format]
    puts tasks_to_report.send("to_#{options[:format]}")
  else
    flog "Tasks since #{report_start}"
    tasks_to_report.each do |t|
      puts "Task: #{t.id}"
      puts "  started @ #{t.created_at}"
      puts "  time spent: #{t.time_spent / 60} minutes" if t.time_spent
      puts t.tags ? "  tags: #{t.tags.collect {|tag| tag.name}.join(', ')}" : "  tags: "
      puts t.details ? "  notes: \n\t#{t.details.collect {|d| "(#{d[1].to_s}) #{d[0]}"}.join("\n\t")}" : "  notes: "
    end
    flog "End of report"
  end
end

def help(command = nil)
  if command
    puts "#{@options[command] ? @options[command][1] : 'commands must be symbols to get help...\':symbol\''}"
  else
    @options.each do |k,v|
      puts "\t#{k}: #{v[0]}"
    end
  end
  return false
end