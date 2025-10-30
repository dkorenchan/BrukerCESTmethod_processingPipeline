import os
import sys
import time
import numpy as np
import scipy.io as sio

from matplotlib import pyplot as plt

from colormaps_dk import b_viridis

# from ..dot_prod_example.configs import ConfigPreclinical
from sequences_dk import write_sequence_DK

from cest_mrf.write_scenario import write_yaml_dict
from cest_mrf.dictionary.generation import generate_mrf_cest_dictionary
from cest_mrf.metrics.dot_product import dot_prod_matching

class Config:
    def get_config(self):
        return self.cfg

class ConfigDK(Config):
    def __init__(self):
        config = {}
        config['yaml_fn'] = 'OUTPUT_FILES/scenario.yaml'
        config['seq_fn'] = 'OUTPUT_FILES/acq_protocol.seq'
        config['dict_fn'] = 'OUTPUT_FILES/dict.mat'
        config['acqdata_fn'] = 'INPUT_FILES/acquired_data.mat'
        config['quantmaps_fn'] = 'OUTPUT_FILES/quant_maps.mat'

        # Modified by DK to pull in dictpars from acquired_data.mat
        dp = {}
        dp_import = sio.loadmat(config['acqdata_fn'])['dictpars']
        for name in dp_import.dtype.names:
            if len(dp_import[name].flatten()[0].flatten()) > 1: #store as list
                dp[name]=dp_import[name].flatten()[0].flatten().tolist()
            elif isinstance(dp_import[name].flatten()[0].flatten()[0],np.integer): #store as single integer value
                dp[name]=int(dp_import[name].flatten()[0].flatten()[0])
            else:
                dp[name]=float(dp_import[name].flatten()[0].flatten()[0]) 

        # Water_pool
        config['water_pool'] = {}
        config['water_pool']['t1'] = dp['water_t1']
        # config['water_pool']['t1'] = config['water_pool']['t1'].tolist()  # vary t1
        config['water_pool']['t2'] = dp['water_t2']
        # config['water_pool']['t2'] = config['water_pool']['t2'].tolist()  # vary t2
        config['water_pool']['f'] = dp['water_f']

        # Solute pool
        config['cest_pool'] = {}
        config['cest_pool']['Amine'] = {}
        config['cest_pool']['Amine']['t1'] = dp['cest_amine_t1']
        config['cest_pool']['Amine']['t2'] = dp['cest_amine_t2']
        config['cest_pool']['Amine']['k'] = dp['cest_amine_k']
        config['cest_pool']['Amine']['dw'] = dp['cest_amine_dw']
        config['cest_pool']['Amine']['f'] = dp['cest_amine_f']
        # config['cest_pool']['Amine']['f'] = config['cest_pool']['Amine']['f'].tolist()
        
        # Additional CEST pool ("MT")
        
        # This is for treating MT as an additional CEST pool
        # if 'cest_mt_f' in dp.keys():
        #    config['cest_pool']['MT'] = {}
        #    config['cest_pool']['MT']['t1'] = dp['cest_mt_t1']
        #    config['cest_pool']['MT']['t2'] = dp['cest_mt_t2']
        #    config['cest_pool']['MT']['k'] = dp['cest_mt_k']
        #    config['cest_pool']['MT']['dw'] = dp['cest_mt_dw']
        #    config['cest_pool']['MT']['f'] = dp['cest_mt_f']            
        # This is for treating MT as an MT pool
        if 'mt_f' in dp.keys():    
            config['mt_pool'] = {}
            config['mt_pool']['t1'] = dp['mt_t1']
            config['mt_pool']['t2'] = dp['mt_t2']
            config['mt_pool']['k'] = dp['mt_k']
            config['mt_pool']['dw'] = dp['mt_dw']
            config['mt_pool']['f'] = dp['mt_f']
            config['mt_pool']['lineshape'] = dp['mt_lineshape']

        # Fill initial magnetization info
        # this is important now for the mrf simulation! For the regular pulseq-cest
        # simulation, we usually assume athat the magnetization reached a steady
        # state after the readout, which means we can set the magnetization vector
        # to a specific scale, e.g. 0.5. This is because we do not simulate the
        # readout there. For mrf we include the readout in the simulation, which
        # means we need to carry the same magnetization vector through the entire
        # sequence. To avoid that the magnetization vector gets set to the initial
        # value after each readout, we need to set reset_init_mag to false
        config['scale'] = dp['magnetization_scale']
        config['reset_init_mag'] = dp['magnetization_reset']

        # Fill scanner info
        config['b0'] = dp['b0']
        config['gamma'] = dp['gamma']
        config['b0_inhom'] = dp['b0_inhom']
        config['rel_b1'] = dp['rel_b1']

        # Fill additional info
        config['verbose'] = 0
        config['max_pulse_samples'] = 100
        config['num_workers'] = 18

        self.cfg = config

def setup_sequence_definitions(cfg):
    # Read in seq_defs from acquired_data.mat
    seq_defs = {}
    sd_import = sio.loadmat(cfg['acqdata_fn'])['seq_defs']
    for name in sd_import.dtype.names:
        if len(sd_import[name].flatten()[0].flatten()) > 1: #store as list
            seq_defs[name]=sd_import[name].flatten()[0].flatten().tolist()
        elif isinstance(sd_import[name].flatten()[0].flatten()[0],np.integer): #store as single integer value
            seq_defs[name]=int(sd_import[name].flatten()[0].flatten()[0])
        else:
            seq_defs[name]=float(sd_import[name].flatten()[0].flatten()[0])
            
    # DK edit 8/26/24: Add in 'SLflag' if not imported above
    if not 'SLflag' in seq_defs.keys():
        seq_defs['SLflag']=seq_defs['offsets_ppm'] < [1e-3]*seq_defs['num_meas']
    # DK edit 9/4/24: Add in 'SLFA' if not imported above
    if not 'SLFA' in seq_defs.keys():
        seq_defs['SLFA']=seq_defs['excFA']    #use excitation tip angles, since that's what it was for a while unfortunately....
        
    seq_defs['B0'] = cfg['b0']  # B0 [T]
    seq_defs['seq_id_string'] = os.path.splitext(cfg['seq_fn'])[1][1:]  # unique seq id

    return seq_defs


def generate_quant_maps(acq_fn, dict_fn):
    """Run dot product matching and save quant maps."""
    # acq_fn = os.path.join(data_f, 'acquired_data.mat')
    quant_maps = dot_prod_matching(dict_fn=dict_fn, acquired_data_fn=acq_fn)
    return quant_maps


def visualize_and_save_results(quant_maps, mat_fn):
    """Visualize quant maps and save them as eps."""
    # os.makedirs(output_f, exist_ok=True)

    # mat_fn = os.path.join(output_f, 'quant_maps.mat')
    sio.savemat(mat_fn, quant_maps)
    print('quant_maps.mat saved')

    mask = quant_maps['dp'] > 0.99974
    mask_fn = 'mask.npy'
    np.save(mask_fn, mask)

    fig_fn = 'OUTPUT_FILES/dot_product_results.eps'
    fig, axes = plt.subplots(1, 3, figsize=(30, 25))
    color_maps = [b_viridis, 'magma', 'magma']
    data_keys = ['fs', 'ksw', 'dp']
    titles = ['[L-arg] (mM)', 'k$_{sw}$ (s$^{-1}$)', 'Dot product']
    clim_list = [(0, 120), (0, 500), (0.999, 1)]
    tick_list = [np.arange(0, 140, 20), np.arange(0, 600, 100), np.arange(0.999, 1.0005, 0.0005)]

    for ax, color_map, key, title, clim, ticks in zip(axes.flat, color_maps, data_keys, titles, clim_list, tick_list):
        vals = quant_maps[key] * (key == 'fs' and 110e3 / 3 or 1) * mask
        plot = ax.imshow(vals, cmap=color_map)
        plot.set_clim(*clim)
        ax.set_title(title, fontsize=25)
        cb = plt.colorbar(plot, ax=ax, ticks=ticks, orientation='vertical', fraction=0.046, pad=0.04)
        cb.ax.tick_params(labelsize=25)
        ax.set_axis_off()

    plt.tight_layout()
    plt.savefig(fig_fn, format="eps")
    plt.close()
    print("Resulting plots saved as EPS")


def main():
    # data_f = 'data'
    # output_f = 'results'

    cfg = ConfigDK().get_config()

    # Write configuration and sequence files
    write_yaml_dict(cfg)
    seq_defs = setup_sequence_definitions(cfg)
    write_sequence_DK(seq_defs=seq_defs, seq_fn=cfg['seq_fn'])

    # Dictionary generation
    if len(cfg['cest_pool'].keys())>1:
        eqvals=[('fs_0','fs_1',0.6666667)]
    else:
        eqvals=None        
    dictionary = generate_mrf_cest_dictionary(seq_fn=cfg['seq_fn'], param_fn=cfg['yaml_fn'], dict_fn=cfg['dict_fn'],
                                 num_workers=cfg['num_workers'], axes='xy', equals=eqvals)

    # Dot product matching and quant map generation
    start_time = time.perf_counter()
    quant_maps = generate_quant_maps(cfg['acqdata_fn'], cfg['dict_fn'])
    print(f"Dot product matching took {time.perf_counter() - start_time:.03f} s.")

    # Visualization and saving results
    visualize_and_save_results(quant_maps, cfg['quantmaps_fn'])


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.realpath(__file__)))
    main()
