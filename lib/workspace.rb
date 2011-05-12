module TimeAssistant
  class Workspace
    require 'rubygems'
    require 'digest/md5'
    require 'yaml'
    require 'fileutils'
    
    attr_reader :id
    
    def initialize(options = {})
      @id = options[:id] ? options[:id] : Time.now.strftime('%Y%V')
      @meta_file = "workspaces/#{@id}/.meta"
      @saved = false
    end
    
    def saved?
      return @saved
    end
    
    def self.find_or_create_by_id(workspace_id)
      if File.exists?("workspaces/#{workspace_id}/.meta")
        workspace = YAML.load_file("workspaces/#{workspace_id}/.meta")
      else
        workspace = Workspace.new(:id => workspace_id)
      end
      return workspace
    end
    
    def tasks
      my_tasks = []
      Dir["workspaces/#{id}/task-*.yaml"].collect {|t| my_tasks << Task.find_by_id_and_workspace(t.match(/-([a-f0-9]+)\.yaml$/)[1], @id)}
      return my_tasks
    end
    
    def save
      FileUtils.mkdir_p(File.dirname(@meta_file))
      @saved = true
      File.open("#{@meta_file}", "w") do |file|
        YAML.dump(self, file)
      end
      return true
    end
  end
end