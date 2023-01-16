package mappers;

import interfaces.IMapper;

class Mapper000 implements IMapper {
	final prgCount:Int;
	final chrCount:Int;

	public function new(prgCount:Int, chrCount:Int) {
		this.prgCount = prgCount;
		this.chrCount = chrCount;
	}

	public function cpuMapRead(addr:Int, mappedAddr:Dynamic) {
		if (addr >= 0x8000 && addr <= 0xffff) {
			Reflect.setProperty(mappedAddr, "a", addr & (this.prgCount > 1 ? 0x7FFF : 0x3FFF));
			return true;
		}
		return false;
	}

	public function cpuMapWrite(addr:Int, mappedAddr:Dynamic) {
		if (addr >= 0x8000 && addr <= 0xffff) {
			Reflect.setProperty(mappedAddr, "a", addr & (this.prgCount > 1 ? 0x7FFF : 0x3FFF));
			return true;
		}
		return false;
	}

	public function ppuMapRead(addr:Int, mappedAddr:Dynamic) {
		if (addr >= 0 && addr <= 0x1fff) {
			if (chrCount == 0) {
				Reflect.setProperty(mappedAddr, "a", addr);
				return true;
			}
		}
		return false;
	}

	public function ppuMapWrite(addr:Int, mappedAddr:Dynamic) {
		if (addr >= 0 && addr <= 0x1fff) {
			if (chrCount == 0) {
				Reflect.setProperty(mappedAddr, "a", addr);
				return true;
			}
		}
		return false;
	}
}
