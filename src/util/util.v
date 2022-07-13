module util

import os
import net.http
import crypto.md5
import encoding.base64
import readline

// Check the releases section on Github and compares hashes if an
// update is available.
pub fn github_update(username string, repo string, file string, force_update bool) {
	println('Checking for updates... ')

	md5_curr := md5.sum(os.read_bytes(os.args[0]) or {
		println('Error calculating existing MD5 sum! Aborting.')
		return
	}).hex()
	println('MD5 current: $md5_curr')

	res := http.head('http://github.com/$username/$repo/releases/latest/download/$file') or {
		println('Error checking for update. Aborting.')
		return
	}

	if res.status_code == 200 {
		md5_latest := base64.decode(res.header.custom_values('Content-MD5')[0]).hex()
		println('MD5 latest:  $md5_latest')

		if compare_strings(md5_curr, md5_latest) != 0 {
			mut user_in := ''

			if !force_update {
				user_in = readline.read_line('An update is available, download now? [y/N] ') or {
					println('Error checking for update. Aborting.')
					return
				}
			}

			if compare_strings(user_in, 'y\n') == 0 || compare_strings(user_in, 'y\r\n') == 0
				|| force_update == true {
				print('[1/4] Backing up old version... ')
				os.mv('$file', '${file}.bak') or {
					println("[FAIL]\nError moving file '$file'. Aborting")
					return
				}
				println('\t[DONE]')

				print('[2/4] Downloading update...')
				http.download_file('http://github.com/$username/$repo/releases/latest/download/$file',
					'$file') or {
					println('[FAIL]\nError downloading update. Aborting.')
					return
				}
				println('\t\t[DONE]')

				print('[3/4] Verifying MD5 of download...')
				mut md5_new := md5.sum(os.read_bytes(file) or {
					println('Error checking MD5. Aborting.')
					return
				}).hex()

				// on linux need to change to execute permssion, if it fails
				// set md5_new to "" so next conditions fail.
				$if linux {
					os.chmod(file, 0o755) or { md5_new = '' }
				}

				if compare_strings(md5_new, md5_latest) == 0 {
					println('\t[DONE]')
				} else {
					println('\t[FAIL]')
					print('[4/4] Restoring backup...')
					os.mv('xertask_bak', 'xertask') or {
						println('[FAIL]\nError moving file. Aborting')
						return
					}
					println('\t\t[DONE]')
					return
				}

				// Deleting old version in Windows will fail as the moved copy (to .bak)
				// is the active file in Task Manager; so it cannot delete a running process.
				print('[4/4] Deleting old version...')
				$if linux {
					os.rm('${file}.bak') or {
						println("\t\t[FAIL]\nError deleting file '${file}.bak'. Delete manually.")
						return
					}
				} $else {
					println('\t\t[Must delete manually in Windows]')
					return
				}
				println('\t\t[DONE]')
			} else {
				// User did not enter 'y' and no force-update parameter.
				println('Update aborted.')
			}
		} else {
			println('You are runnning the latest version. No updates are available.')
		}
	} else {
		println('Error checking for update. Aborting.')
	}
}
