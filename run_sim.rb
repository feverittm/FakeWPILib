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
puts "Compile FRC robot code..."
Dir.chdir(frc_code)
FileUtils.touch Dir.glob('*.java')
system('ant.bat jar')

# compile fake wpi lib
puts "Compile FakeWpilibj..."
Dir.chdir(fakelib_dir)
FileUtils.touch Dir.glob('*.java')
system('ant.bat jar')

# move fake wpi lib jar to sim robot dir
puts "Copy the jar dist/jar files into the sim directory..."
FileUtils.cp(fakelib_dir + "/dist/FakeWPILib.jar", sim_code + "/lib/") if has_sim
FileUtils.cp(frc_code + "/dist/FRCUserProgram.jar", sim_code + "/lib/") if has_sim

# compile simulation jig
puts "... now compile the simulation jig."
Dir.chdir(sim_code)
FileUtils.touch Dir.glob('*.java');
system('ant.bat compile') if has_sim

# prep the fake library build
Dir.chdir(sim_code)

# remove building tmp dirs
tmp_dir = Dir.pwd + "/tmp"
if File.exists?(tmp_dir)
then
	puts "Remove temporary build directory " + tmp_dir
	FileUtils.remove_dir('tmp',force = true)
end
Dir.mkdir(tmp_dir)
puts "new tmp build directory is " + tmp_dir

# copy robot jar
jar_file = frc_code + "/dist/FRCUserProgram.jar"
FileUtils.cp jar_file, tmp_dir + "/FRCUserProgram.jar"

# make temp directories
Dir.chdir(tmp_dir)
Dir.mkdir('classes')
Dir.chdir('classes')

# uncompress robot jar
puts 'unpack the FRC user code in the new build directory...'
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

