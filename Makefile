SOURCE_FILES := $(shell find src/ -type f -name '*')

all: vm web

vm: out/emulator.hl

out/emulator.hl: $(SOURCE_FILES)
	haxe build.hl.hxml

web: web/emulator.js

web/emulator.js: $(SOURCE_FILES)
	haxe build.web.hxml
