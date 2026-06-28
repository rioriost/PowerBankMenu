.PHONY: build test

build:
	xcodebuild -scheme TestTicket19CLI -configuration Debug -destination "platform=macOS,arch=arm64" -quiet build

test:
	direnv exec . sh -lc 'SOLIX_EMAIL="$$SOLIX_EMAIL" SOLIX_PASSWORD="$$SOLIX_PASSWORD" SOLIX_COUNTRY="EU" SOLIX_REQUEST_TIMEOUT=60 \
	~/Library/Developer/Xcode/DerivedData/SolixMenu-*/Build/Products/Debug/TestTicket19CLI'
