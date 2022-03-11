#!/usr/bin/env python
"""
This file contains LeNet-5 network model.
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
__description__= "LeNet-5 network model"

#-------------------------------------------------------------------------------
import torch
import torch.nn as nn
import torch.nn.functional as F

#-------------------------------------------------------------------------------
class Lenet5Model(nn.Module):
    def __init__(self, input_channels=1):
        super(Lenet5Model, self).__init__()
        self.input_channels = input_channels
        self.model = nn.Sequential(
                     nn.Conv2d( in_channels=input_channels  # should be 1, but 3 for test
                              , out_channels=6
                              , kernel_size=(5,5)
                              , stride=1#(1,1)
                              , padding=0#(0,0)
                              , bias=True),# nn.Conv2d(1,6,5)
                     nn.ReLU(), #nn.LeakyReLU(negative_slope=0.01),
                     nn.MaxPool2d( kernel_size=(2,2)
                                 , stride=2#(2,2)
                                 , padding=0#(0,0)
                                 , dilation=1),# nn.MaxPool2d(2)
                     nn.Conv2d( in_channels=6
                              , out_channels=16
                              , kernel_size=5#(5,5)
                              , stride=1#(1,1)
                              , padding=0#(0,0)
                              , bias=True),# nn.Conv2d(6,16,5)
                     nn.ReLU(), #nn.LeakyReLU(negative_slope=0.01),
                     nn.MaxPool2d( kernel_size=(2,2)
                                 , stride=2#(2,2)
                                 , padding=0#(0,0)
                                 , dilation=1),# nn.MaxPool2d(2)
                     nn.Flatten( start_dim=1 # exclude batch
                               , end_dim=-1),# y = y.view(y.shape[0], -1)
                     nn.Linear( in_features=16*5*5
                              , out_features=120 # nn.Linear(400, 120)
                              , bias=True),
                     nn.ReLU(), #nn.LeakyReLU(negative_slope=0.01),
                     nn.Linear( in_features=120
                              , out_features=84 # nn.Linear(84, 84)
                              , bias=True),
                     nn.ReLU(), #nn.LeakyReLU(negative_slope=0.01),
                     nn.Linear( in_features=84
                              , out_features=10 # nn.Linear(84, 10)
                              , bias=True)
                     )

    def forward(self, x): # without softmax, fast converge and better result
        y = self.model(x) 
        return y

    def infer(self, x, softmax=True):
        y = self.forward(x)
        if softmax: y = F.softmax(y, dim=1)
        return y

#-------------------------------------------------------------------------------
if __name__ == '__main__':
    model = Lenet5Model()
    print(model)
    print("Model's state_dict:") # Print model's state_dict
    for param_tensor in model.state_dict():
        print(param_tensor, "\t", model.state_dict()[param_tensor].size())
    ## prints the weight and bias of the model
    #print(list(model.parameters())) # long print

#===============================================================================
# Revision history:
#
# 2020.10.01: Started by Ando Ki (adki@future-ds.com)
#===============================================================================
