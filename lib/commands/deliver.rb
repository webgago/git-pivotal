require 'commands/base'

module Commands
  class Deliver < Base

    def run!
      super

      msg = "Retrieving story to deliver from Pivotal Tracker"
      if options[:only_mine]
        msg += " for #{options[:full_name]}"
      end
      put "#{msg}..."

      unless story
        put "No stories to diliver available!"
        return 0
      end

      put "Story: #{story.name}"
      put "URL:   #{story.url}"

      put "Deliver this story?(y/n):"
      return 1 if input.gets.chomp.downcase != 'y'

      put "Updating story status to deliver in Pivotal Tracker..."
      if story.update_attributes(:current_state => 'delivered')
        sys "git checkout develop"

        commit_message = `git log --pretty=oneline --abbrev-commit -n1`.chomp[/\s(.*)$/].strip
        new_commit_messqge = commit_message + "[##{story.id} fixed]"

        put "Update last commit message to: #{new_commit_messqge}"
        sys %{git ci --amend -m "#{new_commit_messqge}"}

        put "Push develop branch"
        sys "git push origin develop"
        return 0
      else
        put "Unable to deliver story"
        return 1
      end
    end

    protected

    def story
      return @story if @story
      conditions = { :current_state => :finished }
      conditions[:owned_by] = options[:full_name] if options[:only_mine]
      @story = project.stories.find(:conditions => conditions, :limit => 1).first
    end
  end
end
