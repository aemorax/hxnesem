package model;

typedef Registers = {
	var p:Int; // status
	var a:Int; // accum
	var x:Int; // x
	var y:Int; // y
	var s:Int; // stack pointer
	var pc:Int; // program counter
}

class Processor {
	public var bus:Bus;
	public var regs:Registers;
	public var carry(get, set):Int;
	public var zero(get, set):Int;
	public var int(get, set):Int;
	public var dec(get, set):Int;
	public var brek(get, set):Int;
	public var unus(get, set):Int;
	public var ovflow(get, set):Int;
	public var negative(get, set):Int;

	public function new() {
		this.regs = {
			p: 0,
			a: 0,
			x: 0,
			y: 0,
			s: 0,
			pc: 0
		};
	}

	public function connectBus(bus:Bus) {
		this.bus = bus;
	}

	public function read(address:Int) {
		return this.bus.read(address);
	}

	public function write(address:Int, data:Int) {
		this.bus.write(address, data);
	}

	public function clock() {}

	public function reset() {}

	public function irq() {}

	public function nmi() {}

	function get_carry():Int {
		return (this.regs.p & 1);
	}

	function set_carry(value:Int):Int {
		this.regs.p &= ~(1);
		this.regs.p |= (value & 0x1);

		return (value & 0x1);
	}

	function get_zero():Int {
		return ((this.regs.p * 2) >> 1);
	}

	function set_zero(value:Int):Int {
		this.regs.p &= ~(2);
		this.regs.p |= ((value & 0x1) << 1);

		return (value & 0x1);
	}

	function get_int():Int {
		return ((this.regs.p & 4) >> 2);
	}

	function set_int(value:Int):Int {
		this.regs.p &= ~(4);
		this.regs.p |= ((value & 0x1) << 2);

		return (value & 0x1);
	}

	function get_dec():Int {
		return ((this.regs.p & 8) >> 3);
	}

	function set_dec(value:Int):Int {
		this.regs.p &= ~(8);
		this.regs.p |= ((value & 0x1) << 3);

		return (value & 0x1);
	}

	function get_brek():Int {
		return ((this.regs.p & 16) >> 4);
	}

	function set_brek(value:Int):Int {
		this.regs.p &= ~(16);
		this.regs.p |= ((value & 0x1) << 4);

		return (value & 0x1);
	}

	function get_unus():Int {
		return ((this.regs.p & 32) >> 5);
	}

	function set_unus(value:Int):Int {
		this.regs.p &= ~(32);
		this.regs.p |= ((value & 0x1) << 5);

		return (value & 0x1);
	}

	function get_ovflow():Int {
		return ((this.regs.p & 64) >> 6);
	}

	function set_ovflow(value:Int):Int {
		this.regs.p &= ~(64);
		this.regs.p |= ((value & 0x1) << 6);

		return (value & 0x1);
	}

	function get_negative():Int {
		return ((this.regs.p & 128) >> 7);
	}

	function set_negative(value:Int):Int {
		this.regs.p &= ~(128);
		this.regs.p |= ((value & 0x1) << 7);

		return (value & 0x1);
	}
}
