Gem::Specification.new do |s|
  s.name         = "xkeys"
  s.version      = "0.0.1"
  s.authors      = ["Brian Katzung"]
  s.email        = ["briank@kappacs.com"]
  s.homepage     = "http://www.kappacs.com"
  s.summary      = "Extended keys to facilitate fetching and storing in nested hash and array structures with Perl-ish auto-vivification."
  s.description  = "Extended keys to facilitate fetching and storing in nested hash and array structures with Perl-ish auto-vivification."
  s.license      = "MIT"
 
  s.files        = Dir.glob("lib/**/*") + %w{xkeys.gemspec}
  s.test_files   = Dir.glob("test/**/*")
  s.require_path = 'lib'
end
