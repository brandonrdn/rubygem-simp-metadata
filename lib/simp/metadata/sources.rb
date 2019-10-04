require 'yaml'
require 'uri'
require 'fileutils'

module Simp
  module Metadata
    # Set sources based on defaults and input
    class Sources
      attr_accessor :sources
      def initialize(edition = 'community', metadata_repos = {})
        @edition = edition
        @metadata_repos = metadata_repos
        @default_source_data = {}
        @sources = {}

        # Set default source data
        default_source_data
        # Set sources based on defaults and input
        update_sources
      end

      def enterprise_metadata_hash
        { source_type: 'simp-metadata', authoritative: true, version: 'master',
          locations: [{ url: 'simp-enterprise:///enterprise-metadata?version=master&filetype=tgz',
                        method: 'file', extract: true, primary: true }] }
      end

      def simp_metadata_hash
        { source_type: 'simp-metadata', authoritative: true, branch: 'master',
          locations: [{ url: 'https://github.com/simp/simp-metadata',
                        method: 'git', primary: true }] }
      end

      def default_source_data
        data = case @edition
               when 'enterprise'
                 { sources: { enterprise_metadata: enterprise_metadata_hash,
                              simp_metadata: simp_metadata_hash } }
               when 'enterprise-only'
                 { sources: { enterprise_metadata: enterprise_metadata_hash } }
               else
                 { sources: { simp_metadata: simp_metadata_hash } }
               end
        @default_source_data = data[:sources]
      end

      def update_sources
        unless @metadata_repos.empty?
          @metadata_repos.each do |repo_name, url|
            url_matches = [/https?:/, /git@/]
            if url.match?(Regexp.union(url_matches))
              method = 'git'
              extract = false
            else
              method = 'file'
              extract = true
            end
            repo_symbol = repo_name.sub('-', '_').to_sym
            next unless @default_source_data.key?(repo_symbol)

            @default_source_data[repo_symbol][:locations][0][:url] = url
            @default_source_data[repo_symbol][:locations][0][:method] = method
            @default_source_data[repo_symbol][:locations][0][:extract] = extract
          end
        end
        @default_source_data.each { |name, data| @sources[name] = data }
      end
    end
  end
end
