codeunit 134774 "G/L Report UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Register] [UT]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"G/L Report UT");

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"G/L Report UT");

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"G/L Report UT");
    end;

    [Test]
    [HandlerFunctions('GLRgisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestGLRegisterRepShowDetails()
    begin
        GLRegisterReportTest(true)
    end;

    [Test]
    [HandlerFunctions('GLRgisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestGLRegisterRepHideDetails()
    begin
        GLRegisterReportTest(false)
    end;

    local procedure GLRegisterReportTest(ShowDetails: Boolean)
    var
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingGroup: Code[20];
        PostedDoc: Code[20];
        FirstEntry: Integer;
        LastEntry: Integer;
        ExpectedNoOfRows: Integer;
        ShowDetailsTxt: Text;
    begin
        // [SCENARIO] G/L Register can show and Compact all the lines that are posted against a G/L account based on the options.

        Initialize();
        CreateCustomer(Customer);
        CreateSalesInvoiceHeader(SalesHeader, Customer);
        VATPostingGroup := CreateNoVATPostingGLAccount(Customer."VAT Bus. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", VATPostingGroup, 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", VATPostingGroup, 1);
        PostedDoc := PostSalesInvoice(SalesHeader);

        GLEntry.SetRange("Document No.", PostedDoc);
        GLEntry.FindFirst();
        FirstEntry := GLEntry."Entry No.";
        GLEntry.FindLast();
        LastEntry := GLEntry."Entry No.";

        GLRegister.SetRange("From Entry No.", FirstEntry);
        GLRegister.SetRange("To Entry No.", LastEntry);
        GLRegister.FindFirst();

        if ShowDetails then begin
            ShowDetailsTxt := 'Yes';
            ExpectedNoOfRows := 3;
        end else begin
            ShowDetailsTxt := 'No';
            ExpectedNoOfRows := 2;
        end;

        LibraryVariableStorage.Enqueue(Format(GLRegister."No."));
        LibraryVariableStorage.Enqueue(ShowDetailsTxt);
        REPORT.Run(REPORT::"G/L Register");
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(LibraryReportDataset.RowCount(), ExpectedNoOfRows, 'Expected that there are 3 rows');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLRgisterRequestPageHandler(var GLRegister: TestRequestPage "G/L Register")
    var
        DocumentNo: Variant;
        ShowDetailsVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(ShowDetailsVar);
        GLRegister."G/L Register".SetFilter("No.", DocumentNo);
        GLRegister.ShowDetails.Value(ShowDetailsVar);
        GLRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesInvoiceHeader(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
    end;

    local procedure CreateNoVATPostingGLAccount(VATBusPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATPostingSetup."VAT Prod. Posting Group" := FindNoVATPostingSetup(VATBusPostingGroup);
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
    end;

    [Scope('OnPrem')]
    procedure PostSalesInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    [Scope('OnPrem')]
    procedure CreateGLAccount(): Code[20]
    begin
        exit(LibraryERM.CreateGLAccountNo());
    end;

    local procedure FindNoVATPostingSetup(VATBusPostingGroup: Code[20]): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindFirst();
        if VATPostingSetup."Sales VAT Account" = '' then
            VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        if VATPostingSetup."Purchase VAT Account" = '' then
            VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;
}

