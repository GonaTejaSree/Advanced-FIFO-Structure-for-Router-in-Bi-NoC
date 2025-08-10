  Write Interface                  Read Interface
  ---------------                  --------------
  write_en   ---> [Write Pointer]                 [Read Pointer] <--- read_en
  data_in    ---> [ Data Array ] ---> Output Mux ---> data_out
                           ^                           |
                           |<--- Bypass Path ---------|
