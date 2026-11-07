codeunit 101316 "Create Order Promising Setup"
{

    trigger OnRun()
    begin
        if not OrderPromSetup.Get() then
            OrderPromSetup.Insert();
        Evaluate(OrderPromSetup."Offset (Time)", '<1D>');
        "Create No. Series".InitBaseSeries(OrderPromSetup."Order Promising Nos.", XOPROM, XOrderPromising, XOP101001, XOP199999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        if ReqWkshTemplate.FindFirst() then begin
            OrderPromSetup."Order Promising Template" := ReqWkshTemplate.Name;
            ReqWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
            if ReqWkshName.FindFirst() then
                OrderPromSetup."Order Promising Worksheet" := ReqWkshName.Name;
        end;
        OrderPromSetup."Order Promising Nos." := XOPROM;
        OrderPromSetup.Modify();
    end;

    var
        OrderPromSetup: Record "Order Promising Setup";
        "Create No. Series": Codeunit "Create No. Series";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        XOPROM: Label 'O-PROM';
        XOrderPromising: Label 'Order Promising';
        XOP101001: Label 'OP101001';
        XOP199999: Label 'OP199999';
}

