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

def cal_next_sim_cycle(sim_cycle,benchmarks,terminate_flags)

end

def get_running(sim_cycle,benchmarks,terminate_flags)
end

def main()
    testcase=readfile("testcase")
    benchmarks=testcase.benchmarks
    sim_cycle=0
    max_sim_cycle=testcase.max_sim_cycle
    running_benchmarks_is=[]
    num_benchmarks=testcase.benchmarks.size
    terminate_flags=Array.new(num_benchmarks) {|i| false}
    old_num_sms_array=Array.new(num_benchmarks) {|i| 0}
    inst_counts=Array.new(num_benchmarks) {|i| 0}
    new_num_sms_array=[]

    while sim_cycle<max_sim_cycle && terminate_flags.include?(false)
        next_sim_cycle=cal_next_sim_cycle()
        running_benchmarks_is=get_running()
        new_num_sms_array=cal_num_sms()
        File.open("in.txt","w") do |file|
            file.puts(next_sim_cycle-sim_cycle)
            file.puts(num_benchmarks)
            running_benchmarks_is.each do |i|
                b=benchmarks[i]
                file.puts("#{i} #{b.path} #{new_num_sms_array[i]} #{inst_counts}")
            end 
        end
        `ruby sim2.rb >> out.txt`
        File.open("out.txt","r") do |file|
            new_sim_cycle=file.gets("\n").chomp("\n").to_i
            sim_cycle=new_sim_cycle
            running_benchmarks_is.size.times do 
                i=file.gets(" ").chomp(" ").to_i
                inst_counts[i]=file.gets("\n").chomp("\n").to_i
                if inst_counts[i]==-1
                    terminate_flags[i]=true
                end
            end
        end
    end
end

