# frozen_string_literal: true

module Myrb
  module SteepServerMasterPatch
    def process_message_from_client(message)
      case message[:method]
      when "$/typecheck"
        @myrb_project ||= Myrb::Project.new(project.base_dir.to_s)
        @myrb_project.transpile_all
      end

      super
    end
  end
end

Steep::Server::Master.prepend(Myrb::SteepServerMasterPatch)
