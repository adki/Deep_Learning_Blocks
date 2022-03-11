#!/usr/bin/env python
"""
This file contains LeNet-5 training script
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
__description__= "LeNet-5 network model training script"

#-------------------------------------------------------------------------------
import argparse
import shutil
import os
import sys
from datetime import datetime

import numpy as np

import torch
from torchvision.datasets import mnist
from torch.nn import CrossEntropyLoss
from torch.optim import SGD
from torch.utils.data import DataLoader
import torchvision.transforms as transforms
# Following causes AttributeError: 'SummaryWriter' object has no attribute 'export_scalars_to_json'
#from torch.utils.tensorboard import SummaryWriter
from tensorboardX import SummaryWriter

from darknet_lenet5_utils import *
from lenet5_model import Lenet5Model

#-------------------------------------------------------------------------------
def get_dataset( args ):
    """
    It prepares MNIST dataset.
    """
    train_dataset = mnist.MNIST( root='dataset.train' # see train/MNIST/
                               , train=True
                               , download=True
                               , transform=transforms.Compose([
                                           transforms.Resize((32, 32))
                                          ,transforms.Grayscale(num_output_channels=args.input_channels) # make 3 channels (does not work)
                                          ,transforms.ToTensor()]))
    test_dataset  = mnist.MNIST( root='dataset.test'
                               , train=False
                               , download=True
                               , transform=transforms.Compose([
                                           transforms.Resize((32, 32))
                                          ,transforms.Grayscale(num_output_channels=args.input_channels) # make 3 channels (does not work)
                                          ,transforms.ToTensor()]))
    train_loader  = DataLoader( train_dataset
                              , batch_size=args.batch_size
                              , num_workers=8)
    test_loader   = DataLoader( test_dataset
                              , batch_size=args.batch_size
                              , num_workers=8)
    return train_loader, test_loader

#-------------------------------------------------------------------------------
def build_model( args ):
    """
    It build LeNet-5 model and load checkpoint if specified.
    """
    if args.pre_trained_type == 'none':
        model = Lenet5Model(args.input_channels)
    else:
        extension = os.path.splitext(args.pre_trained_weights)[1]
        if extension == '.pkl': # args.pre_trained_weights.endswitch('.pkl')
            model = torch.load(args.pre_trained_weights)
        elif extension == '.pth':
            if args.pre_trained_type == 'model':
                model = torch.load(args.pre_trained_weights)
            elif args.pre_trained_type == 'params':
                model = Lenet5Model(args.input_channels)
                model.load_state_dict(torch.load(args.pre_trained_weights))
            else:
                print(f"Model type {args.pre_trained_type} not known")
                return None, None, None
        elif extension == '.onnx':
            model = torch.onnx.load(args.pre_trained_weights)
            torch.onnix.checker.check_model(model)
        elif extension == '.weights':
            model = Lenet5Model(args.input_channels)
            load_weights(model, args.pre_trained_weights)
        else:
            print("un-known data file: ", args.pre_trained_weights);
            return None, None, None
    optimizer = SGD(model.parameters(), lr=args.learning_rate)
    cross_error = CrossEntropyLoss() # loss function
    return model, optimizer, cross_error

#-------------------------------------------------------------------------------
def train_one_mini_batch( args
                        , model
                        , images # input images
                        , labels # expected label for the input images
                        , cross_error # error function
                        , optimizer # otptimizer
                        ):
    """
    It runs a train on a mini-batch, which consists of a number of images.
    """
    predicts = model(images.float())
    error = cross_error(predicts, labels.long()) # CrossEntropyLoss(calculated, expected)
    optimizer.zero_grad()
    error.backward() # loss
    optimizer.step()
    return error

#-------------------------------------------------------------------------------
def evaluate_one_mini_batch( args
                           , model
                           , images # input images
                           , labels # expected label
                           ):
    """
    It runs an evaluation on a mini-batch, which consists of a number of images.
    """
    predicts = model(images.float()).detach()
    predicts_ys = np.argmax(predicts, axis=-1) # get id of max value
    matched = predicts_ys == labels
    correct = np.sum(matched.numpy(), axis=-1) # num of mached
    sum = matched.shape[0] # number of items (images) in the mini-batch
    return correct, sum

#-------------------------------------------------------------------------------
def save_checkpoint( args
                   , model
                   , accuracy
                   , epoch
                   , name="mnist"
                   ):
    """
    It saves 'checkpoint' if required.
    It returns 'True' for end-condition.
    """
    if not hasattr(save_checkpoint, "accuracy_old"):
       save_checkpoint.accuracy_old = 0

    accuracy_old = save_checkpoint.accuracy_old;

    if accuracy>accuracy_old:
        torch.save(model, f"{args.checkpoints}{os.sep}{name}_model_{accuracy:.3f}.pth")
        torch.save(model.state_dict(), f"{args.checkpoints}{os.sep}{name}_params_{accuracy:.3f}.pth")
        dummy_input = torch.randn(1, args.input_channels, 32, 32, requires_grad=True)
                                 #batch_size, input_channel, input_height, input_width
        torch.onnx.export(model, dummy_input,
                          f"{args.checkpoints}{os.sep}{name}_model_{accuracy:.3f}.onnx")
        if (not args.keep) and (f"{accuracy_old:.3f}" != f"{accuracy:.3f}"):
            pathX = f"{args.checkpoints}{os.sep}{name}_model_{accuracy_old:.3f}.pth"
            if os.path.exists(pathX): os.remove(pathX)
            pathX = f"{args.checkpoints}{os.sep}{name}_params_{accuracy_old:.3f}.pth"
            if os.path.exists(pathX): os.remove(pathX)
            pathX = f"{args.checkpoints}{os.sep}{name}_model_{accuracy_old:.3f}.onnx"
            if os.path.exists(pathX): os.remove(pathX)
            pathX = f"{args.checkpoints}{os.sep}{name}_{accuracy_old:.3f}.weights"
            if os.path.exists(pathX): os.remove(pathX)
        save_checkpoint.accuracy_old = accuracy
    
    if (float(accuracy)>=float(args.accuracy)):
        torch.save(model, f"{args.checkpoints}{os.sep}{name}_model_final.pth")
        torch.save(model.state_dict(), f"{args.checkpoints}{os.sep}{name}_params_final.pth")
        dummy_input = torch.randn(1, args.input_channels, 32, 32, requires_grad=False)
        torch.onnx.export(model, dummy_input, f"{args.checkpoints}{os.sep}{name}_model_final.onnx")
        save_weights(model, f"{args.checkpoints}{os.sep}{name}_final.weights")
        print(f"Look {args.checkpoints}{os.sep}{name}_model_final.pth")
        print(f"Look {args.checkpoints}{os.sep}{name}_params_final.pth")
        print(f"Look {args.checkpoints}{os.sep}{name}_model_final.onnx")
        print(f"Look {args.checkpoints}{os.sep}{name}_final.weights")
        return True
    elif epoch == (args.epochs-1):
        torch.save(model, f"{args.checkpoints}{os.sep}{name}_model_last.pth")
        torch.save(model.state_dict(), f"{args.checkpoints}{os.sep}{name}_params_last.pth")
        dummy_input = torch.randn(1, args.input_channels, 32, 32, requires_grad=False)
        torch.onnx.export(model, dummy_input, f"{args.checkpoints}{os.sep}{name}_model_last.onnx")
        save_weights(model, f"{args.checkpoints}{os.sep}{name}_last.weights")
        print(f"Look {args.checkpoints}{os.sep}{name}_model_last.pth")
        print(f"Look {args.checkpoints}{os.sep}{name}_param_last.pth")
        print(f"Look {args.checkpoints}{os.sep}{name}_model_last.onnx")
        print(f"Look {args.checkpoints}{os.sep}{name}_last.weights")
    return False

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    def get_args():
        parser = argparse.ArgumentParser(description='PyTorch LeNet-5')
        parser.add_argument('-i', '--input_channels', type=int, default=1,
                            metavar='input_channels',
                            help='input channel size (default: 1)')
        parser.add_argument('-b', '--batch_size', type=int, default=100, # 60,000/100=600 iteration==> one epoch
                            metavar='batch_size',
                            help='input batch size (default: 100)')
        parser.add_argument('-e', '--epochs', type=int, default=100,
                            metavar='epochs',
                            help='number of epochs to train (default: 100)')
        parser.add_argument('-l', '--learning_rate', type=float, default=0.1,
                            metavar='learning_rate',
                            help='learning rate (default: 0.1)')
        parser.add_argument('-a', '--accuracy', type=float, default=0.99,
                            metavar='accuracy',
                            help='accuracy (default: 0.99)')
        parser.add_argument('-c', '--checkpoints', type=str, default="checkpoints",
                            metavar='checkpoints',
                            help='directory name for checkpoint (default: checkpoints)')
        parser.add_argument('-t', '--pre_trained_type', type=str
                           ,choices=["params", "model", "weights", "none"]
                           ,default="none"
                           ,metavar='type'
                           ,help='type of pre-trained weights: \"model\", \"params\", \"weights\", or \"none\" (default: \"model\")')
        parser.add_argument('-w', '--pre_trained_weights', type=str, default="checkpoints/mnist_params_final.pth",
                            metavar='file_name',
                            help="pre-trained weight or model path_file_name for checkpoint when '--type' is not none (default: checkpoints/mnist_final.pth)")
        parser.add_argument('-g', '--logdir', type=str, default="tensorboard",
                            metavar='logdir',
                            help='directory name for log (default: tensorboard)')
        parser.add_argument('-k', '--keep', action='store_true',
                            help='make keep intermediate weights (default: False)')
        parser.add_argument('-r', '--rigor', action='store_true',
                            help='set rigor (default: False)')
        parser.add_argument('-v', '--verbose', action='store_true',
                            help='make verbose (default: False)')
        parser.add_argument('-d', '--debug', action='store_true',
                            help='make debug (default: False)')
        args = parser.parse_args()
        return args

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    args = get_args()

    if not os.path.exists(args.checkpoints): os.makedirs(args.checkpoints)

    train_loader, test_loader = get_dataset( args )
    model, optimizer, cross_error = build_model( args )
    model.train() # let the model know it is training, i.e., it sets the mode to train

    if args.debug:
        items = list(model.__dict__['_modules'].items())[0][1]
        print(f"{items[0].__class__.__name__}.bias.data={items[0].bias.data}")

    if os.path.isdir(args.logdir): shutil.rmtree(args.logdir)
    os.makedirs(args.logdir)
    log = SummaryWriter(args.logdir)
    log.add_graph(model, torch.rand(args.batch_size, args.input_channels, 32, 32))

    if args.debug:
        print(f"{items[0].__class__.__name__}.bias.data={items[0].bias.data}")

    if args.verbose:
        # Print model and optimizer and cross_error
        print(model)
        print(model.__dict__['_modules'])
        print(optimizer)
        print(cross_error)
        # Print model's state_dict
        print("Model's state_dict:")
        for param_tensor in model.state_dict():
            print(param_tensor, "\t", model.state_dict()[param_tensor].size())

        # Print optimizer's state_dict
        print("Optimizer's state_dict:")
        for var_name in optimizer.state_dict():
            print(var_name, "\t", optimizer.state_dict()[var_name])

    time_start = datetime.now()
    for epoch in range(args.epochs):
        time_start_epoch = datetime.now()
        for idx, (train_x, train_label) in enumerate(train_loader):
            # idx: 0 to (num of mini-batches 600,000/100 -1 )[0:599]
            # train_x: 100 images of size 32x32
            # train_label: 100 elements
            model.train() # set the mode to train
            error = train_one_mini_batch(args, model, train_x, train_label, cross_error, optimizer)
            if idx % (args.batch_size) == 0: # print error after each batch
                print('idx: {}, error: {}'.format(idx, error))

        correct = 0
        sum = 0
        for idx, (test_x, test_label) in enumerate(test_loader):
            model.eval() # set the mode to evaluate (not to train)
            c, s = evaluate_one_mini_batch(args, model, test_x, test_label)
            correct += c # accumulate the num of mached
            sum += s # accumulate the number of items

        accuracy = correct/sum # ratio of correct from sum
        time_elapsed_epoch = datetime.now() - time_start_epoch
        time_elapsed       = datetime.now() - time_start
        print(f"epoch: {epoch}, accuracy: {accuracy}, elapsed: {time_elapsed_epoch} {time_elapsed}")
        print("----------------------------------")

        log.add_scalar('Train/accuracy', accuracy, epoch)
        log.add_scalar('Train/error', error, epoch)

        if save_checkpoint(args, model, accuracy, epoch):
           break

    log.export_scalars_to_json(args.logdir + os.sep + "all_logs.json")
    log.close()

#===============================================================================
# Revision history:
#
# 2020.10.01: Started by Ando Ki (adki@future-ds.com)
#===============================================================================
