require 'json'
require 'open3'
require 'npm_commands'

module CriticalPathCss
  class CssFetcher
    GEM_ROOT = File.expand_path(File.join('..', '..'), File.dirname(__FILE__))
    MOBILE_OPTION = { screen_width: 375, user_agent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1' }.to_h
    DESKTOP_OPTION = { screen_width: 2000, user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9' }.to_h

    def initialize(config)
      @config = config
    end

    def fetch
      @config.routes.map { |route| [route, css_for_route_retry(route, MOBILE_OPTION)] }.to_h
    end

    def fetch_route(route, critical_option)
      options = {
        'url' => @config.base_url + route,
        'css' => @config.path_for_route(route),
        'width' => critical_option[:screen_width],
        'height' => 900,
        'timeout' => 30_000,
        # CSS selectors to always include, e.g.:
        'forceInclude' => [
          #  '.keepMeEvenIfNotSeenInDom',
          #  '^\.regexWorksToo'
        ],
        # set to true to throw on CSS errors (will run faster if no errors)
        'strict' => false,
        # characters; strip out inline base64 encoded resources larger than this
        'maxEmbeddedBase64Length' => 1000,
        # specify which user agent string when loading the page
        'userAgent' => critical_option[:user_agent],
        # ms; render wait timeout before CSS processing starts (default: 100)
        'renderWaitTime' => 100,
        # set to false to load (external) JS (default: true)
        'blockJSRequests' => true,
        'customPageHeaders' => {
          # use if getting compression errors like 'Data corrupted':
          'Accept-Encoding' => 'identity'
        }
      }.merge(@config.penthouse_options)
      out, err, st = Dir.chdir(GEM_ROOT) do
        Open3.capture3(NpmCommands.node, 'lib/fetch-css.js', JSON.dump(options))
      end
      if !st.exitstatus.zero? || out.empty? && !err.empty?
        STDOUT.puts out
        STDERR.puts err
        STDERR.puts "Failed to get CSS for route #{route}\n" \
              "  with options=#{options.inspect}"
      end
      out
    end

    def fetch_mobile
      @config.routes.map { |route| [route, css_for_route_retry(route, MOBILE_OPTION)] }.to_h
    end

    def fetch_desktop
      @config.routes.map { |route| [route, css_for_route_retry(route, DESKTOP_OPTION)] }.to_h
    end

    protected

    def css_for_route_retry(route, critical_option)
      retry_times = 0
      begin
        fetch_route(route, critical_option)
      rescue StandardError => e
        if retry_times < @config.retry_times
          retry_times += 1
          STDOUT.puts "#{e.message} retry #{retry_times}/#{@config.retry_times}"
          retry
        end
        raise
      end
    end
  end
end
