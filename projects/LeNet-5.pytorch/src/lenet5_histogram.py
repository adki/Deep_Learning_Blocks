#!/usr/bin/env python
"""
This file contains script to draw histogram of LeNet-5 parameters.
"""
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

#-------------------------------------------------------------------------------
__author__     = "Ando Ki"
__copyright__  = "Copyright 2021 Ando Ki"
__credits__    = ["none", "some"]
__license__    = "The 2-Clause BSD License"
__version__    = "0"
__revision__   = "1"
__maintainer__ = "Ando Ki"
__email__      = "contact@future-ds.com"
__status__     = "Development"
__date__       = "2021.01.08"
__description__= "LeNet-5 network model parameter histogram script"

#-------------------------------------------------------------------------------
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

import torch
from torchsummary import summary
from torchvision.utils import make_grid

from darknet_lenet5_utils import *
from lenet5_model import Lenet5Model

#-------------------------------------------------------------------------------
def fullprint(*args, **kwargs):
    import numpy
    #import pprint
    opt = numpy.get_printoptions()
    numpy.set_printoptions(threshold=numpy.inf)
    print(*args, **kwargs) #pprint.pprint(*args, **kwargs)
    numpy.set_printoptions(**opt)

#-------------------------------------------------------------------------------
def fullprint_array_comma(data, *args, **kwargs):
    """data: Torch tensor in N-dimension"""
    import numpy
    opt = numpy.get_printoptions()
    numpy.set_printoptions(threshold=numpy.inf)
    data = torch.flatten(data)
    print(*data.numpy().astype('float32'), sep=", ", *args, **kwargs)
    numpy.set_printoptions(**opt)

#-------------------------------------------------------------------------------
def handle_conv_bn( num_conv
                  , num_bn   # valid when 'bn' is not None
                  , conv
                  , bn
                  , rigor=False
                  , verbose=False):
    """
    """
    status = True
    weight= {}
    bias  = {}
    scale = {}
    rmean = {}
    rvar  = {}
    if bn is not None:
        if bn.bias.is_cuda:
            bias [num_conv] = convert2cpu(bn.bias.data).numpy()
            scale[num_bn] = convert2cpu(bn.weight.data).numpy()
            rmean[num_bn] = convert2cpu(bn.running_mean).numpy()
            rvar [num_bn] = convert2cpu(bn.running_var).numpy()
        else:
            bias [num_conv] = bn.bias.data.cpu().numpy()
            scale[num_bn] = bn.weight.data.cpu().numpy()
            rmean[num_bn] = bn.running_mean.cpu().numpy()
            rvar [num_bn] = bn.running_var.cpu().numpy()
        nelms = bn.bias.data.numel()
    else:
        if conv.bias is not None:
            if conv.bias.is_cuda:
                biase[num_conv] = convert2cpu(conv.bias.data).numpy()
            else:
                bias[num_conv] = conv.bias.data.cpu().numpy()
            nelms = conv.bias.data.numel()
    if conv.weight.is_cuda:
        weight[num_conv] = convert2cpu(conv.weight.data).numpy()
    else:
        weight[num_conv] = conv.weight.data.cpu().numpy()
    nelms = conv.weight.data.numel()

    return status, weight, bias, scale, rmean, rvar

#-------------------------------------------------------------------------------
def handle_fc( num
             , fc
             , rigor=False
             , verbose=False):
    """
    """
    status = True
    weight = {}
    bias   = {}
    if fc.bias is not None:
        if fc.bias.is_cuda:
            bias[num] = convert2cpu(fc.bias.data).numpy()
        else:
            bias[num] = fc.bias.data.cpu().numpy()
        nelms = fc.bias.data.numel()

    if fc.weight.is_cuda:
        weight[num] = convert2cpu(fc.weight.data).numpy()
    else:
        weight[num] = fc.weight.data.cpu().numpy()
    nelms = fc.weight.data.numel()

    return status, weight, bias

#-------------------------------------------------------------------------------
def get_params( model
               , start=0
               , end=-1
               , rigor=False
               , verbose=False):
    """
    Return Torch Tensor of weights and biases.
    conv_weigths {1: array([[[[-0.1381462 ,  ... 0.00484613]]]], dtype=float32),
                  2: array([[[[-8.17815512e-02,  ....]]]], dtype=float32),
    conv_biases {1: array([-0.16303228, ... 0.06072688], dtype=float32),
                 2: array([ 0.10309243, ... 0.15813802], dtype=float32)}
    fc_weights {}
    fc_biases  {}
    :model: state update model
    :start: starting layer
    :end: ending layer, -1 or 0 for all
    """
    if end<=0: cutoff= len(list(model.__dict__['_modules'].items())[0][1])
    else:      cutoff=end

    status = True
    conv_weights= {}
    conv_biases = {}
    bn_scales   = {}
    bn_means    = {}
    bn_variance = {}
    fc_weights  = {}
    fc_biases   = {}

    num_conv=1
    num_bn=1
    num_fc=1
    steps = 0
    items = list(model.__dict__['_modules'].items())[0][1]
    itm = 0
    while itm < len(items):
        fname = items[itm].__class__.__name__
        if ((itm+1)<len(items)): fname_next = items[itm+1].__class__.__name__
        else:                    fname_next = None
        conv = None
        bn   = None
        fc   = None
        if fname == 'Conv2d' and fname_next == 'BatchNorm2d':
            if verbose: print(f"itm={itm} fname={fname} fname_next={fname_next}")
            conv = items[itm]
            bn   = items[itm+1]
            itm += 1
            status, w, b, s, m, v = handle_conv_bn(num_conv, num_bn, conv, bn, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing header for convolutional and batch norm layer")
                return False, weights, biases
            conv_weights.update(w)
            conv_biases.update(b)
            bn_scales.update(s)
            bn_means.update(m)
            bn_variance.update(v)
            num_conv += 1
            num_bn   += 1
        elif fname == 'Conv2d':
            if verbose: print(f"itm={itm} fname={fname}")
            conv = items[itm]
            status, w, b, _, _, _ = handle_conv_bn(num_conv, -1, conv, None, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing header for convolutional and batch norm layer")
                return False, weights, biases
            conv_weights.update(w)
            conv_biases.update(b)
            num_conv += 1
        elif fname == 'Linear':
            if verbose: print(f"itm={itm} fname={fname}")
            fc = items[itm]
            status, w, b = handle_fc(num_fc, fc, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing header for fully connected layer")
                return False, weights, biases
            fc_weights.update(w)
            fc_biases.update(b)
            num_fc += 1
        else:
            if rigor and verbose: print(f"fname={fname} not matched")

        itm += 1
        steps += 1
        if steps>=cutoff: break

    if rigor and verbose: print(f"steps={steps} cutoff={cutoff}")
    return status, conv_weights, conv_biases, fc_weights, fc_biases

#-------------------------------------------------------------------------------
def plot_histogram( ww
                  , title
                  , rigor=False
                  , verbose=False):
    Nmin = np.min(ww) # min value of X
    Nmax = np.max(ww) # max value of X
    Nzero = np.count_nonzero(ww==0) # num of zeroes
    Nsize = np.size(ww) # total number of elements
    if Nsize>=1024*1024: NsizeStr = f"{Nsize/(1024*1024)} Mega"
    elif Nsize>=1024: NsizeStr = f"{Nsize/(1024)} Kilo"
    else: NsizeStr = f"{Nsize}"
    #print(f"min={Nmin} max={Nmax} #zero={Nzero}")
    plt.grid(axis='y', alpha=0.75)
    plt.xlabel('Value')
    plt.ylabel('Frequency')
    plt.title(title)
    n, bins, patches = plt.hist(x=ww, alpha=0.7)
    #n, bins, patches = plt.hist(x=ww, bins='auto', color='#0504AA', alpha=0.7, rwidth=0.85)
    #n, bins, patches = plt.hist(x=ww)
    #print(f"n={n} bins={bins} patches={patches}")
    plt.text(Nmin, np.max(n)*0.8, f"# of elements: {NsizeStr}")
    plt.text(Nmin, np.max(n)*0.7, f"# of zeroes: {Nzero}")
    plt.show(block=False)
    plt.pause(2)
    plt.close()

#-------------------------------------------------------------------------------
def plot_kernels( ww
                , title
                , rigor=False
                , verbose=False):
    plt.imshow(ww[:,:,0])
    plt.show(block=False)
    plt.pause(2)
    plt.close()
    #kernels = torch.from_numpy(ww)
    #kernels = kernels - kernels.min()
    #kernels = kernels / kernels.max()
    #img = make_grid(kernels)
    #plt.imshow(im.permute(1,2,0), cmap='gray')
    #plt.show()

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    def get_args():
        parser = argparse.ArgumentParser(description='PyTorch LeNet-5')
        parser.add_argument('-i', '--input_channels', type=int, default=1,
                            metavar='input_channels',
                            help='input channel size (default: 1)')
        parser.add_argument('-c', '--checkpoint', type=str, default="checkpoints/mnist_params_final.pth",
                            metavar='checkpoint',
                            help='model path_file_name for checkpoint (default: checkpoints/mnist_params_final.pth)')
        parser.add_argument('-r', '--rigor', action='store_true',
                            help='make rigorous (default: False)')
        parser.add_argument('-v', '--verbose', action='store_true',
                            help='make verbose (default: False)')
        args = parser.parse_args()
        return args

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    args = get_args()

    if not os.path.exists(args.checkpoint):
        print(args.checkpoint, "not exist")
        quit()

    model = Lenet5Model(args.input_channels)

    summary_str, (total_params, trainable_params) = summary(model, (args.input_channels, 32, 32))
    if args.verbose:
        print(summary_str)

    extension = os.path.splitext(args.checkpoint)[1]
    if extension == '.pkl':
        model = torch.load(args.checkpoint)
    elif extension == '.pth':
        model.load_state_dict(torch.load(args.checkpoint))
        model.eval()
    elif extension == '.onnx':
        model = torch.onnx.load(args.checkpoint)
        torch.onnix.checker.check_model(model)
    else:
        print("un-known data file: ", args.checkpoint);

    status, conv_weights, conv_biases, fc_weights, fc_biases = get_params(model, rigor=args.rigor, verbose=args.verbose)
    if status is True:
        if args.verbose is True:
            fullprint(f"conv_weigths {conv_weights}")
            fullprint(f"conv_biases {conv_biases}")
            fullprint(f"fc_weights {fc_weights}")
            fullprint(f"fc_biases {fc_biases}")
        for idx in range(len(conv_weights.keys())):
            #print(f"conv_weights[{idx+1}]={conv_weights[idx+1]}");
            ww = conv_weights[idx+1].flatten()
            plot_histogram( ww
                          , f"Convolution {idx+1} Weights"
                          , rigor=args.rigor
                          , verbose=args.verbose)
            #plot_kernels( ww
            #            , f"Convolution {idx+1} Kernels"
            #            , rigor=args.rigor
            #            , verbose=args.verbose)
        for idx in range(len(conv_biases.keys())):
            ww = conv_biases[idx+1] #.flatten()
            plot_histogram( ww
                          , f"Convolution {idx+1} Biases"
                          , rigor=args.rigor
                          , verbose=args.verbose)
        for idx in range(len(fc_weights.keys())):
            ww = fc_weights[idx+1] #.flatten()
            plot_histogram( ww
                          , f"Fully-connected {idx+1} Weights"
                          , rigor=args.rigor
                          , verbose=args.verbose)
        for idx in range(len(fc_biases.keys())):
            ww = fc_biases[idx+1] #.flatten()
            plot_histogram( ww
                          , f"Fully-connected {idx+1} Biases"
                          , rigor=args.rigor
                          , verbose=args.verbose)
    else:
        print("Something went wrong while getting params")

#===============================================================================
# Revision history:
#
# 2020.10.01: Started by Ando Ki (adki@future-ds.com)
#===============================================================================
