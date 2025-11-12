codeunit 139003 "Test Instruction Mgt. PasS"
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
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
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
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler,EmailEditorHandler')]
    [Scope('OnPrem')]
    procedure PostingInstructionNotShownAfterPostingAndSending()
    begin
        PopulateCompanyInformation();
        PostingInstructionNotShownAfterPostingAndSendingInternal();
    end;

    procedure PostingInstructionNotShownAfterPostingAndSendingInternal()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        LibraryEmail: Codeunit "Library - Email";
        SalesInvoice: TestPage "Sales Invoice";
        DocumentNo: Code[20];
    begin
        Initialize();
        LibraryEmail.SetUpEmailAccount();

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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Instruction Mgt. PasS");

        BindActiveDirectoryMockEvents();

        UserPreference.DeleteAll();

        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
    end;

    local procedure PopulateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation."Bank Name" := 'BankName';
        CompanyInformation."Bank Branch No." := 'BranchNo';
        CompanyInformation."Bank Account No." := 'BankAccountNo';
        CompanyInformation.IBAN := 'IBAN';
        CompanyInformation.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendConfirmationModalPageHandler(var PostAndSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostAndSendConfirmation.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.ToField.Value('recipient@recipient.com');
        EmailEditor.Send.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

