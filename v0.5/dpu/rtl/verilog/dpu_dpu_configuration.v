
    dpu_configuration #(.APB_WIDTH_AD      ( P_APB_WIDTH_AD )
                       ,.APB_WIDTH_DA      ( P_APB_WIDTH_DA )
                       ,.AXI_WIDTH_AD      ( M_AXI_WIDTH_AD )
                       ,.AXI_WIDTH_DA      ( M_AXI_WIDTH_DA )
                       ,.DATA_TYPE         ( P_DATA_TYPE    )
                       ,.DATA_WIDTH        ( P_DATA_WIDTH   )
                       `ifdef LINEAR_FIXED_POINT
                       ,.DATA_WIDTH_Q      ( P_DATA_WIDTH_Q )
                       `endif
                       )
    u_dpu_configuration (
          .PRESETn            ( PRESETn    )
        , .PCLK               ( PCLK       )
        , .PSEL               ( PSEL    [0])
        , .PENABLE            ( PENABLE    )
        , .PADDR              ( PADDR      )
        , .PWRITE             ( PWRITE     )
        , .PRDATA             ( PRDATA  [0])
        , .PWDATA             ( PWDATA     )
        , .PREADY             ( PREADY  [0])
        , .PSLVERR            ( PSLVERR [0])
        , .module_convolution ( module_convolution )
        , .module_pooling     ( module_pooling     )
        , .module_linear      ( module_linear      )
        , .module_mover       ( module_mover       )
    );
