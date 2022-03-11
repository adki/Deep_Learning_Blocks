#!/usr/bin/env python
"""
This file contains script to deal with Darknet weights.
"""
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

#-------------------------------------------------------------------------------
__author__     = "Ando Ki"
__copyright__  = "Copyright 2020 Ando Ki"
__credits__    = ["some", "some"]
__license__    = "The 2-Clause BSD License"
__version__    = "0"
__revision__   = "2"
__maintainer__ = "Ando Ki"
__email__      = "contact@future-ds.com"
__status__     = "Development"
__date__       = "2021.10.09"
__description__= "Darknet weights handling for LeNet-5"

# It depends on model description style.
#-------------------------------------------------------------------------------
import numpy as np
import torch

def load_weights_conv_bn( conv
                        , bn
                        , weights
                        , ptr
                        , rigor=False
                        , verbose=False):
    """
    Return True and pointer on success
    :conv: 2D Convolutional layer
    :bn: 2D Barch Normal layer
    :weights: numpy array containg whole weights
    :ptr: strting point to read fro 'weights' numpy

    [convolution only layer]       [convolution with batch norm layer]
    [weights]                      [weights]
    +--------------------+         +--------------------+
    | basies [Co]        |         | basies [Co]        |
    +--------------------+         +--------------------+
    | weights            |         | scales [Co]        |
    |   [Co][Ci][Kh][Kw] |         +--------------------+
    +--------------------+         | running_means [Co] |
                                   +--------------------+
                                   | running_var [Co]   |
                                   +--------------------+
                                   | weights            |
                                   |   [Co][Ci][Kh][Kw] |
                                   +--------------------+
    """
    total = len(weights)
    if bn is not None:
        #Get the number of weights of Batch Norm Layer
        num_bn_biases = bn.bias.numel()
        
        #Load the biases, weights(scales), running_means, running_var
        bn_biases = torch.from_numpy(weights[ptr:ptr + num_bn_biases])
        ptr += num_bn_biases
        bn_weights = torch.from_numpy(weights[ptr: ptr + num_bn_biases])
        ptr  += num_bn_biases
        bn_running_mean = torch.from_numpy(weights[ptr: ptr + num_bn_biases])
        ptr  += num_bn_biases
        bn_running_var = torch.from_numpy(weights[ptr: ptr + num_bn_biases])
        ptr  += num_bn_biases
        if rigor and ptr > total:
            print(f"Weights ccess exceeds.")
        
        #Cast the loaded weights into dims of model weights. 
        bn_biases       = bn_biases.view_as(      bn.bias.data        )
        bn_weights      = bn_weights.view_as(     bn.weight.data      )
        bn_running_mean = bn_running_mean.view_as(bn.running_mean.data)
        bn_running_var  = bn_running_var.view_as( bn.running_var.data )

        if verbose:
            print(f"bn.bias        .numel()={bn.bias        .numel()}")
            print(f"bn.weight      .numel()={bn.weight      .numel()}")
            print(f"bn.running_mean.numel()={bn.running_mean.numel()}")
            print(f"bn.running_var .numel()={bn.running_var .numel()}")
        
        #Copy the data to model
        bn.bias.data.copy_(   bn_biases      )
        bn.weight.data.copy_( bn_weights     )
        bn.running_mean.copy_(bn_running_mean)
        bn.running_var.copy_( bn_running_var )

        if conv.bias is not None:
           print("Warning convolution followed by Batch Norm has biase")
    else:
        # Some convolutional layer does not have bias.
        if conv.bias is not None:
            #Number of biases
            num_biases = conv.bias.numel()
            #Load the biases
            conv_biases = torch.from_numpy(weights[ptr: ptr + num_biases])
            ptr = ptr + num_biases
            #reshape the loaded weights according to the dims of the model weights
            conv_biases = conv_biases.view_as(conv.bias.data)
            #Finally copy the data
            if verbose: print(f"conv.bias.numel()={conv.bias.data.numel()}")
            conv.bias.data.copy_(conv_biases)

    #Let us load the weights for the Convolutional layers
    num_weights = conv.weight.numel()
    #Load the weights
    conv_weights = torch.from_numpy(weights[ptr:ptr+num_weights])
    ptr = ptr + num_weights
    #Cast the loaded weights into dims of model weights. 
    conv_weights = conv_weights.view_as(conv.weight.data)
    #Copy the data to model
    if verbose: print(f"conv.weight.numel()={conv.weight.numel()}")
    conv.weight.data.copy_(conv_weights)

    return True, ptr

#-------------------------------------------------------------------------------
def load_weights_fc( fc
                   , weights
                   , ptr
                   , rigor=False
                   , verbose=False):
    total = len(weights)
    if fc.bias is not None:
        #Number of biases
        num_biases = fc.bias.numel()
        #Load the biases
        fc_biases = torch.from_numpy(weights[ptr: ptr + num_biases])
        ptr = ptr + num_biases
        #reshape the loaded weights according to the dims of the model weights
        fc_biases = fc_biases.view_as(fc.bias.data)
        #Finally copy the data
        if verbose: print(f"fc.bias.numel()={fc.bias.numel()}")
        fc.bias.data.copy_(fc_biases)

        if rigor and ptr > total:
            print(f"Access exceeds.")

    #Let us load the weights for the Fully connected layers
    num_weights = fc.weight.numel()
    #Do the same as above for weights
    if verbose: print(f"fc.weight.numel()={fc.weight.numel()}")
    fc_weights = torch.from_numpy(weights[ptr:ptr+num_weights])
    ptr = ptr + num_weights
    fc_weights = fc_weights.view_as(fc.weight.data)
    fc.weight.data.copy_(fc_weights)

    return True, ptr

#-------------------------------------------------------------------------------
def load_weights( model
                , weights_file
                , cutoff=-1
                , rigor=False
                , verbose=False):
    """
    Return True on success.
    :model: model with or without trained parameters
    :weight_file: file containing weights that will be loaded to the model
    :cutoff: -1 or 0 for all.
    Following shows network model comprised: print(list(model.__dict__['_modules'].items())[0][1])
    Sequential((0): Conv2d(3, 6, kernel_size=(5, 5), stride=(1, 1))
               (1): ReLU()
               (2): MaxPool2d(kernel_size=(2, 2), stride=2, padding=0, dilation=1, ceil_mode=False)
               (3): Conv2d(6, 16, kernel_size=(5, 5), stride=(1, 1))
               (4): ReLU()
               (5): MaxPool2d(kernel_size=(2, 2), stride=2, padding=0, dilation=1, ceil_mode=False)
               (6): Flatten()
               (7): Linear(in_features=400, out_features=120, bias=True)
               (8): ReLU()
               (9): Linear(in_features=120, out_features=84, bias=True)
               (10): ReLU()
               (11): Linear(in_features=84, out_features=10, bias=True)
              )

    Weights file format
    (major*10+minor)<2          (major*10+minor)>=2
    +-------------------+       +-------------------+
    | major (4-byte)    |       | major (4-byte)    |
    +-------------------+       +-------------------+
    | minor (4-byte)    |       | minor (4-byte)    |
    +-------------------+       +-------------------+
    | revision (4-byte) |       | revision (4-byte) |
    +-------------------+       +-------------------+
    | seen     (4-byte) |       | seen     (8-byte) |
    +-------------------+       +-------------------+
    | layer 0           |       | layer 0           |
    +-------------------+       +-------------------+
    | ...........       |       | ...........       |
    +-------------------+       +-------------------+
    | layer x           |       | layer x           |
    +-------------------+       +-------------------+
    """
    if cutoff<=0: cutoff= len(list(model.__dict__['_modules'].items())[0][1])

    if type(weights_file) == str: fp = open(weights_file, 'rb')
    else: fp = weights_file

    header = np.fromfile(fp, count=3, dtype=np.int32)
    version_major   = header[0]
    version_minor   = header[1]
    version_revision= header[2]
    if (version_major*10 + version_minor) >= 2:
        seen = np.fromfile(fp, count=1, dtype=np.int64)
    else:
        seen = np.fromfile(fp, count=1, dtype=np.int32)
    weights = np.fromfile(fp, dtype=np.float32)
    fp.close()
    if verbose: print(f"version_major   ={version_major   }")
    if verbose: print(f"version_minor   ={version_minor   }")
    if verbose: print(f"version_revision={version_revision}")
    if verbose: print(f"seen            ={seen            }")

    steps = 0
    ptr = 0
    # (********************************************** do apply after making sequential model of LeNet-5
    if verbose:
        print(f"model={model}")
        print(f"model.__dict__={model.__dict__}")
        print(f"model.__dict__['_modules']={model.__dict__['_modules']}")
        print(f"model.__dict__['_modules'].items()={model.__dict__['_modules'].items()}")
        print(f"list(model.__dict__['_modules'].items())[0]={list(model.__dict__['_modules'].items())[0]}")
        print(f"list(model.__dict__['_modules'].items())[0][0]={list(model.__dict__['_modules'].items())[0][0]}")
        print(f"list(model.__dict__['_modules'].items())[0][1]={list(model.__dict__['_modules'].items())[0][1]}")
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
            status, ptr = load_weights_conv_bn(conv, bn, weights, ptr, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while loading weights for convolutional and batch norm layer")
                return False
            if verbose:
                print(f"bn.bias={bn.bias} bn.bias.data={bn.bias.data}")
                print(f"bn.weight={bn.weight} bn.weight.data={bn.weight.data}")
                print(f"bn.running_mean={bn.running_mean} bn.running_mean.data={bn.running_mean.data}")
                print(f"bn.running_var={bn.running_var} bn.running_var.data={bn.running_var.data}")
                print(f"conv.weight={conv.weight} conv.weight.data={conv.weight.data}")
        elif fname == 'Conv2d':
            if verbose: print(f"itm={itm} fname={fname}")
            conv = items[itm]
            status, ptr = load_weights_conv_bn(conv, bn, weights, ptr, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while loading weights for convolutional and batch norm layer")
                return False
            if verbose:
                print(f"conv.bias={conv.bias} conv.bias.data={conv.bias.data}")
                print(f"conv.weight={conv.weight} conv.weight.data={conv.weight.data}")

        elif fname == 'Linear':
            if verbose: print(f"itm={itm} fname={fname}")
            fc = items[itm]
            status, ptr = load_weights_fc(fc, weights, ptr, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while loading weights for fully connected layer")
                return False
            if verbose:
                print(f"fc.bias={fc.bias} fc.bias.data={fc.bias.data}")
                print(f"fc.weight={fc.weight} fc.weight.data={fc.weight.data}")
        else:
            if rigor and verbose: print(f"fname={fname} not matched")

        itm += 1
        steps += 1
        if steps>=cutoff: break

    if rigor:
        if ptr != len(weights):
            print(f"Weights access not matched: weights={len(weights)} pt={ptr}")
            # if 300 items mismatch occurs, check input channels and it should be 3.
        else:
            print(f"Weights access matched: weights={len(weights)}")

    if rigor and verbose: print(f"steps={steps} cutoff={cutoff}")

    return True

    ##print(model)
    ##print(model.__dict__)
    ##print(model.__dict__['num_classes'])
    ##print(model.__dict__['_modules'])
    ##print(f"model.__dict__[index]>")
    ##for index in model.__dict__:
    ##    print(f"model.__dict__[{index}]")
    ##print("model.__dict__['_modules'][index]>")
    ##for index in model.__dict__['_modules']:
    ##    print(f"model.__dict__['_modules'][{index}]")
    ##print(f"model.__dict__['_modules'][index]>")
    ##for index in model.__dict__['_modules']:
    ##    print(f"{index} {model.__dict__['_modules'][index]}")
    ##for index in model.__dict__['_modules']:
    ##    print(f"model.__dict__['_modules'][index][blk]>")
    ##    for blk in model.__dict__['_modules'][index]:
    ##        print(f"blk={blk}")
    ##        #print(f"{model.__dict__['_modules'][index][blk]}")
    #for index in model.__dict__['_modules']:
    #    exist = list(dict(model.__dict__['_modules'][index].named_children()).keys())
    #    if 'BatchNorm2d' in exist: print("found")
    #    else: print("not found")

    #    #exist = list(dict(model.__dict__['_modules'][index].named_children()).keys()).index('BatchNorm2d')
    #    #if exist:
    #    #    print(f"found {model.__dict__['_modules'][index][0]} {model.__dict__['_modules'][index][1]}")
    #    #else:
    #    #    print(f"not found {model.__dict__['_modules'][index][0]}")

#-------------------------------------------------------------------------------
def save_weights_conv_bn( conv
                        , bn
                        , fp
                        , rigor=False
                        , verbose=False):
    """
    """
    if bn is not None:
        if bn.bias.is_cuda:
            convert2cpu(bn.bias.data).numpy().tofile(fp)
            convert2cpu(bn.weight.data).numpy().tofile(fp)
            convert2cpu(bn.running_mean).numpy().tofile(fp)
            convert2cpu(bn.running_var).numpy().tofile(fp)
        else:
            bn.bias.data.cpu().numpy().tofile(fp)
            bn.weight.data.cpu().numpy().tofile(fp)
            bn.running_mean.cpu().numpy().tofile(fp)
            bn.running_var.cpu().numpy().tofile(fp)
    else:
        if conv.bias is not None:
            if conv.bias.is_cuda:
                convert2cpu(conv.bias.data).numpy().tofile(fp)
            else:
                conv.bias.data.cpu().numpy().tofile(fp)
    if conv.weight.is_cuda:
        convert2cpu(conv.weight.data).numpy().tofile(fp)
    else:
        conv.weight.data.cpu().numpy().tofile(fp)

    return True

#-------------------------------------------------------------------------------
def save_weights_fc( fc
                   , fp
                   , rigor=False
                   , verbose=False):
    """
    """
    if fc.bias is not None:
        if fc.bias.is_cuda:
            convert2cpu(fc.bias.data).numpy().tofile(fp)
        else:
            fc.bias.data.cpu().numpy().tofile(fp)

    if fc.weight.is_cuda:
        convert2cpu(fc.weight.data).numpy().tofile(fp)
    else:
        fc.weight.data.cpu().numpy().tofile(fp)

    return True

#-------------------------------------------------------------------------------
def save_weights( model
                , weights_file
                , header_major=0
                , header_minor=2
                , header_revision=0
                , header_seen=1
                , cutoff=-1
                , rigor=False
                , verbose=False):
    """
    Return True on success.
    :model: PyTorch model having trained weights
    :weight_file: file to store weights
    :header_major: 32-bit version major
    :header_minor: 32-bit version minor
    :header_revision: 32-bit version revision
    :header_seen: 32- or 64-bit seen (the number of images handled)
    :cutoff: -1 or 0 for all. It corresponds each layer including conv, batch norm, activation, pooling, ..
    """
    if cutoff<=0: cutoff= len(list(model.__dict__['_modules'].items())[0][1])

    if type(weights_file) == str: fp = open(weights_file, 'wb')
    else: fp = weights_file

    np.int32(header_major).tofile(fp)
    np.int32(header_minor).tofile(fp)
    np.int32(header_revision).tofile(fp)
    if (header_major*10 + header_minor) >= 2:
        np.int64(header_seen).tofile(fp)
    else:
        np.int32(header_seen).tofile(fp)

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
            status = save_weights_conv_bn(conv, bn, fp, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing weights for convolutional and batch norm layer")
                fp.close()
                return False
        elif fname == 'Conv2d':
            if verbose: print(f"itm={itm} fname={fname}")
            conv = items[itm]
            status = save_weights_conv_bn(conv, bn, fp, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing weights for convolutional and batch norm layer")
                fp.close()
                return False
        elif fname == 'Linear':
            if verbose: print(f"itm={itm} fname={fname}")
            fc = items[itm]
            status = save_weights_fc(fc, fp, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing weights for fully connected layer")
                fp.close()
                return False
        else:
            if rigor and verbose: print(f"fname={fname} not matched")

        itm += 1
        steps += 1
        if steps>=cutoff: break

    fp.close()
    if rigor and verbose: print(f"steps={steps} cutoff={cutoff}")
    return True

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
def save_header_conv_bn( num_conv
                       , num_bn
                       , conv
                       , bn
                       , fp
                       , rigor=False
                       , verbose=False):
    """
    """
    if bn is not None:
        if bn.bias.is_cuda:
            biases = convert2cpu(bn.bias.data)
            scales = convert2cpu(bn.weight.data)
            rmeans = convert2cpu(bn.running_mean)
            rvars  = convert2cpu(bn.running_var)
        else:
            biases = bn.bias.data.cpu()
            scales = bn.weight.data.cpu()
            rmeans = bn.running_mean.cpu()
            rvars  = bn.running_var.cpu()
        nelms = bn.bias.data.numel()
        print(f"const unsigned int bn{num_bn}_num_bias={nelms};", file=fp)
        print(f"const float bn{num_bn}_bias[{nelms}]=", "{ //", f" {bn.bias.data.shape}", file=fp)
        fullprint_array_comma(biases, file=fp)
        print("};", file=fp)
        print(f"const unsigned int bn{num_bn}_num_scale={nelms};", file=fp)
        print(f"const float bn{num_bn}_scale[{nelms}]=", "{ //", f" {bn.bias.data.shape}", file=fp)
        fullprint_array_comma(scales, file=fp)
        print("};", file=fp)
        print(f"const unsigned int bn{num_bn}_num_mean={nelms};", file=fp)
        print(f"const float bn{num_bn}_mean[{nelms}]=", "{ //", f" {bn.bias.data.shape}", file=fp)
        fullprint_array_comma(rmeans, file=fp)
        print("};", file=fp)
        print(f"const unsigned int bn{num_bn}_num_var={nelms};", file=fp)
        print(f"const float bn{num_bn}_var[{nelms}]=", "{ //", f" {bn.bias.data.shape}", file=fp)
        fullprint_array_comma(rvars, file=fp)
        print("};", file=fp)
    else:
        if conv.bias is not None:
            if conv.bias.is_cuda:
                biases = convert2cpu(conv.bias.data)
            else:
                biases = conv.bias.data.cpu()
            ndim  = conv.bias.data.ndim
            shape = conv.bias.data.shape
            nelms = conv.bias.data.numel()
            print(f"const unsigned int conv{num_conv}_num_bias={nelms};", file=fp)
            print(f"const float conv{num_conv}_bias[{nelms}]=", "{ //", f" {conv.bias.data.shape}", file=fp)
            fullprint_array_comma(biases, file=fp)
            print("};", file=fp)
    if conv.weight.is_cuda:
        weights = convert2cpu(conv.weight.data)
    else:
        weights = conv.weight.data.cpu()
    ndim  = conv.weight.data.ndim
    shape = conv.weight.data.shape
    nelms = conv.weight.data.numel()
    if ndim != 4: return False
    print(f"const unsigned int conv{num_conv}_in_channel={shape[1]};", file=fp)
    print(f"const unsigned int conv{num_conv}_out_channel={shape[0]};", file=fp)
    if len(conv.kernel_size) == 1:
        print(f"const unsigned int conv{num_conv}_kernel_size[2]=","{",f"{conv.kernel_size[0]},{conv.kernel_size[0]}","};", file=fp)
    elif len(conv.kernel_size) == 2:
        print(f"const unsigned int conv{num_conv}_kernel_size[{len(conv.kernel_size)}]=","{",f"{conv.kernel_size[0]},{conv.kernel_size[1]}","};", file=fp)
    else:
        return False
    if type(conv.stride).__name__ == "int":
        print(f"const unsigned int conv{num_conv}_stride[2]=",end="",file=fp);
        print("{",f"{conv.stride},{conv.stride}","};", file=fp)
    elif type(conv.stride).__name__ == "tuple":
        if len(conv.stride) == 1:
            print(f"const unsigned int conv{num_conv}_stride[2]=",end="",file=fp);
            print("{",f"{conv.stride[0]},{conv.stride[0]}","};", file=fp)
        elif len(conv.stride) == 2:
            print(f"const unsigned int conv{num_conv}_stride[{len(conv.stride)}]=",end="",file=fp);
            print("{",f"{conv.stride[0]},{conv.stride[1]}","};", file=fp)
        else:
            return False
    else:
        return False
    if type(conv.padding).__name__ == "int":
        print(f"const unsigned int conv{num_conv}_padding[2]=",end="",file=fp);
        print("{",f"{conv.padding},{conv.padding}","};", file=fp)
    elif type(conv.padding).__name__ == "tuple":
        if len(conv.padding) == 1:
            print(f"const unsigned int conv{num_conv}_padding[2]=",end="",file=fp);
            print("{",f"{conv.padding[0]},{conv.padding[0]}","};", file=fp)
        elif len(conv.padding) == 2:
            print(f"const unsigned int conv{num_conv}_padding[{len(conv.padding)}]=",end="",file=fp);
            print("{",f"{conv.padding[0]},{conv.padding[1]}","};", file=fp)
        else:
            return False
    else:
        return False
    print(f"const unsigned int conv{num_conv}_num_weight={nelms};", file=fp)
    print(f"const float conv{num_conv}_weight[{nelms}]=", "{ //", f" {conv.weight.data.shape}", file=fp)
    fullprint_array_comma(weights, file=fp)
    print("};", file=fp)

    return True

#-------------------------------------------------------------------------------
def save_header_fc( num_fc
                  , fc
                  , fp
                  , rigor=False
                  , verbose=False):
    """
    """
    if fc.bias is not None:
        if fc.bias.is_cuda:
            biass = convert2cpu(fc.bias.data)
        else:
            biass = fc.bias.data.cpu()
        nelms = fc.bias.data.numel()
        print(f"const unsigned int fc{num_fc}_num_bias={nelms};", file=fp)
        print(f"const float fc{num_fc}_bias[{nelms}]=", "{ //", f" {fc.bias.data.shape}", file=fp)
        fullprint_array_comma(biass, file=fp)
        print("};", file=fp)

    if fc.weight.is_cuda:
        weights = convert2cpu(fc.weight.data)
    else:
        weights = fc.weight.data.cpu()
    ndim   = fc.weight.data.ndim
    shape  = fc.weight.data.shape
    nelms  = fc.weight.data.numel()
    if ndim != 2: return False
    print(f"const unsigned int fc{num_fc}_out_features={shape[0]};", file=fp)
    print(f"const unsigned int fc{num_fc}_in_features={shape[1]};", file=fp)
    print(f"const unsigned int fc{num_fc}_num_weight={nelms};", file=fp)
    print(f"const float fc{num_fc}_weight[{nelms}]=", "{ //", f" {fc.weight.data.shape}", file=fp)
    fullprint_array_comma(weights, file=fp)
    print("};", file=fp)

    return True

#-------------------------------------------------------------------------------
def save_header_pool( num_pool
                    , pool
                    , fp
                    , rigor=False
                    , verbose=False):
    """
    """
    if len(pool.kernel_size) == 1:
        print(f"const unsigned int pool{num_pool}_kernel_size[2]=",end="",file=fp)
        print("{",f"{pool.kernel_size[0]},{pool.kernel_size[0]}","};", file=fp)
    elif len(pool.kernel_size) == 2:
        print(f"const unsigned int pool{num_pool}_kernel_size[{len(pool.kernel_size)}]=",end="",file=fp);
        print("{",f"{pool.kernel_size[0]},{pool.kernel_size[1]}","};", file=fp)
    else:
        return False
    if type(pool.stride).__name__ == "int":
        print(f"const unsigned int pool{num_pool}_stride[2]=",end="",file=fp);
        print("{",f"{pool.stride},{pool.stride}","};", file=fp)
    elif type(pool.stride).__name__ == "tuple":
        if len(pool.stride) == 1:
            print(f"const unsigned int pool{num_pool}_stride[2]=",end="",file=fp);
            print("{",f"{pool.stride[0]},{pool.stride[0]}","};", file=fp)
        elif len(pool.stride) == 2:
            print(f"const unsigned int pool{num_pool}_stride[{len(pool.stride)}]=",end="",file=fp);
            print("{",f"{pool.stride[0]},{pool.stride[1]}","};", file=fp)
        else:
            return False
    else:
        print(f"{type(pool.stride)}");
        return False
    if type(pool.padding).__name__ == "int":
        print(f"const unsigned int pool{num_pool}_padding[2]=",end="",file=fp);
        print("{",f"{pool.padding},{pool.padding}","};", file=fp)
    elif type(pool.padding).__name__ == "tuple":
        if len(pool.padding) == 1:
            print(f"const unsigned int pool{num_pool}_padding[2]=",end="",file=fp);
            print("{",f"{pool.padding[0]},{pool.padding[0]}","};", file=fp)
        elif len(pool.padding) == 2:
            print(f"const unsigned int pool{num_pool}_padding[{len(pool.padding)}]=",end="",file=fp);
            print("{",f"{pool.padding[0]},{pool.padding[1]}","};", file=fp)
        else:
            return False
    else:
        return False
    return True

#-------------------------------------------------------------------------------
def save_header( model
               , header_file
               , cutoff=-1
               , rigor=False
               , verbose=False):
    """
    Return True on success.
    :model: model having trained parameters
    :header_file: file to store header file (string or file object)
    :cutoff: -1 or 0 for all. It corresponds each layer including conv, batch norm, activation, pooling, ..
    """
    print(model)
    if cutoff<=0: cutoff= len(list(model.__dict__['_modules'].items())[0][1])

    if type(header_file) == str: fp = open(header_file, 'wb')
    else: fp = header_file

    print("#ifdef __cplusplus", file=fp);
    print("extern \"C\" {", file=fp);
    print("#endif", file=fp);

    num_conv=1
    num_bn=1
    num_fc=1
    num_pool=1
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
        pool = None
        if fname == 'Conv2d' and fname_next == 'BatchNorm2d':
            if verbose: print(f"itm={itm} fname={fname} fname_next={fname_next}")
            conv = items[itm]
            bn   = items[itm+1]
            itm += 1
            status = save_header_conv_bn(num_conv, num_bn, conv, bn, fp, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing header for convolutional and batch norm layer")
                fp.close()
                return False
            num_conv += 1
            num_bn   += 1
        elif fname == 'Conv2d':
            if verbose: print(f"itm={itm} fname={fname}")
            conv = items[itm]
            status = save_header_conv_bn(num_conv, num_bn, conv, bn, fp, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing header for convolutional and batch norm layer")
                fp.close()
                return False
            num_conv += 1
        elif fname == 'Linear':
            if verbose: print(f"itm={itm} fname={fname}")
            fc = items[itm]
            status = save_header_fc(num_fc, fc, fp, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing header for fully connected layer")
                fp.close()
                return False
            num_fc += 1
        elif fname == 'MaxPool2d' or fname == 'AvgPool2d':
            if verbose: print(f"itm={itm} fname={fname}")
            pool = items[itm]
            status = save_header_pool(num_pool, pool, fp, rigor=rigor, verbose=verbose)
            if status is not True:
                print("Something went wrong while writing header for pooling layer")
                fp.close()
                return False
            num_pool += 1
        else:
            if rigor and verbose: print(f"fname={fname} not matched")

        itm += 1
        steps += 1
        if steps>=cutoff: break

    print("#ifdef __cplusplus", file=fp)
    print("}", file=fp)
    print("#endif", file=fp)

    fp.close()
    if rigor and verbose: print(f"steps={steps} cutoff={cutoff}")
    return True

#===============================================================================
# Revision history:
#
# 2021.10.25: "save_header_conv_bn()" bug-fixed.
# 2021.10.09: "save_header_pool()" added.
# 2021.10.09: "conv?_num_in/out_channel, conv?_num_kernel_height/width, conv?_num_bias, fc?_num_in/out" added.
# 2021.10.08: "__cplusplus" added.
# 2020.10.01: Started by Ando Ki (adki@future-ds.com)
#===============================================================================
