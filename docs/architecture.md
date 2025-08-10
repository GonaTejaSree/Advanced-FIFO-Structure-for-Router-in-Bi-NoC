- **Memory**: Dual-port RAM or register array.
- **Pointers**: Binary counters for indexing, Gray-coded for crossing.
- **Synchronizers**: Two-stage flip-flops for safe transfer of Gray pointers between domains.

---

## 5. Pointer Logic
- **Write pointer increment**: `(wr_ptr_bin + 1) % DEPTH`
- **Read pointer increment**: `(rd_ptr_bin + 1) % DEPTH`
- **Gray conversion**:  
  ```verilog
  assign wr_ptr_gray = (wr_ptr_bin >> 1) ^ wr_ptr_bin;
