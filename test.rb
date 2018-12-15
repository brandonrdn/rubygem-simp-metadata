data = {}

data['releases'] = {"test-stub"=>{"pupmod-simp-activemq"=>{"ref"=>"488f5a0d5b53063c125b93a596626193b71aaa08", "branch"=>"master", "version"=>"1.1.1", "tag"=>"1.1.1"}},
                    "test-diff"=>
{"pupmod-simp-activemq"=>
 {"buildinfo"=>{"rpm"=>{"build_method"=>"metadata-build"}}, "ref"=>"3987ra0d5b53063f493b93a596626193b71dddd4", "branch"=>"develop", "version"=>"1.1.2", "tag"=>"1.1.2"}},
"unstable"=>
 {"simp-core"=>{"ref"=>"1ca5327c1d8da5256d1065478ed1520e2a01bf7a", "branch"=>"master", "tag"=>"6.2.0-0"},
  "simp-doc"=>{"ref"=>"e6f8d7f763177b163ed14ffcb6e76cdf7561d04a", "branch"=>"master", "tag"=>"6.2.0-0"},
  "pkg-r10k"=>{"tag"=>"2.6.2-1", "ref"=>"7c699efd368aa0c6d5e6002749dadc5696002235"}},
 "6.2.0-0"=>
 {"simp-core"=>{"ref"=>"7c0e2812dfe955de339c48aeed70b8c333dbf215", "branch"=>"master", "tag"=>"6.2.0-0"},
  "simp-doc"=>{"ref"=>"28e879d425ec54035fe1a74b3c4eadfbc7ee7615", "branch"=>"master", "tag"=>"6.2.0-0"},
  "pupmod-simp-rsync"=>{"ref"=>"b3534c8eb35d9dd527e6459a54277feb8d614f80", "branch"=>"master", "tag"=>"6.0.6"}}}

var = true
test = if var == true
         output = {}
         data['releases'].each do |release,data|
           hash = {'components' => data}
           output[release] = hash
         end
         output
       end

puts test

