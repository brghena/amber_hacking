
The design files are located at
/home/brghena/workspace/amber/trunk/hw/vlog/xs6_ddr3:

   - ddr3.veo:
        veo template file containing code that can be used as a model
        for instantiating a CORE Generator module in a HDL design.

   - ddr3.xco:
       CORE Generator input file containing the parameters used to
       regenerate a core.

   - ddr3_flist.txt:
        Text file listing all of the output files produced when a customized
        core was generated in the CORE Generator.

   - ddr3_readme.txt:
        Text file indicating the files generated and how they are used.

   - ddr3_xmdf.tcl:
        ISE Project Navigator interface file. ISE uses this file to determine
        how the files output by CORE Generator for the core can be integrated
        into your ISE project.

   - ddr3.gise and ddr3.xise:
        ISE Project Navigator support files. These are generated files and
        should not be edited directly.

   - ddr3 directory.

In the ddr3 directory, three folders are created:
   - docs:
        This folder contains Virtex-6 FPGA Memory Interface Solutions user guide
        and data sheet.

   - example_design:
        This folder includes the design with synthesizable test bench.

   - user_design:
        This folder includes the design without test bench modules.

The example_design and user_design folders contain several other folders
and files. All these output folders are discussed in more detail in
Spartan-6 FPGA Memory Controller user guide (ug388.pdf) located in docs folder.
    