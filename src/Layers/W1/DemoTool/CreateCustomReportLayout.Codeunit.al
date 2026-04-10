codeunit 101400 "Create Custom Report Layout"
{
    trigger OnRun()
    begin
        UpdateReportSelections();
        UpdateReportLayoutSelections();
        UpdateEmailBodySelections();
    end;

    var
        MS1303Email: Label 'SalesInvoiceSimpleEmail.docx', Locked = true;
        MS1304Email: Label 'StandardSalesQuoteEmail.docx', Locked = true;
        MS1305Email: Label 'StandardOrderConfirmationEmail.docx', Locked = true;
        MS1306EmailDef: Label 'StandardSalesInvoiceDefEmail.docx', Locked = true;
        MS1307EmailDef: Label 'StandardSalesCreditMemoEmail.docx', Locked = true;
        MS1316EmailDef: Label 'StandardCustomerStatementEmail.docx', Locked = true;
        MS1322EmailDef: Label 'StandardPurchaseOrderEmail.docx', Locked = true;
        MS117EmailDef: Label 'DefaultReminderEmail.docx', Locked = true;
        MS1303BlueSimple: Label 'StandardDraftSalesInvoiceBlue.docx', Locked = true;
        MS1304BlueSimple: Label 'StandardSalesQuoteBlue.docx', Locked = true;
        MS1306BlueSimple: Label 'StandardSalesInvoiceBlueSimple.docx', Locked = true;
        MS1302Default: Label 'StandardSalesProFormaInv.docx', Locked = true;
        MS1308BlueSimple: Label 'SimpleSalesShipment.docx', Locked = true;
        MS1309BlueSimple: Label 'SimpleSalesReturnReceipt.docx', Locked = true;

    local procedure AddEmailBodyLayout(ReportID: Integer; ReportLayoutName: Text)
    var
        ReportSelections: Record "Report Selections";
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange(Name, ReportLayoutName);
        if not ReportLayoutList.FindFirst() then
            exit;

        ReportSelections.SetRange("Report ID", ReportID);
        if ReportSelections.FindFirst() then begin
            ReportSelections.Validate("Use for Email Body", true);
            ReportSelections.Validate("Email Body Layout Name", CopyStr(ReportLayoutName, 1, MaxStrLen(ReportSelections."Email Body Layout Name")));
            ReportSelections.Modify(true);
        end;
    end;

    local procedure UpdateEmailBodySelections()
    begin
        // Add default email body layouts to the report selections
        AddEmailBodyLayout(REPORT::"Standard Sales - Quote", Format(MS1304Email));
        AddEmailBodyLayout(REPORT::"Standard Sales - Order Conf.", Format(MS1305Email));
        AddEmailBodyLayout(REPORT::"Standard Sales - Invoice", Format(MS1306EmailDef));
        AddEmailBodyLayout(REPORT::"Standard Sales - Credit Memo", Format(MS1307EmailDef));
        AddEmailBodyLayout(REPORT::"Standard Sales - Draft Invoice", Format(MS1303Email));
        AddEmailBodyLayout(REPORT::"Standard Statement", Format(MS1316EmailDef));
        AddEmailBodyLayout(REPORT::"Standard Purchase - Order", Format(MS1322EmailDef));
        AddEmailBodyLayout(REPORT::Reminder, Format(MS117EmailDef));
    end;

    local procedure UpdateReportSelections()
    var
        DummyReportSelections: Record "Report Selections";
    begin
        UpdateRepSelection(DummyReportSelections.Usage::"S.Order", '1', REPORT::"Standard Sales - Order Conf.");
        UpdateRepSelection(DummyReportSelections.Usage::"S.Invoice", '1', REPORT::"Standard Sales - Invoice");
        UpdateRepSelection(DummyReportSelections.Usage::"S.Cr.Memo", '1', REPORT::"Standard Sales - Credit Memo");
        UpdateRepSelection(DummyReportSelections.Usage::"S.Quote", '1', REPORT::"Standard Sales - Quote");
        UpdateRepSelection(DummyReportSelections.Usage::"P.Order", '1', REPORT::"Standard Purchase - Order");
    end;

    local procedure UpdateRepSelection(ReportUsage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(ReportUsage, Sequence) then
            exit;
        ReportSelections.Validate("Report ID", ReportId);
        ReportSelections.Modify(true);
    end;

    local procedure UpdateReportLayoutSelections()
    begin
        // For rapidstart packages, see 101995 and processing rules to control the defaults.
        UpdateRepLayoutSelection(REPORT::"Standard Sales - Invoice", MS1306BlueSimple);
        UpdateRepLayoutSelection(REPORT::"Standard Sales - Draft Invoice", MS1303BlueSimple);
        UpdateRepLayoutSelection(REPORT::"Standard Sales - Quote", MS1304BlueSimple);
        UpdateRepLayoutSelection(REPORT::"Standard Sales - Pro Forma Inv", MS1302Default);
        UpdateRepLayoutSelection(REPORT::"Standard Sales - Shipment", MS1308BlueSimple);
        UpdateRepLayoutSelection(REPORT::"Standard Sales - Return Rcpt.", MS1309BlueSimple);
    end;

    local procedure UpdateRepLayoutSelection(ReportID: Integer; ReportLayoutName: Text[250])
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange(Name, ReportLayoutName);
        if not ReportLayoutList.FindFirst() then
            exit;

        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := ReportID;
        TenantReportLayoutSelection."Layout Name" := ReportLayoutName;
        TenantReportLayoutSelection."App ID" := ReportLayoutList."Application ID";

        if not TenantReportLayoutSelection.Insert(true) then
            TenantReportLayoutSelection.Modify(true);
    end;
}
