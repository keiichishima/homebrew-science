class Libeemd < Formula
  desc "Library for performing the ensemble empirical mode decomposition"
  homepage "https://bitbucket.org/luukko/libeemd"
  url "https://bitbucket.org/luukko/libeemd/get/v1.4.tar.gz"
  sha256 "c484f4287f4469f3ac100cf4ecead8fd24bf43854efa63650934dd698d6b298b"

  depends_on "gsl"
  depends_on "pkg-config" => :build

  needs :openmp

  patch :DATA

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <math.h>
      #include <stdio.h>
      #include <stdlib.h>

      #include <gsl/gsl_math.h>
      #include <eemd.h>

      const size_t ensemble_size = 250;
      const unsigned int S_number = 4;
      const unsigned int num_siftings = 50;
      const double noise_strength = 0.2;
      const unsigned long int rng_seed = 0;

      const size_t N = 1024;
      static inline double input_signal(double x) {
        const double omega = 2*M_PI/(N-1);
        return sin(17*omega*x)+0.5*(1.0-exp(-0.002*x))*sin(51*omega*x+1);
      }

      int main(void) {
        libeemd_error_code err;
        double* inp = malloc(N*sizeof(double));
        for (size_t i=0; i<N; i++) {
          inp[i] = input_signal((double)i);
        }
        size_t M = emd_num_imfs(N);
        double* outp = malloc(M*N*sizeof(double));
        err = eemd(inp, N, outp, M, ensemble_size, noise_strength,
                   S_number, num_siftings, rng_seed);
        if (err != EMD_SUCCESS) {
          return -1;
        }
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-leemd", "-o", "test"
    system "./test"
  end
end

__END__
--- a/Makefile	2016-09-19 16:58:13.000000000 +0900
+++ b/Makefile	2016-12-08 11:50:50.000000000 +0900
@@ -23,7 +23,7 @@
 endef
 export uninstall_msg
 
-all: libeemd.so.$(version) libeemd.a eemd.h
+all: libeemd.$(version).dylib libeemd.a eemd.h
 
 clean:
 	rm -f libeemd.so libeemd.so.$(version) libeemd.a eemd.h obj/eemd.o
@@ -34,8 +34,8 @@
 	install -d $(PREFIX)/lib
 	install -m644 eemd.h $(PREFIX)/include
 	install -m644 libeemd.a $(PREFIX)/lib
-	install libeemd.so.$(version) $(PREFIX)/lib
-	cp -Pf libeemd.so $(PREFIX)/lib
+	install libeemd.$(version).dylib $(PREFIX)/lib
+	cp -Pf libeemd.dylib $(PREFIX)/lib
 
 uninstall:
 	@echo "$$uninstall_msg"
@@ -44,14 +44,14 @@
 	mkdir -p obj
 
 obj/eemd.o: src/eemd.c src/eemd.h | obj
-	gcc $(commonflags) -c $< $(gsl_flags) -o $@
+	$(CC) $(commonflags) -c $< $(gsl_flags) -o $@
 
 libeemd.a: obj/eemd.o
 	$(AR) rcs $@ $^
 
-libeemd.so.$(version): src/eemd.c src/eemd.h
-	gcc $(commonflags) $< -fPIC -shared -Wl,$(SONAME),$@ $(gsl_flags) -o $@
-	ln -sf $@ libeemd.so
+libeemd.$(version).dylib: src/eemd.c src/eemd.h
+	$(CC) $(commonflags) $< -fPIC -shared -Wl,$(SONAME),$@ $(gsl_flags) -o $@
+	ln -sf $@ libeemd.dylib
 
 eemd.h: src/eemd.h
 	cp $< $@
