@everywhere using DrWatson                                                      
@everywhere quickactivate("/home/mvanega1/SpatialRust/", "SpatialRust")         
                                                                                
                                                                                
@everywhere using Agents, CSV, DataFrames, Distributed, Random, StatsBase, Statistics
                                                                                
@everywhere include(srcdir("FarmInit.jl"))                                     
@everywhere include(srcdir("ABMsim.jl"))                                       
@everywhere include(srcdir("OneFarm.jl"))                                      
@everywhere include(srcdir("AddToAgents.jl"))                                  
@everywhere include(srcdir("ReportFncts.jl"))                                  
                                                                                
pmap(i -> println("I'm worker $(myid()), working on i=$i"), 1:10)               
                                                                                
@everywhere printsquare(i) = println("working on i=$i: its square it $(i^2)")   
@sync @distributed for i in 1:10                                                
  printsquare(i)                                                                
end    


#      From worker 2:    I'm worker 2, working on i=1                            
#       From worker 3:    I'm worker 3, working on i=2                            
#       From worker 5:    I'm worker 5, working on i=3                            
#       From worker 4:    I'm worker 4, working on i=4                            
#       From worker 2:    I'm worker 2, working on i=6                            
#       From worker 3:    I'm worker 3, working on i=5                            
#       From worker 3:    I'm worker 3, working on i=7                            
#       From worker 2:    I'm worker 2, working on i=8                            
#       From worker 3:    I'm worker 3, working on i=9                            
#       From worker 2:    I'm worker 2, working on i=10                           
#       From worker 2:    working on i=1: its square it 1                         
#       From worker 2:    working on i=2: its square it 4                         
#       From worker 2:    working on i=3: its square it 9                         
#       From worker 3:    working on i=4: its square it 16                        
#       From worker 3:    working on i=5: its square it 25                        
#       From worker 3:    working on i=6: its square it 36                        
#       From worker 5:    working on i=9: its square it 81                        
#       From worker 5:    working on i=10: its square it 100                      
#       From worker 4:    working on i=7: its square it 49                        
#       From worker 4:    working on i=8: its square it 64