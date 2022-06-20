// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import flag
import xer
import time

struct Driver {
mut:
	xer_name    string
	task_id     string
	driver_id   string
	pred_type   string
	task_code   string
	task_name   string
	driver_code string
	driver_name string
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('xerpred')

	fp.version('v2022.02.24\nCopyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.\nUse of this source code (/program) is governed by an MIT license,\nthat can be found in the LICENSE file.')

	fp.description('\nLogic-traces all the XER predecessor line items.\nOutput is of [parent-node]->[child-node] relations, up to specified depth.\nThis software will -NOT- make any changes to your XER files.')

	fp.skip_executable()

	mut xer_arg := fp.string('xer', `f`, '', 'specify the XER for analysis')
	mut minimal_output_arg := fp.bool('minimal', `m`, false, 'output only task-id records')
	mut max_levels_arg := fp.int('depth', `l`, 5, 'specify max predecessor depth [default:5]')
	mut drivers_arg := fp.bool('drivers', `d`, false, 'output schedule drivers and exit')

	additional_args := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	additional_args.join_lines()

	// Get the XER files in current directory
	dir_elems := os.ls('.') or { panic(err) }
	mut xer_files := []string{}

	mut drivers_arr := []Driver{}

	for file in dir_elems {
		if file.ends_with('.xer') {
			xer_files << file
		}
	}

	if xer_arg.len == 0 && xer_files.len == 0 {
		eprintln('[ERROR] You must specify an XER file for analysis, or the directory must containt at least one XER.\nSee usage below.\n')
		println(fp.usage())
		exit(0)
		return
	}

	if drivers_arg {
		mut fout := os.create('XER_drivers.txt') or { panic(err) }

		fout.writeln('xer_file\ttask_id\tdriver_id\tpred_type\ttask_code\ttask_name\tdriver_code\tdriver_name\tpred_early_start\tpred_early_end\tpred_late_start\tpred_late_end\tsucc_early_start\tsucc_early_end\tsucc_late_start\tsucc_late_end\trel_early_finish\trel_late_start\trel_free_float') or {
			panic(err)
		}

		if xer_arg.len == 0 {
			for xer_file in xer_files {
				print_drivers(mut fout, xer_file, mut drivers_arr)
			}
		} else {
			print_drivers(mut fout, xer_arg, mut drivers_arr)
		}
		analyze_drivers(mut drivers_arr)
		fout.close()
		exit(0)
	}

	lines := os.read_lines(xer_arg) or { panic(err) }

	mut line_index := 0

	mut pred_map := map[string][]string{}

	for line in lines {
		line_index++
		if compare_strings(line, '%T\tTASKPRED') == 0 {
			line_index++ // Advance passed header...
			for i := line_index; i < lines.len; i++ {
				if lines[i].starts_with('%T') {
					break
				}

				mut delimited_row := lines[i].split('\t')

				pred_map[delimited_row[2]] << delimited_row[3]
			}
		}
	}

	mut tree_arr := []Tree{}

	for key, mut value in pred_map {
		recurse(mut tree_arr, pred_map, key, key, value, 0, max_levels_arg)
	}

	tree_arr.sort(b.concat > a.concat)

	mut task_items := map[string]xer.XER_task{}
	if !minimal_output_arg {
		task_items = xer.parse_task_idkey(xer_arg)
	}

	// Print output Header....
	print('node\tdepth\tparent\tchild')
	if minimal_output_arg {
		println('')
	} else {
		print('\tnode_task_code\tnode_task_name\tparent_task_code\tparent_task_name\tchild_task_code\tchild_task_name\n')
	}

	for pred in tree_arr {
		print('$pred.task_id\t$pred.depth\t$pred.parent_node\t$pred.child_node')

		if minimal_output_arg {
			println('')
		} else {
			print('\t${task_items[pred.task_id].task_code}\t${task_items[pred.task_id].task_name}\t${task_items[pred.parent_node].task_code}\t${task_items[pred.parent_node].task_name}\t${task_items[pred.child_node].task_code}\t${task_items[pred.child_node].task_name}\n')
		}
	}
}

struct Driver_detail {
	xer_file    string
	task_code   string
	driver_code string
}

fn analyze_drivers(mut drivers_arr []Driver) {
	// map of filename of task code of drivers
	mut drivers_map := map[string]map[string][]string{}
	mut driver_det_map := map[string]map[string][]Driver_detail{}
	mut driver_cnt_map := map[string]map[string]int{}

	// println(drivers_arr)

	for elem in drivers_arr {
		drivers_map[elem.xer_name][elem.task_code] << elem.driver_code

		driver_det_map[elem.task_code][elem.xer_name] << Driver_detail{elem.xer_name, elem.task_code, elem.driver_code}

		driver_cnt_map[elem.xer_name][elem.task_code] =
			driver_cnt_map[elem.xer_name][elem.task_code] + 1
	}

	xer_files := drivers_map.keys()
	mut cum_delta := 0

	mut fout := os.create('driver_analysis.txt') or { panic(err) }

	print('Performing driver analysis... ')

	fout.writeln('curr_snap\tprev_snap\ttask_code\tcurr_driver_cnt\tprev_driver_cnt\tcnt_delta\tcumulative_delta\tdriver_code\tstatus\tverbiage') or {
		panic(err)
	}

	for idx, file in xer_files {
		if idx == 0 {
			continue
		}

		for key, val in driver_cnt_map[file] {
			// each key is the task_code for the file	
			// check if in previous
			prev_xer := xer_files[idx - 1]
			mut prev_cnt := driver_cnt_map[prev_xer][key]
			mut cnt_delta := val - prev_cnt
			mut did_drop_pass := false

			cum_delta += cnt_delta

			for driver in drivers_map[file][key] {
				mut prev_status := ''

				if drivers_map[prev_xer][key].contains(driver) {
					prev_status = 'REMAINS'
				} else {
					prev_status = 'ADDED'
				}

				// See what was dropped; only do this once per task_code so keep a bool if done for this code.
				// Otherwise will get duplicate "DROPPED" records.
				if !did_drop_pass {
					for driver2 in drivers_map[prev_xer][key] {
						mut future_status := ''
						if !drivers_map[file][key].contains(driver2) {
							future_status = 'DROPPED'
							fout.writeln('$file\t$prev_xer\t$key\t$val\t$prev_cnt\t$cnt_delta\t$cum_delta\t$driver2\t$future_status\t$future_status in $prev_xer') or {
								panic(err)
							}
						}
						did_drop_pass = true
					}
				}

				fout.writeln('$file\t$prev_xer\t$key\t$val\t$prev_cnt\t$cnt_delta\t$cum_delta\t$driver\t$prev_status\t$prev_status in $file') or {
					panic(err)
				}
			}
		}
	}
	println('[DONE]')
	fout.close()
}

fn print_drivers(mut fout os.File, xer_file string, mut drivers_arr []Driver) {
	task_items := xer.parse_task_idkey(xer_file)
	pred_items := xer.parse_pred(xer_file)

	mut relation_map := map[string][]Relation{}

	for _, value in pred_items {
		mut a_relation := Relation{}
		a_relation.pred_task_id = value.pred_task_id
		a_relation.pred_type = value.pred_type
		a_relation.early_finish = value.aref
		a_relation.late_start = value.arls
		relation_map[value.task_id] << a_relation
	}

	println('Calculating drivers in $xer_file')

	// key is the task_id in relation_map, so key is the successor,
	// value is []Relation, are the relations
	for key, mut value in relation_map {
		driver_threshold := 96

		// value is []Drivers
		for rel in value {
			mut rel_free_float := 0.00
			mut is_driver := false
			succ := task_items[key]
			pred := task_items[rel.pred_task_id]

			if compare_strings(rel.pred_type, 'PR_FS') == 0 {
				// Worst case float is relationship early finish less pred late start....
				dc4 := time.parse('$rel.early_finish:00') or { time.Time{} }
				dc3 := time.parse('$pred.late_start_date:00') or { time.Time{} }
				rel_free_float = (dc4 - dc3).hours()

				// Otherwise... early date of successor less relationship early finish
				if rel_free_float > driver_threshold || rel_free_float < 0 {
					dc9 := time.parse('$succ.early_start_date:00') or { time.Time{} }
					dc10 := time.parse('$rel.early_finish:00') or { time.Time{} }
					rel_free_float = (dc9 - dc10).hours()
				}
			} else if compare_strings(rel.pred_type, 'PR_SS') == 0 {
				// Worst case float is relationship early finish less pred late start....
				dc4 := time.parse('$rel.early_finish:00') or { time.Time{} }
				dc3 := time.parse('$pred.late_start_date:00') or { time.Time{} }
				rel_free_float = (dc4 - dc3).hours()

				// Otherwise... early date of successor less relationship early finish
				if rel_free_float > driver_threshold || rel_free_float < 0 {
					dc12 := time.parse('$succ.early_start_date:00') or { time.Time{} }
					dc13 := time.parse('$rel.early_finish:00') or { time.Time{} }
					rel_free_float = (dc12 - dc13).hours()
				}
			} else if compare_strings(rel.pred_type, 'PR_SF') == 0 {
				dc7 := time.parse('$pred.early_start_date:00') or { time.Time{} }
				dc8 := time.parse('$succ.early_end_date:00') or { time.Time{} }
				rel_free_float = (dc8 - dc7).hours()

				// Otherwise... early date of successor less relationship early finish
				if rel_free_float > driver_threshold || rel_free_float < 0 {
					dc12 := time.parse('$succ.early_start_date:00') or { time.Time{} }
					dc13 := time.parse('$rel.early_finish:00') or { time.Time{} }
					rel_free_float = (dc12 - dc13).hours()
				}
			} else if compare_strings(rel.pred_type, 'PR_FF') == 0 {
				dc7 := time.parse('$pred.early_end_date:00') or { time.Time{} }
				dc8 := time.parse('$succ.early_end_date:00') or { time.Time{} }
				rel_free_float = (dc8 - dc7).hours()

				// Otherwise... early date of successor less relationship early finish
				if rel_free_float > driver_threshold || rel_free_float < 0 {
					dc12 := time.parse('$succ.early_start_date:00') or { time.Time{} }
					dc13 := time.parse('$rel.early_finish:00') or { time.Time{} }
					rel_free_float = (dc12 - dc13).hours()
				}
			}

			if rel_free_float < driver_threshold && rel_free_float >= 0 {
				is_driver = true
			}

			// Is a driver, so record...
			if is_driver {
				// Write to file
				fout.writeln('$xer_file\t$key\t$rel.pred_task_id\t$rel.pred_type\t$succ.task_code\t$succ.task_name\t${task_items[rel.pred_task_id].task_code}\t${task_items[rel.pred_task_id].task_name}\t${task_items[rel.pred_task_id].early_start_date}\t${task_items[rel.pred_task_id].early_end_date}\t${task_items[rel.pred_task_id].late_start_date}\t${task_items[rel.pred_task_id].late_end_date}\t$succ.early_start_date\t$succ.early_end_date\t$succ.late_start_date\t$succ.late_end_date\t$rel.early_finish\t$rel.late_start\t$rel_free_float') or {
					panic(err)
				}
				// Save to struct
				mut a_driver := Driver{}
				a_driver.xer_name = xer_file
				a_driver.task_id = key
				a_driver.driver_id = rel.pred_task_id
				a_driver.pred_type = rel.pred_type
				a_driver.task_code = succ.task_code
				a_driver.task_name = succ.task_name
				a_driver.driver_code = task_items[rel.pred_task_id].task_code
				a_driver.driver_name = task_items[rel.pred_task_id].task_name
				drivers_arr << a_driver
			}
		}
	}
}

struct Relation {
mut:
	pred_task_id string
	pred_type    string
	early_finish string
	late_start   string
}

fn recurse(mut tree []Tree, pred_map map[string][]string, root_key string, parent string, children []string, levels int, max_levels int) {
	if children.len == 0 {
		return
	}
	if levels == max_levels {
		return
	}

	// println("called level, $root_key, $children")
	for pred in children {
		// println("recurse $pred with child ${pred_map[pred]}")
		mut a_tree := Tree{}
		a_tree.concat = root_key + levels.str() // for sorting only
		a_tree.task_id = root_key
		a_tree.depth = levels
		a_tree.parent_node = parent
		a_tree.child_node = pred
		tree << a_tree

		recurse(mut tree, pred_map, root_key, pred, pred_map[pred], levels + 1, max_levels)
	}
}

struct Tree {
mut:
	concat string
	// for sorting only.
	task_id     string
	depth       int
	parent_node string
	child_node  string
}
