codeunit 163405 "Create VAT Sales Ledgers"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();

        InsertLedger(1, XSB + '1007', CA.AdjustDate(19021001D), CA.AdjustDate(19021031D));
        ProcessLedger(1, XSB + '1007');

        InsertLedger(1, XSB + '1107', CA.AdjustDate(19021101D), CA.AdjustDate(19021130D));
        ProcessLedger(1, XSB + '1107');

        InsertLedger(1, XSB + '1207', CA.AdjustDate(19021201D), CA.AdjustDate(19021231D));
        ProcessLedger(1, XSB + '1207');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        VATLedger: Record "VAT Ledger";
        CA: Codeunit "Make Adjustments";
        CreateVATSalesLedger: Report "Create VAT Sales Ledger";
        XSB: Label 'SB';

    procedure InsertLedger(Type: Option Purchase,Sales; "Code": Code[20]; StartDate: Date; EndDate: Date)
    begin
        VATLedger.Init();
        VATLedger.Type := Type;
        VATLedger.Code := Code;
        VATLedger.Validate("Start Date", StartDate);
        VATLedger.Validate("End Date", EndDate);
        if VATLedger.Insert() then;
    end;

    procedure ProcessLedger(Type: Option Purchase,Sales; "Code": Code[20])
    begin
        Clear(CreateVATSalesLedger);
        VATLedger.SetRange(Type, Type);
        VATLedger.SetRange(Code, Code);
        CreateVATSalesLedger.SetTableView(VATLedger);
        CreateVATSalesLedger.InitializeRequest('');
        CreateVATSalesLedger.UseRequestPage(false);
        CreateVATSalesLedger.RunModal();
    end;
}

