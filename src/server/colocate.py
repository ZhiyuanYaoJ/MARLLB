import numpy as np
import sys
import time
while (True):
    time.sleep(45)
    t0 = time.time()
    while (time.time()-t0 < 30):
        a = np.random.random((512, 512))
        np.exp(a)
        time.sleep(float(sys.argv[1]))
