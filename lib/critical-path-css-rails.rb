require 'critical_path_css/configuration'
require 'critical_path_css/css_fetcher'
require 'critical_path_css/rails/config_loader'

module CriticalPathCss
  CACHE_NAMESPACE = 'critical-path-css'.freeze

  def self.generate(route)
    ::Rails.cache.write(route, fetcher.css_for_route_retry(route), namespace: CACHE_NAMESPACE, expires_in: nil)
  end

  def self.generate_all
    fetcher.fetch_mobile.each do |route, css|
      puts "critical mobile #{route}"
      ::Rails.cache.write(['mobile', route], css, namespace: CACHE_NAMESPACE, expires_in: nil)
    end
    fetcher.fetch_desktop.each do |route, css|
      puts "critical desktop #{route}"
      ::Rails.cache.write(['desktop', route], css, namespace: CACHE_NAMESPACE, expires_in: nil)
    end
  end

  def self.clear(route)
    ::Rails.cache.delete(route, namespace: CACHE_NAMESPACE)
  end

  def self.clear_matched(routes)
    ::Rails.cache.delete_matched(routes, namespace: CACHE_NAMESPACE)
  end

  def self.fetch(route)
    ::Rails.cache.read(route, namespace: CACHE_NAMESPACE) || ''
  end

  def self.fetcher
    @fetcher ||= CssFetcher.new(Configuration.new(config_loader.config))
  end

  def self.config_loader
    @config_loader ||= CriticalPathCss::Rails::ConfigLoader.new
  end
end
