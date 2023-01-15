package model;

import haxe.ds.Vector;

class Bus {
	public var ram:Vector<Int> = new Vector<Int>(64 * 1024);

	public function write(address:Int, data:Int) {
		if (address >= 0 && address <= 0xffff)
			ram[address] = data;
	}

	public function read(address:Int):Int {
		if (address >= 0 && address <= 0xffff)
			return ram[address];
		return 0;
	}
}
