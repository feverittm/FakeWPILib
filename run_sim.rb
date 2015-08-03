#!/usr/bin/ruby
require 'fileutils'
require 'mkmf'

has_code = File.exists?(ARGV[0])
has_sim_code = File.exists?(ARGV[1])
abort "Error: Robot code doesn't exist in project #{ARGV[0]}" unless has_code
abort "Error: Sim Robot code doesn't exist in project #{ARGV[0]}" unless has_sim_code
abort "Error: Ant not found. Try installing with 'brew install ant'." unless find_executable 'ant'

# First ARG is the main FRC code directory i.e. FRC-2015
frc_code = ARGV[0]

# Second ARG is the simulation jig / driver code
sim_code = ARGV[1]
has_sim = ARGV[1] != ".."

# Should have been launched in the 'Fake' directory
fakelib_dir = Dir.pwd

# compile robot code
Dir.chdir(frc_code)
FileUtils.touch Dir.glob('*.java')
system('ant.bat jar')

# compile fake wpi lib
Dir.chdir(fakelib_dir)
FileUtils.touch Dir.glob('*.java')
system('ant.bat jar')

# move fake wpi lib jar to sim robot dir
FileUtils.cp(fakelib_dir + "/dist/FakeWPILib.jar", sim_code + "/lib/") if has_sim
FileUtils.cp(ARGV[0]+ "/dist/FRCUserProgram.jar", sim_code + "/lib/") if has_sim

# compile simulation jig
Dir.chdir(sim_code)
FileUtils.touch Dir.glob('*.java');
system('ant.bat compile') if has_sim

# prep the fake library build
Dir.chdir(fakelib_dir)

# remove building tmp dirs
tmp_dir = Dir.pwd + "/tmp"
if File.exists?(tmp_dir)
then
	puts "Remove temporary directory " + tmp_dir
	FileUtils.remove_dir('tmp',force = true)
end

# copy robot jar
jar_file = ARGV[0] + "/dist/FRCUserProgram.jar"
Dir.mkdir(tmp_dir) unless File.exists?(tmp_dir)
FileUtils.cp jar_file, tmp_dir + "/FRCUserProgram.jar"

# make temp directories
Dir.chdir('tmp')
Dir.mkdir('classes')
Dir.chdir('classes')

# uncompress robot jar
`jar -xf ../FRCUserProgram.jar`
exit


FileUtils.cp "META-INF/MANIFEST.MF", "META-INF/MANIFEST.MF.old"

# copy compiled fake wpi lib
FileUtils.cp_r '../../bin', '.' 
FileUtils.cp "META-INF/MANIFEST.MF.old", "META-INF/MANIFEST.MF"
FileUtils.rm "META-INF/MANIFEST.MF.old"

# Copy sim robot class files
source = cur_dir + '/' + ARGV[1] + '/bin'
puts "Source Directory ="+source
FileUtils.cp_r source, '.' if has_sim
exit

# make test harness
Dir.chdir('..')
`jar -cmvf classes/META-INF/MANIFEST.MF to_sim.jar -C classes .`

# run test harness
system("java -jar to_sim.jar")

