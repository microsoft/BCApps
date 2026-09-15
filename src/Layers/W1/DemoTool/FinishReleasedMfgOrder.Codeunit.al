codeunit 119075 "Finish Released Mfg. Order"
{

    trigger OnRun()
    begin
        FinishProdOrder('1011001', 19030909D);
    end;

    var
        ChangeStatusMfgOrder: Codeunit "Change Status Mfg. Order";

    procedure FinishProdOrder(OrderNo: Code[20]; PostDate: Date)
    begin
        ChangeStatusMfgOrder.ChangeStatus(3, OrderNo, "Production Order Status"::Finished, PostDate);
    end;
}

