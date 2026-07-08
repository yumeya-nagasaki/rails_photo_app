module HttpStubHelper
  def stub_http_response(body:, status: "200", success: true)
    response = Object.new
    response.define_singleton_method(:body) { body }
    response.define_singleton_method(:code) { status }
    response.define_singleton_method(:is_a?) { |klass| success && klass == Net::HTTPSuccess }

    http = Object.new
    http.define_singleton_method(:request) { |_request| response }

    original_start = Net::HTTP.method(:start)
    Net::HTTP.singleton_class.define_method(:start) do |*_args, **_kwargs, &block|
      block.call(http)
    end

    yield
  ensure
    Net::HTTP.singleton_class.define_method(:start, original_start) if original_start
  end

  def with_env(key, value)
    original = ENV[key]
    ENV[key] = value
    yield
  ensure
    if original.nil?
      ENV.delete(key)
    else
      ENV[key] = original
    end
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include HttpStubHelper
end

ActiveSupport.on_load(:active_support_test_case) do
  include HttpStubHelper
end
