# vim: set expandtab ts=2 sw=2:
require 'simp/metadata'
require 'optparse'
require 'ostruct'
require 'pp'
require 'json'

command, *args = ARGV;
metadata = Simp::Metadata::Engine.new("scratch/data")

def rest_request(request, method = "GET", body = nil)
  require 'net/http'
  require 'uri'

  uri = URI.parse(request)
  case method
  when "POST"
    request = Net::HTTP::Post.new(uri)
  when "GET"
    request = Net::HTTP::Get.new(uri)
  when "PUT"
    request = Net::HTTP::Put.new(uri)
  when "DELETE"
    request = Net::HTTP::Delete.new(uri)
  end
  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  # response.code
  JSON.parse(response.body)
end


case command
when "generate"
  options = OpenStruct.new
  options.puppetfile = false
  options.release = nil
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: main.rb generate [options]"
    opts.separator ""
    opts.separator "Specific options:"
    opts.on("-p", "--puppetfile", "Generate puppetfile") do |p|
      options.puppetfile = p
    end
    opts.on("-r", "--release=MANDATORY", "Release to generate") do |r|
      options.release = r
    end
  end
  opt_parser.parse!(args)
  if options.release == nil
    puts "must specify -r or --release"
    exit 1
  end
  if options.puppetfile == true
    paths = metadata.list_components_with_data(options.release)
    file = []
    paths.each do | key, value|
      path = key.slice(1, key.length)
      file << "moduledir #{path}"
      file << ""
      value.each do |modulename, modinfo|
         file << "mod '#{modulename}',"
         url = metadata.url(modulename)
         file << "    :git => '#{url}'"
         file << "    :ref => '#{modinfo["ref"]}'"
         file << ""
      end
    end
    puts file.join("\n")
  end
when "mirror"
  options = OpenStruct.new
  options.puppetfile = false
  options.destination = "scratch/mirror"
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: main.rb mirror [options]"
    opts.separator ""
    opts.separator "Specific options:"
    opts.on("-d", "--destination", "Specify destination") do |p|
      options.destination = p
    end
    opts.on("-u", "--url", "Specify destination url") do |p|
      options.destination = p
    end
  end
  opt_parser.parse!(args)
  begin
    Dir.mkdir(options.destination)
  rescue
  end
  Dir.chdir(options.destination) do 
    components = metadata.component_list()
    components.each do |component|
      url = metadata.url(component)
      puts url
      `git clone #{url} #{component}`
    end
  end
end
