TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
FINALPACKAGE = 1
THEOS_PACKAGE_SCHEME = roothide

# WSL builds from /mnt/c use drvfs permissions (777), which dpkg-deb rejects
# for the control directory. Keep Theos' staging tree on the Linux filesystem.
ifeq ($(shell uname -s),Linux)
THEOS_STAGING_DIR ?= /tmp/touchpoint-theos-staging
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TouchPoint
TouchPoint_FILES = TouchPoint.xm
TouchPoint_CFLAGS = -fobjc-arc
TouchPoint_FRAMEWORKS = UIKit QuartzCore
TouchPoint_INSTALL_PATH = /usr/lib/TweakInject

APPLICATION_NAME = TouchPointSettings
TouchPointSettings_FILES = TouchPointSettings.m
TouchPointSettings_CFLAGS = -fobjc-arc
TouchPointSettings_FRAMEWORKS = UIKit
TouchPointSettings_CODESIGN_FLAGS = -Sentitlements.plist
# Theos copies application metadata through RESOURCE_FILES; INFO_PLIST is not
# a recognized project variable and would produce an app without Info.plist.
TouchPointSettings_RESOURCE_FILES = Info.plist icon.png
TouchPointSettings_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/application.mk

before-stage::
	@if [ -d "$(THEOS_PROJECT_DIR)/layout/DEBIAN" ]; then chmod 755 "$(THEOS_PROJECT_DIR)/layout/DEBIAN"; fi

# RootHide validates the application bundle's resource signature as well as
# the executable. Theos signs the binary before staging resources, so sign the
# completed staged bundle once more after Info.plist/icon files are copied.
after-stage::
	@if [ -d "$(THEOS_STAGING_DIR)/DEBIAN" ]; then chmod 755 "$(THEOS_STAGING_DIR)/DEBIAN"; fi
	@if [ -f "$(THEOS_STAGING_DIR)/usr/lib/TweakInject/TouchPoint.plist" ]; then chmod 644 "$(THEOS_STAGING_DIR)/usr/lib/TweakInject/TouchPoint.plist"; fi
	@if [ -d "$(THEOS_STAGING_DIR)/Applications/TouchPointSettings.app" ]; then \
		$(TARGET_CODESIGN) $(TouchPointSettings_CODESIGN_FLAGS) "$(THEOS_STAGING_DIR)/Applications/TouchPointSettings.app"; \
	fi
	@if [ -f "$(THEOS_STAGING_DIR)/DEBIAN/postinst" ]; then chmod 755 "$(THEOS_STAGING_DIR)/DEBIAN/postinst"; fi

# dm.pl rejects a DEBIAN directory copied from Windows/DrvFS with mode 0777.
# Normalize it immediately before package creation (after all stage moves).
before-package::
	@if [ -d "$(THEOS_STAGING_DIR)/DEBIAN" ]; then chmod 755 "$(THEOS_STAGING_DIR)/DEBIAN"; fi
	@if [ -f "$(THEOS_STAGING_DIR)/DEBIAN/postinst" ]; then chmod 755 "$(THEOS_STAGING_DIR)/DEBIAN/postinst"; fi

# Run after Theos has generated/copyied all DEBIAN files, immediately before
# dm.pl validates maintainer-script permissions.
internal-package-check::
	@if [ -d "$(THEOS_STAGING_DIR)/DEBIAN" ]; then chmod 755 "$(THEOS_STAGING_DIR)/DEBIAN"; fi
	@if [ -f "$(THEOS_STAGING_DIR)/DEBIAN/postinst" ]; then chmod 755 "$(THEOS_STAGING_DIR)/DEBIAN/postinst"; fi

after-install::
	install.exec "sbreload || true"
