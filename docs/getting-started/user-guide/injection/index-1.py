import matplotlib.pyplot as plt
import numpy as np

my_value = 0.6

fig, ax = plt.subplots(nrows=1, ncols=1, figsize=(5,3))
ax.plot([0, 1], [my_value, my_value])

ax.set_ylim(-0.1, 1)

ax.set_xlabel("Time (sec)")
ax.set_ylabel("Injected Signal")

anno_lw = 2

# Add value label
ax.plot([0.5-0.02, 0.5+0.02], [my_value, my_value], color='black', linewidth=anno_lw)
ax.plot([0.5-0.02, 0.5+0.02], [0, 0], color='black', linewidth=anno_lw)
ax.plot([0.5, 0.5], [0, my_value], color='black', linewidth=anno_lw)
ax.text(0.5 + 0.04, my_value/2, "value",  ha="left", bbox=dict(facecolor='white', alpha=0.8))

fig.tight_layout()

fig.show()