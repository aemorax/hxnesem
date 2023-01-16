package model;

import haxe.io.Bytes;

class Bus {
	public var cpu:Processor;

	public var ram:Bytes = Bytes.alloc(2048);

	private var systemClockCounter = 0;

	public function new() {
		cpu = new Processor(this);
	}

	public function write(address:Int, data:Int) {
		if (address >= 0 && address <= 0x1fff)
			ram.set(address, data);
	}

	public function read(address:Int):Int {
		var d = 0;
		if (address >= 0x0000 && address <= 0x1FFFF) {
			d = ram.get(address & 0x7ff);
		} else if (address >= 0x2000 && address <= 0x3FFF) {}
		return d;
	}

	public function insertCartridge(cartridge:Cartridge) {}

	public function clock() {
		if ((systemClockCounter % 3) == 0) {
			cpu.clock();
		}
		systemClockCounter++;
	}
}
