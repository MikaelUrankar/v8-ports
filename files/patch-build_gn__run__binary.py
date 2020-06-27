--- build/gn_run_binary.py.orig	2020-06-26 18:07:59 UTC
+++ build/gn_run_binary.py
@@ -19,7 +19,7 @@ path = './' + sys.argv[1]
 # The rest of the arguments are passed directly to the executable.
 args = [path] + sys.argv[2:]
 
-ret = subprocess.call(args)
+ret = subprocess.call(args, env={"CHROME_EXE_PATH":"${WRKSRC}/out/Release/chrome"})
 if ret != 0:
   if ret <= -100:
     # Windows error codes such as 0xC0000005 and 0xC0000409 are much easier to
