namespace :redmine do
  namespace :plugins do
    namespace :git_mirror do
      desc <<-END_DESC
  Clear tags table.

    rake redmine:plugins:git_mirror:remove_unreachable_commits RAILS_ENV="production"
  END_DESC

      task :remove_unreachable_commits => :environment do
        Repository::GitMirror.find_each do |repo|
          puts "Removing unreachable commits from %s repo" % repo.identifier
          repo.remove_unreachable_commits
        end
      end
    end
  end
end
