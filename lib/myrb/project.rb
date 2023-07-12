# frozen_string_literal: true

module Myrb
  class Project
    attr_reader :root_path

    def initialize(root_path)
      @root_path = root_path
    end

    def find(relative_path)
      absolute_path = File.join(root_path, relative_path)

      unless File.exist?(absolute_path)
        raise Errno::ENOENT.new(absolute_path)
      end

      AnnotatedFile.new(absolute_path, self)
    end

    def each_file(&block)
      each_file_in(paths, &block)
    end

    def paths
      Dir.glob(File.join(root_path, "**", "*.trb"))
    end

    def transpile_all(&block)
      file_list = paths

      each_file_in(file_list).with_index do |file, idx|
        unless cache.contains?(file.path)
          file.write_rbs
          file.write_rewritten_source
          cache.store(file.path)
        end

        yield(idx) if block
      end
    end

    def sig_path
      @sig_path ||= File.join(root_path, 'sig')
    end

    private

    def each_file_in(file_list)
      return to_enum(__method__, file_list) unless block_given?

      file_list.each do |path|
        yield AnnotatedFile.new(path, self)
      end
    end

    def cache
      @cache ||= ProjectCache.new(File.join(sig_path, ".cache.yml"))
    end
  end
end
