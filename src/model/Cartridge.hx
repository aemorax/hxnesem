package model;

import mappers.Mapper000;
import interfaces.IMapper;
import haxe.io.Bytes;

typedef INesHeader = {
	var name:String;
	var prg:Int;
	var chr:Int;
	var mapper1:Int;
	var mapper2:Int;
	var ram_size:Int;
	var tv_system1:Int;
	var tv_system2:Int;
	var unused:String;
}

enum Mirror {
	Horizontal;
	Vertical;
	OneScreen_Lo;
	OneScreen_Hi;
}

class Cartridge {
	public var pos:Int = 0;
	public var mapper:IMapper;
	public var mapperID:Int = 0;
	public var mirror:Mirror;

	var prgCount = 0;
	var chrCount = 0;
	var prgMemory:Bytes;
	var chrMemory:Bytes;

	public function new(bytes:Bytes) {
		var header:INesHeader = {
			name: bytes.getString(0, 4),
			prg: bytes.get(pos += 4),
			chr: bytes.get(pos += 1),
			mapper1: bytes.get(pos += 1),
			mapper2: bytes.get(pos += 1),
			ram_size: bytes.get(pos += 1),
			tv_system1: bytes.get(pos += 1),
			tv_system2: bytes.get(pos += 1),
			unused: bytes.getString(pos, 5)
		};
		pos += 5;

		if ((header.mapper1 & 0x04) != 0)
			pos += 512;

		mapperID = ((header.mapper2 >> 4) << 4) | (header.mapper1 >> 4);
		mirror = (header.mapper1 & 0x01) != 0 ? Vertical : Horizontal;

		var fileType = 1;

		if (fileType == 0) {} else if (fileType == 1) {
			prgCount = header.prg;
			var prgData:String = bytes.getString(pos, prgCount * 16384);
			pos += prgCount * 16384;
			prgMemory = Bytes.ofString(prgData);

			chrCount = header.chr;
			var chrData:String = bytes.getString(pos, chrCount * 8192);
			pos += chrCount * 8192;
			chrMemory = Bytes.ofString(chrData);
		} else if (fileType == 2) {}

		switch mapperID {
			case 0:
				mapper = new Mapper000(prgCount, chrCount);
		}
	}

	public function ppuRead(addr:Int, data:Dynamic) {
		var map_addr = {a: 0};
		if (mapper.ppuMapRead(addr, map_addr)) {
			data = chrMemory.get(map_addr.a);
			return true;
		}

		return false;
	}

	public function ppuWrite(addr:Int, data:Int) {
		var map_addr = {a: 0};
		if (mapper.ppuMapRead(addr, map_addr)) {
			chrMemory.set(map_addr.a, data);
			return true;
		}

		return false;
	}
}
