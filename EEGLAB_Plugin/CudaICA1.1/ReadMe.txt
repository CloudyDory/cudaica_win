1. Place the folder in EEGLAB's plugins folder.
2, Find your EEGLAB version, copy the "pop_runica.m" file in the "replace" folder to corresponding EEGLAB folder, overwriting the existing one (backup the original one first!). This function do not actually calculate ICA but is needed to call CUDAICA from GUI and command line. Other EEGLAB versions are not tested. You can also study the script and modify it by yourself :).

-- END --
