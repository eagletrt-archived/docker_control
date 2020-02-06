# Cross-compiling setup 

if __FILE__ == $PROGRAM_NAME then
  require 'fileutils'
  
  unless File.exists?('mruby')
    system "git clone -b #{ENV["MRUBY_VERSION"]} --depth 1 https://github.com/mruby/mruby.git"
  end
  
  unless system(%Q[cd mruby; MRUBY_CONFIG=#{File.expand_path __FILE__} ./minirake #{ARGV.join(' ')}])
    warn "Build error"
    exit -1
  end
    
  exit 0
end

MRuby::Build.new do |conf|
  toolchain :gcc
 # C compiler settings
  conf.cc do |cc|
    cc.command = 'gcc'
    cc.flags = [ENV['CFLAGS'] || %w()]
    cc.include_paths = ["#{root}/include"]
    cc.defines = %w()
    cc.option_include_path = '-I%s'
    cc.option_define = '-D%s'
    cc.compile_options = "%{flags} -MMD -o %{outfile} -c %{infile}"
  end

  # mrbc settings
  conf.mrbc do |mrbc|
    mrbc.compile_options = "-g -B%{funcname} -o-" # The -g option is required for line numbers
  end

  # Linker settings
  conf.linker do |linker|
    linker.command = 'gcc'
    linker.flags = [ENV['LDFLAGS'] || []]
    linker.flags_before_libraries = []
    linker.libraries = %w(m)
    linker.flags_after_libraries = []
    linker.library_paths = []
    linker.option_library = '-l%s'
    linker.option_library_path = '-L%s'
    linker.link_options = "%{flags} -o %{outfile} %{objs} %{libs}"
  end

  # Archiver settings
  conf.archiver do |archiver|
    archiver.command = 'ar'
    archiver.archive_options = 'rs %{outfile} %{objs}'
  end

  #lightweight regular expression
  conf.gem :github => "pbosetti/mruby-hs-regexp", :branch => "master"
  
end

# Define cross build settings
MRuby::CrossBuild.new(ENV["DEFAULT_DOCKCROSS_IMAGE"]) do |conf|
  toolchain :gcc

  # Mac OS X
  # 
  CROSS_ROOT = ENV["CROSS_ROOT"]
  CROSS_TRIPLE = ENV["CROSS_TRIPLE"]
  SYSROOT = "#{CROSS_ROOT}/#{CROSS_TRIPLE}/sysroot"

  conf.cc do |cc|
    cc.command = "#{CROSS_ROOT}/bin/#{CROSS_TRIPLE}-gcc"
    cc.include_paths << ["#{CROSS_ROOT}/include", "#{SYSROOT}/usr/include/"]
    cc.flags << %w(-std=gnu11)
    cc.flags << %w(-O2 -pipe -g -feliminate-unused-debug-types)
    cc.flags << "--sysroot=#{SYSROOT}"
    cc.defines = %w(ENABLE_READLINE)
  end

  conf.cxx do |cxx|
    cxx.command = "#{CROSS_ROOT}/bin/#{CROSS_TRIPLE}-g++"
    cxx.include_paths = conf.cc.include_paths.dup
    # cxx.include_paths << "#{CROSS_ROOT}/#{CROSS_TRIPLE}/include/c++/4.9.4"
    cxx.flags = conf.cc.flags.dup
    cxx.defines = conf.cc.defines.dup
    cxx.compile_options = conf.cc.compile_options.dup    
  end

  conf.archiver do |archiver|
    archiver.command = "#{CROSS_ROOT}/bin/#{CROSS_TRIPLE}-ar"
    archiver.archive_options = 'rcs %{outfile} %{objs}'
  end

  conf.linker do |linker|
    linker.command = "#{CROSS_ROOT}/bin/#{CROSS_TRIPLE}-gcc"
    linker.flags << "--sysroot=#{SYSROOT}"
    linker.library_paths << ["#{CROSS_ROOT}/lib", "#{SYSROOT}/lib", "#{SYSROOT}/lib64"]
    linker.libraries = %w(m readline ncurses)
  end

  #do not build executable test
  conf.build_mrbtest_lib_only

  conf.gembox 'default'

  #lightweight regular expression
  conf.gem :github => "pbosetti/mruby-hs-regexp", :branch => "master"

end
