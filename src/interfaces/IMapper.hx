package interfaces;

interface IMapper {
	public function cpuMapRead(address:Int, mapperAddress:Dynamic):Bool;
	public function cpuMapWrite(address:Int, mapperAddress:Dynamic):Bool;
	public function ppuMapRead(address:Int, mapperAddress:Dynamic):Bool;
	public function ppuMapWrite(address:Int, mapperAddress:Dynamic):Bool;
}
