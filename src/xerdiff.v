// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import xer
import os
import util
import flag

fn main() {
	mut pre_built_str := ''
	$if prebuilt ? {
		pre_built_str = '[pre-built binary release (##DATE##)]\n'
	}

	mut fp := flag.new_flag_parser(os.args)
	fp.application('xerdiff')

	fp.version('${pre_built_str}Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.\nUse of this source code (/program) is governed by an MIT license,\nthat can be found in the LICENSE file.')

	fp.description('\nPrints the difference between 2 or more XER files.\nThis software will -NOT- make any changes to your XER files.')

	fp.skip_executable()

	update_arg := fp.bool('update', `u`, false, 'check for tool updates')

	additional_args := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	additional_args.join_lines()

	if update_arg {
		util.github_update('chipnetics', 'xertools', 'xerdiff.exe')
		return
	}

	args_str := os.args.clone()
	dir_elems := os.ls('.') or { panic(err) }

	mut xer_files := []string{}
	mut full_output := false

	for param in args_str {
		if compare_strings(param, '--full') == 0 {
			full_output = true
		}
	}

	for file in dir_elems {
		if file.ends_with('.xer') {
			xer_files << file
		}
	}

	if xer_files.len < 2 {
		println('Require two .xer files to compare.')
		println('Ensure at least two .xer files are in same folder asexecutable.')
		return
	}

	mut file_out := os.create('xerdiff_output.txt') or { panic(err) }

	defer {
		file_out.close()
	}

	// Print appropriate Header
	if full_output {
		header := xer.task_header().split('\t')
		file_out.writeln('xer_1\txer_2\taction\tstmt\t' + xer.array_to_tab(header[1..]))?
	} else {
		file_out.writeln('xer_1\txer_2\taction\tstmt\ttask_code\ttask_name')?
	}

	for index, _ in xer_files {
		if index == xer_files.len - 1 {
			println('[Done]')
			println('')
			break // End of traversing files.
		}

		println('[Analyzing]  ${xer_files[index]} against ${xer_files[index + 1]}')

		xer_1 := xer.parse_task(xer_files[index])
		xer_2 := xer.parse_task(xer_files[index + 1])

		xer_1_keys := xer_1.keys()
		xer_2_keys := xer_2.keys()

		mut row_str := ''

		for i in xer_1_keys {
			if !xer_2_keys.contains(i) {
				task_array := xer_1[i].to_array()

				if full_output {
					row_str = xer.array_to_tab(task_array[1..])
				} else {
					row_str = xer.array_to_tab(task_array[14..16])
				}

				file_out.writeln('${xer_files[index]}\t${xer_files[index + 1]}\tDeleted\tDeleted from ${xer_files[index]}\t$row_str')?
			}
		}
		for i in xer_2_keys {
			if !xer_1_keys.contains(i) {
				task_array := xer_2[i].to_array()

				if full_output {
					row_str = xer.array_to_tab(task_array[1..])
				} else {
					row_str = xer.array_to_tab(task_array[14..16])
				}

				file_out.writeln('${xer_files[index]}\t${xer_files[index + 1]}\tAdded\tAdded in ${xer_files[
					index + 1]}\t$row_str')?
			}
		}
	}
}
