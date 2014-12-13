require "capistrano/ubuntu/version"

module Capistrano
  module Ubuntu

  end
end

import File.expand_path("../tasks/ubuntu.rake", __FILE__)
