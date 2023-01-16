package model;

import sys.net.Address;
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
	var addressingFunction:Void->Void;
	var operationFunction:Void->Void;
}

class Processor {
	final opTable:Vector<Operation> = new Vector<Operation>(256);

	public var bus:Bus;
	public var regs:Registers;
	public var carry(get, set):Int;
	public var zero(get, set):Int;
	public var int(get, set):Int;
	public var decm(get, set):Int;
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

		this.opTable.set(0x00, {cycles: 7, addressingFunction: this.imp, operationFunction: this.brk});
		this.opTable.set(0x01, {cycles: 6, addressingFunction: this.izx, operationFunction: this.ora});
		this.opTable.set(0x05, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.ora});
		this.opTable.set(0x06, {cycles: 5, addressingFunction: this.zp0, operationFunction: this.asl});
		this.opTable.set(0x08, {cycles: 8, addressingFunction: this.imp, operationFunction: this.php});
		this.opTable.set(0x09, {cycles: 2, addressingFunction: this.imm, operationFunction: this.ora});
		this.opTable.set(0x0A, {cycles: 2, addressingFunction: this.imp, operationFunction: this.asl});
		this.opTable.set(0x0D, {cycles: 4, addressingFunction: this.abs, operationFunction: this.ora});
		this.opTable.set(0x0E, {cycles: 6, addressingFunction: this.abs, operationFunction: this.asl});

		this.opTable.set(0x10, {cycles: 2, addressingFunction: this.rel, operationFunction: this.bpl});
		this.opTable.set(0x11, {cycles: 5, addressingFunction: this.izy, operationFunction: this.ora});
		this.opTable.set(0x15, {cycles: 4, addressingFunction: this.zpx, operationFunction: this.ora});
		this.opTable.set(0x16, {cycles: 6, addressingFunction: this.zpx, operationFunction: this.asl});
		this.opTable.set(0x18, {cycles: 2, addressingFunction: this.imp, operationFunction: this.clc});
		this.opTable.set(0x19, {cycles: 4, addressingFunction: this.aby, operationFunction: this.ora});
		this.opTable.set(0x1D, {cycles: 4, addressingFunction: this.abx, operationFunction: this.ora});
		this.opTable.set(0x1E, {cycles: 7, addressingFunction: this.abx, operationFunction: this.asl});

		this.opTable.set(0x20, {cycles: 6, addressingFunction: this.abs, operationFunction: this.jsr});
		this.opTable.set(0x21, {cycles: 6, addressingFunction: this.izx, operationFunction: this.and});
		this.opTable.set(0x24, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.bit});
		this.opTable.set(0x25, {cycles: 3, addressingFunction: this.zp0, operationFunction: this.and});
		this.opTable.set(0x26, {cycles: 5, addressingFunction: this.zp0, operationFunction: this.rol});
		this.opTable.set(0x28, {cycles: 4, addressingFunction: this.imp, operationFunction: this.plp});
		this.opTable.set(0x29, {cycles: 2, addressingFunction: this.imm, operationFunction: this.and});
		this.opTable.set(0x2A, {cycles: 2, addressingFunction: this.imp, operationFunction: this.rol});
		this.opTable.set(0x2C, {cycles: 4, addressingFunction: this.abs, operationFunction: this.bit});
		this.opTable.set(0x2D, {cycles: 4, addressingFunction: this.abs, operationFunction: this.and});
		this.opTable.set(0x2E, {cycles: 6, addressingFunction: this.abs, operationFunction: this.rol});

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
	function imm() {}

	function imp() {}

	function zpx() {}

	function zpy() {}

	function zp0() {}

	function rel() {}

	function abs() {}

	function abx() {}

	function aby() {}

	function ind() {}

	function izx() {}

	function izy() {}

	// ---- Opcode ops

	/**
		add with carry
	**/
	function adc() {}

	/**
		and with accumulator
	**/
	function and() {}

	/**
		arithmetic shift left
	**/
	function asl() {}

	/**
		branch on carry clear
	**/
	function bcc() {}

	/**
		branch on carry set
	**/
	function bcs() {}

	/**
		branch on equal (zero set)
	**/
	function beq() {}

	/**
		bit test
	**/
	function bit() {}

	/**
		branch on minus (negative set)
	**/
	function bmi() {}

	/**
		branch on not equal (zero clear)
	**/
	function bne() {}

	/**
		branch on plus (negative clear)
	**/
	function bpl() {}

	/**
		break
	**/
	function brk() {}

	/**
		branch on overflow clear
	**/
	function bvc() {}

	/**
		branch on overflow set
	**/
	function bvs() {}

	/**
		clear carry
	**/
	function clc() {}

	/**
		clear decimal
	**/
	function cld() {}

	/**
		clear interrupt disable
	**/
	function cli() {}

	/**
		clear overflow
	**/
	function clv() {}

	/**
		compare with accumulator
	**/
	function cmp() {}

	/**
		compare with x
	**/
	function cpx() {}

	/**
		compare with y
	**/
	function cpy() {}

	/**
		decrement
	**/
	function dec() {}

	/**
		decrement x
	**/
	function dex() {}

	/**
		decrement y
	**/
	function dey() {}

	/**
		exclusive or accumulator
	**/
	function eor() {}

	/**
		increment
	**/
	function inc() {}

	/**
		increment x
	**/
	function inx() {}

	/**
		increment y
	**/
	function iny() {}

	/**
		jump
	**/
	function jmp() {}

	/**
		jump subroutine	
	**/
	function jsr() {}

	/**
		load accumulator
	**/
	function lda() {}

	/**
		load x
	**/
	function ldx() {}

	/**
		load y
	**/
	function ldy() {}

	/**
		logical shift right
	**/
	function lsr() {}

	/**
		no operation
	**/
	function nop() {}

	/**
		or with accumulator
	**/
	function ora() {}

	/**
		push accumulator
	**/
	function pha() {}

	/**
		push processor status
	**/
	function php() {}

	/**
		pull accumulator
	**/
	function pla() {}

	/**
		pull processor status
	**/
	function plp() {}

	/**
		rotate left
	**/
	function rol() {}

	/**
		rotate right
	**/
	function ror() {}

	/**
		return from interrupt
	**/
	function rti() {}

	/**
		return from subroutine
	**/
	function rts() {}

	/**
		substract with carry
	**/
	function sbc() {}

	/**
		set carry
	**/
	function sec() {}

	/**
		set decimal
	**/
	function sed() {}

	/**
		set interrupt disable
	**/
	function sei() {}

	/**
		store accumulator
	**/
	function sta() {}

	/**
		store x
	**/
	function stx() {}

	/**
		store y
	**/
	function sty() {}

	/**
		transfer a to x
	**/
	function tax() {}

	/**
		transfer a to y
	**/
	function tay() {}

	/**
		transfer stack pointer to x
	**/
	function tsx() {}

	/**
		transfer x to a
	**/
	function txa() {}

	/**
		transfer x to stack pointer
	**/
	function txs() {}

	/**
		transfer y to a
	**/
	function tya() {}
}
