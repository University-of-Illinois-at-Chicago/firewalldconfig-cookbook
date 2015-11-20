class Firewalldconfig
  @etc_dir = '/etc/firewalld'
  @lib_dir = '/usr/lib/firewalld'
  class << self
    attr_accessor :etc_dir
    attr_accessor :lib_dir
  end 
end
