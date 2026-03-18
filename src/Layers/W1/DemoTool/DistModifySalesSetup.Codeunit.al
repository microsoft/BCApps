codeunit 118811 "Dist. Modify Sales Setup"
{

    trigger OnRun()
    begin
        "Sales & Receivables Setup".Get();
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Order Nos.", XSORDD, XSalesOrderDist, 6);
        "Sales & Receivables Setup"."Order Nos." := XSORDD;
        "Sales & Receivables Setup".Modify();
    end;

    var
        "Sales & Receivables Setup": Record "Sales & Receivables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XSORDD: Label 'S-ORD-D';
        XSalesOrderDist: Label 'Sales Order (Dist)';
        XSORD1: Label 'S-ORD-1';

    procedure Finalize()
    begin
        "Sales & Receivables Setup".Get();
        "Sales & Receivables Setup"."Order Nos." := XSORD1;
        "Sales & Receivables Setup".Modify();
    end;
}

