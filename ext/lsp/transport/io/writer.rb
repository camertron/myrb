# frozen_string_literal: true

require "language_server-protocol"

module Myrb
  module LSPTransportWriterPatch
    def write(response)
      case response[:method]
        when :"textDocument/publishDiagnostics"
          params = response[:params]
          uri = params.uri.to_s

          if File.extname(uri) == ".rb"
            trb_uri = Pathname(uri.delete_prefix("file://")).sub_ext(".trb")

            if trb_uri.exist?
              response[:params] = LanguageServer::Protocol::Interface::PublishDiagnosticsParams.new(
                uri: "file://#{trb_uri}",
                diagnostics: params.diagnostics
              )
            end
          end
      end

      super
    end
  end
end

LanguageServer::Protocol::Transport::Io::Writer.prepend(
  Myrb::LSPTransportWriterPatch
)
