@ECHO OFF

RMDIR /QS src/__pycache__
RMDIR /QS train test
RMDIR /QS checkpoints
DEL   /Q  lenet5_params.h x.txt y.txt
