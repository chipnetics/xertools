# Primavera XER Tools

A repository of small utilities that will help in analyzing the project schedules (.xer files) output by the scheduling software "Oracle Primavera".

These command-line utilities can be ran manually, or integrated into an automated-process/work-flow.  In general these utilities follow the [UNIX philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) much as possible.

# Project Motivation

Small and nimble utilities for analyzing XER files can aid in quickly identifying changes, trends, or mistakes in project schedules; especially in large projects where manual data manipulation in Excel is too time consuming and error-prone.

The output from these utilities are intended to be useful for promoting discussions when looked upon in isolation; but can also be useful for embedding in data viz (BI tools) or importing into SQL databases.  

By default, these utilities will output only what's _relevant_.  What is meant by this, is that when output is used in BI tools or SQL, the output should be joined (as a table relationship) with other data sets to garner a complete perspective of the data.  However, as this may not always be sufficient for some users, the utility (where possible) will include the functionality to output a greater verbosity of data.

# Pre-Compiled Binaries

Binaries (.exe) for Windows OS have been pre-compiled and can be found in the 'bin' folder.

With git, you can download all the latest source and binaries with `git clone https://github.com/chipnetics/xertools`

Alternatively, if you don't have git installed:

1. Download the latest release [here](https://github.com/chipnetics/xertools/releases)
2. Unzip to a local directory.
3. Navigate to 'bin' directory for executables.

# Compiling from Source

Utilities are written in the V programming language and will compile under Windows, Linux, and MacOS.

V is syntactically similar to Go, while equally fast as C.  You can read about V [here](https://vlang.io/).

Each utility is its own .v file, so after installing the [latest V compiler](https://github.com/vlang/v/releases/), it's as easy as executing the below.  _Be sure that the V compiler root directory is part of your PATH environment._

```
git clone https://github.com/chipnetics/xertools
cd src
v build filename.v
```
Alternatively, if you don't have git installed:

1. Download the bundled source [here](https://github.com/chipnetics/xertools/archive/refs/heads/main.zip)
2. Unzip to a local directory
3. Navigate to src directory and run `v build filename.v`

Please see the [V language documentation](https://github.com/vlang/v/blob/master/doc/docs.md) for further help if required.

# Running Optional Command Line Arguments

For Windows users, if you want to pass optional command line arguments to an executable:

1. Navigate to the directory of the utility.
2. Hold Shift + Right Mouse Click.
3. Select "Open PowerShell Window Here".
4. Type the name of the exe along with the optional argument (i.e. `./utilityname.exe --full` ).

# Date Conventions

When there's more than one .xer input file expected, input files are parsed alphabetically. Therefore it is important that file naming follow the [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) date convention.

Simply stated, this means input files should be named starting with YYYYMMDD or YYYY-MM-DD, as these are guaranteed to sort chronologically as well as alphabetically.  Notwithstanding, this simply amounts to respectfully sane file organization.

# Comparing to Baselines

With the date conventions above in mind, it is possible to generate comparisons to baselines by ensuring the baseline schedule sorts first alphabetically. As a suggestion, an easy way to flag your baseline .xer and have it sort first is by simple naming it `0000.xer` (as one example).

# Viewing Large Files

As an aside, the author recommends the excellent tool _EmEditor_ by Emurasoft for manually editing or viewing large text-based files for data science & analytics. Check out the tool [here](https://www.emeditor.com/).  _EmEditor_ is paid software but well worth the investment to increase effeciency.

*** 

# Utilities

## XER Difference
### bin/xerdiff.exe 
> Identify what task codes have been added or deleted between 2 or more XER files. The utility will parse each successive pair of .xer files.  That is, if you have three xer files (A.xer, B.xer, C.xer) it will compare A-with-B and then B-with-C.  Files are parsed alphabetically.  There is no limit to the number of .xer files that can be inputted.

**Input:** Two or more .xer files, in the same directory as xerdiff.exe

**Output:** xerdiff.txt, in the same directory as xerdiff.exe

**Optional Command Line Arguments** 

> `xerdiff.exe --full`  
Outputs all field columns from XER TASK table (default is Task Code and Task Name only).

---
## XER Dump
### bin/xerdump.exe 
> Extract all embedded tables within a .xer to individual .txt files.  That is, if the input file is XYZ.xer, xerdump will create a folder 'XYZ' and extract all tables in the xer (i.e. ACTVCODE, ACTVTYPE, TASK, etc...) within that folder.  It will continue this process for all .xer files in the directory. There is no limit to the number of .xer files that can be inputted.

**Input:** One or more .xer files, in the same directory as xerdump.exe

**Output:** Various .txt files for each input XER, in individual folders, in the same directory as xerdump.exe

**Optional Command Line Arguments** 

_No optional arguments at this time._

----


