require 'formula'

class CppEthereum < Formula
  # official_version-protocol_version-database_version
  version '0.9.29-61'

  homepage 'https://github.com/ethereum/cpp-ethereum'
  head 'https://github.com/ethereum/cpp-ethereum.git', :branch => 'poc-8'
  url 'https://github.com/ethereum/cpp-ethereum.git', :branch => 'master'

  bottle do
    revision 162
    root_url 'https://build.ethdev.com/builds/OSX%20C%2B%2B%20master%20brew/162/bottle'
    sha1 '87a3369cfbf10031054ef06347dd0678d0a40d4e' => :yosemite
  end

  devel do
    bottle do
      revision 1000
      root_url 'https://build.ethdev.com/builds/OSX%20C%2B%2B%20develop%20brew/1000/bottle'
      sha1 'ad1e38522ed25d2a4a17e0cc8786fca274736fb8' => :yosemite
    end

    if build.include? "successful"
      version '0.9.29-61'
      url 'https://github.com/ethereum/cpp-ethereum.git', :revision => 'b1b8a9b46e0e177a9a570caadc318326e8ce45d4'
    else
    version '0.9.29-61'
    url 'https://github.com/ethereum/cpp-ethereum.git', :branch => 'develop'
    end
  end

  depends_on 'cmake' => :build
  depends_on 'boost' => "c++11"
  depends_on 'boost-python' => "c++11"
  depends_on 'llvm' => ["without-shared", "with-clang"] if build.with? "evmjit"
  depends_on 'qt5' if build.with? 'gui'
  depends_on 'readline'
  depends_on 'cryptopp'
  depends_on 'miniupnpc'
  depends_on 'leveldb'
  depends_on 'gmp'
  depends_on 'curl'
  depends_on 'libjson-rpc-cpp'
  depends_on 'v8-315' if build.with? 'v8-console'

  option "with-gui", "Build with GUI (AlethZero)"
  option "with-gpu-mining", "Build with OpenCL GPU mining (experimental)"
  option "with-evmjit", "Build with LLVM and enable EVMJIT"
  option "with-v8-console", "Build with V8 JavaScript console"
  option "with-paranoia", "Build with -DPARANOID=1"
  option "with-debug", "Build with debug"
  option "with-vmtrace", "Build with VMTRACE"
  option "successful", "Last successful build with --devel only"

  def install
    args = *std_cmake_args

    if build.with? "evmjit"
      args << "-DLLVM_DIR=/usr/local/opt/llvm/share/llvm/cmake"
      args << "-DEVMJIT=1"
      ENV["CXX"] = "/usr/local/opt/llvm/bin/clang++ -stdlib=libc++"
      ENV["CXXFLAGS"] = "#{ENV.cxxflags} -nostdinc++ -I/usr/local/opt/llvm/include/llvm"
      ENV["LDFLAGS"] = "#{ENV.ldflags} -L/usr/local/opt/llvm/lib"
    end

    if build.with? "debug"
      args << "-DCMAKE_BUILD_TYPE=Debug"
    else
      args << "-DCMAKE_BUILD_TYPE=Release"
    end

    args << "-DFATDB=1" # https://github.com/ethereum/cpp-ethereum/issues/1403
    args << "-DBUNDLE=default"
    args << "-DGUI=0" if build.without? "gui"
    args << "-DETHASHCL=1" if build.with? "gpu-mining"
    args << "-DJSCONSOLE=1" if build.with? "v8-console"
    args << "-DVMTRACE=1" if build.with? "vmtrace"
    args << "-DPARANOID=1" if build.with? "paranoia"

    system "cmake", *args
    system "make"
    system "make", "install"

    bin.install 'test/testeth'
    (prefix/"test").install Dir['test/*.json']

    if build.with? "gui"
      prefix.install 'alethzero/AlethZero.app'
      prefix.install 'mix/Mix.app' if build.devel?
      # prefix.install 'third/Third.app' if build.devel?
    end
  end

  test do
    system "testeth"
  end

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>ThrottleInterval</key>
        <integer>300</integer>
        <key>ProgramArguments</key>
        <array>
            <string>#{opt_bin}/eth</string>
            <string>-d</string>
            <string>#{prefix}/.ethereum</string>
            <string>-b</string>
        </array>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
      </dict>
    </plist>
    EOS
  end
end
