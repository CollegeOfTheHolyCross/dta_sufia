class Posts < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  # Try building a slug based on the following fields in
  # increasing order of specificity.
  def slug_candidates
    [
        [:created_ym, :title],
        :title,
        [:created_ym, :title, :user]
    ]
  end
end
