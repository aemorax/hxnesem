package model;

import haxe.io.Bytes;

class PPU {
	public var frameDone = false;

	private var tableName:Bytes;
	private var tablePattern:Bytes;
	private var tablePalette:Bytes;
	private var cartridge:Cartridge;
	private var cycle:Int = 0;
	private var scanline:Int = -1;
	private var screen:Bytes;

	private var palette:Array<Int> = [
		0x545454, 0x001e74, 0x081090, 0x300088, 0x440064, 0x5c0030, 0x540400, 0x3c1800, 0x202a00, 0x083a00, 0x004000, 0x003c00, 0x00323c, 0x000000, 0x000000,
		0x000000, 0x989698, 0x084cc4, 0x3032ec, 0x5c1ee4, 0x8814b0, 0xa01464, 0x982220, 0x783c00, 0x545a00, 0x287200, 0x087c00, 0x007628, 0x006678, 0x000000,
		0x000000, 0x000000, 0xeceeec, 0x4c9aec, 0x787cec, 0xb062ec, 0xe454ec, 0xec58b4, 0xec6a64, 0xd48820, 0xa0aa00, 0x74c400, 0x4cd020, 0x38cc6c, 0x38b4cc,
		0x3c3c3c, 0x000000, 0x000000, 0xeceeec, 0xa8ccec, 0xbcbcec, 0xd4b2ec, 0xecaeec, 0xecaed4, 0xecb4b0, 0xe4c490, 0xccd278, 0xb4de78, 0xa8e290, 0x98e2b4,
		0xa0d6e4, 0xa0a2a0, 0x000000, 0x000000
	];

	public function new(cart:Cartridge) {
		this.cartridge = cart;
		screen = Bytes.alloc(256 * 240 * 3);
	}

	public function cpuRead(addr:Int, ?rdonly:Bool = false) {}

	public function cpuWrite(addr:Int, data:Int) {}

	public function ppuRead(addr:Int, ?rdonly:Bool = false) {
		var d = 0;
		addr &= 0x3FF;
		if (cartridge.ppuRead(addr, d)) {}

		return d;
	}

	public function ppuWrite(addr:Int, data:Int) {
		addr &= 0x3fff;

		if (cartridge.ppuWrite(addr, data)) {}
	}

	public function clock() {
		var x = cycle;
		var y = scanline;
		screen.setInt32(x * 3 + y * 256 * 3, palette[Math.random() > 0.5 ? 0x3f : 0x30]);

		cycle++;
		if (cycle >= 341) {
			cycle = 0;
			scanline++;
			if (scanline >= 261) {
				scanline = 0;
				frameDone = true;
			}
		}
	}
}
