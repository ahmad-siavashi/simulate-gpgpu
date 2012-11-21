
$min_weight=0.5
$max_weight=1.0
$max_coming_time=10000

class Benchmark
    attr_accessor :path,:num_blocks
    def initialize(path,num_blocks)
        @path=path
        @num_blocks=num_blocks
    end
end

class Benchmark_info
    attr_accessor :path,:min_sm,:opt_sm,:coming_time
    def initialize(path,min_sm,opt_sm,coming_time)
        @path=path
        @min_sm=min_sm
        @opt_sm=opt_sm
        @coming_time=coming_time
    end
end


class TestCase
    attr_accessor :benchmarks,:max_sim_cycle
    def initialize(benchmarks,num_benchmarks,max_sim_cycle)
        @benchmarks=[]
        @max_sim_cycle=max_sim_cycle
        num_benchmarks.times do
            i=rand(benchmarks.size)
            max_sm=benchmarks[i].num_blocks
            min_sm=rand(max_sm)
            if min_sm==0 
                min_sm=1
            end
            weight=rand*($max_weight-$min_weight)+$min_weight
            opt_sm=Integer(max_sm*weight)
            min_sm=Integer(min_sm*weight)
            benchmarks_case=Benchmark_info.new(benchmarks[i].path,min_sm,opt_sm,rand(max_sim_cycle/2))
            @benchmarks << benchmarks_case
        end
        @benchmarks.sort! {|a,b| a.coming_time <=> b.coming_time}
        @benchmarks[0].coming_time=0
    end
end

def readfile(fileName)
    benchmarks=Array.new
    num_ben=0
    File.open(fileName,"r") do |file|
        num_ben=file.gets("\n").chomp.to_i
        num_ben.times {
            path=file.gets(" ").chomp(" ")
            num_blocks=file.gets("\n").chomp.to_i
            b=Benchmark.new(path,num_blocks)
            benchmarks << b 
        } 
    end 
    benchmarks
end

def writefile(testcase,fileName)
    File.open(fileName,"w") do |file|
        file.puts(testcase.max_sim_cycle)
        file.puts(testcase.benchmarks.size)
        testcase.benchmarks.each do |b|
            file.puts("#{b.path} #{b.min_sm} #{b.opt_sm} #{b.coming_time}")
        end
    end
end

srand(0)
testcase=TestCase.new(readfile("benchmarks.txt"),4,5000)
writefile(testcase,"testcase")
print `./test.sh`
`rm _ptx*`
