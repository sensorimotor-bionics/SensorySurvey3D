@echo off
call conda activate climber_core
python launch_survey3d_server.py
call conda deactivate
pause