#i bin/ruby

$max_sim=15
$max_l2_clocks=700.0

class BenchmarkRecord
    attr_accessor :id,:path,:num_sm,:inst_ct
    def initialize(id,path,num_sm,inst_ct)
        @id=id
        @path=path
        @num_sm=num_sm
        @inst_ct=inst_ct
    end
end

def readfile(fileName)
    #fd=IO.sysopen(fileName)
    #fileReader=IO.new(fd)
    #num=fileReader.gets(" \n").chomp.chomp
    benchmarks=Array.new
    num_ben=0
    num_cycle=0
    File.open(fileName,"r") do |file|
        num_cycle=file.gets("\n").chomp.to_i
        num_ben=file.gets("\n").chomp.to_i
        num_ben.times {
            id=file.gets(" ").chomp.to_i
            path=file.gets(" ").chomp
            num_sm=file.gets(" ").chomp.to_i
            inst_ct=file.gets("\n").chomp.to_i
            b=BenchmarkRecord.new(id,path,num_sm,inst_ct)
            benchmarks << b 
        } 
    end 
    [num_cycle,benchmarks]
end

def simulate(num_cycle,benchmarks)
    result_array=[]  
    terminate_benchmarks=[]
    min_sim_cycle=num_cycle
    benchmarks.each do |b|
        sim_cycle=0
        File.open("sim_config.txt","w") do |config_file|
            config_file.puts(num_cycle) 
            config_file.puts(b.inst_ct)
        end
        #File.open("gpgpusim.config","w") do |gpu_config_file|
        #  gpu_config_file.
        #end

        `sed -i "s/-gpgpu_n_clusters [0-9]*/-gpgpu_n_clusters #{b.num_sm}/g" gpgpusim.config`
        line_array=`grep "gpgpu_clock_domains [0-9]" gpgpusim.config`.split(' ')
        clocks_array=line_array[1].split(':')
        clocks_array[2]=($max_l2_clocks*b.num_sm/$max_sim).to_s
        line_array[1]=clocks_array.join(':')
        `sed -i  "s/-gpgpu_clock_domains [0-9].*$/#{line_array.join(' ')}/g" gpgpusim.config`

        `#{b.path}`#>> tmp.txt`

        File.open("sim_out.txt","r") do |sim_out_file|
            sim_cycle=sim_out_file.gets("\n").chomp.to_i
            sim_inst_ct=sim_out_file.gets("\n").chomp.to_i
            result_array << sim_inst_ct
        end
        if sim_cycle < min_sim_cycle
            min_sim_cycle=sim_cycle
            terminate_benchmarks=[]
            terminate_benchmarks << b.id
        elsif sim_cycle==min_sim_cycle && min_sim_cycle<num_cycle
            terminate_benchmarks << b.id
        end
    end  

    if terminate_benchmarks.empty?
        benchmarks.each do |b|
            b.inst_ct=result_array.shift
        end
        return [min_sim_cycle,benchmarks]
    end

    benchmarks.each do |b|
        File.open("sim_config.txt","w") do |config_file|
            config_file.puts(min_sim_cycle) 
            config_file.puts(b.inst_ct)
        end
        `#{b.path}`
        File.open("sim_out.txt","r") do |sim_out_file|
            sim_cycle=sim_out_file.gets("\n").chomp.to_i
            sim_inst_ct=sim_out_file.gets("\n").chomp.to_i
            if terminate_benchmarks.include?(b.id)
                b.inst_ct=-1
            else 
                b.inst_ct=sim_inst_ct
            end
        end
    end  
    [min_sim_cycle,benchmarks]
end

read_result=readfile("in.txt")
sim_result=simulate(*read_result)
p sim_result[0]
sim_result[1].each do |b|
    print "#{b.id} #{b.inst_ct}\n"
end
