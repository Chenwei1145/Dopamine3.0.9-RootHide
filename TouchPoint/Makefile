TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
FINALPACKAGE = 1
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TouchPoint
TouchPoint_FILES = TouchPoint.xm
TouchPoint_CFLAGS = -fobjc-arc
TouchPoint_FRAMEWORKS = UIKit QuartzCore
TouchPoint_INSTALL_PATH = /usr/lib/TweakInject

APPLICATION_NAME = TouchPointSettings
TouchPointSettings_FILES = TouchPointSettings.m
TouchPointSettings_FRAMEWORKS = UIKit
TouchPointSettings_CODESIGN_FLAGS = -Sentitlements.plist
TouchPointSettings_INFO_PLIST = Info.plist
TouchPointSettings_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "sbreload || true"
