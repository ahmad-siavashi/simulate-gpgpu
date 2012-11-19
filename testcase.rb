class Benchmark_info
    attr_accessor :path,:min_sm,:opt_sm,:coming_time
    def initialize(path,min_sm,opt_sm,coming_time)
        @path=path
        @min_sm=min_sm
        @opt_sm=opt_sm
        @coming_time=coming_time       
    end
end

class Testcase_info
    attr_accessor :max_sim_cycle,:benchmarks
    def initialize(max_sim_cycle,benchmarks)
        @max_sim_cycle=max_sim_cycle
        @benchmarks=benchmarks
    end
end

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
    max_sim_cycle=0
    num_benchmarks=0
    benchmarks=Array.new
    File.open(fileName,"r") do |f|
       sim_cycle=f.gets("\n").chomp.to_i
       num_benchmarks=f.gets("\n").chomp.to_i
       num_benchmarks.times do 
           path=f.gets(" ").chomp(" ")
           min_sm=f.gets(" ").chomp(" ").to_i
           opt_sm=f.gets(" ").chomp(" ").to_i
           coming_time=f.gets("\n").chomp.to_i
           benchmark=Benchmark_info.new(path,min_sm,opt_sm,coming_time)
           benchmarks << benchmark
       end
    end
    testcase = Testcase_info.new(max_sim_cycle,benchmarks)
    testcase
end

testcase=readfile("testcase")
