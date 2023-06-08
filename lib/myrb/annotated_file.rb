# frozen_string_literal: true

require 'parser/current'
require 'fileutils'

module Myrb
  class AnnotatedFile < AnnotatedSource
    attr_reader :path, :project

    def initialize(path, project = nil)
      @path = path
      @project = project
    end

    def source
      @source ||= ::File.read(path)
    end

    def write_rbs(path_to_use = rbs_path)
      raise Errno::ENOENT.new(path_to_use) unless path_to_use

      FileUtils.mkdir_p(File.dirname(path_to_use))
      File.write(path_to_use, rbs_source)
    end

    private

    def rbs_path
      return nil unless project

      relative_path = Pathname(path)
        .relative_path_from(project.root_path)
        .sub_ext('.rbs')
        .to_s

      File.join(project.sig_path, relative_path)
    end

    def make_source_buffer
      ::Parser::Source::Buffer.new(path, source: source)
    end
  end
end
