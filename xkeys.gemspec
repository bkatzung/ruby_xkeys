Gem::Specification.new do |s|
  s.name         = "xkeys"
  s.version      = "2.2.0"
  s.date         = "2014-05-07"
  s.authors      = ["Brian Katzung"]
  s.email        = ["briank@kappacs.com"]
  s.homepage     = "http://rubygems.org/gems/xkeys"
  s.summary      = "Extended keys to facilitate fetching and storing in nested hash and array structures with Perl-ish auto-vivification."
  s.description  = "Extended keys to facilitate fetching and storing in nested hash and array structures with Perl-ish auto-vivification."
  s.license      = "MIT"
 
  s.files        = Dir.glob("lib/**/*") +
  		   %w{xkeys.gemspec .yardopts HISTORY.txt}
  s.test_files   = Dir.glob("test/**/*.rb")
  s.require_path = 'lib'
end
