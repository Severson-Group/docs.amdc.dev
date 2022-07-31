import matplotlib.pyplot as plt
import numpy as np
import random

t_step = 1e-3
tt = np.arange(0, 1, t_step)
yy = np.zeros_like(tt)

offset = 0.5
gain = 0.3

t_local = 0
for idx,t in enumerate(tt):
    yy[idx] = random.uniform(-1, 1)*gain + offset

fig, ax = plt.subplots(nrows=1, ncols=1, figsize=(5,3))
ax.plot(tt, yy)

ax.set_ylim(-0.1, 1)

ax.set_xlabel("Time (sec)")
ax.set_ylabel("Injected Signal")

anno_lw = 2

ax.plot([0,1], [offset, offset], color='red', linewidth=anno_lw, linestyle='dashed')
ax.plot([0.5-0.02, 0.5+0.02], [offset, offset], color='black', linewidth=anno_lw)

# Add gain label
ax.plot([0.5-0.02, 0.5+0.02], [offset+gain, offset+gain], color='black', linewidth=anno_lw)
ax.plot([0.5, 0.5], [offset, offset+gain], color='black', linewidth=anno_lw)
ax.text(0.5 + 0.04, offset+gain/2, "gain",  ha="left", bbox=dict(facecolor='white', alpha=0.8))

ax.plot([0.5-0.02, 0.5+0.02], [0, 0], color='black', linewidth=anno_lw)
ax.plot([0.5, 0.5], [0, offset], color='black', linewidth=anno_lw)
ax.text(0.5 + 0.04, offset/2, "offset",  ha="left", bbox=dict(facecolor='white', alpha=0.8))

fig.tight_layout()

fig.show()