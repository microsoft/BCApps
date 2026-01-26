codeunit 147532 "Cartera Recv. Exported Formats"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryBillGroupExportN19: Codeunit "Library Bill Group Export N19";
        LibraryBillGroupExportN32: Codeunit "Library Bill Group Export N32";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IncorrectLineTagErr: Label 'Line tag is wrong.';
        IncorrectPostingDateErr: Label 'Posting Date is wrong.';
        IncorrectDueDateErr: Label 'Due Date is wrong.';
        IncorrectDocNoErr: Label 'Document Number is wrong.';
        IncorrectAmountErr: Label 'Amount is wrong.';
        IncorrectTotalAmountErr: Label 'TotalAmount is wrong.';
        IncorrectGrandTotalAmountErr: Label 'GrandTotalAmount is wrong.';
        LocalCurrencyCode: Code[10];

    [Test]
    [HandlerFunctions('BillGroupExportN19RequestPageHandler,SuffixesPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ExportN19FormatBillGroupToFile()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        FileMgt: Codeunit "File Management";
        DocumentNo: Code[20];
        FileName: Text[1024];
        Suffix: Code[3];
        Line: Text[1024];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Setup
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.UpdateBankAccountWithFormatN19(BankAccount);
        Suffix := LibraryCarteraReceivables.CreateSuffixForBankAccount(BankAccount."No.");
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Pre-Exercise
        FileName := CopyStr(FileMgt.ServerTempFileName('txt'), 1, MaxStrLen(FileName));

        // Exercise
        LibraryVariableStorage.Enqueue(Suffix);

        LibraryBillGroupExportN19.RunBillGroupExportN19Report(BillGroup."No.", FileName);

        // Verify
        Line := LibraryTextFileValidation.ReadLine(FileName, 1);
        ValidateN19ExportHeader(Line, Suffix, BankAccount);

        Line := LibraryTextFileValidation.ReadLine(FileName, 2);
        ValidateN19ExportBillGroup(Line, Suffix, BankAccount);

        Line := LibraryTextFileValidation.ReadLine(FileName, 3);
        CustomerBankAccount.Get(Customer."No.", Customer."Preferred Bank Account Code");
        ValidateN19ExportTransaction(Line, Suffix, DocumentNo, CarteraDoc."Remaining Amount", Customer, CustomerBankAccount);

        Line := LibraryTextFileValidation.ReadLine(FileName, 4);
        ValidateN19ExportTotal(Line, Suffix, CarteraDoc."Remaining Amount");

        Line := LibraryTextFileValidation.ReadLine(FileName, 5);
        ValidateN19ExportFooter(Line, Suffix, CarteraDoc."Remaining Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BillGroupExportN32RequestPageHandler,SuffixesPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ExportN32FormatBillGroupToFile()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        FileMgt: Codeunit "File Management";
        DocumentNo: Code[20];
        FileName: Text[1024];
        Suffix: Code[3];
        Line: Text[1024];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Setup
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.UpdateBankAccountWithFormatN32(BankAccount);
        Suffix := LibraryCarteraReceivables.CreateSuffixForBankAccount(BankAccount."No.");
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        FileName := CopyStr(FileMgt.ServerTempFileName('txt'), 1, MaxStrLen(FileName));

        // Exercise
        LibraryVariableStorage.Enqueue(Suffix);
        LibraryBillGroupExportN32.RunBillGroupExportN32Report(BillGroup."No.", FileName);

        // Verify
        Line := LibraryTextFileValidation.ReadLine(FileName, 1);
        ValidateN32ExportHeader(Line, BankAccount);

        Line := LibraryTextFileValidation.ReadLine(FileName, 2);
        ValidateN32ExportTransactionInformation(Line, Suffix, BankAccount);

        Line := LibraryTextFileValidation.ReadLine(FileName, 3);
        ValidateN32ExportPostingInformation(Line, CarteraDoc);

        Line := LibraryTextFileValidation.ReadLine(FileName, 4);
        ValidateN32ExportCustomerInformation(Line, CarteraDoc);

        Line := LibraryTextFileValidation.ReadLine(FileName, 6);
        ValidateN32ExportBillGroupInformation(Line, CarteraDoc);

        Line := LibraryTextFileValidation.ReadLine(FileName, 7);
        ValidateN32ExportTotalAmountInformation(Line, CarteraDoc."Remaining Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LocalCurrencyCode := '';
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SuffixesPageHandler(var SuffixesPage: Page Suffixes; var Respone: Action)
    var
        Suffix: Record Suffix;
        SuffixCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(SuffixCode);

        Suffix.SetRange(Suffix, SuffixCode);
        Suffix.FindFirst();

        // Select the record with SuffixCode on the page
        SuffixesPage.SetRecord(Suffix);

        Respone := ACTION::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupExportN19RequestPageHandler(var BillGroupExportN19TestRequestPage: TestRequestPage "Bill group - Export N19")
    begin
        BillGroupExportN19TestRequestPage.BankSuffix.Lookup();
        BillGroupExportN19TestRequestPage.CheckErrors.SetValue(true);
        BillGroupExportN19TestRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupExportN32RequestPageHandler(var BillGroupExportN32TestRequestPage: TestRequestPage "Bill group - Export N32")
    begin
        BillGroupExportN32TestRequestPage.BankSuffix.Lookup();
        BillGroupExportN32TestRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupExportN58RequestPageHandler(var BillGroupExportN58TestRequestPage: TestRequestPage "Bill group - Export N58")
    begin
        BillGroupExportN58TestRequestPage.BankSuffix.Lookup();
        BillGroupExportN58TestRequestPage.CheckErrors.SetValue(true);
        BillGroupExportN58TestRequestPage.OK().Invoke();
    end;

    local procedure ValidateN19ExportHeader(Line: Text[1024]; SuffixValue: Code[3]; CompanyBankAccount: Record "Bank Account")
    var
        CompanyInformation: Record "Company Information";
        Suffix: Record Suffix;
    begin
        CompanyInformation.Get();

        // Validate Header
        Assert.AreEqual(5180, LibraryBillGroupExportN19.ReadLineTag(Line), IncorrectLineTagErr);
        Assert.AreEqual(CompanyInformation."VAT Registration No.", LibraryBillGroupExportN19.ReadCompanyVATRegNo(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption("VAT Registration No.")));
        Assert.AreEqual(SuffixValue, LibraryBillGroupExportN19.ReadBankSuffix(Line),
          StrSubstNo('%1 is wrong.', Suffix.FieldCaption(Suffix)));
        Assert.AreEqual(Format(WorkDate(), 6, 5), LibraryBillGroupExportN19.ReadHeaderPostingDate(Line), IncorrectPostingDateErr);
        Assert.AreEqual(PadStr(CompanyInformation.Name, 40, ' '), LibraryBillGroupExportN19.ReadHeaderCompanyName(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption(Name)));
        Assert.AreEqual(CompanyBankAccount."CCC Bank No.", LibraryBillGroupExportN19.ReadHeaderBankNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank No.")));
        Assert.AreEqual(CompanyBankAccount."CCC Bank Branch No.", LibraryBillGroupExportN19.ReadHeaderBankBranchNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank Branch No.")));
    end;

    local procedure ValidateN19ExportBillGroup(Line: Text[1024]; SuffixValue: Code[3]; CompanyBankAccount: Record "Bank Account")
    var
        CompanyInformation: Record "Company Information";
        Suffix: Record Suffix;
    begin
        CompanyInformation.Get();

        // Validate Bill Group
        Assert.AreEqual(5380, LibraryBillGroupExportN19.ReadLineTag(Line), IncorrectLineTagErr);
        Assert.AreEqual(CompanyInformation."VAT Registration No.", LibraryBillGroupExportN19.ReadCompanyVATRegNo(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption("VAT Registration No.")));
        Assert.AreEqual(SuffixValue, LibraryBillGroupExportN19.ReadBankSuffix(Line),
          StrSubstNo('%1 is wrong.', Suffix.FieldCaption(Suffix)));
        Assert.AreEqual(Format(WorkDate(), 6, 5), LibraryBillGroupExportN19.ReadBillGroupPostingDate(Line), IncorrectPostingDateErr);
        Assert.AreEqual(Format(WorkDate(), 6, 5), LibraryBillGroupExportN19.ReadBillGroupDueDate(Line), IncorrectDueDateErr);
        Assert.AreEqual(CompanyBankAccount."CCC Bank No.", LibraryBillGroupExportN19.ReadBillGroupBankNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank No.")));
        Assert.AreEqual(CompanyBankAccount."CCC Bank Branch No.", LibraryBillGroupExportN19.ReadBillGroupBankBranchNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank Branch No.")));
        Assert.AreEqual(CompanyBankAccount."CCC Control Digits", LibraryBillGroupExportN19.ReadBillGroupBankControlDigits(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Control Digits")));
        Assert.AreEqual(CompanyBankAccount."CCC Bank Account No.", LibraryBillGroupExportN19.ReadBillGroupBankAccountNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank Account No.")));
    end;

    local procedure ValidateN19ExportTransaction(Line: Text[1024]; SuffixValue: Code[3]; DocNumber: Code[20]; DocAmount: Decimal; Customer: Record Customer; CustomerBankAccount: Record "Customer Bank Account")
    var
        CompanyInformation: Record "Company Information";
        Suffix: Record Suffix;
        AmountAsText: Text[10];
    begin
        CompanyInformation.Get();
        AmountAsText := LibraryBillGroupExportN19.EuroAmount(DocAmount);

        // Validate Cartera Doc
        Assert.AreEqual(5680, LibraryBillGroupExportN19.ReadLineTag(Line), IncorrectLineTagErr);
        Assert.AreEqual(CompanyInformation."VAT Registration No.", LibraryBillGroupExportN19.ReadCompanyVATRegNo(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption("VAT Registration No.")));
        Assert.AreEqual(SuffixValue, LibraryBillGroupExportN19.ReadBankSuffix(Line),
          StrSubstNo('%1 is wrong.', Suffix.FieldCaption(Suffix)));
        Assert.AreEqual(PadStr(Customer.Name, 40, ' '), LibraryBillGroupExportN19.ReadCarteraDocCustomerName(Line),
          StrSubstNo('%1 is wrong.', Customer.FieldCaption(Name)));
        Assert.AreEqual(CustomerBankAccount."CCC Bank No.", LibraryBillGroupExportN19.ReadCarteraDocCustomerBankNo(Line),
          StrSubstNo('%1 is wrong.', CustomerBankAccount.FieldCaption("CCC Bank No.")));
        Assert.AreEqual(CustomerBankAccount."CCC Bank Branch No.", LibraryBillGroupExportN19.ReadCarteraDocCustomerBankBranchNo(Line),
          StrSubstNo('%1 is wrong.', CustomerBankAccount.FieldCaption("CCC Bank Branch No.")));
        Assert.AreEqual(CustomerBankAccount."CCC Control Digits", LibraryBillGroupExportN19.ReadCarteraDocCustomerBankControlDigits(Line),
          StrSubstNo('%1 is wrong.', CustomerBankAccount.FieldCaption("CCC Control Digits")));
        Assert.AreEqual(CustomerBankAccount."CCC Bank Account No.", LibraryBillGroupExportN19.ReadCarteraDocCustomerBankAccountNo(Line),
          StrSubstNo('%1 is wrong.', CustomerBankAccount.FieldCaption("CCC Bank Account No.")));
        Assert.AreEqual(PadStr(DocNumber + '/1', 10, ' '),
          LibraryBillGroupExportN19.ReadCarteraDocNumber(Line), IncorrectDocNoErr);
        Assert.AreEqual(AmountAsText, LibraryBillGroupExportN19.ReadCarteraDocAmount(Line), IncorrectAmountErr);
    end;

    local procedure ValidateN19ExportTotal(Line: Text[1024]; SuffixValue: Code[3]; TotalAmount: Decimal)
    var
        CompanyInformation: Record "Company Information";
        Suffix: Record Suffix;
        AmountAsText: Text[10];
    begin
        CompanyInformation.Get();
        AmountAsText := LibraryBillGroupExportN19.EuroAmount(TotalAmount);

        // Validate Cartera Doc Total line
        Assert.AreEqual(5880, LibraryBillGroupExportN19.ReadLineTag(Line), IncorrectLineTagErr);
        Assert.AreEqual(CompanyInformation."VAT Registration No.", LibraryBillGroupExportN19.ReadCompanyVATRegNo(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption("VAT Registration No.")));
        Assert.AreEqual(SuffixValue, LibraryBillGroupExportN19.ReadBankSuffix(Line),
          StrSubstNo('%1 is wrong.', Suffix.FieldCaption(Suffix)));
        Assert.AreEqual(AmountAsText, LibraryBillGroupExportN19.ReadCarteraDocAmount(Line), IncorrectTotalAmountErr);
    end;

    local procedure ValidateN19ExportFooter(Line: Text[1024]; SuffixValue: Code[3]; GrandTotalAmount: Decimal)
    var
        CompanyInformation: Record "Company Information";
        Suffix: Record Suffix;
        AmountAsText: Text[10];
    begin
        CompanyInformation.Get();
        AmountAsText := LibraryBillGroupExportN19.EuroAmount(GrandTotalAmount);

        // Validate document footer
        Assert.AreEqual(5980, LibraryBillGroupExportN19.ReadLineTag(Line), IncorrectLineTagErr);
        Assert.AreEqual(CompanyInformation."VAT Registration No.", LibraryBillGroupExportN19.ReadCompanyVATRegNo(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption("VAT Registration No.")));
        Assert.AreEqual(SuffixValue, LibraryBillGroupExportN19.ReadBankSuffix(Line),
          StrSubstNo('%1 is wrong.', Suffix.FieldCaption(Suffix)));
        Assert.AreEqual(AmountAsText, LibraryBillGroupExportN19.ReadCarteraDocAmount(Line), IncorrectGrandTotalAmountErr);
    end;

    local procedure ValidateN32ExportHeader(Line: Text[1024]; CompanyBankAccount: Record "Bank Account")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        Assert.AreEqual('0265', LibraryBillGroupExportN32.ReadLineTag(Line), IncorrectLineTagErr);

        Assert.AreEqual(Format(WorkDate(), 6, 5), LibraryBillGroupExportN32.ReadHeaderPostingDate(Line), IncorrectPostingDateErr);

        Assert.AreEqual(CompanyBankAccount."CCC Bank No.", LibraryBillGroupExportN32.ReadHeaderBankNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank No.")));
        Assert.AreEqual(CompanyBankAccount."CCC Bank Branch No.", LibraryBillGroupExportN32.ReadHeaderBankBranchNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank Branch No.")));
    end;

    local procedure ValidateN32ExportTransactionInformation(Line: Text[1024]; SuffixValue: Code[3]; CompanyBankAccount: Record "Bank Account")
    var
        CompanyInformation: Record "Company Information";
        Suffix: Record Suffix;
    begin
        CompanyInformation.Get();

        Assert.AreEqual('1165', LibraryBillGroupExportN32.ReadLineTag(Line), IncorrectLineTagErr);

        Assert.AreEqual(CompanyInformation."VAT Registration No.", LibraryBillGroupExportN32.ReadCompanyVATRegNo(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption("VAT Registration No.")));

        Assert.AreEqual(SuffixValue, LibraryBillGroupExportN32.ReadBankSuffix(Line),
          StrSubstNo('%1 is wrong.', Suffix.FieldCaption(Suffix)));

        Assert.AreEqual(CompanyBankAccount."CCC Bank No.", LibraryBillGroupExportN32.ReadBillGroupBankNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank No.")));
        Assert.AreEqual(CompanyBankAccount."CCC Bank Branch No.", LibraryBillGroupExportN32.ReadBillGroupBankBranchNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank Branch No.")));
        Assert.AreEqual(CompanyBankAccount."CCC Control Digits", LibraryBillGroupExportN32.ReadBillGroupBankControlDigits(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Control Digits")));
        Assert.AreEqual(CompanyBankAccount."CCC Bank Account No.", LibraryBillGroupExportN32.ReadBillGroupBankAccountNo(Line),
          StrSubstNo('%1 is wrong.', CompanyBankAccount.FieldCaption("CCC Bank Account No.")));
    end;

    local procedure ValidateN32ExportPostingInformation(Line: Text[1024]; CarteraDoc: Record "Cartera Doc.")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        Assert.AreEqual('2565', LibraryBillGroupExportN32.ReadLineTag(Line), IncorrectLineTagErr);

        Assert.AreEqual(PadStr(CarteraDoc."Document No." + '/1', 10, ' '), LibraryBillGroupExportN32.ReadCarteraDocNumber(Line),
          StrSubstNo('%1 is wrong.', CarteraDoc.FieldCaption("Document No.")));

        Assert.AreEqual(Format(CarteraDoc."Due Date", 6, 5), LibraryBillGroupExportN32.ReadCarteraDocDueDate(Line),
          StrSubstNo('%1 is wrong.', CarteraDoc.FieldCaption("Due Date")));

        Assert.AreEqual(PadStr(CopyStr(CompanyInformation."Post Code", 1, 2), 2, '0'), LibraryBillGroupExportN32.ReadCompanyPostCode(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption("Post Code")));

        Assert.AreEqual(PadStr(CompanyInformation.City, 20, ' '), LibraryBillGroupExportN32.ReadCompanyCity(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption(City)));

        Assert.AreEqual(Format(CarteraDoc."Due Date", 6, 5), LibraryBillGroupExportN32.ReadCarteraDocDueDate(Line),
          StrSubstNo('%1 is wrong.', CarteraDoc.FieldCaption("Due Date")));
    end;

    local procedure ValidateN32ExportCustomerInformation(Line: Text[1024]; CarteraDoc: Record "Cartera Doc.")
    var
        CompanyInformation: Record "Company Information";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustBankAccount: Record "Customer Bank Account";
    begin
        CompanyInformation.Get();

        Assert.AreEqual('2665', LibraryBillGroupExportN32.ReadLineTag(Line), IncorrectLineTagErr);

        CustLedgEntry.Get(CarteraDoc."Entry No.");
        Customer.Get(CustLedgEntry."Customer No.");
        CustBankAccount.Get(CustLedgEntry."Customer No.", CarteraDoc."Cust./Vendor Bank Acc. Code");

        Assert.AreEqual(CustBankAccount."CCC Bank No.", LibraryBillGroupExportN32.ReadCustomerCCCBankNo(Line),
          StrSubstNo('%1 is wrong.', CustBankAccount.FieldCaption("CCC Bank No.")));

        Assert.AreEqual(CustBankAccount."CCC Bank Branch No.", LibraryBillGroupExportN32.ReadCustomerCCCBankBranchNo(Line),
          StrSubstNo('%1 is wrong.', CustBankAccount.FieldCaption("CCC Bank Branch No.")));

        Assert.AreEqual(CustBankAccount."CCC Control Digits", LibraryBillGroupExportN32.ReadCustomerCCCControlDigits(Line),
          StrSubstNo('%1 is wrong.', CustBankAccount.FieldCaption("CCC Bank No.")));

        Assert.AreEqual(CustBankAccount."CCC Bank Account No.", LibraryBillGroupExportN32.ReadCustomerCCCBankAccountNo(Line),
          StrSubstNo('%1 is wrong.', CustBankAccount.FieldCaption("CCC Bank Account No.")));

        Assert.AreEqual(PadStr(CompanyInformation.Name, 34, ' '), LibraryBillGroupExportN32.ReadCustomerCompanyName(Line),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption(Name)));

        Assert.AreEqual(PadStr(Customer.Name, 34, ' '), LibraryBillGroupExportN32.ReadCustomerName(Line),
          StrSubstNo('%1 is wrong.', Customer.FieldCaption(Name)));
    end;

    local procedure ValidateN32ExportBillGroupInformation(Line: Text[1024]; CarteraDoc: Record "Cartera Doc.")
    var
        InterimAmount: Text[10];
    begin
        Assert.AreEqual('7165', LibraryBillGroupExportN32.ReadLineTag(Line), IncorrectLineTagErr);

        InterimAmount := LibraryBillGroupExportN32.EuroAmount(CarteraDoc."Remaining Amt. (LCY)");

        Assert.AreEqual(InterimAmount, LibraryBillGroupExportN32.ReadBillGroupAmount(Line),
          StrSubstNo('%1 is wrong.', CarteraDoc.FieldCaption("Remaining Amt. (LCY)")));
    end;

    local procedure ValidateN32ExportTotalAmountInformation(Line: Text[1024]; GrandTotalAmount: Decimal)
    var
        CompanyInformation: Record "Company Information";
        AmountAsText: Text[10];
    begin
        CompanyInformation.Get();
        AmountAsText := LibraryBillGroupExportN32.EuroAmount(GrandTotalAmount);

        Assert.AreEqual('9865', LibraryBillGroupExportN32.ReadLineTag(Line), IncorrectLineTagErr);

        Assert.AreEqual(AmountAsText, LibraryBillGroupExportN32.ReadTotalAmount(Line), StrSubstNo('Amount is wrong'));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
