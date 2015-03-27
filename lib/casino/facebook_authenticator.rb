require 'active_record'
require 'rails'
require 'koala'

class CASino::FacebookAuthenticator

  class AuthDatabase < ::ActiveRecord::Base
    self.abstract_class = true
  end

  # @param [Hash] options
  def initialize(options)
    if !options.respond_to?(:deep_symbolize_keys)
      raise ArgumentError, "When assigning attributes, you must pass a hash as an argument."
    end
    @options = options.deep_symbolize_keys

    # user active record initialization
    raise ArgumentError, "User table name is missing" unless @options[:user_table]
    @user_model = create_model(@options[:user_table], @options[:user_model])

    @username_column = @options[:username_column] || 'username'
    @user_id_column = @options[:user_id_column] || 'id'

    # account active record initialization
    if @options[:account_table]
      @account_model = create_model(@options[:account_table], @options[:account_model])

      if @options[:account_type] and @options[:account_type_column]
        @account_type = @options[:account_type]
        @account_type_column = @options[:account_type_column]
      end

      raise ArgumentError, "Account user id column name is missing" unless @options[:account_user_id_column]
      @account_user_id_column = @options[:account_user_id_column]
    end

    # facebook column that stores facebook id
    raise ArgumentError, "Facebook id column name is missing" unless @options[:facebook_id_column]
    @facebook_id_column =  @options[:facebook_id_column]

    # facebook initialization
    raise ArgumentError, "App ID is missing" unless @options[:app_id]
    @app_id = @options[:app_id]

    raise ArgumentError, "App secret is missing" unless @options[:app_secret]
    app_secret = @options[:app_secret]

    @oauth = Koala::Facebook::OAuth.new(@app_id, app_secret)
  end

  def validate(params, cookies)
    user_access_token = params[:access_token]
    if user_access_token
      load_user_data(user_access_token)
    else
      false
    end
  rescue ActiveRecord::RecordNotFound
    false
  end

  def view
    @options[:view] || '/facebook_login.html.erb'
  end

  def app_id
    @app_id
  end

  private
  def create_model(table_name, model_name)
    if model_name.nil?
      model_name = table_name
      if @options[:connection][:database]
        model_name = "#{@options[:connection][:database].gsub(/[^a-zA-Z]+/, '')}_#{model_name}"
      end
      model_name = model_name.classify
    end
    model_class_name = "#{self.class.to_s}::#{model_name}"
    eval <<-END
      class #{model_class_name} < AuthDatabase
        self.table_name = "#{table_name}"
        self.inheritance_column = :_type_disabled
      end
    END

    model = model_class_name.constantize
    model.establish_connection @options[:connection]
    return model
  end

  def load_user_data(user_access_token)
    data = facebook_data_from_token(user_access_token)
    return false unless data
    user = find_user_by_facebook_id(data['user_id'])
    user_data(user, user_access_token)
  end

  def user_data(user, user_access_token)
    { username: user.send(@username_column), extra_attributes: extra_attributes(user, user_access_token) }
  end

  def facebook_data_from_token(user_access_token)
    app_access_token_info = @oauth.get_app_access_token_info
    if user_access_token and app_access_token_info
      graph = Koala::Facebook::API.new(app_access_token_info['access_token'])
      debug_token_info = graph.debug_token(user_access_token)
      data = debug_token_info['data'] unless debug_token_info.nil?
      if data and data['is_valid'] and data['app_id'].to_s == @app_id.to_s
        return data
      end
    end
  end

  def find_user_by_facebook_id(facebook_id)
    facebook_id_find_by = "find_by_#{@facebook_id_column}"
    if @account_model
      account = nil
      if @account_type_column.nil? || @account_type.nil?
        account = @account_model.send("#{facebook_id_find_by}!", facebook_id)
      else
        account = @account_model.send("#{facebook_id_find_by}_and_#{@account_type_column}!", facebook_id, @account_type)
      end
      user_id = account.send(@account_user_id_column)
      user = @user_model.send("find_by_id!", user_id)
    else
      user = @user_model.send("#{facebook_id_find_by}!", facebook_id)
    end
  end

  def extra_attributes(user, user_access_token)
    attributes = {}
    # activerecord attributes
    extra_database_attributes_option.each do |attribute_name, database_column|
      attributes[attribute_name] = user.send(database_column)
    end
    # facebook attributes
    if extra_attributes_option.has_key?(:facebook)
      facebook_profile = facebook_profile_data(user_access_token)
      extra_facebook_attributes_option.each do |attribute_name, facebook_attribute|
        attributes[attribute_name] = facebook_profile[facebook_attribute]
      end
    end
    attributes
  end

  def facebook_profile_data(user_access_token)
    Koala::Facebook::API.new(user_access_token).get_object("me")
  end

  def extra_database_attributes_option
    extra_attributes_option[:database] || {}
  end

  def extra_facebook_attributes_option
    extra_attributes_option[:facebook] || {}
  end

  def extra_attributes_option
    @options[:extra_attributes] || {}
  end

end
