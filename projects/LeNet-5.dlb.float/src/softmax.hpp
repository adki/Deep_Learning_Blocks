#pragma once
//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------

template<class TYPE=float>
void softmax(const TYPE * const input, const int n, double * const output)
{
    int i;
    double sum = 0;
    double max = (double)input[0];
    for(i = 1; i < n; ++i) {
        if((double)input[i] > max) max = (double)input[i];
    }

    for(i = 0; i < n; ++i){
        double e = exp((double)input[i] - max);
        sum += e;
        output[i] = e;
    }
    for(i = 0; i < n; ++i){
        output[i] /= sum;
    }
}

