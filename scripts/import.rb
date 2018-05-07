# vim: set expandtab ts=2 sw=2:
require 'simp/metadata'
require 'yaml'
$UPSTREAMREPO="https://github.com/simp/simp-core.git"
$DATAREPO="git@github.com:simp/simp-metadata.git"

begin
  Dir.mkdir("scratch")
  Dir.mkdir("scratch/data")
rescue
end

Dir.chdir("scratch") do
  unless Dir.exists?("upstream")
    `git clone #{$UPSTREAMREPO} upstream`
  else
    Dir.chdir("upstream") do
      `git fetch origin`
    end
  end
  Dir.chdir("data") do
    unless Dir.exists?("simp-metadata/")
      `git clone #{$DATAREPO} simp-metadata`
    else
      Dir.chdir("simp-metadata") do
        `git pull origin`
      end
    end
    begin
      Dir.mkdir("data/releases")
    rescue
    end
  end
end

repo = ENV.fetch('EXTRAREPO', nil)
if (repo == nil)
  repos = [ $DATAREPO ]
else
  repos = [ $DATAREPO, repo ]
end

metadata = Simp::Metadata::Engine.new("scratch", repos)
#binding.pry

data = {}
data['components'] = {}
data['releases'] = {}
components = data['components']
component_by_url = {}

class Puppetfile
  def initialize()
    @repos = {}
    @moduledir = "/"
  end
  def repos()
    @repos
  end
  def mod(name, params = {})
    @repos[name] = params.merge({"destination" => @moduledir})
  end
  def forge(url)
    puts url
  end
  def moduledir(name)
    @moduledir = "/#{name}"
  end
end

def parse_git(url)
  case url
  when /^https:/
    https_url = url.split("/")
    host = https_url[2]
    path = https_url.drop(3).join("/").gsub(".git","")
    type = "https"
  when /^git@/
    git_url = url.split(":")
    host = git_url[0].gsub("git@","")
    path = git_url[1].gsub(".git", "")
    type = "ssh"
  when /^git:/
    git_url = url.split("/")
    host = git_url[2]
    path = git_url.drop(3).join("/").gsub(".git","")
    type = "ssh"
  end
  return { "host" => host, "path" => path, "type" => type }
end

repo_url = {}
Dir.chdir("scratch/upstream") do
  branches = "master\n6.0.0-Alpha-Release\n" + `git tag -l`
  branches.split("\n").each do |branch|
    begin
      pfile = Puppetfile.new
      `git checkout #{branch}`
      if File.exists?("Puppetfile.stable")
        release = {}
        pfile.instance_eval(File.read("Puppetfile.stable").gsub("}",""))
        pfile.repos.each do |key, value|
          ret = {}
          ret["type"] = "git"
          ret["authoritative"] = true
          gitinfo = parse_git(value[:git])
          ret["primary_source"] = gitinfo.dup.delete_if { |key, value| key == "type" }
          object = {
            "ref" => value[:ref],
            "type" => gitinfo["type"],
            "path" => value["destination"]
          }
          if (component_by_url.key?(ret["primary_source"]))
            release[component_by_url[ret["primary_source"]]] = object
          else
            [ "", "-1", "-2", "-3", "-4", "-5", "-6" ].each do |opt|
              nkey = key + opt
              ret["mirrors"] = { "gitlab" => { "host" => "gitlab.com", "path" => "simp/" + nkey}}
              if (components.key?(nkey))
                if components[nkey]["type"] != ret["type"] && components[nkey]["primary_source"] != ret["primary_source"] 
                  next
                else
                  release[nkey] = object
                  break
                end
              else
                components[nkey] = ret
                component_by_url[ret["primary_source"]] = nkey
                release[nkey] = object
                break
              end
            end
          end
        end
      end
      data['releases'][branch] = release
      #    rescue
    end
  end
end
comp = { "components" => components }
File.open("scratch/data/simp-metadata/v1/components.yaml", 'w') {|f| f.write comp.to_yaml }

data['releases'].each do |key, value|
  release = { "releases" => { key => value } }
  File.open("scratch/data/simp-metadata/v1/releases/#{key}.yaml", 'w') {|f| f.write release.to_yaml }
end
Dir.chdir("scratch/data") do
  `git add -A`
  `git commit -m "Auto Update by rubygem-simp-metadata"`
  #  `git push origin`
end
