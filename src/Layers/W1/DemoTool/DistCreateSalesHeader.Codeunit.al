codeunit 118812 "Dist. Create Sales Header"
{

    trigger OnRun()
    begin
        CreateSalesHeader.InsertData(1, '49525252', 19031012D);
        CreateSalesHeader.InsertData(1, '49525252', 19031016D);
        CreateSalesHeader.InsertData(1, '49633663', 19031022D);
        CreateSalesHeader.InsertData(1, '49633663', 19030127D);
        CreateSalesHeader.InsertData(1, '10000', 19030118D);

        "Sales & Receivables Setup".Get();
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Order Nos.", XSORDD1, XSalesOrderDist, 104);
        "Sales & Receivables Setup"."Order Nos." := XSORDD1;
        "Sales & Receivables Setup".Modify();

        CreateSalesHeader.InsertData(1, '10000', 19030118D);
        CreateSalesHeader.InsertData(1, '20000', 19030118D);
        CreateSalesHeader.InsertData(1, '30000', 19030118D);
        CreateSalesHeader.InsertData(1, '40000', 19030118D);
        CreateSalesHeader.InsertData(1, '60000', 19030118D);

        CreateSalesHeader.InsertData(1, '10000', 19030118D);
        CreateSalesHeader.InsertData(1, '20000', 19030118D);
        CreateSalesHeader.InsertData(1, '30000', 19030118D);
        CreateSalesHeader.InsertData(1, '40000', 19030118D);
        CreateSalesHeader.InsertData(1, '60000', 19030118D);

        CreateSalesHeader.InsertData(1, '10000', 19030118D);
        CreateSalesHeader.InsertData(1, '20000', 19030118D);
        CreateSalesHeader.InsertData(1, '30000', 19030118D);
        CreateSalesHeader.InsertData(1, '40000', 19030118D);
        CreateSalesHeader.InsertData(1, '61000', 19030118D);

        CreateSalesHeader.InsertData(1, '60000', 19030118D);
        CreateSalesHeader.InsertData(1, '61000', 19030118D);
        CreateSalesHeader.InsertData(1, '62000', 19030118D);

        CreateSalesHeader.InsertData(1, '61000', 19030131D);
        CreateSalesHeader.InsertData(1, '62000', 19030131D);

        CreateSalesHeader.InsertData(1, '60000', 19030118D);
    end;

    var
        CreateSalesHeader: Codeunit "Create Sales Header";
        "Sales & Receivables Setup": Record "Sales & Receivables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XSORDD1: Label 'S-ORD-D1';
        XSalesOrderDist: Label 'Sales Order (Dist)';
}

