#!/usr/bin/env python
"""
This file contains LeNet-5 inferencing script.
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
__description__= "LeNet-5 network model inferencing script"

#-------------------------------------------------------------------------------
import argparse
import os
import sys

import numpy as np

from PIL import Image
from PIL import ImageOps
import matplotlib.pyplot as plt

import torch
import torchvision as tv
import torchvision.transforms as tf

from darknet_lenet5_utils import *
from lenet5_model import Lenet5Model

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    def get_args():
        parser = argparse.ArgumentParser(description='PyTorch LeNet-5')
        parser.add_argument('-i', '--input_channels', type=int, default=1,
                            metavar='input_channels',
                            help='input channel size (default: 1)')
        parser.add_argument('-t', '--type', type=str
                           ,choices=["params", "model", "weights"]
                           ,default="params"
                           ,metavar='type'
                           ,help='type of state: \"model\", \"params\" or \"weights\" (default: \"params\")')
        parser.add_argument('-c', '--checkpoint', type=str, default="checkpoints/mnist_params_final.pth",
                            metavar='file_name',
                            help='model path_file_name for checkpoint (default: checkpoints/mnist_final.pth)')
        parser.add_argument('-s', '--softmax', action='store_true',
                            help='set rigor (default: False)')
        parser.add_argument('-r', '--rigor', action='store_true',
                            help='set rigor (default: False)')
        parser.add_argument('-v', '--verbose', action='store_true',
                            help='make verbose (default: False)')
        parser.add_argument('-d', '--debug', action='store_true',
                            help='make debug (default: False)')
        parser.add_argument('image', type=str,
                            help='image path_file_name to infer')
        args = parser.parse_args()
        return args

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
outputs=[]
def hook( module, input, output ):
    """ for nn.MODULE object, the signature for the hook function,
        hook(module, grad_input, grad_output) -> Tensor or None
    """
    #outputs.update({module.__class__.__name__: output}) # when outputs={} for dictionary
    outputs.append(module.__class__.__name__)
    outputs.append(input)
    outputs.append(output)

def hook_fn( module, input, output ):
    print(module)
    print("------------Input Grad------------")
    
    for grad in input:
      try:
        print(grad.shape)
      except AttributeError: 
        print ("None found for Gradient")
    
    print("------------Output Grad------------")
    for grad in output:
      try:
        print(grad.shape)
      except AttributeError: 
        print ("None found for Gradient")
    print("\n")

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    args = get_args()

    if not os.path.exists(args.checkpoint):
        print(args.checkpoint, "not exist")
        quit()

    extension = os.path.splitext(args.checkpoint)[1]
    if extension == '.pkl':
        model = Lenet5Model(args.input_channels)
        model = torch.load(args.checkpoint)
    elif extension == '.pth':
        if args.type == 'model':
            model = torch.load(args.checkpoint)
        elif args.type == 'params':
            model = Lenet5Model(args.input_channels)
            model.load_state_dict(torch.load(args.checkpoint))
        else:
            print(f"Model type {args.type} not known")
    elif extension == '.onnx':
        model = torch.onnx.load(args.checkpoint)
        torch.onnix.checker.check_model(model)
    elif extension == '.weights':
        model = Lenet5Model(args.input_channels)
        if args.debug:
            for name, param in model.named_parameters():
                print(f"name={name}")
            for k, v in model.state_dict().items():
                print(k, type(v))
        #if args.debug:
        #    print(f"model.state_dict()={model.state_dict()}")
        #    items = list(model.__dict__['_modules'].items())[0][1]
        #    print(f"{items[0].__class__.__name__}.bias.data={items[0].bias.data}")
        #    print(f"{items[0].__class__.__name__}.weight.data={items[0].weight.data}")
        status = load_weights( model, args.checkpoint, cutoff=-1, rigor=args.rigor, verbose=args.verbose)
        if not status: print(f"Error while loding {args.checkpoint}")
        #if args.debug:
        #    print(f"{items[0].__class__.__name__}.bias.data={items[0].bias.data}")
    else:
        print("un-known data file: ", args.checkpoint);

    if args.debug:
        try:
            items
        except NameError:
            items = list(model.__dict__['_modules'].items())[0][1]
        if args.debug:
            """To get bias ans weights of 0-th layer"""
            print(f"{items[0].__class__.__name__}.bias.data={items[0].bias.data}")
            print(f"{items[0].__class__.__name__}.weight.data={items[0].weight.data}")
            print(f"items={items}")
        for itm in items:
            print(f"itm={itm}")
            itm.register_forward_hook(hook)
            #itm.register_forward_hook(hook_fn)
        #(list(model.__dict__['_modules'].items())[0][1])[0].register_forward_hook(hook)
        #(list(model.__dict__['_modules'].items())[0][1])[1].register_forward_hook(hook)
        #(list(model.__dict__['_modules'].items())[0][1])[2].register_forward_hook(hook)

    model.eval() # not for train

    if args.verbose:
        print(f"model={model}")
        print(f"model.__dict__['_modules']={model.__dict__['_modules']}")
        # Print model's state_dict
        print("Model's state_dict:")
        for param_tensor in model.state_dict():
            print(param_tensor, "\t", model.state_dict()[param_tensor].size())

    if not os.path.exists(args.image):
        print(args.image, "not exist")
        quit()

    img = Image.open(args.image)
    img = img.resize((32,32), Image.ANTIALIAS)
    img.show() #img.save('x.png')
    if img.mode != 'L': # Not Luminance
        if args.verbose: print("Convert to grayscale")
        img = img.convert('L') # get luminance using Pillow convert()
        img.show() #img.save('x.png')
        img = ImageOps.invert(img)
        img.show() #img.save('x.png')
    if args.input_channels != 1:
        if args.verbose: print(f"need to convert {args.input_channels}-channel to 1-channel")
        img = np.stack([img]*args.input_channels, axis=-1)
    data = tv.transforms.ToTensor()(img)
    #print(data)
    #print(data.shape, data.ndim)
    data = data.view(-1,args.input_channels,32,32) # make [mini_batch, channel, height(rows), width(cols)]
                                 # -1 force to infer from other dimensions
    #torch.set_printoptions(profile="full")
    #print(data)
    result = model.infer(data, args.softmax).view(10) #result = result.view(10)
    max_ind = torch.argmax(result)
    for idx in range(10):
        if idx == max_ind:
            print(f"{idx}: {result[idx]:7.2f} *")
        else:
            print(f"{idx}: {result[idx]:7.2f}")
    if args.debug:
        """when 'debug' is set and 'Hook' is used."""
        fullprint(f"outputs={outputs}")

#===============================================================================
# Revision history:
#
# 2020.10.01: Started by Ando Ki (adki@future-ds.com)
#===============================================================================
