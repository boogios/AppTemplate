#!/usr/bin/env python3
"""iOS entrypoint; accepts the shared validator's --root/--locales/--devices flags."""
import sys
from store_screenshots import main
if __name__ == '__main__':
    sys.argv[1:1] = ['--platform', 'ios']
    sys.exit(main())
