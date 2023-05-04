function write_array_script(popsize::Int, gen::Int, reps::Int, steps::Int, cprice::Float64, expfolder::String)
    fpath = joinpath(expfolder, "scripts/array-$gen.sh")
    write(fpath,"""
    #!/bin/bash
    #SBATCH --array=1-$popsize
    #SBATCH --ntasks-per-core=1
    #SBATCH --mem=1G
    #SBATCH --ntasks=1
    #SBATCH -p htc
    #SBATCH -q debug
    #SBATCH -J debug-GA-ind-$gen
    #SBATCH -t 0-00:15:00
    # #SBATCH -J GA-ind-$gen
    # #SBATCH -t 0-01:00:00
    #SBATCH -o logs/GA/g-%A.o
    #SBATCH -e logs/GA/g-%A.e
    #SBATCH --mail-type=ALL
    #SBATCH --mail-user=mvanega1@asu.edu

    module purge
    module load julia/1.8.2

    echo `date +%F-%T`
    echo $SLURM_JOB_ID
    julia ~/SpatialRust/scripts/GA/testIndividual.jl \
    $SLURM_ARRAY_TASK_ID $gen $reps $steps $cprice $expfolder
    """)
    return fpath
end

function write_ngen_script(popsize::Int, gen::Int, maxgens::Int, reps::Int, steps::Int, cprice::Float64, pcrs::Float64, pmut::Float64, expfolder::String)
    fpath = joinpath(expfolder, "scripts/newgen-$gen.sh")
    write(fpath,"""
    #!/bin/bash
    #SBATCH --ntasks-per-core=1
    #SBATCH --mem=1G
    #SBATCH --ntasks=1
    #SBATCH -p htc
    #SBATCH -q debug
    #SBATCH -J debug-GA-gen-$gen
    #SBATCH -t 0-00:15:00
    # #SBATCH -J GA-gen-$gen
    # #SBATCH -t 0-01:00:00
    #SBATCH -o logs/GA/g-%A.o
    #SBATCH -e logs/GA/g-%A.e
    #SBATCH --mail-type=ALL
    #SBATCH --mail-user=mvanega1@asu.edu

    module purge
    module load julia/1.8.2

    echo `date +%F-%T`
    julia ~/SpatialRust/scripts/GA/produceGeneration.jl \
    $popsize $gen $maxgens $reps $steps $cprice $pcrs $pmut $expfolder
    """)
    return fpath
end



