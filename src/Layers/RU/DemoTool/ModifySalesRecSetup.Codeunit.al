codeunit 119044 "Modify Sales & Rec. Setup"
{

    trigger OnRun()
    begin
        "Sales & Receivables Setup".Get();
        "Create No. Series".InsertSeriesOnly("Sales & Receivables Setup"."Order Nos.", XSAL + '-12-4', XSalesOrderManufacturing, true, false, true);
        "Create No. Series".InsertSeriesLine("Sales & Receivables Setup"."Order Nos.", XSORDM, 10000, 0D, 1);
        "Sales & Receivables Setup"."Order Nos." := XSAL + '-12-4';
        "Sales & Receivables Setup".Modify();
    end;

    var
        "Sales & Receivables Setup": Record "Sales & Receivables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XSORDM: Label 'SOM';
        XSalesOrderManufacturing: Label 'Sales Order (Manufacturing)';
        XSAL: Label 'SAL';

    procedure Finalize()
    begin
        "Sales & Receivables Setup".Get();
        "Sales & Receivables Setup"."Order Nos." := XSAL + '-12';
        "Sales & Receivables Setup".Modify();
    end;
}

