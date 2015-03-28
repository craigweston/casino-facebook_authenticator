require 'spec_helper'
require 'casino/facebook_authenticator'

shared_examples "a validate" do
  context 'valid user access token' do
    let(:valid_facebook_data) {{ 'user_id' => 9876 }}
    let(:valid_facebook_profile) {{ 'name' => 'John Doe' }}

    before(:each) do
      subject.should_receive(:facebook_data_from_token).with(kind_of(String)).and_return(valid_facebook_data)
      subject.should_receive(:facebook_profile_data).with(kind_of(String)).and_return(valid_facebook_profile)
    end
    it 'returns the username' do
      subject.validate(params, cookies)[:username].should eq('test')
    end
    it 'returns the database extra attributes' do
      subject.validate(params, cookies)[:extra_attributes][:email].should eq('mail@example.org')
    end
    it 'returns the facebook extra attributes' do
      subject.validate(params, cookies)[:extra_attributes][:fb_name].should eq('John Doe')
    end
  end
  context 'valid user access token but no user match' do
    let(:invalid_facebook_data) {{ 'user_id' => 111 }}

    before(:each) do
      subject.should_receive(:facebook_data_from_token).and_return(invalid_facebook_data)
    end
    it 'returns false' do
      subject.validate(params, cookies).should eq(false)
    end
  end
  context 'invalid user access token' do
    before(:each) do
      subject.should_receive(:facebook_data_from_token).and_return(nil)
    end
    it 'returns false' do
      subject.validate(params, cookies).should eq(false)
    end
  end
end

shared_examples 'a invalid yaml input' do
  context 'no hash input' do
    it 'throws an argument error if the supplied input was not hash' do
      expect{described_class.new("string")}.to raise_error ArgumentError
    end
    it 'does not throw an error if the correct hash was supplied' do
      expect{described_class.new(options)}.not_to raise_error
    end
  end
  context 'invalid table name' do
    let(:no_user_table_options){ options.merge(user_table: nil) }
    it 'throws an argument error if the table was nil/not supplied' do
      expect{described_class.new(no_user_table_options)}.to raise_error ArgumentError
    end
  end
  context 'invalid facebook id column name' do
    let(:no_facebook_id_column_options){ options.merge(facebook_id_column: nil) }
    it 'throws an argument error if the account/facebook id column was nil/not supplied' do
      expect{described_class.new(no_facebook_id_column_options)}.to raise_error ArgumentError
    end
  end
  context 'invalid app id' do
    let(:no_app_id_options){ options.merge(app_id: nil) }
    it 'throws an argument error if the app id was nil/not supplied' do
      expect{described_class.new(no_app_id_options)}.to raise_error ArgumentError
    end
  end
  context 'invalid app secret' do
    let(:no_app_secret_options){ options.merge(app_secret: nil) }
    it 'throws an argument error if the app secret was nil/not supplied' do
      expect{described_class.new(no_app_secret_options)}.to raise_error ArgumentError
    end
  end
end

shared_examples 'a custom user model name' do
  let(:user_model) { 'UserCustom' }
  before do
    options[:user_model] = user_model
  end
  it 'should create the user model with the name specified' do
    described_class.new(options)
    expect(described_class.const_get(user_model)).to be_a Class
  end
end


shared_examples 'a custom account model name' do
  let(:account_model) { 'AccountCustom' }
  let(:account_table) { 'account' }
  let(:account_user_id_column) { 'user_id' }
  before do
    options[:account_table] = account_table
    options[:account_model] = account_model
    options[:account_user_id_column] = account_user_id_column
  end
  it 'should create the account model with the name specified' do
    described_class.new(options)
    expect(described_class.const_get(account_model)).to be_a Class
  end
end

shared_examples 'a invalid yaml input with account mapping table specified' do
  let(:account_table_options){ options.merge(account_table: 'account') }
  context 'invalid account user id column name' do
    let(:no_account_user_id_options){ account_table_options.merge(account_user_id_column: nil) }
    it 'throws an argument error if the account user id column name was nil/not supplied' do
      expect{described_class.new(no_account_user_id_options)}.to raise_error ArgumentError
    end
  end
end


describe CASino::FacebookAuthenticator do

  let(:database_extra_attributes) {{ email: 'email' }}
  let(:facebook_extra_attributes) {{ fb_name: 'name' }}

  let(:params) {{ access_token: '1111222' }}

  let(:cookies) { {} }

  let(:options) do
    {
      connection: {
        adapter: 'sqlite3',
        database: '/tmp/casino-test-auth.sqlite'
      },
      app_id: '1234',
      app_secret: '5678',
      user_table: 'users',
      username_column: 'username',
      facebook_id_column: 'facebook_id',
      extra_attributes: {
        database: database_extra_attributes,
        facebook: facebook_extra_attributes
      }
    }
  end

  describe 'config with single user table' do

    let(:user_class) { described_class::TmpcasinotestauthsqliteUser }

    subject { described_class.new(options) }

    before do
      subject # ensure everything is initialized

      ::ActiveRecord::Base.establish_connection options[:connection]

      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Schema.define do
          create_table :users do |t|
            t.string :username
            t.string :email
            t.string :facebook_id
          end
        end
      end

      user_class.create!(
        id: 123,
        username: 'test',
        email: 'mail@example.org',
        facebook_id: 9876)
    end

    after do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Schema.define do
          drop_table :users
        end
      end
    end

    describe 'validate user model with single user table' do
      it_should_behave_like "a custom user model name"
    end

    describe 'invalid yaml input with single user table' do
      it_should_behave_like "a invalid yaml input"
    end

    describe 'validate with single user table' do
      it_should_behave_like "a validate"
    end

  end

  describe 'config user and account mapping table' do

    let(:user_class) { described_class::TmpcasinotestauthsqliteUser }
    let(:account_class) { described_class::TmpcasinotestauthsqliteAccount }

    subject { described_class.new(options.merge(account_table: 'accounts', account_user_id_column: 'user_id', facebook_id_column: 'account_id')) }

    before do
      subject # ensure everything is initialized

      ::ActiveRecord::Base.establish_connection options[:connection]

      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Schema.define do
          create_table :users do |t|
            t.string :username
            t.string :email
          end

          create_table :accounts do |t|
            t.string :account_id
            t.string :user_id
          end

        end
      end

      user_class.create!(
        id: 123,
        username: 'test',
        email: 'mail@example.org')

      account_class.create!(
        account_id: 9876,
        user_id: 123)
    end

    after do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Schema.define do
          drop_table :users
          drop_table :accounts
        end
      end
    end

    describe 'validate user model with account mapping table' do
      it_should_behave_like "a custom user model name"
    end

    describe 'invalid yaml input with account mapping table' do
      it_should_behave_like "a invalid yaml input"
      it_should_behave_like "a invalid yaml input with account mapping table specified"
    end

    describe 'validate with account mapping table' do
      it_should_behave_like "a validate"
    end

  end

end
