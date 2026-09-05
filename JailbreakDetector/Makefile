TARGET = JailbreakDetector
ARCHS = arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = JailbreakDetector

JailbreakDetector_FILES = main.swift
JailbreakDetector_FRAMEWORKS = UIKit SwiftUI Foundation
JailbreakDetector_CODESIGN_FLAGS = -Sentitlements.plist
JailbreakDetector_SWIFT_VERSION = 5.0

include $(THEOS_MAKE_PATH)/application.mk

after-clean::
	@rm -rf .theos packages
