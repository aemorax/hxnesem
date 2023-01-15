package;

import model.Processor;

class Emulator {
	static function main() {
		var p:Processor = new Processor();
		p.carry = 1;
		p.negative = 1;
		trace(p.regs.p);
	}
}
