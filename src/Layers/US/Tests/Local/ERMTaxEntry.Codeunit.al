codeunit 144017 "ERM Tax Entry"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Unrealized]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        AmountError: Label '%1 must be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure FullUnrealizedTaxTypeFirstFullyPaid()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        CustomerNo: Code[20];
        ResourceNo: Code[20];
        PostedDocumentNo: Code[20];
        TaxAreaCode: Code[20];
        Amount: Decimal;
        PartialPaymentAmount: Decimal;
    begin
        // Check that First Fully Paid Unrealized Amount exists in GL Entry after posting Sales Invoice and Applying Payment over it.

        // Setup: Update General Ledger Setup, Create and Post Sales Invoice.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        TaxAreaCode := CreateTaxAreaLineWithUnrealizedType(TaxDetail, TaxJurisdiction."Unrealized VAT Type"::"First (Fully Paid)");
        CustomerNo := CreateCustomerWithTaxArea(TaxAreaCode);
        ResourceNo := CreateResourceWithTaxGroup(TaxDetail."Tax Group Code");
        PostedDocumentNo := CreateAndPostSalesInvoice(SalesLine, CustomerNo, ResourceNo);
        TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        Amount := FindPostedSalesAmount(PostedDocumentNo, TaxDetail."Tax Below Maximum");
        PartialPaymentAmount := Amount - LibraryRandom.RandInt(5);

        // Exercise: Make Payment against Invoice and Apply the Payment over Invoice.
        CreateAndPostJournalLine(GenJournalLine, SalesLine."Sell-to Customer No.", -PartialPaymentAmount, PostedDocumentNo);
        CreateAndPostJournalLine(GenJournalLine, SalesLine."Sell-to Customer No.", -(Amount - PartialPaymentAmount), PostedDocumentNo);

        // Verify: Verify the Amount in G/L Entry.
        VerifyGLEntryAmount(GenJournalLine."Document No.", TaxJurisdiction."Unreal. Tax Acc. (Sales)", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullUnrealizedTaxTypeLast()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        CustomerNo: Code[20];
        ResourceNo: Code[20];
        PostedDocumentNo: Code[20];
        TaxAreaCode: Code[20];
        Amount: Decimal;
    begin
        // Check that Last Fully Paid Unralized Amount exists in GL Entry after posting Sales Invoice and Applying Payment over it.

        // Setup: Update General Ledger Setup, Create and Post Sales Invoice.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        TaxAreaCode := CreateTaxAreaLineWithUnrealizedType(TaxDetail, TaxJurisdiction."Unrealized VAT Type"::Last);
        CustomerNo := CreateCustomerWithTaxArea(TaxAreaCode);
        ResourceNo := CreateResourceWithTaxGroup(TaxDetail."Tax Group Code");
        PostedDocumentNo := CreateAndPostSalesInvoice(SalesLine, CustomerNo, ResourceNo);
        TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        Amount := FindPostedSalesAmount(PostedDocumentNo, TaxDetail."Tax Below Maximum");

        // Exercise: Make Payment against Invoice and Apply the Payment over Invoice.
        CreateAndPostJournalLine(GenJournalLine, SalesLine."Sell-to Customer No.", -SalesLine."Outstanding Amount", PostedDocumentNo);

        // Verify: Verify the Amount in G/L Entry.
        VerifyGLEntryAmount(GenJournalLine."Document No.", TaxJurisdiction."Unreal. Tax Acc. (Sales)", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialUnrealizedTaxTypeFirstFullyPaid()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        CustomerNo: Code[20];
        ResourceNo: Code[20];
        PostedDocumentNo: Code[20];
        TaxAreaCode: Code[20];
        Amount: Decimal;
    begin
        // Check that First Fully Paid Unrealized Amount exists in GL Entry after posting Sales Invoice and Applying Partial Payment over it.

        // Setup: Update General Ledger Setup, Create and Post General Journal.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        TaxAreaCode := CreateTaxAreaLineWithUnrealizedType(TaxDetail, TaxJurisdiction."Unrealized VAT Type"::"First (Fully Paid)");
        CustomerNo := CreateCustomerWithTaxArea(TaxAreaCode);
        ResourceNo := CreateResourceWithTaxGroup(TaxDetail."Tax Group Code");
        PostedDocumentNo := CreateAndPostSalesInvoice(SalesLine, CustomerNo, ResourceNo);
        TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        Amount := FindPostedSalesAmount(PostedDocumentNo, TaxDetail."Tax Below Maximum");

        // Exercise: Make Payment against Invoice and Apply the Payment over Invoice.
        CreateAndPostJournalLine(GenJournalLine, SalesLine."Sell-to Customer No.", -Amount, PostedDocumentNo);

        // Verify: Verify the Amount in G/L Entry.
        VerifyGLEntryAmount(GenJournalLine."Document No.", TaxJurisdiction."Unreal. Tax Acc. (Sales)", Amount);
    end;

    local procedure Initialize()
    begin
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure CreateAndPostJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ResourceNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResourceNo, LibraryRandom.RandDec(100, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomerWithTaxArea(TaxArea: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Validate("Tax Area Code", TaxArea);
        Customer.Validate("Tax Liable", true);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateResourceWithTaxGroup(TaxGroupCode: Code[20]): Code[20]
    var
        Resource: Record Resource;
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Tax Group Code", TaxGroupCode);
        Resource.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 1500, 2));  // Take Random Unit Price greater than 1000 to avoid rounding issues.
        Resource.Validate("VAT Prod. Posting Group", '');
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateSalesTaxDetailWithUnrealizedType(var TaxDetail: Record "Tax Detail"; UnrealizedVATType: Option)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(
          TaxDetail, CreateSalesTaxJurisdictionWithUnrealizedType(UnrealizedVATType),
          TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandIntInRange(1, 3));  // Using RANDOM value for Tax Below Maximum.
        TaxDetail.Modify(true);
    end;

    local procedure CreateSalesTaxJurisdictionWithUnrealizedType(UnrealizedVATType: Option): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Unrealized VAT Type", UnrealizedVATType);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Unreal. Tax Acc. (Sales)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateTaxAreaLineWithUnrealizedType(var TaxDetail: Record "Tax Detail"; UnrealizedVATType: Option): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetailWithUnrealizedType(TaxDetail, UnrealizedVATType);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        TaxDetail.Validate("Tax Type", TaxDetail."Tax Type"::"Sales Tax Only");
        TaxDetail.Modify(true);
        exit(TaxArea.Code);
    end;

    local procedure FindPostedSalesAmount(DocumentNo: Code[20]; TaxBelowMaximum: Decimal): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();

        // Return Payment Amount less than VAT Amount to use it as partial Amount.
        exit((SalesInvoiceLine.Amount * TaxBelowMaximum) / 100);
    end;

    local procedure VerifyGLEntryAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
    end;
}

