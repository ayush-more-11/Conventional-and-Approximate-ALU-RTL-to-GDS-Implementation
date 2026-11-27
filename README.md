# 8-bit ALU vs. Approximate ALU — RTL, Simulation and Genus Synthesis

Two 8-bit synchronous ALUs, an exact baseline (`alu`) and an approximate variant (`approx_alu`), taken through RTL simulation (baseline only) and logic synthesis with Cadence Genus. Every file in this repository is an unmodified original from the project archive. This README and `MANIFEST.md` are the only added files.

> **Evidence scope.** All results below come from files in this repository. Anything not backed by a file is marked **not available** or **unverified**. See [Verification status](#verification-status).

## Designs

Both designs share one interface: `clk`, active-low asynchronous reset `rst_n`, operands `A[7:0]` and `B[7:0]`, select `ALU_Sel[2:0]`, registered outputs `ALU_Out[7:0]` and `CarryOut`.

| `ALU_Sel` | `alu` (exact) | `approx_alu` |
|---|---|---|
| `000` | A + B, 9-bit result, carry out | **Approximate:** bits [7:2] exact add, bits [1:0] = `A[1:0] \| B[1:0]`; `CarryOut` = carry of the upper 6-bit add; no carry from the lower 2 bits into the upper add |
| `001` | A − B, borrow in `CarryOut` | **Approximate:** bits [7:2] exact subtract, bits [1:0] = `A[1:0] ^ B[1:0]`; `CarryOut` = borrow of the upper 6-bit subtract |
| `010` | A × B, low 8 bits | Same as `alu` |
| `011` | A & B | Same |
| `100` | A \| B | Same |
| `101` | A ^ B | Same |
| `110` | Shift left by 1, `CarryOut` = `A[7]` | Same |
| `111` | `A > B` → 1 else 0 | Same |

## Repository layout

```
rtl/            alu.v, approx_alu.v
tb/             alu_tb.v, approx_alu_tb.v
constraints/    alu.sdc                        (used by both synthesis runs; files are byte-identical)
simulation/
  normal_alu/   irun.log, waves.shm/           (Cadence irun / SimVision)
synthesis/
  normal_alu/   scripts/ logs/ reports/ netlist/
  approx_alu/   scripts/ logs/ reports/ netlist/
docs/images/
  simulation/   console + waveform screenshots (baseline ALU)
  synthesis/    Genus timing terminal captures, gate-level schematics
MANIFEST.md     what was kept, what was excluded and why, SHA-256 of every kept file
```

## Verification status

| Item | `alu` | `approx_alu` |
|---|---|---|
| Testbench present | Yes, 13 directed tests (`tb/alu_tb.v`) | Yes, 37 directed tests plus a reset check (`tb/approx_alu_tb.v`) |
| Simulation log / waveform in archive | **Yes.** `simulation/normal_alu/irun.log` reports `VERIFICATION SUMMARY: 13 Passed, 0 Failed`, `$finish` at 290 NS. Screenshots in `docs/images/simulation/`. | **No.** No log, waveform or screenshot of an `approx_alu` simulation exists in the archive. Pass/fail is **unverified**. |
| Genus synthesis | Completed, `Error=0` (`genus.log1`) | Completed, `Error=0` (`genus.log`) |
| Setup timing | Worst reported path met | Worst reported path met |
| Hold timing, DRC, formal equivalence, place and route, gate-level simulation with the SDF | **Not available** in the archive | **Not available** |
| Approximation error metrics (error rate, MED, etc.) | n/a | **Not available.** Only hand-written expected values inside the testbench. |

The baseline testbench is directed, with 13 vectors covering each of the 8 operations at least once. No coverage report is present, so no coverage figure is claimed.

## Synthesis results (Cadence Genus 21.14-s082_1)

Setup from `rc_script.tcl` and `constraints/alu.sdc`: library `slow.lib` located at `/home/install/FOUNDRY/digital/90nm/dig/lib` (the library itself is **not** in the archive; the 90 nm label comes from that path only). Operating conditions are reported as `slow (balanced_tree)`. Clock 10.0 ns (100 MHz), clock transition 0.1 ns, uncertainty 0.01 ns, input and output delays 1.0 ns.

| Metric | `alu` | `approx_alu` | Difference (approx − exact) | Source |
|---|---|---|---|---|
| Cell count | 240 | 218 | −22 (−9.17 %) | `*_cell.rep` |
| Total cell area | 1382.099 | 1302.625 | −79.474 (−5.75 %) | `*_cell.rep` |
| Leakage power (W) | 5.73318e-06 | 5.40602e-06 | −5.71 % | `*_power.rep` |
| Internal power (W) | 4.62236e-05 | 4.38054e-05 | −5.23 % | `*_power.rep` |
| Switching power (W) | 1.52620e-05 | 1.40491e-05 | −7.95 % | `*_power.rep` |
| Total power (W) | 6.72187e-05 | 6.32606e-05 | −5.89 % | `*_power.rep` |
| Worst setup slack (ps) | 6747 | 6581 | −166 (−2.46 %) | `*_timing.rep` |
| Worst path data delay (ps) | 2172 | 2338 | +166 (+7.64 %) | `*_timing.rep` |

The Difference column was computed from the reported values. Area units are as printed by Genus; the report does not state a unit.

Notes on interpretation:

- The worst setup path in both designs runs through the multiplier (`mul_15_34_*` in `alu`, `mul_34_33_*` in `approx_alu`) to `ALU_Out_reg[6]/D`. The approximate adder and subtractor are therefore not on the reported critical path, and the approximate design shows lower slack, not higher.
- Only the worst setup path (`report_timing` default) is in the archive. Slack on other paths is not available.
- Power reports cite `PDB Frames: /stim#0/frame#0`. No VCD or SAIF file is in the archive, so treat these as tool estimates, not measurements of the simulated workload. The `approx_alu` subtotal row prints `100.01 %` in the original report; this is a rounding artifact in the tool output and was left untouched.
- All numbers in the table come from the `.rep` files. Screenshots are supporting evidence only.

## Reproducing the flow

Tool versions seen in the logs: Cadence irun 15.20-s086 (simulation) and Genus 21.14-s082_1 (synthesis). Neither tool nor the `slow.lib` library is included, and this repository was **not** re-run in preparing it. The commands below are untested here.

The original scripts used relative file names, so stage the files in one working directory first:

```bash
# Exact ALU synthesis
mkdir work_alu && cd work_alu
cp ../rtl/alu.v ../constraints/alu.sdc ../synthesis/normal_alu/scripts/rc_script.tcl .
genus            # then at the prompt: source rc_script.tcl

# Approximate ALU synthesis
mkdir work_approx && cd work_approx
cp ../rtl/approx_alu.v ../constraints/alu.sdc ../synthesis/approx_alu/scripts/rc_script.tcl .
genus            # then at the prompt: source rc_script.tcl
```

Simulation (baseline), as recorded in `simulation/normal_alu/irun.log`:

```bash
irun alu.v alu_tb.v -access +rwc -gui
```

Edit `set_db lib_search_path` in `rc_script.tcl` to point at your own library location.

## File notes

- `synthesis/normal_alu/logs/genus.log1` and `scripts/genus.cmd1` belong to the successful run. An earlier failed run (it called the removed `synthesize` command, error `SYNTH-29`) was excluded.
- `synthesis/normal_alu/netlist/alu_sdc.sdc` and `synthesis/approx_alu/netlist/approx_alu_sdc.sdc` are the SDC files exported by Genus, not the input constraints.
- `rc_script.tcl` ends with `gui_show`, which needs a display.
- The header comment in `rtl/approx_alu.v` names Innovus and Vivado as target tools. No Innovus or Vivado output exists in the archive.
- File names such as `genus.log1` and `genus.cmd1` are original names and were not changed.
- `docs/images/synthesis/Genus_approx_alu_gui_schematic.gif` is labeled by its original file name; the GIF itself carries no design name.

## Authorship and license

Not specified in the archive. Add author and license information before publishing.
