# A secret token used to encrypt user_id's in the Bookmarks#export callback URL
# functionality, for example in Refworks export of Bookmarks. In Rails 4, Blacklight
# will use the application's secret key base instead.
#


# %>'3df14f006c0a00e977bb9b2b6c6102716903bf431e7d6b6620062e2f670780fc2dd6466d0a980c6edc24a8ac60a6e0357b43de304bd59f85cbc86ee397f0f52c'
Blacklight.secret_key = ENV["RAILS_SECRET"]

