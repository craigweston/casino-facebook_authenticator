require 'spec_helper'
require 'casino/facebook_authenticator'

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
      facebook_id_column: "facebook_id",
      extra_attributes: {
        database: database_extra_attributes,
        facebook: facebook_extra_attributes
      }
    }
  end
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

  describe 'custom model name' do
    let(:user_model) { 'UserCustom' }
    before do
      options[:user_model] = user_model
    end

    it 'should create the user model with the name specified' do
      described_class.new(options)
      expect(described_class.const_get(user_model)).to be_a Class
    end
  end

  describe 'invalid yaml input' do

    let(:no_user_table_options){ options.merge(user_table: nil) }
    let(:no_facebook_id_column_options){ options.merge(facebook_id_column: nil) }
    let(:no_app_id_options){ options.merge(app_id: nil) }
    let(:no_app_secret_options){ options.merge(app_secret: nil) }

    context 'no hash input' do
      it 'throws an argument error if the supplied input was not hash' do
        expect{described_class.new("string")}.to raise_error ArgumentError
      end
      it 'does not throw an error if the correct hash was supplied' do
        expect{described_class.new(options)}.not_to raise_error
      end
    end
    context 'invalid table name' do
      it 'throws an argument error if the table was nil/not supplied' do
        expect{described_class.new(no_user_table_options)}.to raise_error ArgumentError
      end
    end
    context 'invalid facebook id column name' do
      it 'throws an argument error if the facebook id column was nil/not supplied' do
        expect{described_class.new(no_facebook_id_column_options)}.to raise_error ArgumentError
      end
    end
    context 'invalid app id' do
      it 'throws an argument error if the app id was nil/not supplied' do
        expect{described_class.new(no_app_id_options)}.to raise_error ArgumentError
      end
    end
    context 'invalid app secret' do
      it 'throws an argument error if the app secret was nil/not supplied' do
        expect{described_class.new(no_app_secret_options)}.to raise_error ArgumentError
      end
    end
  end

  describe '#validate' do

    let(:valid_username) { 'test' }
    let(:valid_email) { 'mail@example.org'}
    let(:valid_facebook_data) {{ 'user_id' => 9876 }}
    let(:valid_facebook_profile) {{ 'name' => 'John Doe' }}
    let(:fb_name) { 'John Doe' }
    let(:invalid_facebook_data) {{ 'user_id' => 111 }}

    context 'valid user access token' do
      before(:each) do
        subject.should_receive(:facebook_data_from_token).with(kind_of(String)).and_return(valid_facebook_data)
        subject.should_receive(:facebook_profile_data).with(kind_of(String)).and_return(valid_facebook_profile)
      end

      it 'returns the username' do
        subject.validate(params, cookies)[:username].should eq(valid_username)
      end
      it 'returns the database extra attributes' do
        subject.validate(params, cookies)[:extra_attributes][:email].should eq(valid_email)
      end
      it 'returns the facebook extra attributes' do
        subject.validate(params, cookies)[:extra_attributes][:fb_name].should eq(fb_name)
      end
    end
    context 'valid user access token but no user match' do
      it 'returns the username' do
        subject.should_receive(:facebook_data_from_token).and_return(invalid_facebook_data)
        subject.validate(params, cookies).should eq(false)
      end
    end
    context 'invalid user access token' do
      it 'returns the false' do
        subject.should_receive(:facebook_data_from_token).and_return(nil)
        subject.validate(params, cookies).should eq(false)
      end
    end

  end

end
