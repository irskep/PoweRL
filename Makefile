.PHONY: deploy

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
