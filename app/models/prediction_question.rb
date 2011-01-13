class PredictionQuestion < ActiveRecord::Base
  acts_as_voteable
  acts_as_taggable_on :tags
  acts_as_featured_item
  acts_as_moderatable
  acts_as_wall_postable
  acts_as_tweetable

  belongs_to  :user
  belongs_to  :prediction_group, :counter_cache => true, :touch => true
  has_many    :prediction_guesses
  has_many  :correct_prediction_guesses, :conditions => [ "is_correct = 1"]
  has_many  :prediction_results

  attr_accessor :tags_string
  attr_accessor :list_of_choices, :start_range, :end_range

  has_friendly_id :title, :use_slug => true
  validate :validate_choices
  validate :validate_prediction_type
  validates_presence_of :title
  validates_presence_of :choices
  validates_presence_of :status

  named_scope :newest, lambda { |*args| { :order => ["created_at desc"], :limit => (args.first || 10)} }
  named_scope :top, lambda { |*args| { :order => ["prediction_guesses_count desc, created_at desc"], :limit => (args.first || 10)} }
  named_scope :open, lambda { |*args| { :order => ["status = 'open'" ]} }
  #todo add migration for timestamp closed_at
  named_scope :closed, lambda { |*args| { :order => ["status = 'closed', updated_at desc"], :limit => (args.first || 7)} }

  def validate_choices
    case self.prediction_type
      when 'multi'
        unless list_of_choices =~ /^([-a-zA-Z0-9_ ]+,?)+$/
          errors.add(:list_of_choices, 'Please provide a comma separated list of options')
        else
          choices = list_of_choices.split(',')
        end
      when 'text'
        choices = []
      when 'yesno'
        choices = ['yes', 'no']
      when 'numeric'
        errors.add(:start_range, 'Please provide a valid numeric start range') unless start_range.present? 
        errors.add(:end_range, 'Please provide a valid numeric end range') unless end_range.present? 
        errors.add(:start_range, 'Start range must be a numeric value') unless start_range =~ /^[0-9]+$/
        errors.add(:end_range, 'End range must be a numeric value') unless end_range =~ /^[0-9]+$/
        errors.add(:end_range, 'End range must be greater than start range') unless end_range.to_i > start_range.to_i
      when 'year'
        errors.add(:start_range, 'Please provide a valid numeric start year') unless start_range.present? 
        errors.add(:end_range, 'Please provide a valid numeric end year') unless end_range.present? 
        errors.add(:start_range, 'Start year must be a valid year') unless start_range =~ /^[0-9]{4}$/
        errors.add(:end_range, 'End year must be a valid year') unless end_range =~ /^[0-9]{4}$/
        errors.add(:end_range, 'End year must be greater than start year') unless end_range.to_i > start_range.to_i
    end
  end

  def validate_prediction_type
      errors.add(:prediction_type, 'Please select a valid question type') unless self.class.prediction_types.keys.include? prediction_type
  end
  
  def self.prediction_types
      { 'multi' => 'multiple choice', 
        'yesno' => 'yes or no',
        'year' => 'year',
        'numeric' => 'number',
        'text' => 'text'
        }
  end

  def self.prediction_type_options
    self.prediction_types.collect {|k,v| [ v, k] }
  end
  
  def user_guessed? user
    prediction_guesses.exists?(:user_id => user.id)
  end

  def update_stats
    case self.prediction_type
      when "yesno"
        PredictionGuess.count(:group => :guess, :conditions => {:prediction_question_id => self.id})
      when "multi"
        PredictionGuess.count(:group => :guess, :conditions => {:prediction_question_id => self.id})
      when "numeric"
        PredictionGuess.count(:group => :guess, :conditions => {:prediction_question_id => self.id})
      when "text"
        PredictionGuess.count(:group => :guess, :conditions => {:prediction_question_id => self.id})
    end
  end
  
  def accept_prediction_result prediction_result
    # all users who made the correct guess on the question
    # correct guess = when user guess = prediction_result.result
    correct_guesses = self.prediction_guesses.find(:all, :conditions => [ "guess = ?",prediction_result.result], :include => :user)
    correct_guesses.each do |prediction_guess|
      prediction_guess.update_attribute("is_correct",true)
    end
    update_scores
    #todo - send notifications
    #Notifier.deliver_prediction_question_message(prediction_result.prediction_question)
  end
  
  def update_scores
    self.prediction_guesses.each do |prediction_guess|
      prediction_guess.user.get_prediction_score.increment_score prediction_guess.is_correct?
    end
  end

  def approve
    @prediction_question = PredictionQuestion.find(params[:id])
    @prediction_question.is_approved = true
    #if @prediction_question.update_attributes(params[:id])
  end  

  def voices
    self.prediction_guesses.find(:all, :include => :user, :group => :user_id).map(&:user)
  end

  def recipient_voices
    users = self.voices
    users << self.user
    # todo - get list of people who liked question prediction group
    #users.concat self.commentable.votes.map(&:voter) 
    users.uniq
  end
  
  def expire
    self.class.sweeper.expire_prediction_question_all self
  end

  def self.sweeper
    PredictionSweeper
  end

end
