# vim: set expandtab ts=2 sw=2:
require 'simp/metadata'
require 'optparse'
require 'ostruct'
require 'pp'
require 'json'

command, *args = ARGV

engine = Simp::Metadata::Engine.new

def rest_request(request, method = 'GET', _body = nil)
  require 'net/http'
  require 'uri'

  uri = URI.parse(request)
  case method
  when 'POST'
    request = Net::HTTP::Post.new(uri)
  when 'GET'
    request = Net::HTTP::Get.new(uri)
  when 'PUT'
    request = Net::HTTP::Put.new(uri)
  when 'DELETE'
    request = Net::HTTP::Delete.new(uri)
  else
    exit(Simp::Metadata.error("Unrecognized URI request #{method}")[0])
  end
  req_options = { use_ssl: uri.scheme == 'https' }
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }

  # response.code
  JSON.parse(response.body)
end

case command
when 'generate'
  options = OpenStruct.new
  options.puppetfile = false
  options.release = nil
  option_parser = OptionParser.new do |parser|
    parser.banner = 'Usage: main.rb generate [options]'
    parser.separator ''
    parser.separator 'Specific options:'
    parser.on('-p', '--puppetfile', 'Generate puppetfile') { |puppetfile| options.puppetfile = puppetfile }
    parser.on('-r', '--release=MANDATORY', 'Release to generate') { |release| options.release = release }
  end
  parser.parse!(args)
  exit(Simp::Metadata.critical('must specify -r or --release')[0]) if options.release.nil?

  if options.puppetfile
    paths = engine.list_components_with_data(options.release)
    file = []
    paths.each do |key, value|
      path = key.slice(1, key.length)
      file << "moduledir #{path}"
      file << ''
      value.each do |module_name, module_info|
        file << "mod '#{module_name}',"
        url = engine.url(module_name)
        file << "    git: '#{url}'"
        file << "    ref: '#{module_info[:ref]}'"
        file << ''
      end
    end
    puts file.join("\n")
  end
when 'mirror'
  options = OpenStruct.new
  options.puppetfile = false
  options.destination = 'scratch/mirror'
  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: main.rb mirror [options]'
    opts.separator ''
    opts.separator 'Specific options:'
    opts.on('-d', '--destination', 'Specify destination') do |p|
      options.destination = p
    end
    opts.on('-u', '--url', 'Specify destination url') do |p|
      options.destination = p
    end
  end
  parser.parse!(args)
  begin
    Dir.mkdir(options.destination)
  rescue StandardError => e
    Simp::Metadata.critical(e.message)
    Simp::Metadata.backtrace(e.backtrace)
  end

  Dir.chdir(options.destination) do
    components = engine.component_list
    components.each do |component|
      url = engine.url(component)
      puts url
      `git clone #{url} #{component}`
    end
  end
end
