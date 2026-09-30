codeunit 144024 "UT REP VATREP"
{
    //  3 - 4. Purpose of this test is to validate Purchase Quote.
    //
    // Covers Test Cases for WI - 341554
    // -----------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                   TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordPurchaseQuote

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [VAT]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseQuote()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        No: Code[20];
    begin
        // Setup.
        Initialize();
        CreateResponsibilityCenter(ResponsibilityCenter);
        No := CreatePurchaseQuote(ResponsibilityCenter.Code);
        LibraryVariableStorage.Enqueue(No);  // Enqueue value for PurchaseQuoteRequestPageHandler.
        Commit();  // Commit required, because it is explicitly called by OnRun Trigger of Codeunit ID - 317 Purch.Header-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Quote");  // Open PurchaseQuoteRequestPageHandler.

        // Verify: Verify Purchase Quote No and Company Information Phone No on Report Purchase - Quote.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PurchHeadNo', No);
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoPhoneNo', ResponsibilityCenter."Phone No.");
    end;


    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;


    local procedure CreatePurchaseQuote(ResponsibilityCenter: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Vendor Invoice No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Responsibility Center" := ResponsibilityCenter;
        PurchaseHeader.Insert();
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Amount Including VAT" := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Insert();
        exit(PurchaseHeader."No.");
    end;


    local procedure CreateResponsibilityCenter(var ResponsibilityCenter: Record "Responsibility Center")
    begin
        ResponsibilityCenter.Code := LibraryUTUtility.GetNewCode10();
        ResponsibilityCenter."Phone No." := LibraryUTUtility.GetNewCode();
        ResponsibilityCenter.Insert();
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseQuote."Purchase Header".SetFilter("No.", No);
        PurchaseQuote.LogInteraction.SetValue(true);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

}
