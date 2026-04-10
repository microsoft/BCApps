codeunit 118811 "Dist. Modify Sales Setup"
{

    trigger OnRun()
    begin
        "Sales & Receivables Setup".Get();
        "Create No. Series".InsertSeriesOnly("Sales & Receivables Setup"."Order Nos.", XSAL + '-12-1', XSalesOrderDist, true, false, true);
        "Create No. Series".InsertSeriesLine("Sales & Receivables Setup"."Order Nos.", XSORDD, 10000, 0D, 1);
        "Sales & Receivables Setup"."Order Nos." := XSAL + '-12-1';
        "Sales & Receivables Setup".Modify();
    end;

    var
        "Sales & Receivables Setup": Record "Sales & Receivables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XSORDD: Label 'SOD';
        XSalesOrderDist: Label 'Sales Order (Dist)';
        XSAL: Label 'SAL';

    procedure Finalize()
    begin
        "Sales & Receivables Setup".Get();
        "Sales & Receivables Setup"."Order Nos." := XSAL + '-12';
        "Sales & Receivables Setup".Modify();
    end;
}

