#!/bin/bash

MAX_CPU_USAGE=90 # maximum CPU usage
CHECK_INTERVAL=60 # check interval = 60s

for set in {0..3} # for each individual
do  
  while true
  do
      # Get idle CPU percentage, ensuring numeric locale for dot decimal separator
      cpu_idle_raw=$(LC_NUMERIC=C top -bn1 | grep "Cpu(s)" | awk '{print $8}')
      current_jobs=$(ps aux | grep -E "tumor_growth_case" | grep -v grep | wc -l) # current number of 'tumor_growth_case' jobs

      # Check if cpu_idle_raw is a valid number
      if [[ "$cpu_idle_raw" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
          cpu_usage=$(echo "100 - $cpu_idle_raw" | bc -l)
          echo "current CPU usage: ${cpu_usage}% current number of jobs: $current_jobs"

          # bc returns 1 for true, 0 for false. Test this directly.
          comparison_result=$(echo "$cpu_usage < $MAX_CPU_USAGE" | bc -l)
          if [[ "$comparison_result" -eq 1 ]]; then
              break # Exit while loop, CPU usage is acceptable
          fi
      else
          cpu_usage="Error" # Indicate an error in getting CPU usage
          echo "current CPU usage: ${cpu_usage}% current number of jobs: $current_jobs"
          echo "Warning: Could not parse CPU idle percentage: '$cpu_idle_raw'. Waiting before retry."
      fi

      sleep $CHECK_INTERVAL
  done     
  echo "current CPU usage: ${cpu_usage}% current number of jobs: $current_jobs"
  
  # start tumor_growth_case jobs 
  nohup ./bin/tumor_growth_case tumor_growth_case_output $set 1 200 0 &
  
  # ./bin/tumor_growth_case \          # path to the executable file for MSABM tumor growth case
  # tumor_growth_case_output \         # output folder name to store the population results (argv[1])
  # $set \                             # output set name to store each individual results (argv[2])
  # 1 \                                # number of simulations for an individual (argv[3])
  # 200 \                              # simulation time 200 days (argv[4])
  # 0                                  # whether to enable randomness for the key parameters, 1 for enable and 0 for disable (argv[5])
done

