class PredictionGroup < ActiveRecord::Base
  acts_as_voteable
  acts_as_taggable_on :tags, :sections
  acts_as_featured_item
  acts_as_moderatable
  acts_as_media_item
  acts_as_refineable
  acts_as_wall_postable

  belongs_to  :user
  has_many    :prediction_questions
  has_one :tweeted_item, :as => :item

  attr_accessor :tags_string


  has_friendly_id :title, :use_slug => true
  validates_presence_of :title, :section, :description

  named_scope :newest, lambda { |*args| { :order => ["created_at desc"], :limit => (args.first || 10)} }

  def to_s
    "Prediction Group: #{title}"
  end

end
