# Custom methods to be used as helpers in the irb console
@options = {
  :help           => "Displays this output",
  :start          => "Starts a new task in the open workspace", 
  :switch         => "Switches to an existing (or new) task",
  :save           => "Saves the current workspace to a file",
  :resume         => "Alias for :switch",
  :task_list      => "Displays tasks for the current workspace",
  :tag            => "Tags the current task",
  :note           => "Adds a note to the current task",
  :spent          => "Allows you to specify how long you spent on this task",
  :report         => "Generates a report of the last weeks tasks"
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

def task_list
  tasks = Task.where("created_at >= #{Date.today - 7}").order("created_at DESC")
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

def help(command = nil)
  @options.each do |k,v|
    puts "\t#{k}: #{v}"
  end
  return false
end