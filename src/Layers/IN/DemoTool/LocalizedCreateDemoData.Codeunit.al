codeunit 101903 "Localized Create Demo Data"
{

    trigger OnRun()
    begin
    end;

    procedure CreateDataBeforeActions()
    begin
    end;

    procedure CreateDataAfterActions()
    begin
    end;

    procedure CreateEvaluationData()
    var
        CreateSalesHeader: Codeunit "Create Sales Header";
        CreateSalesLine: Codeunit "Create Sales Line";
        CreatePurchHeader: Codeunit "Create Purchase Header";
        CreatePurchLine: Codeunit "Create Purchase Line";
        CreateTransferOrderAdd: Codeunit "Create Transfer Order Add.";
        AddNoSeries: Codeunit "Add No. Series";
        AddNoSeriesLine: Codeunit "Add No. Series Line";
        XINSALES: Label 'IN-SALES';
        XIN00001: Label 'IN-SI-00001';
        XPostedINSales: Label 'Posted Sales IN Invoice';
    begin
        AddNoSeries.InsertRec(XINSALES, XPostedINSales, '1');
        AddNoSeriesLine.InsertRec(XINSALES, 10000, XIN00001, '', 19030127D);

        CreateSalesHeader.CreateINSalesOrders();
        CreateSalesLine.CreateINSalesOrderLines();
        CreateSalesHeader.CreateINSalesInvoice();
        CreateSalesLine.CreateSalesInvLines();
        CreateSalesHeader.CreateINSalesCrMemo();
        CreateSalesLine.CreateSalesCrMemoLines();

        CreatePurchHeader.CreateINPurchOrder();
        CreatePurchHeader.CreateINPurchInvoice();
        CreatePurchHeader.CreateINPurchCrMemo();

        CreatePurchLine.CreateINPurchOrderLines();
        CreatePurchLine.CreateINPurchInvoiceLines();
        CreatePurchLine.CreateINPurchCrMemoLines();

        CreateTransferOrderAdd.CreateINTransferOrder();
    end;

    procedure CreateExtendedData()
    begin
    end;
}

