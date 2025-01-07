require 'sinatra'
require 'rack/test'
require 'webmock/rspec'
require File.join(File.dirname(__FILE__), '..', 'app.rb')

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false
use Rack::Session::Cookie

def app
  WordGuesserApp.new!
end

def session
  last_request.env['rack.session']
end

# Mock the random word API
def stub_random_word(word)
  stub_request(:post, 'http://randomword.saasbook.info/RandomWord').to_return(body: word)
end

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.before do
    # Simulate the random word API returning "foobar"
    stub_request(:post, "http://randomword.saasbook.info/RandomWord").to_return(body: "foobar")
  end
  config.color = true
  config.filter_run_excluding pending: true
end

# Test cases for the app
RSpec.describe 'WordGuesserApp' do
  it 'should load the home page' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Guess the word')
  end

  it 'should respond with correct guess' do
    post '/guess', word: 'word'
    expect(last_response.body).to eq('Correct! The word is word')
  end

  it 'should respond with incorrect guess' do
    post '/guess', word: 'wrong'
    expect(last_response.body).to eq('Incorrect. Try again!')
  end
end
