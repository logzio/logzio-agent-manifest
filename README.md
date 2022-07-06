# Logz.io Agent Manifest

- [Architecture](#architecture)
- [Logic](#logic)
- [Agent Script Arguments](#agent-script-arguments)
- [Running The Agent Script](#running-the-agent-script)
    - [Linux](#linux)
    - [MacOS](#macos)
    - [Windows](#windows)
- [Troubleshooting Tools](#troubleshooting-tools)
    - [Script Arguments](#script-arguments)
    - [Linux](#linux-1)
    - [MacOS](#macos-1)
    - [Windows](#windows-1)

This repo contains all the scripts needed to ship logs, metrics and traces to Logz.io for supported datasources using the Logz.io agent.

Supports the following OS:

- Linux
- MacOS
- Windows

Supports the following datasources:

- AKS (Kubernetes)
- EKS (Kubernetes)
- GKE (Kubernetes)

## Architecture

Each datasource is represented as a path of 3 directories from the root of this repo (dir1/dir2/dir3) (for example: Kubernetes/AKS/Kubernetes).

This is the structure of directories in each path (dir1/dir2/dir3):

- prerequisites
    - linux
    - mac
    - windows
- telemetry
    - installer
        - linux
        - mac
        - windows
    - logs
        - linux
        - mac
        - windows
    - metrics
        - linux
        - mac
        - windows
    - traces
        - linux
        - mac
        - windows

Each leaf directory contains main script (tasks to run using the functions from the functions script) and functions script (functions only).

* Also can contain other helper files

scripts directory contains the agent (entry point script. uses the functions from the functions script), functions (functions only) and utils functions (functions for all scripts in this repo) scripts for each OS, which are the entry point for all the scripts in this repo.

## Logic 

The agent script will get the agent application JSON from the agent. According the JSON file, it will get a path of 3 directories (dir1/dir2/dir3) that exists in this repo (from the root). This path represents a datasource.

Using that path, it will get the prerequisites and the telemetry (installer, logs, metrics, traces) scripts.

The agent script will run the prerequisites and then the installer.

The installer script will get logs, metrics, traces scripts depending on the application JSON, and will run each of them.

* Through the whole process, the scripts will get files from this repo according the application JSON from the agent.
* Each main script contains tasks to execute. Each task runs in a separate process/job, and only if finished successfully will continue to the next task. If a task was not finished successfully, an error message will be shown and the agent script will exit.
* Some tasks depends on the application JSON (for example: metrics parameters).
* A success message will be shown at the end of a successful run.
* All scripts downloaded from this repo and temp files will be saved in Logz.io temp directory, which will be deleted at the end of the running.
* A log file will be created at the beginning of the running in the directory where the agent script was running from (except in Windows, which will be created under `Documents` directory).

## Agent Script Arguments

Each agent script has the following flags:

| Flag | Description |
| --- | --- |
| `--url=<<LOGZIO_APP_URL>>` | The Logz.io app URL (for example: https://app.logz.io) |
| `--id=<AGENT_ID>` | The Logz.io agent ID. You will get it from the agent in Logz.io application |
| `debug=<<APP_JSON>>` | Runs the script with a local application JSON (for tests only) |

* You can run the agent script with `--help` to show the script usage.

## Running The Agent Script

### Linux

```Bash
bash <(curl -sSL https://github.com/logzio/logzio-agent-manifest/releases/download/latest/agent_linux.bash) --url=LOGZIO_APP_URL --id=AGENT_ID
```

### MacOS

```Bash
bash <(curl -sSL https://github.com/logzio/logzio-agent-manifest/releases/download/latest/agent_mac.bash) --url=LOGZIO_APP_URL --id=AGENT_ID
```

### Windows

* Must run from `Windows PowerShell` (NOT Windows PowerShell (x86) or Windows PowerShell ISE).
* Temp directory and the log file will be created under `Documents` directory.

```PowerShell
powershell { iex “& { $(irm https://github.com/logzio/logzio-agent-manifest/releases/download/latest/agent_windows.ps1) } --url=LOGZIO_APP_URL --id=AGENT_ID” }
```

## Troubleshooting Tools

under each OS in scripts directory, there is troubleshooting-tools directory which contains troubleshooting scripts (mainly for Support team).

* A log file will be created at the beginning of the running in the directory where the script was running from (except in Windows, which will be created under `Documents` directory).

### Script Arguments

| Flag | Description |
| --- | --- |
| `--path=LOGZIO_REPO_DATASOURCE_PATH` | The path of a datasource in this repo (dir1/dir2/dir3 for example: Kubernetes/AKS/Kubernetes) |

* You can run the script with `--help` to show the script usage.

### Linux

```Bash
bash <(curl -sSL https://github.com/logzio/logzio-agent-manifest/releases/download/latest/run_prerequisites_linux.bash) --path=LOGZIO_REPO_DATASOURCE_PATH
```

### MacOS

```Bash
bash <(curl -sSL https://github.com/logzio/logzio-agent-manifest/releases/download/latest/run_prerequisites_mac.bash) --path=LOGZIO_REPO_DATASOURCE_PATH
```

### Windows

* Must run from `Windows PowerShell` (NOT Windows PowerShell (x86) or Windows PowerShell ISE).
* Temp directory and the log file will be created under `Documents` directory.

```PowerShell
powershell { iex “& { $(irm https://github.com/logzio/logzio-agent-manifest/releases/download/latest/run_prerequisites_windows.ps1) } --path=LOGZIO_REPO_DATASOURCE_PATH” }
```
