package model;

import haxe.ds.Vector;

typedef Registers = {
	var p:Int; // status
	var a:Int; // accum
	var x:Int; // x
	var y:Int; // y
	var s:Int; // stack pointer
	var pc:Int; // program counter
}

typedef Operation = {
	var cycles:Int;
	var addressingFunction:Void->Bool;
	var operationFunction:Void->Bool;
}

class Processor {
	final opTable:Vector<Operation> = new Vector<Operation>(256);

	public var timer:Int = 0;

	public var bus:Bus;
	public var regs:Registers;
	public var data:Int = 0;
	public var addr:Int = 0;
	public var cache:Int = 0;
	public var relAddr:Int = 0;
	public var carry(get, set):Int;
	public var zero(get, set):Int;
	public var int(get, set):Int;
	public var decm(get, set):Int;
	public var brek(get, set):Int;
	public var unus(get, set):Int;
	public var ovflow(get, set):Int;
	public var negative(get, set):Int;

	public function new(bus:Bus) {
		this.bus = bus;
		this.regs = {
			p: 32,
			a: 0,
			x: 0,
			y: 0,
			s: 0xFD,
			pc: 0
		};

		addr = 0xfffc;
		regs.pc = read(addr) | (read(addr + 1) << 8);

		relAddr = 0;
		addr = 0;
		data = 0;
		cache = 0;

		this.opTable.set(0x00, {cycles: 7, addressingFunction: this.imp, operationFunction: this.brk}); // brk imp 7
		this.opTable.set(0x01, {cycles: 6, addressingFunction: this.izx, operationFunction: this.ora}); // ora izx 6
		this.opTable.set(0x05, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.ora}); // ora zp0 3
		this.opTable.set(0x06, {cycles: 5, addressingFunction: this.zp0, operationFunction: this.asl}); // asl zp0 5
		this.opTable.set(0x08, {cycles: 8, addressingFunction: this.imp, operationFunction: this.php}); // php imp 8
		this.opTable.set(0x09, {cycles: 2, addressingFunction: this.imm, operationFunction: this.ora}); // ora imm 2
		this.opTable.set(0x0A, {cycles: 2, addressingFunction: this.imp, operationFunction: this.asl}); // asl imp 2
		this.opTable.set(0x0D, {cycles: 4, addressingFunction: this.abs, operationFunction: this.ora}); // ora abs 4
		this.opTable.set(0x0E, {cycles: 6, addressingFunction: this.abs, operationFunction: this.asl}); // asl abs 6

		this.opTable.set(0x10, {cycles: 2, addressingFunction: this.rel, operationFunction: this.bpl}); // bpl rel 2
		this.opTable.set(0x11, {cycles: 5, addressingFunction: this.izy, operationFunction: this.ora}); // ora izy 5
		this.opTable.set(0x15, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.ora}); // ora zpx 4
		this.opTable.set(0x16, {cycles: 6, addressingFunction: this.zpx, operationFunction: this.asl}); // asl zpx 6
		this.opTable.set(0x18, {cycles: 2, addressingFunction: this.imp, operationFunction: this.clc}); // clc imp 2
		this.opTable.set(0x19, {cycles: 4, addressingFunction: this.aby, operationFunction: this.ora}); // ora aby 4
		this.opTable.set(0x1D, {cycles: 4, addressingFunction: this.abx, operationFunction: this.ora}); // ora abx 4
		this.opTable.set(0x1E, {cycles: 7, addressingFunction: this.abx, operationFunction: this.asl}); // asl abx 7

		this.opTable.set(0x20, {cycles: 6, addressingFunction: this.abs, operationFunction: this.jsr}); // jsr abs 6
		this.opTable.set(0x21, {cycles: 6, addressingFunction: this.izx, operationFunction: this.and}); // and izx 6
		this.opTable.set(0x24, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.bit}); // bit zp0 3
		this.opTable.set(0x25, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.and}); // and zp0 3
		this.opTable.set(0x26, {cycles: 5, addressingFunction: this.zp0, operationFunction: this.rol}); // rol zp0 5
		this.opTable.set(0x28, {cycles: 4, addressingFunction: this.imp, operationFunction: this.plp}); // plp imp 4
		this.opTable.set(0x29, {cycles: 2, addressingFunction: this.imm, operationFunction: this.and}); // and imm 2
		this.opTable.set(0x2A, {cycles: 2, addressingFunction: this.imp, operationFunction: this.rol}); // rol imp 2
		this.opTable.set(0x2C, {cycles: 4, addressingFunction: this.abs, operationFunction: this.bit}); // bit abs 4
		this.opTable.set(0x2D, {cycles: 4, addressingFunction: this.abs, operationFunction: this.and}); // and abs 4
		this.opTable.set(0x2E, {cycles: 6, addressingFunction: this.abs, operationFunction: this.rol}); // rol abs 6

		this.opTable.set(0x30, {cycles: 2, addressingFunction: this.rel, operationFunction: this.bmi}); // bmi rel 2
		this.opTable.set(0x31, {cycles: 5, addressingFunction: this.izx, operationFunction: this.and}); // and izx 5
		this.opTable.set(0x35, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.and}); // and zpx 4
		this.opTable.set(0x36, {cycles: 6, addressingFunction: this.zpx, operationFunction: this.rol}); // rol zpx 6
		this.opTable.set(0x38, {cycles: 2, addressingFunction: this.imp, operationFunction: this.sec}); // sec imp 2
		this.opTable.set(0x39, {cycles: 4, addressingFunction: this.aby, operationFunction: this.and}); // and aby 4
		this.opTable.set(0x3D, {cycles: 4, addressingFunction: this.abx, operationFunction: this.and}); // and abx 4
		this.opTable.set(0x3E, {cycles: 7, addressingFunction: this.abx, operationFunction: this.rol}); // rol abx 7

		this.opTable.set(0x40, {cycles: 6, addressingFunction: this.imp, operationFunction: this.rti}); // rti imp 6
		this.opTable.set(0x41, {cycles: 6, addressingFunction: this.izx, operationFunction: this.eor}); // eor izx 6
		this.opTable.set(0x45, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.eor}); // eor zp0 3
		this.opTable.set(0x46, {cycles: 5, addressingFunction: this.zp0, operationFunction: this.lsr}); // lsr zp0 5
		this.opTable.set(0x48, {cycles: 3, addressingFunction: this.imp, operationFunction: this.pha}); // pha imp 3
		this.opTable.set(0x49, {cycles: 2, addressingFunction: this.imm, operationFunction: this.eor}); // eor imm 2
		this.opTable.set(0x4A, {cycles: 2, addressingFunction: this.imp, operationFunction: this.lsr}); // lsr imp 2
		this.opTable.set(0x4C, {cycles: 3, addressingFunction: this.abs, operationFunction: this.jmp}); // jmp abs 3
		this.opTable.set(0x4D, {cycles: 4, addressingFunction: this.abs, operationFunction: this.eor}); // eor abs 4
		this.opTable.set(0x4E, {cycles: 6, addressingFunction: this.abs, operationFunction: this.lsr}); // lsr abs 6

		this.opTable.set(0x50, {cycles: 2, addressingFunction: this.rel, operationFunction: this.bvc}); // bvc rel 2
		this.opTable.set(0x51, {cycles: 5, addressingFunction: this.izy, operationFunction: this.eor}); // eor izy 5
		this.opTable.set(0x55, {cycles: 3, addressingFunction: this.zpx, operationFunction: this.eor}); // eor zpx 3
		this.opTable.set(0x56, {cycles: 5, addressingFunction: this.zpx, operationFunction: this.lsr}); // lsr zpx 5
		this.opTable.set(0x58, {cycles: 2, addressingFunction: this.imp, operationFunction: this.cli}); // cli imp 2
		this.opTable.set(0x59, {cycles: 4, addressingFunction: this.aby, operationFunction: this.eor}); // eor aby 4
		this.opTable.set(0x5D, {cycles: 4, addressingFunction: this.abx, operationFunction: this.eor}); // eor abx 4
		this.opTable.set(0x5E, {cycles: 7, addressingFunction: this.abx, operationFunction: this.lsr}); // lsr abx 7

		this.opTable.set(0x60, {cycles: 5, addressingFunction: this.imp, operationFunction: this.rts}); // rts imp 5
		this.opTable.set(0x61, {cycles: 5, addressingFunction: this.izx, operationFunction: this.adc}); // adc izx 5
		this.opTable.set(0x65, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.adc}); // adc zp0 3
		this.opTable.set(0x66, {cycles: 5, addressingFunction: this.zp0, operationFunction: this.ror}); // ror zp0 5
		this.opTable.set(0x68, {cycles: 4, addressingFunction: this.imp, operationFunction: this.pla}); // pla imp 4
		this.opTable.set(0x69, {cycles: 2, addressingFunction: this.imm, operationFunction: this.adc}); // adc imm 2
		this.opTable.set(0x6A, {cycles: 2, addressingFunction: this.imp, operationFunction: this.ror}); // ror imp 2
		this.opTable.set(0x6C, {cycles: 5, addressingFunction: this.ind, operationFunction: this.jmp}); // jmp ind 5
		this.opTable.set(0x6D, {cycles: 4, addressingFunction: this.abs, operationFunction: this.adc}); // adc abs 4
		this.opTable.set(0x6E, {cycles: 6, addressingFunction: this.abs, operationFunction: this.ror}); // ror abs 6

		this.opTable.set(0x70, {cycles: 2, addressingFunction: this.rel, operationFunction: this.bvs}); // bvs rel 2
		this.opTable.set(0x71, {cycles: 5, addressingFunction: this.izy, operationFunction: this.adc}); // adc izy 5
		this.opTable.set(0x75, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.adc}); // adc zpx 4
		this.opTable.set(0x76, {cycles: 6, addressingFunction: this.zpx, operationFunction: this.ror}); // ror zpx 6
		this.opTable.set(0x78, {cycles: 2, addressingFunction: this.imp, operationFunction: this.sei}); // sei imp 2
		this.opTable.set(0x79, {cycles: 4, addressingFunction: this.aby, operationFunction: this.adc}); // adc aby 4
		this.opTable.set(0x7D, {cycles: 4, addressingFunction: this.abx, operationFunction: this.adc}); // adc abx 4
		this.opTable.set(0x7E, {cycles: 7, addressingFunction: this.abx, operationFunction: this.ror}); // ror abx 7

		this.opTable.set(0x81, {cycles: 6, addressingFunction: this.izx, operationFunction: this.sta}); // sta izx 6
		this.opTable.set(0x84, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.sty}); // sty zp0 3
		this.opTable.set(0x85, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.sta}); // sta zp0 3
		this.opTable.set(0x86, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.stx}); // stx zp0 3
		this.opTable.set(0x88, {cycles: 2, addressingFunction: this.imp, operationFunction: this.dey}); // dey imp 2
		this.opTable.set(0x8A, {cycles: 2, addressingFunction: this.imp, operationFunction: this.txa}); // txa imp 2
		this.opTable.set(0x8C, {cycles: 4, addressingFunction: this.abs, operationFunction: this.sty}); // sty abs 4
		this.opTable.set(0x8D, {cycles: 4, addressingFunction: this.abs, operationFunction: this.sta}); // sta abs 4
		this.opTable.set(0x8E, {cycles: 4, addressingFunction: this.abs, operationFunction: this.stx}); // stx abs 4

		this.opTable.set(0x90, {cycles: 2, addressingFunction: this.rel, operationFunction: this.bcc}); // bcc rel 2
		this.opTable.set(0x91, {cycles: 6, addressingFunction: this.izy, operationFunction: this.sta}); // sta izy 6
		this.opTable.set(0x94, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.sty}); // sty zpx 4
		this.opTable.set(0x95, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.sta}); // sta zpx 4
		this.opTable.set(0x96, {cycles: 4, addressingFunction: this.zpy, operationFunction: this.stx}); // stx zpy 4
		this.opTable.set(0x98, {cycles: 2, addressingFunction: this.imp, operationFunction: this.tya}); // tya imp 2
		this.opTable.set(0x99, {cycles: 5, addressingFunction: this.aby, operationFunction: this.sta}); // sta aby 5
		this.opTable.set(0x9A, {cycles: 2, addressingFunction: this.imp, operationFunction: this.txs}); // txs imp 2
		this.opTable.set(0x9D, {cycles: 5, addressingFunction: this.abx, operationFunction: this.sta}); // sta abx 5

		this.opTable.set(0xA0, {cycles: 2, addressingFunction: this.imm, operationFunction: this.ldy}); // ldy imm 2
		this.opTable.set(0xA1, {cycles: 6, addressingFunction: this.izx, operationFunction: this.lda}); // lda izx 6
		this.opTable.set(0xA2, {cycles: 2, addressingFunction: this.imm, operationFunction: this.ldx}); // ldx imm 2
		this.opTable.set(0xA4, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.ldy}); // ldy zp0 3
		this.opTable.set(0xA5, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.lda}); // lda zp0 3
		this.opTable.set(0xA6, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.ldx}); // ldx zp0 3
		this.opTable.set(0xA8, {cycles: 2, addressingFunction: this.imp, operationFunction: this.tay}); // tay imp 2
		this.opTable.set(0xA9, {cycles: 2, addressingFunction: this.imm, operationFunction: this.lda}); // lda imm 2
		this.opTable.set(0xAA, {cycles: 2, addressingFunction: this.imp, operationFunction: this.tax}); // tax imp 2
		this.opTable.set(0xAC, {cycles: 4, addressingFunction: this.abs, operationFunction: this.ldy}); // ldy abs 4
		this.opTable.set(0xAD, {cycles: 4, addressingFunction: this.abs, operationFunction: this.lda}); // lda abs 4
		this.opTable.set(0xAE, {cycles: 4, addressingFunction: this.abs, operationFunction: this.ldx}); // ldx abs 4

		this.opTable.set(0xB0, {cycles: 2, addressingFunction: this.rel, operationFunction: this.bcs}); // bcs rel 2
		this.opTable.set(0xB1, {cycles: 5, addressingFunction: this.izy, operationFunction: this.lda}); // lda izy 5
		this.opTable.set(0xB4, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.ldy}); // ldy zpx 4
		this.opTable.set(0xB5, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.lda}); // lda zpx 4
		this.opTable.set(0xB6, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.ldx}); // ldx zpx 4
		this.opTable.set(0xB8, {cycles: 2, addressingFunction: this.imp, operationFunction: this.clv}); // clv imp 2
		this.opTable.set(0xB9, {cycles: 4, addressingFunction: this.aby, operationFunction: this.lda}); // lda aby 4
		this.opTable.set(0xBA, {cycles: 2, addressingFunction: this.imp, operationFunction: this.tsx}); // tsx imp 2
		this.opTable.set(0xBC, {cycles: 4, addressingFunction: this.abx, operationFunction: this.ldy}); // ldy abx 4
		this.opTable.set(0xBD, {cycles: 4, addressingFunction: this.abx, operationFunction: this.lda}); // lda abx 4
		this.opTable.set(0xBE, {cycles: 4, addressingFunction: this.aby, operationFunction: this.ldx}); // ldx aby 4

		this.opTable.set(0xC0, {cycles: 2, addressingFunction: this.imm, operationFunction: this.cpy}); // cpy imm 2
		this.opTable.set(0xC1, {cycles: 6, addressingFunction: this.izx, operationFunction: this.cmp}); // cmp izx 6
		this.opTable.set(0xC4, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.cpy}); // cpy zp0 3
		this.opTable.set(0xC5, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.cmp}); // cmp zp0 3
		this.opTable.set(0xC6, {cycles: 5, addressingFunction: this.zp0, operationFunction: this.dec}); // dec zp0 5
		this.opTable.set(0xC8, {cycles: 2, addressingFunction: this.imp, operationFunction: this.iny}); // iny imp 2
		this.opTable.set(0xC9, {cycles: 2, addressingFunction: this.imm, operationFunction: this.cmp}); // cmp imm 2
		this.opTable.set(0xCA, {cycles: 2, addressingFunction: this.imp, operationFunction: this.dex}); // dex imp 2
		this.opTable.set(0xCC, {cycles: 4, addressingFunction: this.abs, operationFunction: this.cpy}); // cpy abs 4
		this.opTable.set(0xCD, {cycles: 4, addressingFunction: this.abs, operationFunction: this.cmp}); // cmp abs 4
		this.opTable.set(0xCE, {cycles: 6, addressingFunction: this.abs, operationFunction: this.dec}); // dec abs 6

		this.opTable.set(0xD0, {cycles: 2, addressingFunction: this.rel, operationFunction: this.bne}); // bne rel 2
		this.opTable.set(0xD1, {cycles: 5, addressingFunction: this.izy, operationFunction: this.cmp}); // cmp izy 5
		this.opTable.set(0xD5, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.cmp}); // cmp zpx 4
		this.opTable.set(0xD6, {cycles: 6, addressingFunction: this.zpx, operationFunction: this.dec}); // dec zpx 6
		this.opTable.set(0xD8, {cycles: 2, addressingFunction: this.imp, operationFunction: this.cld}); // cld imp 2
		this.opTable.set(0xD9, {cycles: 4, addressingFunction: this.aby, operationFunction: this.cmp}); // cmp aby 4
		this.opTable.set(0xDD, {cycles: 4, addressingFunction: this.abx, operationFunction: this.cmp}); // cmp abx 4
		this.opTable.set(0xDE, {cycles: 7, addressingFunction: this.abx, operationFunction: this.dec}); // dec abx 7

		this.opTable.set(0xE0, {cycles: 2, addressingFunction: this.imm, operationFunction: this.cpx}); // cpx imm 2
		this.opTable.set(0xE1, {cycles: 6, addressingFunction: this.izx, operationFunction: this.sbc}); // sbc izx 6
		this.opTable.set(0xE4, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.cpx}); // cpx zp0 3
		this.opTable.set(0xE5, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.sbc}); // sbc zp0 3
		this.opTable.set(0xE6, {cycles: 5, addressingFunction: this.zp0, operationFunction: this.inc}); // inc zp0 5
		this.opTable.set(0xE8, {cycles: 2, addressingFunction: this.imp, operationFunction: this.inx}); // inx imp 2
		this.opTable.set(0xE9, {cycles: 2, addressingFunction: this.imm, operationFunction: this.sbc}); // sbc imm 2
		this.opTable.set(0xEA, {cycles: 2, addressingFunction: this.imm, operationFunction: this.nop}); // nop imm 2
		this.opTable.set(0xEC, {cycles: 4, addressingFunction: this.abs, operationFunction: this.cpx}); // cpx abs 4
		this.opTable.set(0xED, {cycles: 4, addressingFunction: this.abs, operationFunction: this.sbc}); // sbc abs 4
		this.opTable.set(0xEE, {cycles: 6, addressingFunction: this.abs, operationFunction: this.inc}); // inc abs 6

		this.opTable.set(0xF0, {cycles: 2, addressingFunction: this.rel, operationFunction: this.beq}); // beq rel 2
		this.opTable.set(0xF1, {cycles: 5, addressingFunction: this.izy, operationFunction: this.sbc}); // sbc izy 5
		this.opTable.set(0xF5, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.sbc}); // sbc zpx 4
		this.opTable.set(0xF6, {cycles: 6, addressingFunction: this.zpx, operationFunction: this.inc}); // inc zpx 6
		this.opTable.set(0xF8, {cycles: 2, addressingFunction: this.imp, operationFunction: this.sed}); // sed imp 2
		this.opTable.set(0xF9, {cycles: 4, addressingFunction: this.aby, operationFunction: this.sbc}); // sbc aby 4
		this.opTable.set(0xFD, {cycles: 4, addressingFunction: this.abx, operationFunction: this.sbc}); // sbc abx 4
		this.opTable.set(0xFE, {cycles: 7, addressingFunction: this.abx, operationFunction: this.inc}); // inc abx 7
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

	public function fetch():Int {
		if (this.opTable.get(currentOpcode).addressingFunction != this.imp) {
			data = read(addr);
		}
		return data;
	}

	public function clock() {
		if (remainingCycle == 0) {
			currentOpcode = read(regs.pc);
			unus = 1;
			regs.pc++;
			if (this.opTable.get(currentOpcode) != null) {
				remainingCycle = this.opTable.get(currentOpcode).cycles;
				var need_c1 = this.opTable.get(currentOpcode).addressingFunction();
				var need_c2 = this.opTable.get(currentOpcode).operationFunction();
				if (need_c1)
					remainingCycle++;
				if (need_c2)
					remainingCycle++;
			}
			unus = 1;
		}

		remainingCycle--;
		timer++;
	}

	public function reset() {
		addr = 0xfffc;
		var lo = read(addr);
		var hi = read(addr + 1);
		regs.pc = (hi << 8) | lo;

		regs.a = 0;
		regs.x = 0;
		regs.y = 0;
		regs.s = 0xFD;
		regs.p = 32;

		relAddr = 0;
		addr = 0;
		data = 0;
		cache = 0;

		remainingCycle = 8;
	}

	public function irq() {
		if (int == 0) {
			nmi();
			remainingCycle = 7;
		}
	}

	public function nmi() {
		write(0x100 + regs.s, (regs.pc >> 8) & 0xff);
		regs.s--;
		write(0x100 + regs.s, (regs.pc) & 0xff);
		regs.s--;

		brek = 0;
		unus = 1;
		int = 1;
		write(0x100 + regs.s, regs.p);
		regs.s--;

		addr = 0xfffa;
		regs.pc = read(addr) | (read(addr + 1) << 8);
		remainingCycle = 8;
	}

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

	function get_decm():Int {
		return ((this.regs.p & 8) >> 3);
	}

	function set_decm(value:Int):Int {
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

	private var currentOpcode:Int = 0;
	private var remainingCycle:Int = 0;

	function tick() {
		if (remainingCycle == 0) {
			currentOpcode = read(this.regs.pc);
			this.regs.pc++;

			resolve(currentOpcode);
		}
	}

	function resolve(opcode:Int) {}

	// --- Addressing mode ops
	function imm() {
		addr = regs.pc++;
		return false;
	}

	function imp() {
		data = regs.a;
		return false;
	}

	function zpx() {
		addr = read(regs.pc) + regs.x;
		regs.pc++;
		addr &= 0xFF;
		return false;
	}

	function zpy() {
		addr = read(regs.pc) + regs.y;
		regs.pc++;
		addr &= 0xFF;
		return false;
	}

	function zp0() {
		addr = read(regs.pc);
		regs.pc++;
		addr &= 0xFF;
		return false;
	}

	function rel() {
		relAddr = read(regs.pc);
		regs.pc++;
		if ((relAddr & 0x80) != 0) {
			relAddr |= 0xFF00;
		}
		return false;
	}

	function abs() {
		var lo = read(regs.pc);
		regs.pc++;
		var hi = read(regs.pc);
		regs.pc++;

		addr = (hi << 8) | lo;
		return false;
	}

	function abx() {
		var lo = read(regs.pc);
		regs.pc++;
		var hi = read(regs.pc);
		regs.pc++;

		addr = (hi << 8) | lo;
		addr += regs.x;

		if ((addr & 0xFF00) != (hi << 8)) {
			return true;
		}
		return false;
	}

	function aby() {
		var lo = read(regs.pc);
		regs.pc++;
		var hi = read(regs.pc);
		regs.pc++;

		addr = (hi << 8) | lo;
		addr += regs.y;

		if ((addr & 0xFF00) != (hi << 8)) {
			return true;
		}
		return false;
	}

	function ind() {
		var lo = read(regs.pc);
		regs.pc++;
		var hi = read(regs.pc);
		regs.pc++;

		var ptr = (hi << 8) | lo;

		if (lo == 0x00fff) {
			addr = (read(ptr & 0xFF00) << 8) | read(ptr + 0);
		} else {
			addr = (read(ptr + 1) << 8) | read(ptr + 0);
		}
		return false;
	}

	function izx() {
		var t = read(regs.pc);
		regs.pc++;

		var lo = read((t + regs.x) & 0xFF);
		var hi = read((t + regs.x + 1) & 0xFF);

		addr = (hi << 8) | lo;
		return false;
	}

	function izy() {
		var t = read(regs.pc);
		regs.pc++;

		var lo = read(t & 0xFF);
		var hi = read((t + 1) & 0xFF);

		addr = (hi << 8) | lo;
		addr += regs.y;

		if ((addr & 0xFF00) != (hi << 8)) {
			return true;
		}
		return false;
	}

	// ---- Opcode ops

	/**
		add with carry
	**/
	function adc() {
		fetch();

		cache = regs.a + data + carry;

		carry = cache > 255 ? 1 : 0;
		zero = (cache & 0xff) == 0 ? 1 : 0;
		ovflow = ((~(regs.a ^ data) & (regs.a ^ cache)) & 0x80) == 0 ? 0 : 1;
		negative = ((cache & 0x80) == 0) ? 0 : 1;

		regs.a = cache & 0xff;

		return true;
	}

	/**
		and with accumulator
	**/
	function and() {
		fetch();
		regs.a = regs.a & data;
		zero = regs.a == 0 ? 0 : 1;
		negative = (regs.a & 0x80) == 0 ? 0 : 1;
		return true;
	}

	/**
		arithmetic shift left
	**/
	function asl() {
		fetch();
		cache = data << 1;
		carry = (cache & 0xff00) > 0 ? 1 : 0;
		zero = (cache & 0xff);
		negative = (cache & 0x80) == 0 ? 0 : 1;
		if (this.opTable.get(currentOpcode).addressingFunction == this.imp) {
			regs.a = cache & 0xFF;
		} else {
			write(addr, cache & 0xFF);
		}
		return false;
	}

	/**
		branch on carry clear
	**/
	function bcc() {
		if (carry == 0) {
			this.remainingCycle++;
			addr = regs.pc + relAddr;

			if ((relAddr * 0xFF00) != (regs.pc & 0xFF00))
				this.remainingCycle++;

			regs.pc = addr;
		}
		return false;
	}

	/**
		branch on carry set
	**/
	function bcs() {
		if (carry == 1) {
			this.remainingCycle++;
			addr = regs.pc + relAddr;

			if ((relAddr * 0xFF00) != (regs.pc & 0xFF00))
				this.remainingCycle++;

			regs.pc = addr;
		}
		return false;
	}

	/**
		branch on equal (zero set)
	**/
	function beq() {
		if (carry == 0) {
			this.remainingCycle++;
			addr = regs.pc + relAddr;

			if ((relAddr * 0xFF00) != (regs.pc & 0xFF00))
				this.remainingCycle++;

			regs.pc = addr;
		}
		return false;
	}

	/**
		bit test
	**/
	function bit() {
		fetch();
		cache = regs.a & data;
		zero = (cache & 0xff) == 0 ? 1 : 0;
		negative = data > 0x7F ? 1 : 0;
		ovflow = data > 0x39 ? 1 : 0;
		return false;
	}

	/**
		branch on minus (negative set)
	**/
	function bmi() {
		if (negative == 1) {
			this.remainingCycle++;
			addr = regs.pc + relAddr;

			if ((relAddr * 0xFF00) != (regs.pc & 0xFF00))
				this.remainingCycle++;

			regs.pc = addr;
		}
		return false;
	}

	/**
		branch on not equal (zero clear)
	**/
	function bne() {
		if (zero == 0) {
			this.remainingCycle++;
			addr = regs.pc + relAddr;

			if ((relAddr * 0xFF00) != (regs.pc & 0xFF00))
				this.remainingCycle++;

			regs.pc = addr;
		}
		return false;
	}

	/**
		branch on plus (negative clear)
	**/
	function bpl() {
		if (negative == 0) {
			this.remainingCycle++;
			addr = regs.pc + relAddr;

			if ((relAddr * 0xFF00) != (regs.pc & 0xFF00))
				this.remainingCycle++;

			regs.pc = addr;
		}
		return false;
	}

	/**
		break
	**/
	function brk() {
		regs.pc++;

		int = 1;
		write(0x0100 + regs.s, (regs.pc >> 8) & 0xFF);
		regs.s--;
		write(0x100 + regs.s, regs.pc & 0xFF);
		regs.s--;

		brek = 1;
		write(0x100 + regs.s, regs.p);
		regs.s--;
		brek = 0;
		regs.pc = read(0xfffe) | (read(0xffff) << 8);
		return false;
	}

	/**
		branch on overflow clear
	**/
	function bvc() {
		if (ovflow == 0) {
			this.remainingCycle++;
			addr = regs.pc + relAddr;

			if ((relAddr * 0xFF00) != (regs.pc & 0xFF00))
				this.remainingCycle++;

			regs.pc = addr;
		}
		return false;
	}

	/**
		branch on overflow set
	**/
	function bvs() {
		if (ovflow == 1) {
			this.remainingCycle++;
			addr = regs.pc + relAddr;

			if ((relAddr * 0xFF00) != (regs.pc & 0xFF00))
				this.remainingCycle++;

			regs.pc = addr;
		}
		return false;
	}

	/**
		clear carry
	**/
	function clc() {
		carry = 0;
		return false;
	}

	/**
		clear decimal
	**/
	function cld() {
		decm = 0;
		return false;
	}

	/**
		clear interrupt disable
	**/
	function cli() {
		int = 0;
		return false;
	}

	/**
		clear overflow
	**/
	function clv() {
		ovflow = 0;
		return false;
	}

	/**
		compare with accumulator
	**/
	function cmp() {
		fetch();
		cache = regs.a - data;
		carry = regs.a >= data ? 1 : 0;
		zero = (cache & 0xff) == 0 ? 1 : 0;
		negative = (cache & 0x80) != 0 ? 1 : 0;
		return true;
	}

	/**
		compare with x
	**/
	function cpx() {
		fetch();
		cache = regs.x - data;
		carry = regs.x >= data ? 1 : 0;
		zero = (cache & 0xff) == 0 ? 1 : 0;
		negative = (cache & 0x80) != 0 ? 1 : 0;
		return true;
	}

	/**
		compare with y
	**/
	function cpy() {
		fetch();
		cache = regs.y - data;
		carry = regs.y >= data ? 1 : 0;
		zero = (cache & 0xff) == 0 ? 1 : 0;
		negative = (cache & 0x80) != 0 ? 1 : 0;
		return true;
	}

	/**
		decrement
	**/
	function dec() {
		fetch();
		cache = data - 1;
		write(addr, cache & 0xff);
		zero = (cache & 0xff) == 0 ? 1 : 0;
		negative = (cache & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		decrement x
	**/
	function dex() {
		regs.x--;
		zero = regs.x == 0 ? 1 : 0;
		negative = (regs.x & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		decrement y
	**/
	function dey() {
		regs.y--;
		zero = regs.y == 0 ? 1 : 0;
		negative = (regs.y & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		exclusive or accumulator
	**/
	function eor() {
		fetch();
		regs.a ^= data;
		zero = regs.a == 0 ? 1 : 0;
		negative = (regs.a & 0x80) != 0 ? 1 : 0;
		return true;
	}

	/**
		increment
	**/
	function inc() {
		fetch();
		cache = data + 1;
		write(addr, cache & 0xff);
		zero = (cache & 0xff) == 0 ? 1 : 0;
		negative = (cache & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		increment x
	**/
	function inx() {
		regs.x++;
		zero = regs.x == 0 ? 1 : 0;
		negative = (regs.x & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		increment y
	**/
	function iny() {
		regs.y++;
		zero = regs.x == 0 ? 1 : 0;
		negative = (regs.x & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		jump
	**/
	function jmp() {
		regs.pc = addr;
		return false;
	}

	/**
		jump subroutine	
	**/
	function jsr() {
		regs.pc--;

		write(0x100 + regs.s, (regs.pc >> 8) & 0xff);
		regs.s--;
		write(0x100 + regs.s, regs.pc & 0xff);

		regs.pc = addr;
		return false;
	}

	/**
		load accumulator
	**/
	function lda() {
		fetch();
		regs.a = data;
		zero = regs.a == 0 ? 1 : 0;
		negative = (regs.a & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		load x
	**/
	function ldx() {
		fetch();
		regs.x = data;
		zero = regs.x == 0 ? 1 : 0;
		negative = (regs.x & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		load y
	**/
	function ldy() {
		fetch();
		regs.y = data;
		zero = regs.y == 0 ? 1 : 0;
		negative = (regs.y & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		logical shift right
	**/
	function lsr() {
		fetch();
		carry = (data & 1);
		cache = data >> 1;
		zero = ((cache & 0xff) == 0) ? 1 : 0;
		negative = ((cache & 0x80) != 0) ? 1 : 0;
		if (this.opTable.get(currentOpcode).addressingFunction == this.imp) {
			regs.a = cache & 0xff;
		} else {
			write(addr, cache & 0xff);
		}
		return false;
	}

	/**
		no operation
	**/
	function nop() {
		switch (currentOpcode) {
			case 0x1C:
				return true;
			case 0x3C:
				return true;
			case 0x5C:
				return true;
			case 0x7C:
				return true;
			case 0xDC:
				return true;
			case 0xFC:
				return true;
			default:
				return false;
		}
	}

	/**
		or with accumulator
	**/
	function ora() {
		fetch();
		regs.a |= data;
		zero = regs.a == 0 ? 1 : 0;
		negative = (regs.a & 0x80) != 0 ? 1 : 0;
		return true;
	}

	/**
		push accumulator
	**/
	function pha() {
		write(0x100 + regs.s, regs.a);
		regs.s--;
		return false;
	}

	/**
		push processor status
	**/
	function php() {
		write(0x100 + regs.s, regs.p | 16 | 32);
		brek = 0;
		unus = 0;
		regs.s--;
		return false;
	}

	/**
		pull accumulator
	**/
	function pla() {
		regs.s++;
		regs.a = read(0x100 + regs.s);
		zero = (regs.a == 0) ? 1 : 0;
		negative = (regs.a & 0x80) != 0 ? 1 : 0;
		return false;
	}

	/**
		pull processor status
	**/
	function plp() {
		regs.s++;
		regs.p = read(0x100 + regs.s);
		unus = 1;
		return false;
	}

	/**
		rotate left
	**/
	function rol() {
		fetch();
		cache = data << 1 | carry;
		carry = cache & 0xff00;
		zero = (cache & 0xff) == 0 ? 1 : 0;
		negative = (cache & 0x80);

		if (this.opTable.get(currentOpcode).addressingFunction == this.imp) {
			regs.a = cache & 0xff;
		} else {
			write(addr, cache & 0xff);
		}
		return false;
	}

	/**
		rotate right
	**/
	function ror() {
		fetch();
		cache = carry << 7 | data >> 1;
		carry = data & 0x1;
		zero = (data & 0xff) == 0 ? 1 : 0;
		negative = (data & 0x80);
		if (this.opTable.get(currentOpcode).addressingFunction == this.imp) {
			regs.a = cache & 0xff;
		} else {
			write(addr, cache & 0xff);
		}

		return false;
	}

	/**
		return from interrupt
	**/
	function rti() {
		regs.s++;
		regs.p = read(0x100 + regs.s);
		regs.p &= (~16);
		regs.p &= (~32);
		regs.s++;
		regs.pc = read(0x100 + regs.s);
		regs.s++;
		regs.pc |= read(0x100 + regs.s) << 8;

		return false;
	}

	/**
		return from subroutine
	**/
	function rts() {
		regs.s++;
		regs.pc = read(0x100 + regs.s);
		regs.s++;
		regs.pc |= read(0x100 + regs.s) << 8;
		regs.pc++;
		return false;
	}

	/**
		substract with carry
	**/
	function sbc() {
		fetch();
		var val = data ^ 0xff;

		cache = regs.a + val + carry;
		carry = cache & 0xff00;
		zero = (cache & 0xff) == 0 ? 1 : 0;
		ovflow = (cache ^ regs.a) & (cache ^ val) & 0x80;
		negative = cache & 0x80;
		regs.a = cache & 0xff;
		return true;
	}

	/**
		set carry
	**/
	function sec() {
		carry = 1;
		return false;
	}

	/**
		set decimal
	**/
	function sed() {
		decm = 1;
		return false;
	}

	/**
		set interrupt disable
	**/
	function sei() {
		int = 1;
		return false;
	}

	/**
		store accumulator
	**/
	function sta() {
		write(addr, regs.a);
		return false;
	}

	/**
		store x
	**/
	function stx() {
		write(addr, regs.x);
		return false;
	}

	/**
		store y
	**/
	function sty() {
		write(addr, regs.y);
		return false;
	}

	/**
		transfer a to x
	**/
	function tax() {
		regs.x = regs.a;
		zero = regs.x == 0 ? 1 : 0;
		negative = regs.x & 0x80;
		return false;
	}

	/**
		transfer a to y
	**/
	function tay() {
		regs.y = regs.a;
		zero = regs.y == 0 ? 1 : 0;
		negative = regs.y & 0x80;
		return false;
	}

	/**
		transfer stack pointer to x
	**/
	function tsx() {
		regs.x = regs.s;
		zero = regs.x == 0 ? 1 : 0;
		negative = regs.x & 0x80;
		return false;
	}

	/**
		transfer x to a
	**/
	function txa() {
		regs.a = regs.x;
		zero = regs.a == 0 ? 1 : 0;
		negative = regs.a & 0x80;
		return false;
	}

	/**
		transfer x to stack pointer
	**/
	function txs() {
		regs.s = regs.x;
		return false;
	}

	/**
		transfer y to a
	**/
	function tya() {
		regs.a = regs.y;
		zero = regs.a == 0 ? 1 : 0;
		negative = regs.a & 0x80;
		return false;
	}
}
