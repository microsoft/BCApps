codeunit 143020 "Library - Cartera Receivables"
{
    // Library Codeunit for ES Cartera Receivables


    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryESLocalization: Codeunit "Library - ES Localization";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";

    procedure AddCarteraDocumentToBillGroup(var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20]; AccountNo: Code[20]; BillGroupNo: Code[20])
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", AccountNo);
        CarteraDoc.FindFirst();
        CarteraDoc.Validate("Bill Gr./Pmt. Order No.", BillGroupNo);
        CarteraDoc.Modify(true);
    end;

    procedure AddInstallmentCarteraDocumentsToBillGroup(var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20]; AccountNo: Code[20]; BillGroupNo: Code[20])
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", AccountNo);
        CarteraDoc.FindSet();

        repeat
            CarteraDoc.Validate("Bill Gr./Pmt. Order No.", BillGroupNo);
            CarteraDoc.Modify(true);
        until CarteraDoc.Next() = 0;
    end;

    procedure CreateBankAccount(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("CCC Bank No.", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        BankAccount.Validate("CCC Bank Branch No.", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        BankAccount.Validate("CCC Control Digits", Format(LibraryRandom.RandIntInRange(11, 99)));
        BankAccount.Validate("CCC Bank Account No.", Format(LibraryRandom.RandIntInRange(11111111, 99999999)));
        BankAccount.Validate("Bank Acc. Posting Group", FindBankAccountPostingGroup());
        BankAccount."Customer Ratings Code" := BankAccount."No.";
        BankAccount.Modify(true);
    end;

    procedure CreateBillGroup(var BillGroup: Record "Bill Group"; BankAccountNo: Code[20]; DealingType: Enum "Cartera Dealing Type"): Code[20]
    begin
        BillGroup.Init();
        BillGroup.Validate("Bank Account No.", BankAccountNo);
        BillGroup.Validate("Dealing Type", DealingType);
        BillGroup.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
        BillGroup.Insert(true);
        exit(BillGroup."No.");
    end;

    procedure CreateCarteraCustomer(var Customer: Record Customer; CurrencyCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
    begin
        CreateBillToCarteraPaymentMethod(PaymentMethod);
        CreateCustomer(Customer, CurrencyCode, PaymentMethod.Code);
    end;

    procedure CreateBillToCarteraPaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Create Bills", true);
        PaymentMethod.Validate("Collection Agent", PaymentMethod."Collection Agent"::Bank);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::"Bill of Exchange");
        PaymentMethod.Modify(true);
    end;

    procedure CreateCustomer(var Customer: Record Customer; CurrencyCode: Code[10]; PaymentMethodCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    procedure CreateCarteraCustomerForUnrealizedVAT(var Customer: Record Customer; CurrencyCode: Code[10])
    begin
        CreateCarteraCustomer(Customer, CurrencyCode);
        UpdatePaymentMethodForInvoicesWithUnrealizedVAT(Customer."Payment Method Code");
    end;

    procedure CreateCarteraJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    procedure CreateCustomerBankAccount(var Customer: Record Customer; var CustomerBankAccount: Record "Customer Bank Account")
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.Validate("Currency Code", Customer."Currency Code");
        CustomerBankAccount.Validate("CCC Bank No.", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        CustomerBankAccount.Validate("CCC Bank Branch No.", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        CustomerBankAccount.Validate("CCC Control Digits", Format(LibraryRandom.RandIntInRange(11, 99)));
        CustomerBankAccount.Validate("CCC Bank Account No.", Format(LibraryRandom.RandIntInRange(11111111, 99999999)));
        CustomerBankAccount.Modify(true);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Modify(true);
    end;

    procedure CreateCustomerRatingForBank(var CustomerRating: Record "Customer Rating"; BankCode: Code[20]; CurrencyCode: Code[10]; CustomerNo: Code[20])
    begin
        Clear(CustomerRating);
        CustomerRating.Validate(Code, BankCode);
        CustomerRating.Validate("Currency Code", CurrencyCode);
        CustomerRating.Validate("Customer No.", CustomerNo);
        CustomerRating.Validate("Risk Percentage", LibraryRandom.RandDec(100, 2));
        CustomerRating.Insert(true);
    end;

    procedure CreateDiscountOperationFeesForBankAccount(BankAccount: Record "Bank Account")
    var
        OperationFee: Record "Operation Fee";
    begin
        CreateOperationFeesForBankAccount(BankAccount."No.", BankAccount."Currency Code",
          OperationFee."Type of Fee"::"Collection Expenses", LibraryRandom.RandDec(10, 2));
        CreateOperationFeesForBankAccount(BankAccount."No.", BankAccount."Currency Code",
          OperationFee."Type of Fee"::"Discount Expenses", LibraryRandom.RandDec(10, 2));
        CreateOperationFeesForBankAccount(BankAccount."No.", BankAccount."Currency Code",
          OperationFee."Type of Fee"::"Discount Interests", LibraryRandom.RandDec(10, 2));
    end;

    procedure CreateFactoringOperationFeesForBankAccount(BankAccount: Record "Bank Account")
    var
        OperationFee: Record "Operation Fee";
    begin
        CreateOperationFeesForBankAccount(BankAccount."No.", BankAccount."Currency Code",
          OperationFee."Type of Fee"::"Unrisked Factoring Expenses", LibraryRandom.RandDec(10, 2));
        CreateOperationFeesForBankAccount(BankAccount."No.", BankAccount."Currency Code",
          OperationFee."Type of Fee"::"Risked Factoring Expenses ", LibraryRandom.RandDec(10, 2));
    end;

    procedure CreateFactoringCustomer(var Customer: Record Customer; CurrencyCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
    begin
        CreateFactoringPaymentMethod(PaymentMethod);
        CreateCustomer(Customer, CurrencyCode, PaymentMethod.Code);
    end;

    procedure CreateFactoringPaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Invoices to Cartera", true);
        PaymentMethod.Validate("Collection Agent", PaymentMethod."Collection Agent"::Bank);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::" ");
        PaymentMethod.Modify(true);
    end;

    procedure CreateFeeRange(var FeeRange: Record "Fee Range"; "Code": Code[20]; CurrencyCode: Code[10]; TypeOfFee: Option)
    begin
        Clear(FeeRange);
        FeeRange.Validate(Code, Code);
        FeeRange.Validate("Currency Code", CurrencyCode);
        FeeRange.Validate("Type of Fee", TypeOfFee);
        FeeRange.Validate("Charge Amount per Doc.", LibraryRandom.RandDec(100, 2));
        FeeRange.Validate("Charge % per Doc.", LibraryRandom.RandDec(100, 2));
        FeeRange.Insert(true);
    end;

    procedure CreateMultipleInstallments(PaymentTermsCode: Code[10]; NoOfInstallments: Integer)
    var
        Installment: Record Installment;
        Index: Integer;
    begin
        for Index := 1 to NoOfInstallments do begin
            Clear(Installment);
            LibraryESLocalization.CreateInstallment(Installment, PaymentTermsCode);
            Installment.Validate("% of Total", 100 / NoOfInstallments);
            Installment.Validate("Gap between Installments", '1M');
            Installment.Modify(true);
        end;
    end;

    procedure CreateOperationFeesForBankAccount(BankCode: Code[20]; CurrencyCode: Code[10]; TypeOfFee: Option; ChargeAmtPerOperation: Decimal)
    var
        OperationFee: Record "Operation Fee";
    begin
        OperationFee.Init();
        OperationFee.Validate(Code, BankCode);
        OperationFee.Validate("Currency Code", CurrencyCode);
        OperationFee.Validate("Type of Fee", TypeOfFee);
        OperationFee.Validate("Charge Amt. per Operation", ChargeAmtPerOperation);
        OperationFee.Insert(true);
    end;

    procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader,
          SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(1000, 2));
    end;

    procedure CreateSalesInvoiceWithCustBankAcc(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; CurrencyCode: Code[10])
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CreateCarteraCustomer(Customer, CurrencyCode);
        CreateCustomerBankAccount(Customer, CustomerBankAccount);
        CreateSalesInvoice(SalesHeader, Customer."No.");
    end;

    procedure CreateServiceInvoice(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySales.FindItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader,
          ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(50));
        ServiceLine.Modify(true);
    end;

    procedure CreateSuffixForBankAccount(BankAccountCode: Code[20]) SuffixValue: Code[3]
    var
        Suffix: Record Suffix;
    begin
        Suffix.Init();
        Suffix.Validate("Bank Acc. Code", BankAccountCode);
        SuffixValue := Format(LibraryRandom.RandIntInRange(111, 999));
        Suffix.Validate(Suffix, SuffixValue);
        Suffix.Insert(true);
    end;

    local procedure FindBankAccountPostingGroup(): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.SetFilter("Liabs. for Disc. Bills Acc.", '<>%1', '');
        BankAccountPostingGroup.SetFilter("Bank Services Acc.", '<>%1', '');
        BankAccountPostingGroup.SetFilter("Discount Interest Acc.", '<>%1', '');
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        exit(BankAccountPostingGroup.Code);
    end;

    procedure FindCarteraDocCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentNo: Code[20]; DocumentSituation: Enum "ES Document Situation"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Situation", DocumentSituation);
        CustLedgerEntry.FindLast();
    end;

    procedure FindCarteraDocs(var CarteraDoc: Record "Cartera Doc."; AccountNo: Code[20]; DocumentNo: Code[20])
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", AccountNo);
        CarteraDoc.FindSet();
    end;

    procedure FindCarteraGLEntries(var GLEntry: Record "G/L Entry"; BillGroupNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document No.", BillGroupNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.FindFirst();
    end;

    procedure FindDetailedCustomerLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustomerNo: Code[20]; DocumentNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.FindFirst();
    end;

    procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindLast();
    end;

    procedure FindOpenCarteraDocCustomerLedgerEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentNo: Code[20]; DocumentSituation: Enum "ES Document Situation"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Situation", DocumentSituation);
        CustLedgerEntry.SetRange("Document Status", CustLedgerEntry."Document Status"::Open);
        CustLedgerEntry.FindSet();
    end;

    procedure GetPostedSalesInvoiceAmount(CustomerNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        exit(CustLedgerEntry.Amount);
    end;

    procedure PrepareCarteraDiscountJournalLines(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // -----------------------------------------------------------------------------
        // This function should not exist if new G/L Accounts are created, instead of
        // reusing the existing G/L Accounts with lots of extra, unneeded details.
        // -----------------------------------------------------------------------------
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.ModifyAll("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::" ");
        GenJournalLine.ModifyAll("Gen. Bus. Posting Group", '');
        GenJournalLine.ModifyAll("Gen. Prod. Posting Group", '');
        GenJournalLine.ModifyAll("VAT Bus. Posting Group", '');
        GenJournalLine.ModifyAll("VAT Prod. Posting Group", '');
    end;

    procedure PostCarteraJournalLines(GenJournalBatchName: Code[10])
    var
        CarteraJournal: TestPage "Cartera Journal";
    begin
        CarteraJournal.OpenEdit();
        CarteraJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CarteraJournal.Post.Invoke();
    end;

    procedure PostCarteraBillGroup(BillGroup: Record "Bill Group")
    var
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
    end;

    procedure SetPaymentTermsVatDistribution(PaymentTermsCode: Code[10]; VATDistribution: Option)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        PaymentTerms.Validate("VAT distribution", VATDistribution);
        PaymentTerms.Modify(true);
    end;

    procedure SetupPaymentDiscountType(PaymentDiscountType: Option)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();

        GLSetup.Validate("Discount Calculation", GLSetup."Discount Calculation"::" ");
        GLSetup.Validate("Payment Discount Type", PaymentDiscountType);
        GLSetup.Modify(true);
    end;

    local procedure UpgradeBankAccountFormat(var BankAccount: Record "Bank Account"; BillGroupExportCodeunitID: Integer)
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.SetRange("Processing Codeunit ID", BillGroupExportCodeunitID);
        BankExportImportSetup.FindFirst();
        BankAccount.Validate("SEPA Direct Debit Exp. Format", BankExportImportSetup.Code);
        BankAccount.Modify(true);
    end;

    procedure UpdateBankAccountWithFormatN19(var BankAccount: Record "Bank Account")
    begin
        UpgradeBankAccountFormat(BankAccount, CODEUNIT::"Bill group - Export N19");
    end;

    procedure UpdateBankAccountWithFormatN58(var BankAccount: Record "Bank Account")
    begin
        UpgradeBankAccountFormat(BankAccount, CODEUNIT::"Bill group - Export N58");
    end;

    procedure UpdateBankAccountWithFormatN32(var BankAccount: Record "Bank Account")
    begin
        UpgradeBankAccountFormat(BankAccount, CODEUNIT::"Bill group - Export N32");
    end;

    procedure UpdatePaymentMethodForBillsWithUnrealizedVAT(var PaymentMethod: Record "Payment Method")
    begin
        PaymentMethod.Validate("Create Bills", true);
        PaymentMethod.Validate("Invoices to Cartera", false);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::" ");
        PaymentMethod.Modify(true);
    end;

    procedure UpdatePaymentMethodForInvoicesWithUnrealizedVAT(PaymentMethodCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(PaymentMethodCode);
        PaymentMethod.Validate("Create Bills", false);
        PaymentMethod.Validate("Invoices to Cartera", true);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::" ");
        PaymentMethod.Modify(true);
    end;
}

