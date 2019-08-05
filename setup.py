from distutils.core import setup
from Cython.Build import cythonize

setup(ext_modules=cythonize("main.pyx", language="c++"))

#import main
#main.main()
