# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bulk_record/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Shunsuke Mikami"]
  gem.email         = ["shun0102@gmail.com"]
  gem.description   = "library for mysql bulk insert"
  gem.summary       = "library for mysql bulk insert"
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "bulk_record"
  gem.require_paths = ["lib"]
  gem.version       = BulkRecord::VERSION

  gem.add_runtime_dependency "mysql2"
  gem.add_runtime_dependency "activesupport"
  gem.add_development_dependency "mysql2"
  gem.add_development_dependency "activesupport"
end
