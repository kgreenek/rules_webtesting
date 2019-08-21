# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Windows Utils

These functions help making rules work on Windows.
"""

def is_windows(ctx):
    """
    Check if we are building for Windows.
    """

    # Only on Windows the path separator would be ';'
    # We should switch to a proper API after
    # https://github.com/bazelbuild/bazel/issues/9209 is resolved.
    return ctx.configuration.host_path_separator == ";"

def create_windows_native_launcher_script(ctx, shell_script):
    """
    Create a Windows Batch file to launch the given shell script.
    The rule should specify @bazel_tools//tools/sh:toolchain_type as a required toolchain.
    """
    name = shell_script.basename
    if name.endswith(".sh"):
        name = name[:-3]
    win_launcher = ctx.actions.declare_file(name + ".bat", sibling = shell_script)
    ctx.actions.write(
        output = win_launcher,
        content = r"""@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
if "%RUNFILES_MANIFEST_ONLY%" neq "1" (
  set run_script={sh_script}
  goto :run
)
set MF=%RUNFILES_MANIFEST_FILE:/=\%
set script={sh_script}
if "!script:~0,9!" equ "external/" (set script=!script:~9!) else (set script=!TEST_WORKSPACE!/!script!)
for /F "tokens=2* usebackq" %%i in (`findstr.exe /l /c:"!script! " "%MF%"`) do (
  set run_script=%%i
)
if "!run_script!" equ "" (
  echo>&2 ERROR: !script! not found in runfiles manifest
  exit /b 1
)
:run
{bash_bin} -c "!run_script!"
""".format(
            bash_bin = ctx.toolchains["@bazel_tools//tools/sh:toolchain_type"].path,
            sh_script = shell_script.short_path,
        ),
        is_executable = True,
    )
    return win_launcher
