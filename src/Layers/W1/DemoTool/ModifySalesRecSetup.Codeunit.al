codeunit 119044 "Modify Sales & Rec. Setup"
{

    trigger OnRun()
    begin
        "Sales & Receivables Setup".Get();
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Order Nos.", XSORDM, XSalesOrderManufacturing, 9);
        "Sales & Receivables Setup"."Order Nos." := XSORDM;
        "Sales & Receivables Setup".Modify();
    end;

    var
        "Sales & Receivables Setup": Record "Sales & Receivables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XSORDM: Label 'S-ORD-M';
        XSalesOrderManufacturing: Label 'Sales Order (Manufacturing)';
        XSORD1: Label 'S-ORD-1';

    procedure Finalize()
    begin
        "Sales & Receivables Setup".Get();
        "Sales & Receivables Setup"."Order Nos." := XSORD1;
        "Sales & Receivables Setup".Modify();
    end;
}

