codeunit 118812 "Dist. Create Sales Header"
{

    trigger OnRun()
    begin
        CreateSalesHeader.InsertData(1, '49525252', 19031012D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '49525252', 19031016D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '49633663', 19031022D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '49633663', 19030127D, '', '', '', '', 0, '');

        CreateSalesHeader.InsertData(1, '10000', 19030118D, '', '', '', '', 0, '');

        "Sales & Receivables Setup".Get();
        "Create No. Series".InsertSeriesOnly("Sales & Receivables Setup"."Order Nos.", XSAL + '-12-3', XSalesOrderDist, true, false, true);
        "Create No. Series".InsertSeriesLine("Sales & Receivables Setup"."Order Nos.", XSORDD1, 10000, 0D, 1);
        "Sales & Receivables Setup"."Order Nos." := XSAL + '-12-3';
        "Sales & Receivables Setup".Modify();

        CreateSalesHeader.InsertData(1, '10000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '20000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '30000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '40000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '60000', 19030118D, '', '', '', '', 0, '');

        CreateSalesHeader.InsertData(1, '10000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '20000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '30000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '40000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '60000', 19030118D, '', '', '', '', 0, '');

        CreateSalesHeader.InsertData(1, '10000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '20000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '30000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '40000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '61000', 19030118D, '', '', '', '', 0, '');

        CreateSalesHeader.InsertData(1, '60000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '61000', 19030118D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '62000', 19030118D, '', '', '', '', 0, '');

        CreateSalesHeader.InsertData(1, '61000', 19030131D, '', '', '', '', 0, '');
        CreateSalesHeader.InsertData(1, '62000', 19030131D, '', '', '', '', 0, '');

        CreateSalesHeader.InsertData(1, '60000', 19030118D, '', '', '', '', 0, '');
    end;

    var
        CreateSalesHeader: Codeunit "Create Sales Header";
        "Sales & Receivables Setup": Record "Sales & Receivables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XSORDD1: Label 'SOD1';
        XSalesOrderDist: Label 'Sales Order (Dist)';
        XSAL: Label 'SAL';
}

