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

    def each_file
      return to_enum(__method__) unless block_given?

      Dir.glob(File.join(root_path, "**", "*.trb")).each do |path|
        yield AnnotatedFile.new(path, self)
      end
    end

    def sig_path
      @sig_path ||= File.join(root_path, 'sig')
    end
  end
end
