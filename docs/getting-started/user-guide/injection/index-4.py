import matplotlib.pyplot as plt
import numpy as np

t_step = 1e-3
tt = np.arange(0, 1, t_step)
yy = np.zeros_like(tt)

period = 0.65
minValue = 0.35
maxValue = 0.85

my_slope = (maxValue-minValue) / (period/2)

t_local = 0
for idx,t in enumerate(tt):
    if (t_local < period/4):
        yy[idx] = +my_slope * t_local + (maxValue+minValue)/2
    elif (period/4 <= t_local and t_local < 3*period/4):
        yy[idx] = -my_slope * (t_local-period/4) + maxValue
    elif (3*period/4 <= t_local):
        yy[idx] = +my_slope * (t_local - (3*period/4)) + minValue
    else:
        yy[idx] = 0

    t_local += t_step
    if (t_local > period):
        t_local = 0

fig, ax = plt.subplots(nrows=1, ncols=1, figsize=(5,3))
ax.plot(tt, yy)

ax.set_ylim(0, 1)

ax.set_xlabel("Time (sec)")
ax.set_ylabel("Injected Signal")

anno_lw = 2

# Add annotations
ax.plot([0, 1], [maxValue, maxValue], color='black', linewidth=anno_lw, linestyle='dashed')
ax.text(0, minValue + 0.06, "valueMin", bbox=dict(facecolor='white', alpha=0.8))
ax.plot([0, 1], [minValue, minValue], color='black', linewidth=anno_lw, linestyle='dashed')
ax.text(0, maxValue + 0.06, "valueMax", bbox=dict(facecolor='white', alpha=0.8))

# Add period label
ax.plot([0, period], [0.1, 0.1], color='black', linewidth=anno_lw)
ax.plot([0, 0], [0.1-0.02, 0.1+0.02], color='black', linewidth=anno_lw)
ax.plot([period, period], [0.1-0.02, 0.1+0.02], color='black', linewidth=anno_lw)
ax.text(period/2, 0.1 + 0.06, "period",  ha="center", bbox=dict(facecolor='white', alpha=0.8))

fig.tight_layout()

fig.show()