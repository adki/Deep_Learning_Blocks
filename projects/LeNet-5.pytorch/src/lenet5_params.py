#!/usr/bin/env python
"""
This file contains LeNet-5 parameter script.
"""
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

#-------------------------------------------------------------------------------
__author__     = "Ando Ki"
__copyright__  = "Copyright 2020 Ando Ki"
__credits__    = ["none", "some"]
__license__    = "The 2-Clause BSD License"
__version__    = "0"
__revision__   = "1"
__maintainer__ = "Ando Ki"
__email__      = "contact@future-ds.com"
__status__     = "Development"
__date__       = "2020.10.01"
__description__= "LeNet-5 network model parameter script"

#-------------------------------------------------------------------------------
import argparse
import os
import sys

import numpy as np

import torch
from torchsummary import summary

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
if __name__ == '__main__':
    def get_args():
        parser = argparse.ArgumentParser(description='PyTorch LeNet-5')
        parser.add_argument('-i', '--input_channels', type=int, default=1,
                            metavar='input_channels',
                            help='input channel size (default: 1)')
        parser.add_argument('-c', '--checkpoint', type=str, default="checkpoints/mnist_params_final.pth",
                            metavar='checkpoint',
                            help='model path_file_name for checkpoint (default: checkpoints/mnist_params_final.pth)')
        parser.add_argument('-t', '--txt', type=str, default="None",
                            metavar='txt',
                            help='path_file_name to wirte parameters in ASCII text (default: standard output)')
        parser.add_argument('-b', '--bin', type=str, default="None",
                            metavar='bin',
                            help='path_file_name to wirte parameters in binary (default: standard output)')
        parser.add_argument('-a', '--header', type=str, default="None",
                            metavar='header',
                            help='path_file_name to wirte parameters in C header (default: standard output)')
        parser.add_argument('-d', '--darknet', type=str, default="None",
                            metavar='darknet',
                            help='path_file_name to wirte parameters in Darknet binary (default: standard output)')
        parser.add_argument('-v', '--verbose', action='store_true',
                            help='make verbose (default: False)')
        args = parser.parse_args()
        return args

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    def prepare_file( fname, mode ):
        try:
            if fname == 'None':
                fa = None
            elif fname == 'stdout':
                fa = sys.stdout
            else: fa = open(fname, mode)
        except OSError as err:
            print("OS error: could not open/write file: {0}".format(err))
        except IOError:
            print("Could not open.")
        except:
            print("Unexpected error:", sys.exc_info()[0])
            raise
        return fa

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    args = get_args()

    if not os.path.exists(args.checkpoint):
        print(args.checkpoint, "not exist")
        quit()

    fa = prepare_file( args.txt, 'w')
    fb = prepare_file( args.bin, 'wb')
    fc = prepare_file( args.header, 'w')
    fd = prepare_file( args.darknet, 'wb')

    model = Lenet5Model(args.input_channels)

    summary_str, (total_params, trainable_params) = summary(model, (args.input_channels, 32, 32))
    if args.verbose:
        print(summary_str, file=fa)

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

    if fd is not None:
        version_major    = 0
        version_minor    = 2
        version_revision = 0
        seen             = 1
        np.int32(version_major   ).tofile(fd)
        np.int32(version_minor   ).tofile(fd)
        np.int32(version_revision).tofile(fd)
        if (version_major*10+version_minor)>=2:
            np.int64(seen).tofile(fd)
        else:
            np.int32(seen).tofile(fd)

    for name, param in model.named_parameters():
        if param.requires_grad:
            #print(name, param.data, file=fa) # tensor
            #print(name, param.shape, '\n', param.data.numpy(), file=fa) # more precise
            if fa is not None:
                fullprint(name, param.shape, '\n', param.data.numpy(), file=fa) # more precise
            if fb is not None:
                #fb.write(param.data.numpy().astype('float32'))
                param.data.numpy().astype('float32').tofile(fb)
            if False:
                if fc is not None:
                    nelms = param.data.numel()
                    print(f"const float {name.replace('.','_')}[{nelms}]=", "{ //", f" {param.data.shape}", file=fc)
                    fullprint_array_comma(param.data, file=fc)
                    print("};", file=fc)
            if fd is not None:
                nelms = param.data.numel()
                param.data.numpy().astype('float32').tofile(fd)
    if fc is not None:
       save_header(model, header_file=fc)

    if (args.txt    != 'stdout') and (args.txt    != 'None'): fa.close()
    if (args.bin    != 'stdout') and (args.bin    != 'None'): fb.close()
    if (args.header != 'stdout') and (args.header != 'None'): fc.close()
    if (args.darknet!= 'stdout') and (args.darknet!= 'None'): fd.close()

    if (args.bin!='stdout') and (args.bin!='None'):
        """check size of binary file"""
        bnum  = os.path.getsize(args.bin)
        nbyte = trainable_params*4 # for 'float32'
        if (bnum!=nbyte):
           print(f"binary file \"{args.bin}\" size mis-match: {bnum}:{nbyte}")
        else:
            if args.verbose: print(f"binary file \"{args.bin}\" size OK.")

#===============================================================================
# Revision history:
#
# 2020.10.01: Started by Ando Ki (adki@future-ds.com)
#===============================================================================
