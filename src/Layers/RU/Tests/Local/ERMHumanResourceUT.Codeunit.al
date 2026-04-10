codeunit 147202 "ERM Human Resource UT"
{
    // // [FEATURE] [UI] [UT]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchAdvanceReportsPageHandler(var PostedPurchAdvanceReports: TestPage "Posted Purch. Advance Reports")
    begin
        LibraryVariableStorage.Enqueue(Format(PostedPurchAdvanceReports."No.".Value));
        LibraryVariableStorage.Enqueue(Format(PostedPurchAdvanceReports."Buy-from Vendor No.".Value));
        PostedPurchAdvanceReports.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicesPageHandler(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    begin
        LibraryVariableStorage.Enqueue(Format(PostedPurchaseInvoices."No.".Value));
        LibraryVariableStorage.Enqueue(Format(PostedPurchaseInvoices."Buy-from Vendor No.".Value));
        PostedPurchaseInvoices.Close();
    end;
}

