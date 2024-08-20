import os
import climber_core_utilities.load_config as load_config

sys_config = load_config.system()
cmd = "uvicorn main:app --host " + str(sys_config["ipExec"]) + " --port 5002  --log-level warning"
os.system(cmd)