package model;

import haxe.io.Bytes;

class Bus {
	public var cpu:Processor;
	public var ppu:PPU;

	/**
		CPU can be mapped to 8kb of RAM but the RAM in NES is actually
		2kb which is 2048 (0x800) bytes.
	 */
	public var ram:Bytes = Bytes.alloc(0x800);

	private var systemClockCounter = 0;

	public function new() {
		cpu = new Processor(this);
		ppu = new PPU(null);
	}

	public function write(address:Int, data:Int):Void {
		if (address >= 0 && address <= 0x1FFF) {
			address &= 0x7FF;
			ram.set(address, data);
		}
	}

	public function read(address:Int):Int {
		var d = 0;
		if (address >= 0x0000 && address <= 0x1FFF) {
			d = ram.get(address & 0x7FF);
		} else if (address >= 0x2000 && address <= 0x3FFF) {}
		return d;
	}

	public function insertCartridge(cartridge:Cartridge) {}

	public function clock():Void {
		ppu.clock();
		// CPU clock runs 3 times slower than PPU clock.
		if ((systemClockCounter % 3) == 0) {
			cpu.clock();
		}
		systemClockCounter++;
	}
}
