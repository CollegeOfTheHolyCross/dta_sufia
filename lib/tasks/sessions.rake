namespace :sessions do
  task :cleanup => :environment do
    ActiveRecord::SessionStore::Session.delete_all(["updated_at < ?", 1.days.ago])
  end
end