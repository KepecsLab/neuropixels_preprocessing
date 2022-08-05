import numpy as np
from joblib import load
import phy
from scipy.io import savemat

with open('./.phy/spikes_per_cluster.pkl', 'rb') as f:
	data = load(f)
	data_dict = {'f' + str(key): data[key] for key in data.keys()}
	savemat('spikes_per_cluster.mat', data_dict)

