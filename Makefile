.PHONY: deploy

status:
	butler status irskep/powerq

archive:
	xcodebuild archive -project LD39.xcodeproj -scheme macOS -archivePath build/Power-Q.xcarchive

export:
	xcodebuild \
		-exportArchive \
		-exportOptionsPlist exportOptions.plist \
		-archivePath build/Power-Q.xcarchive \
		-exportPath build/export
	rm \
		build/export/DistributionSummary.plist \
		build/export/ExportOptions.plist \
		build/export/Packaging.log

upload:
	butler push build/export irskep/powerq:osx

run:
	open build/export/Power-Q.app

qa: archive export run

deploy: archive export upload

icons:
	cp art/icon_mac/icon-16.png macOS/Mac.xcassets/AppIcon.appiconset/icon-16.png
	convert art/icon_mac/icon-16.png -interpolate Nearest -filter point -resize 200% \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-32.png
	convert art/icon_mac/icon-16.png -interpolate Nearest -filter point -resize 400% \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-64.png
	convert art/icon_mac/icon-16.png -interpolate Nearest -filter point -resize 800% \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-128.png
	convert art/icon_mac/icon-16.png -interpolate Nearest -filter point -resize 1600% \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-256.png
	convert art/icon_mac/icon-16.png -interpolate Nearest -filter point -resize 3200% \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-512.png
	convert art/icon_mac/icon-16.png -interpolate Nearest -filter point -resize 6400% \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-1024.png

	cp 	macOS/Mac.xcassets/AppIcon.appiconset/icon-32.png \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-33.png
	cp 	macOS/Mac.xcassets/AppIcon.appiconset/icon-256.png \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-257.png
	cp 	macOS/Mac.xcassets/AppIcon.appiconset/icon-512.png \
		macOS/Mac.xcassets/AppIcon.appiconset/icon-513.png

	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 29x29 \
		art/icon_ios/Icon-App-29x29@1x.png
	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 58x58 \
		art/icon_ios/Icon-App-29x29@2x.png
	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 87x87 \
		art/icon_ios/Icon-App-29x29@3x.png

	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 40x40 \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-40x40@1x-1.png
	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 80x80 \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-40x40@2x-1.png
	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 120x120 \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-40x40@3x-1.png

	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 120x120 \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-60x60@2x-1.png
	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 180x180 \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-60x60@3x-1.png

	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 76x76 \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-76x76@1x-1.png
	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 152x152 \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 288x288 \
		art/icon_ios/Icon-App-76x76@3x.png

	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 167x167 \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-83.5x85.5@2x-1.png

	convert art/icon_ios/icon-16.png -interpolate Nearest -filter point -resize 1024x1024 \
		iOS/iOS.xcassets/AppIcon.appiconset/appstore.png

	cp iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-40x40@2x-1.png \
		iOS/iOS.xcassets/AppIcon.appiconset/Icon-App-40x40@2x-2.png

