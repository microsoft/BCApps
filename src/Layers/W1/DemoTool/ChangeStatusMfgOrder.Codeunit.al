codeunit 119072 "Change Status Mfg. Order"
{

    trigger OnRun()
    begin
        ChangeStatus(2, '1010001', ProductionOrderStatus::Released, 19030908D);
        ChangeStatus(2, '1010002', ProductionOrderStatus::Released, 19030909D);
        ChangeStatus(2, '1010003', ProductionOrderStatus::Released, 19030910D);
        ChangeStatus(2, '1010004', ProductionOrderStatus::Released, 19030911D);
    end;

    var
        ProductionOrder: Record "Production Order";
        ProdOrderChangeStatus: Codeunit "Prod. Order Status Management";
        MakeAdjustments: Codeunit "Make Adjustments";
        ProductionOrderStatus: Enum "Production Order Status";

    procedure ChangeStatus(Type: Integer; ProductionOrderNo: Code[20]; NewStatus: Enum "Production Order Status"; PostingDate: Date)
    begin
        ProductionOrder.Get(Type, ProductionOrderNo);
        ProdOrderChangeStatus.ChangeProdOrderStatus(ProductionOrder, NewStatus, MakeAdjustments.AdjustDate(PostingDate), false);
    end;
}

