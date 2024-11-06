import os
import subprocess
import signal
import time

class FindTerminateServerPIDs:
    def __init__(self, port):
        self.port = port

    def find_and_kill_process(self):
        try:
            # Use lsof to find all PIDs using the port
            pid_command = f"lsof -t -i:{self.port}"
            pids = subprocess.check_output(pid_command, shell=True).decode().strip().split('\n')
            if pids and pids != ['']:
                print(f"Port {self.port} is in use by PIDs: {', '.join(pids)}. Attempting to kill them.")
                for pid in pids:
                    try:
                        os.kill(int(pid), signal.SIGTERM)
                        print(f"Process {pid} terminated gracefully.")
                    except ProcessLookupError:
                        print(f"Process {pid} does not exist or has already been terminated.")
                    except Exception as e:
                        print(f"Failed to terminate process {pid}: {e}")
                
                # Wait for processes to terminate
                time.sleep(2)

                # Re-check if any processes are still using the port
                remaining_pids = subprocess.check_output(pid_command, shell=True).decode().strip().split('\n')
                remaining_pids = [pid for pid in remaining_pids if pid]

                if remaining_pids:
                    print(f"Processes {', '.join(remaining_pids)} still using port {self.port}. Attempting to force kill.")
                    for pid in remaining_pids:
                        try:
                            os.kill(int(pid), signal.SIGKILL)
                            print(f"Process {pid} killed forcefully.")
                        except ProcessLookupError:
                            print(f"Process {pid} does not exist or has already been terminated.")
                        except Exception as e:
                            print(f"Failed to force kill process {pid}: {e}")

                    # Final wait to ensure port is freed
                    time.sleep(2)
                else:
                    print(f"All processes using port {self.port} have been terminated.")

            else:
                print(f"Port {self.port} is not in use. No process to kill.")
        except subprocess.CalledProcessError:
            # lsof returns non-zero exit status if no process is found
            print(f"No process found using port {self.port}.")
        except Exception as e:
            print(f"Error while finding/killing process: {e}")
