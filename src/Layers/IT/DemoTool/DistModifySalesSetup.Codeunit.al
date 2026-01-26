codeunit 118811 "Dist. Modify Sales Setup"
{

    trigger OnRun()
    var
        "No. Series": Record "No. Series";
    begin
        "Sales & Receivables Setup".Get();
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Order Nos.", XSORDD, XSalesOrderDist, 6,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
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

