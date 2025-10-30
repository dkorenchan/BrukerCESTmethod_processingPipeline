import numpy as np
import pypulseq as pp

def write_sequence_DK(seq_defs: dict = None,
                   seq_fn: str = 'protocol.seq'):
    """
    NOTE: I updated this 8/22/24 to reflect the 60deg pulses before + after CESL
    
    Create preclinical continous-wave sequence for CEST with simple readout
    :param seq_defs: sequence definitions
    :param seq_fn: sequence filename
    :return: sequence object
    """

    # >>> Gradients and scanner limits - see pulseq doc for more info
    # Mostly relevant for clinical scanners
    # lims =  mr.opts('MaxGrad',30,'GradUnit','mT/m',...
    #     'MaxSlew',100,'SlewUnit','T/m/s', ...
    #     'rfRingdownTime', 50e-6, 'rfDeadTime', 200e-6, 'rfRasterTime',1e-6)
    # <<<

    # gamma
    gyro_ratio_hz = 42.5764  # for H [Hz/uT]
    gyro_ratio_rad = gyro_ratio_hz * 2 * np.pi  # [rad/uT]

    # DK addition: parameter values for B-SL pulses: 90 degree pulses on either 
    # side of spin-lock pulse (keep as block pulses); refocusing pulses with opposite phases
    pw_90 = 0.1e-3  #90 degree pulse width, in s
    pw_180 = 0.2e-3  #180 degree pulse width, in s
    
    # This is the info for the 2d readout sequence. As gradients etc ar
    # simulated as delay, we can just add a delay afetr the imaging pulse for
    # simulation which has the same duration as the actual sequence

    # the duration of the readout sequence:
    te = 20e-3
    imaging_delay = pp.make_delay(te)

    # init sequence
    seq = pp.Sequence()

    # Loop b1s
    for idx in range(seq_defs['num_meas']):
        exctip = seq_defs['excFA'][idx]
        B1 = seq_defs['B1pa'][idx]
        ppmoff = seq_defs['offsets_ppm'][idx]
        tp = seq_defs['tp'][idx]
    #     td = seq_defs['td'][idx]
        trec = seq_defs['Trec'][idx-1]
        isSL = seq_defs['SLflag'][idx]
        SLtip = seq_defs['SLFA'][idx]

        if idx > 0:  # add relaxtion block after first measurement
            seq.add_block(pp.make_delay(trec - te))  # net recovery time

        # saturation/spinlock pulse
        current_offset_hz = ppmoff * seq_defs['B0'] * gyro_ratio_hz
        fa_sat = B1 * gyro_ratio_rad * tp  # flip angle of sat pulse, in rad/s
        
        # excitation pulse, prior to readout
        imaging_pulse = pp.make_block_pulse(exctip * np.pi / 180, duration=2.1e-3)

        
        # pre- and post-spinlock pulses
        # DK mod 9/5/24: because I don't believe Pulseq assumes things are 
        # phase-continuous as we hop between rotating frames, we must account for 
        # the extra phase the water accumulates as it "follows" the B_eff field, 
        # which is stationary in the off-resonant rotating frame but in water's 
        # frame precesses about the z-axis! (and brings the water along with it!) 
        # See write_sequence_clinical() in original sequences.py file 
        accum_phase = np.mod(current_offset_hz * 2 * np.pi * tp, 2 * np.pi)
        
        # DK mod 9/5/24: We also need to reverse the pre- and post-SL pulse phases, 
        # similar to write_sequence_clinical() in original sequences.py file
        pre_spinlock_pulse = pp.make_block_pulse(SLtip * np.pi / 180, duration=pw_90, freq_offset=0, phase_offset=90 * np.pi / 180)
        post_spinlock_pulse = pp.make_block_pulse(SLtip * np.pi / 180, duration=pw_90, freq_offset=0, phase_offset=270 * np.pi / 180 + accum_phase)
        bsl_refpulse_1 = pp.make_block_pulse(180 * np.pi / 180, duration=pw_180, freq_offset=0, phase_offset=180 * np.pi / 180 + accum_phase/4)
        bsl_refpulse_2 = pp.make_block_pulse(180 * np.pi / 180, duration=pw_180, freq_offset=0, phase_offset=0 * np.pi / 180 + accum_phase*3/4)
        # add pulses
        # DK modification: detect if current_offset_hz is 0, and if so
        # add in 90deg pre-pulse for on-resonance spin-lock
        # if current_offset_hz < 1e-3:
        if isSL:
            seq.add_block(pre_spinlock_pulse)
            for n_p in range(seq_defs['n_pulses']):
                # ### REGULAR SPIN-LOCK ###
                # # If B1 is 0 simulate delay instead of any pulses
                # if B1 == 0:
                #     seq.add_block(pp.make_delay(tp))  # net recovery time
                # else:
                #     sl_lockpulse = pp.make_block_pulse(fa_sat, duration=tp, freq_offset=current_offset_hz, phase_offset=0 * np.pi / 180)
                #     # =='system', lims== should be added for clinical scanners
                #     seq.add_block(sl_lockpulse)
                # # delay between pulses
                # if n_p < seq_defs['n_pulses'] - 1:
                #     seq.add_block(pp.make_delay(seq_defs['td']))
                # ### END REGULAR SPIN-LOCK ###

                # ### BALANCED SPIN-LOCK ###
                # # If B1 is 0 simulate delay instead of any pulses
                # if B1 == 0:
                #     seq.add_block(pp.make_delay(tp))  # net recovery time
                # else:
                #     bsl_lockpulse_beg = pp.make_block_pulse(fa_sat/4, duration=tp/4, freq_offset=current_offset_hz, phase_offset=0 * np.pi / 180)
                #     bsl_lockpulse_mid = pp.make_block_pulse(fa_sat/2, duration=tp/2, freq_offset=current_offset_hz, phase_offset=180 * np.pi / 180  + accum_phase/4)
                #     bsl_lockpulse_end = pp.make_block_pulse(fa_sat/4, duration=tp/4, freq_offset=current_offset_hz, phase_offset=0 * np.pi / 180 + accum_phase*3/4)
                #     # =='system', lims== should be added for clinical scanners
                #     seq.add_block(bsl_lockpulse_beg)
                #     seq.add_block(bsl_refpulse_1)
                #     seq.add_block(bsl_lockpulse_mid)
                #     seq.add_block(bsl_refpulse_2)
                #     seq.add_block(bsl_lockpulse_end)
                # # delay between pulses
                # if n_p < seq_defs['n_pulses'] - 1:
                #     seq.add_block(pp.make_delay(seq_defs['td']))
                # ### END BALANCED SPIN-LOCK ###

                ### COMBO SPIN-LOCK : REGULAR IF OFF-RES, BALANCED IF ON-RES ###
                # If B1 is 0 simulate delay instead of any pulses
                if B1 == 0:
                    seq.add_block(pp.make_delay(tp))  # net recovery time
                elif current_offset_hz < 1e-3:  # balanced spin-lock if on-res
                    bsl_lockpulse_beg = pp.make_block_pulse(fa_sat/4, duration=tp/4, freq_offset=current_offset_hz, phase_offset=180 * np.pi / 180)
                    bsl_lockpulse_mid = pp.make_block_pulse(fa_sat/2, duration=tp/2, freq_offset=current_offset_hz, phase_offset=0 * np.pi / 180  + accum_phase/4)
                    bsl_lockpulse_end = pp.make_block_pulse(fa_sat/4, duration=tp/4, freq_offset=current_offset_hz, phase_offset=180 * np.pi / 180 + accum_phase*3/4)
                    # =='system', lims== should be added for clinical scanners
                    seq.add_block(bsl_lockpulse_beg)
                    seq.add_block(bsl_refpulse_1)
                    seq.add_block(bsl_lockpulse_mid)
                    seq.add_block(bsl_refpulse_2)
                    seq.add_block(bsl_lockpulse_end)
                else:   # regular spin-lock if off-res
                    sl_lockpulse = pp.make_block_pulse(fa_sat, duration=tp, freq_offset=current_offset_hz, phase_offset=180 * np.pi / 180)
                    # =='system', lims== should be added for clinical scanners
                    seq.add_block(sl_lockpulse)                  
                # delay between pulses
                if n_p < seq_defs['n_pulses'] - 1:
                    seq.add_block(pp.make_delay(seq_defs['td']))
                ### END COMBO SPIN-LOCK ###
                
            seq.add_block(post_spinlock_pulse)
        else:
            for n_p in range(seq_defs['n_pulses']):
                # If B1 is 0 simulate delay instead of a saturation pulse
                if B1 == 0:
                    seq.add_block(pp.make_delay(tp))  # net recovery time
                else:
                    sat_pulse = pp.make_block_pulse(fa_sat, duration=tp, freq_offset=current_offset_hz)
                    # =='system', lims== should be added for clinical scanners
                    seq.add_block(sat_pulse)
                # delay between pulses
                if n_p < seq_defs['n_pulses'] - 1:
                    seq.add_block(pp.make_delay(seq_defs['td']))

        # DK note: maybe I need a spoiler here??

        # Imaging pulse
        seq.add_block(imaging_pulse)
        seq.add_block(imaging_delay)
        pseudo_adc = pp.make_adc(1, duration=1e-3)
        seq.add_block(pseudo_adc)

    def_fields = seq_defs.keys()
    for field in def_fields:
        seq.set_definition(field, seq_defs[field])

    seq.write(seq_fn)
    return seq