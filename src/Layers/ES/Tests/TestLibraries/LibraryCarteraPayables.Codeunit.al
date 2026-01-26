codeunit 143010 "Library - Cartera Payables"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryESLocalization: Codeunit "Library - ES Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    procedure AddCarteraDocumentToBillGroup(var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20]; AccountNo: Code[20]; BillGroupNo: Code[20])
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", AccountNo);
        CarteraDoc.FindFirst();
        CarteraDoc.Validate("Bill Gr./Pmt. Order No.", BillGroupNo);
        CarteraDoc.Modify(true);
    end;

    procedure AddPaymentOrderToCarteraDocument(var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20]; AccountNo: Code[20]; PaymentOrderNo: Code[20])
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", AccountNo);
        CarteraDoc.FindFirst();
        CarteraDoc.Validate("Bill Gr./Pmt. Order No.", PaymentOrderNo);
        CarteraDoc.Modify(true);
    end;

    procedure CheckIfCarteraDocExists(DocumentNo: Code[20]; PaymentOrderNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrderNo);
        CarteraDoc.FindFirst();
    end;

    procedure CheckIfCarteraDocIsClosed(PaymentOrderNo: Code[20])
    var
        ClosedPaymentOrder: Record "Closed Payment Order";
        PostedPaymentOrder: Record "Posted Payment Order";
    begin
        PostedPaymentOrder.SetRange("No.", PaymentOrderNo);
        Assert.IsTrue(PostedPaymentOrder.IsEmpty, StrSubstNo('%1 was found.', PostedPaymentOrder.TableCaption()));

        ClosedPaymentOrder.SetRange("No.", PaymentOrderNo);
        Assert.IsFalse(ClosedPaymentOrder.IsEmpty, StrSubstNo('%1 was not found.', ClosedPaymentOrder.TableCaption()));
    end;

    procedure CreateBankAccount(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Country/Region Code", GetCountryCode());
        BankAccount.Validate("CCC Bank No.", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        BankAccount.Validate("CCC Bank Branch No.", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        BankAccount.Validate("CCC Control Digits", Format(LibraryRandom.RandIntInRange(11, 99)));
        BankAccount.Validate("CCC Bank Account No.", Format(LibraryRandom.RandIntInRange(11111111, 99999999)));
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
    end;

    procedure CreateBillGroup(var BillGroup: Record "Bill Group"; BankAccountNo: Code[20]; DealingType: Option): Code[20]
    begin
        BillGroup.Init();
        BillGroup.Validate("Bank Account No.", BankAccountNo);
        BillGroup.Validate("Dealing Type", DealingType);
        BillGroup.Insert(true);
        exit(BillGroup."No.");
    end;

    procedure CreateBillToCarteraPaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Create Bills", true);
        PaymentMethod.Validate("Collection Agent", PaymentMethod."Collection Agent"::Bank);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::"Bill of Exchange");
        PaymentMethod.Modify(true);
    end;

    procedure CreateCarteraPayableDocument(var Vendor: Record Vendor): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    procedure CreateCarteraPayableDocumentWithPaymentMethod(VendorNo: Code[20]; PaymentMethodNo: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseInvoice(PurchaseHeader, VendorNo);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethodNo);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    procedure CreateCarteraVendor(var Vendor: Record Vendor; CurrencyCode: Code[10]; PaymentMethodCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", PaymentMethodCode);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Country/Region Code", GetCountryCode());
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
    end;

    procedure CreateCarteraVendorUseInvoicesToCarteraPayment(var Vendor: Record Vendor; CurrencyCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
    begin
        CreateInvoiceToCarteraPaymentMethod(PaymentMethod);
        CreateCarteraVendor(Vendor, CurrencyCode, PaymentMethod.Code);
    end;

    procedure CreateCarteraVendorUseBillToCarteraPayment(var Vendor: Record Vendor; CurrencyCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
    begin
        CreateBillToCarteraPaymentMethod(PaymentMethod);
        CreateCarteraVendor(Vendor, CurrencyCode, PaymentMethod.Code);
    end;

    procedure CreateCarteraVendorForUnrealizedVAT(var Vendor: Record Vendor; CurrencyCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
    begin
        CreateCarteraVendorUseBillToCarteraPayment(Vendor, CurrencyCode);
        PaymentMethod.Get(Vendor."Payment Method Code");
        PaymentMethod.Validate("Create Bills", false);
        PaymentMethod.Validate("Invoices to Cartera", true);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::" ");
        PaymentMethod.Modify(true);
    end;

    procedure CreateCarteraJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    procedure CreateCarteraPaymentOrder(var BankAccount: Record "Bank Account"; var PaymentOrder: Record "Payment Order"; CurrencyCode: Code[10])
    begin
        CreateBankAccount(BankAccount, CurrencyCode);
        UpdateBankAccountWithFormatN431(BankAccount);
        CreatePaymentOrder(PaymentOrder, CurrencyCode, BankAccount."No.");
    end;

    procedure CreateInvoiceToCarteraPaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Invoices to Cartera", true);
        PaymentMethod.Validate("Collection Agent", PaymentMethod."Collection Agent"::Bank);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::Check);
        PaymentMethod.Modify(true);
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

    procedure CreatePaymentOrder(var PaymentOrder: Record "Payment Order"; CurrencyCode: Code[10]; BankAccountNo: Code[20]): Code[20]
    begin
        PaymentOrder.Init();
        PaymentOrder.Insert(true);
        PaymentOrder.Validate("Currency Code", CurrencyCode);
        PaymentOrder.Validate("Bank Account No.", BankAccountNo);
        PaymentOrder.Validate("Export Electronic Payment", true);
        PaymentOrder.Modify(true);
        exit(PaymentOrder."No.");
    end;

    procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        RandomQuantity: Integer;
    begin
        LibrarySales.FindItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        RandomQuantity := LibraryRandom.RandInt(1000);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", RandomQuantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    procedure CreateVendorBankAccount(var Vendor: Record Vendor; CurrencyCode: Code[10])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("CCC Bank No.", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        VendorBankAccount.Validate("CCC Bank Branch No.", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        VendorBankAccount.Validate("CCC Control Digits", Format(LibraryRandom.RandIntInRange(11, 99)));
        VendorBankAccount.Validate("CCC Bank Account No.", Format(LibraryRandom.RandIntInRange(11111111, 99999999)));
        VendorBankAccount.Validate("Use For Electronic Payments", true);
        VendorBankAccount.Validate("Currency Code", CurrencyCode);
        VendorBankAccount.Validate("Country/Region Code", GetCountryCode());
        VendorBankAccount.Modify(true);

        VendorBankAccount.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount.Modify();

        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify(true);
    end;

    procedure FindInvoiceVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentNo: Code[20]; DocumentSituation: Enum "ES Document Situation")
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Situation", DocumentSituation);
        VendorLedgerEntry.FindLast();
    end;

    procedure FindCarteraDocs(var CarteraDoc: Record "Cartera Doc."; AccountNo: Code[20]; DocumentNo: Code[20])
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", AccountNo);
        CarteraDoc.FindSet();
    end;

    procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindLast();
    end;

    procedure FindOpenCarteraDocVendorLedgerEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentNo: Code[20]; DocumentSituation: Enum "ES Document Situation"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Situation", DocumentSituation);
        VendorLedgerEntry.SetRange("Document Status", VendorLedgerEntry."Document Status"::Open);
        VendorLedgerEntry.FindSet();
    end;

    procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation."Country/Region Code");
    end;

    procedure GetPostedPurchaseInvoiceAmount(VendorNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        exit(VendorLedgerEntry.Amount);
    end;

    procedure PostCarteraJournalLines(GenJournalBatchName: Code[10])
    var
        CarteraJournal: TestPage "Cartera Journal";
    begin
        CarteraJournal.OpenEdit();
        CarteraJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CarteraJournal.Post.Invoke();
    end;

    procedure PostCarteraPaymentOrder(var PaymentOrder: Record "Payment Order")
    var
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        POPostAndPrint.PayablePostOnly(PaymentOrder);
    end;

    procedure SetPaymentTermsVatDistribution(PaymentTermsCode: Code[10]; VATDistribution: Option)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        PaymentTerms.Validate("VAT distribution", VATDistribution);
        PaymentTerms.Modify(true);
    end;

    procedure UpdateBankAccountWithFormatN431(var BankAccount: Record "Bank Account")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.SetRange("Processing Codeunit ID", CODEUNIT::"PO - Export N34.1");
        BankExportImportSetup.FindFirst();
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Modify(true);
    end;

    procedure UpdateBankAccountWithFormatN34(var BankAccount: Record "Bank Account")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.SetRange("Processing Codeunit ID", CODEUNIT::"Payment order - Export N34");
        BankExportImportSetup.FindFirst();
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Modify(true);
    end;

    procedure GetRandomAllowedNumberOfDecimals(DecimalPlacesRange: Text[5]): Integer
    var
        MinNoOfDecimals: Integer;
        MaxNoOfDecimals: Integer;
        LeftMargin: Text[5];
        RightMargin: Text[5];
    begin
        // Given a DecimalPlacesRange in the following format, Min:Max, return a random number in this interval.
        // The format is flexible, and can be as well Min:,:Max,Min
        // For the detailed specifications of this function, refer to DecimalPlaces Property in the NAV documentation.
        MinNoOfDecimals := 0;
        MaxNoOfDecimals := 0;

        if StrPos(DecimalPlacesRange, ':') = 0 then begin
            Evaluate(MinNoOfDecimals, DecimalPlacesRange);
            MaxNoOfDecimals := MinNoOfDecimals;
        end else begin
            DecimalPlacesRange := ConvertStr(DecimalPlacesRange, ':', ',');

            LeftMargin := SelectStr(1, DecimalPlacesRange);
            if LeftMargin <> '' then
                Evaluate(MinNoOfDecimals, LeftMargin);

            RightMargin := SelectStr(2, DecimalPlacesRange);
            if RightMargin <> '' then
                Evaluate(MaxNoOfDecimals, RightMargin);
        end;

        exit(LibraryRandom.RandIntInRange(MinNoOfDecimals, MaxNoOfDecimals));
    end;

    procedure ValidatePostedInvoiceUnrVATGLEntries(DocumentNo: Code[20]; VATAccountNo: Code[20]; TotalAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TotalCreditAmount: Decimal;
        TotalDebitAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);

        Assert.AreEqual(3, GLEntry.Count, 'There should be three entries.');

        GLEntry.Find('-');
        VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group");
        TotalDebitAmount := GLEntry."Debit Amount";
        Assert.IsTrue(TotalDebitAmount > 0, 'Total Debit Amount has a wrong value');

        GLEntry.Next();
        ExpectedVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision());

        Assert.IsTrue(ExpectedVATAmount > 0, 'Expected VAT Amount must be greater than zero for this test');
        Assert.AreEqual(ExpectedVATAmount, GLEntry."Debit Amount", 'Wrong VAT Amount was set on the line');
        Assert.AreEqual(VATAccountNo, GLEntry."G/L Account No.", 'Wrong account is set on the line');

        GLEntry.Next();
        TotalCreditAmount := GLEntry."Credit Amount";
        Assert.IsTrue(TotalDebitAmount > 0, 'Total Amount without VAT should be greater than zero');
        Assert.AreEqual(TotalAmount, TotalCreditAmount, 'Wrong total value was set on line');

        // Verify numbers add up
        Assert.AreEqual(TotalCreditAmount, TotalDebitAmount + ExpectedVATAmount, 'Total  and Debit Amounts do not add up');
    end;

    procedure ValidatePaymentUnrVATGLEntries(DocumentNo: Code[20]; VATAccountNo: Code[20]; InitialAmount: Decimal; ExpectedVATAmount: Decimal; SettledAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);

        Assert.AreEqual(6, GLEntry.Count, 'There should be three entries.');

        GLEntry.Find('-');

        // Check total amount
        Assert.AreNearlyEqual(
          InitialAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong value for the inital amount line');
        GLEntry.Next();

        Assert.AreNearlyEqual(
          InitialAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong value for the inital amount line');
        GLEntry.Next();

        // Check Unrealized VAT amount
        Assert.AreNearlyEqual(
          ExpectedVATAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong total value was set on line');
        Assert.AreEqual(VATAccountNo, GLEntry."G/L Account No.", 'Wrong account is set on the line');
        GLEntry.Next();

        Assert.AreNearlyEqual(
          ExpectedVATAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong VAT Amount was set on the line');
        GLEntry.Next();

        // Check settled amount
        Assert.AreNearlyEqual(
          SettledAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong value for the settled amount line');
        GLEntry.Next();

        Assert.AreNearlyEqual(
          SettledAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), 'Wrong value for the settled amount line');
        GLEntry.Next();
    end;
}

