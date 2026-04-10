codeunit 163404 "Create VAT Purchase Ledgers"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();

        InsertLedger(0, XPB + '1007', CA.AdjustDate(19021001D), CA.AdjustDate(19021031D));
        ProcessLedger(0, XPB + '1007');

        InsertLedger(0, XPB + '1107', CA.AdjustDate(19021101D), CA.AdjustDate(19021130D));
        ProcessLedger(0, XPB + '1107');

        InsertLedger(0, XPB + '1207', CA.AdjustDate(19021201D), CA.AdjustDate(19021231D));
        ProcessLedger(0, XPB + '1207');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        VATLedger: Record "VAT Ledger";
        CA: Codeunit "Make Adjustments";
        CreateVATPurchLedger: Report "Create VAT Purchase Ledger";
        XPB: Label 'PB';

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
        Clear(CreateVATPurchLedger);
        VATLedger.SetRange(Type, Type);
        VATLedger.SetRange(Code, Code);
        CreateVATPurchLedger.SetTableView(VATLedger);
        CreateVATPurchLedger.InitializeRequest(false, '', true);
        CreateVATPurchLedger.UseRequestPage(false);
        CreateVATPurchLedger.RunModal();
    end;
}

