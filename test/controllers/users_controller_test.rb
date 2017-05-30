require 'test_helper'
require 'json'

class UsersControllerTest < ActionController::TestCase

  test "Should get valid list of users" do
    get :index
    assert_response :success
    assert_equal response.content_type, 'application/vnd.api+json'
    jdata = JSON.parse response.body
    assert_equal 6, jdata['data'].length
    assert_equal jdata['data'][0]['type'], 'users'
  end

  test "Should get valid user data" do
    user = users('user_1')
    get :show, params: { id: user.id }
    assert_response :success
    jdata = JSON.parse response.body
    assert_equal user.id.to_s, jdata['data']['id']
    assert_equal user.username, jdata['data']['attributes']['username']
  end

  test "Should get JSON:API error block when requesting user data with invalid ID" do
    get :show, params: { id: "z" }
    assert_response 404
    jdata = JSON.parse response.body
    assert_equal "Wrong ID provided", jdata['errors'][0]['detail']
    assert_equal '/data/attributes/id', jdata['errors'][0]['source']['pointer']
  end

  test "Creating new user without sending correct content-type should result in error" do
    post :create, params: {}
    assert_response 403
  end

  test "Creating new user without sending X-Api-Key should result in error" do
    @request.headers["Content-Type"] = 'application/vnd.api+json'
    post :create, params: {}
    assert_response 403
  end

  test "Creating new user with incorrect X-Api-Key should result in error" do
    @request.headers["Content-Type"] = 'application/vnd.api+json'
    @request.headers["X-Api-Key"] = '0000'
    post :create, params: {}
    assert_response 403
  end

  test "Creating new user with invalid type in JSON data should result in error" do
    user = users('user_1')
    @request.headers["Content-Type"] = 'application/vnd.api+json'
    @request.headers["X-Api-Key"] = user.token
    post :create, params: { data: { type: 'posts' }}
    assert_response 409
  end

  test "Creating new user with invalid data should result in error" do
    user = users('user_1')
    @request.headers["Content-Type"] = 'application/vnd.api+json'
    @request.headers["X-Api-Key"] = user.token
    post :create, params: {
                    data: {
                      type: 'users',
                      attributes: {
                        username: nil,
                        password: nil,
                        password_confirmation: nil }}}
    assert_response 422
    jdata = JSON.parse response.body
    pointers = jdata['errors'].collect { |e|
      e['source']['pointer'].split('/').last
    }.sort
    assert_equal ['password', 'username'], pointers
  end

  test "Creating new user with valid data should create new user" do
    user = users('user_1')
    @request.headers["Content-Type"] = 'application/vnd.api+json'
    @request.headers["X-Api-Key"] = user.token
    post :create, params: {
                    data: {
                      type: 'users',
                      attributes: {
                        username: 'User Number7',
                        password: 'password',
                        password_confirmation: 'password' }}}
    assert_response 201
    jdata = JSON.parse response.body
    assert_equal 'User Number7',
                 jdata['data']['attributes']['username']
  end
end