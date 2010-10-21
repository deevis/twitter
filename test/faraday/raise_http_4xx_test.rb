require 'test_helper'

class RaiseHttp4xxTest < Test::Unit::TestCase

  context "RaiseHttp4xx" do
    %w(json xml).each do |format|
      context "with request formata#{format}" do

        setup do
          Twitter.format = format
        end

        should "raise BadRequest when rate limited" do
          stub_get("statuses/show/400.#{format}", "bad_request.#{format}", "application/#{format}; charset=utf-8", 400)
          assert_raise Twitter::BadRequest do
            client = Twitter::Unauthenticated.new
            client.status(400)
          end
        end

        should "raise Unauthorized for a request to a protected user's timeline" do
          stub_get("statuses/user_timeline.#{format}?screen_name=protected", "unauthorized.#{format}", "application/#{format}; charset=utf-8", 401)
          assert_raise Twitter::Unauthorized do
            client = Twitter::Unauthenticated.new
            client.timeline('protected')
          end
        end

        should "raise Forbidden when update limited" do
          stub_post("statuses/update.#{format}", "forbidden.#{format}", "application/#{format}; charset=utf-8", 403)
          assert_raise Twitter::Forbidden do
            client = Twitter::Authenticated.new
            client.update('@noradio working on implementing #NewTwitter API methods in the twitter gem. Twurl is making it easy. Thank you!')
          end
        end

        should "raise NotFound for a request to a deleted or nonexistent status" do
          stub_get("statuses/show/404.#{format}", "not_found.#{format}", "application/#{format}; charset=utf-8", 404)
          assert_raise Twitter::NotFound do
            client = Twitter::Unauthenticated.new
            client.status(404)
          end
        end
      end
    end
  end

  should "raise NotAcceptable when an invalid format is specified" do
    stub_get("search.json?q=from%3Asferik", "not_acceptable.json", "application/json; charset=utf-8", 406)
    assert_raise Twitter::NotAcceptable do
      search = Twitter::Search.new
      search.from('sferik')
      search.fetch
    end
  end

  should "raise EnhanceYourCalm when search is rate limited" do
    stub_get("search.json?q=from%3Asferik", "enhance_your_calm.text", "text/plain; charset=utf-8", 420, nil, true)
    begin
      search = Twitter::Search.new
      search.from('sferik')
      search.fetch
      flunk 'Should have exception at this point'
    rescue => err
      assert_instance_of Twitter::EnhanceYourCalm, err
      assert_operator err.retry_after, :> , 0
    end
  end

end
