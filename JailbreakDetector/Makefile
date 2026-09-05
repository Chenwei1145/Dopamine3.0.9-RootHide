TARGET = iphone:clang:latest:14.0
# arm64 runs on the A13 and avoids the incompatible arm64e Swift ABI warning
# emitted by the Linux cross-toolchain.
ARCHS = arm64
INSTALL_TARGET_PROCESSES = JailbreakDetector

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = JailbreakDetector

JailbreakDetector_FILES = main.swift
JailbreakDetector_FRAMEWORKS = UIKit SwiftUI Foundation
JailbreakDetector_CODESIGN_FLAGS = -Sentitlements.plist
JailbreakDetector_SWIFT_VERSION = 5.0

include $(THEOS_MAKE_PATH)/application.mk

after-clean::
	@rm -rf .theos packages
