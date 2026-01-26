codeunit 139007 "Test Instruction Mgt. SaaS"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Post and Send] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostingInstructionNotShownForEmptySalesInvoice()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        // Exercise
        SalesInvoice.OpenNew();

        // Verify
        // Instruction is not displayed
        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostingInstructionNotShownAfterPostingAndSending()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesInvoice: TestPage "Sales Invoice";
        DocumentNo: Code[20];
    begin
        Initialize();

        DocumentSendingProfile.SetRange(Default, true);
        if DocumentSendingProfile.FindFirst() then begin
            DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::No;
            DocumentSendingProfile.Modify();
        end;

        // Setup
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '', '', 1, '', 0D);
        DocumentNo := SalesHeader."No.";

        // Exercise
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndSend.Invoke();

        // Verify
        SalesInvoiceHeader.SetCurrentKey("Pre-Assigned No.");
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", DocumentNo);
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    local procedure Initialize()
    var
        UserPreference: Record "User Preference";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        UserPreference.DeleteAll();

        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendConfirmationModalPageHandler(var PostAndSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostAndSendConfirmation.Yes().Invoke();
    end;
}

