import matplotlib.pyplot as plt
import numpy as np

# See: https://github.com/Severson-Group/AMDC-Firmware/pull/216#issuecomment-961394976
#
def func_chirp(w1, w2, A, period, time):
    half_period = period / 2.0

    freq_slope = (w2 - w1) / half_period

    if (time < half_period):
        mytime = time
        mygain = 1
    else:
        mytime = period - time
        mygain = -1

    freq = freq_slope * mytime/2.0 + w1

    return (A * mygain * np.sin(freq * mytime))

t_step = 1e-3
tt = np.arange(0, 7.5, t_step)
yy = np.zeros_like(tt)

w1 = 2*np.pi*1 # [rad/s]
w2 = 2*np.pi*3 # [rad/s]
A = 0.6
period = 5 # [sec]

t_local = 0
for idx,t in enumerate(tt):
    yy[idx] = func_chirp(w1, w2, A, period, t_local)

    t_local += t_step
    if (t_local > period):
        t_local = 0

fig, ax = plt.subplots(nrows=1, ncols=1, figsize=(5,3))
ax.plot(tt, yy)

ax.set_ylim(-1, 0.9)

ax.set_xlabel("Time (sec)")
ax.set_ylabel("Injected Signal")

anno_lw = 2

# Add period label
period_label_y = -0.9
ax.plot([0, period], [period_label_y, period_label_y], color='black', linewidth=anno_lw)
ax.plot([0, 0], [period_label_y-0.06, period_label_y+0.06], color='black', linewidth=anno_lw)
ax.plot([period, period], [period_label_y-0.06, period_label_y+0.06], color='black', linewidth=anno_lw)
ax.text(period/2, period_label_y + 0.10, "period",  ha="center", bbox=dict(facecolor='white', alpha=0.8))

# Add gain label
ax.plot([0.5-0.2, 0.5+0.2], [0, 0], color='black', linewidth=anno_lw)
ax.plot([0.5-0.2, 0.5+0.2], [A, A], color='black', linewidth=anno_lw)
ax.plot([0.5, 0.5], [0, A], color='black', linewidth=anno_lw)
ax.text(0.5 + 0.15, A/2, "gain",  ha="left", bbox=dict(facecolor='white', alpha=0.8))

fig.tight_layout()

fig.show()