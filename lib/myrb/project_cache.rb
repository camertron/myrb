# frozen_string_literal: true

require "digest"

module Myrb
  class ProjectCache
    attr_reader :cache_file

    def initialize(cache_file)
      @cache_file = cache_file

      if File.exist?(cache_file)
        @entries = YAML.load_file(cache_file)
      else
        @entries = {}
        update_cache_file
      end
    end

    def store(file)
      @entries[file] = digest(file)
      update_cache_file
    end

    def contains?(file)
      @entries[file] == digest(file)
    end

    private

    def digest(file)
      Digest::SHA256.hexdigest(File.read(file))
    end

    def update_cache_file
      File.write(cache_file, YAML.dump(@entries))
    end
  end
end
