simulate-gpgpu
==============
This is the script source code for simulating the spatial multitasking gpgpu-sim.

File descriptions:
benchmarks/*                    Several benchmarks for testing
random_benchmarks.rb            generate the testcase(file "testcase") from the benchmark pool (file "benchmarks.txt") 
                                and run "test.sh" to simulate the testcase
test.sh                         Take the "testcase" as input, simulate the testcase by remap the resource (number of SM) 
                                for each application, generate "in.txt", and call "sim2.rb" to simulate. And calculate 
                                the result.
                                Written by Shiwei, Modified by Jiang km.
sim2.rb                         After each remap of the resource, configure the gpgpu-sim according to "in.txt" and 
                                launch one gpgpu-sim for each application(currently single thread, maybe multi-thread 
                                later). 
config_fermi_islip.icnt         icnt config file for gpgpu-sim, please refer to the manual of gpgpu-sim
gpgpusim.config                 gpgpusim config file for gpgpu-sim, please refer the manulal of gpgpu-sim



