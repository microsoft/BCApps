codeunit 147544 "Cartera Receivable Prepayment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        LocalCurrencyCode: Code[10];
        RecordFoundErr: Label '%1 was found.';

    [Test]
    [Scope('OnPrem')]
    procedure PrepaidAmountNotShowingInCartera()
    var
        CarteraDoc: Record "Cartera Doc.";
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraPayables.CreateInvoiceToCarteraPaymentMethod(PaymentMethod);
        LibraryCarteraReceivables.CreateCustomer(Customer, LocalCurrencyCode, PaymentMethod.Code);
        Customer.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        Customer.Modify(true);

        // Setup
        CreateSalesOrder(SalesHeader, Customer."No.");

        // Exercise
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Post-Exercise
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Prepayment");

        // Verify
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.SetRange("Account No.", Customer."No.");
        Assert.IsTrue(CarteraDoc.IsEmpty, StrSubstNo(RecordFoundErr, CarteraDoc.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountShowingInCarteraAsInvoice()
    var
        CarteraDoc: Record "Cartera Doc.";
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        OriginalAmount: Decimal;
        PrepaymentAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraPayables.CreateInvoiceToCarteraPaymentMethod(PaymentMethod);
        LibraryCarteraReceivables.CreateCustomer(Customer, LocalCurrencyCode, PaymentMethod.Code);
        Customer.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        Customer.Modify(true);

        // Setup
        CreateSalesOrder(SalesHeader, Customer."No.");
        SalesHeader.CalcFields("Amount Including VAT");
        OriginalAmount := SalesHeader."Amount Including VAT";

        // Pre-Exercise
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        PrepaymentAmount := CalculateTotalPrepaymentAmount(SalesHeader);

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.SetRange("Account No.", Customer."No.");
        CarteraDoc.FindFirst();
        CarteraDoc.TestField("Remaining Amount", OriginalAmount - PrepaymentAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountShowingInCarteraAsBill()
    var
        CarteraDoc: Record "Cartera Doc.";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        OriginalAmount: Decimal;
        PrepaymentAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        Customer.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        Customer.Modify(true);

        // Setup
        CreateSalesOrder(SalesHeader, Customer."No.");
        SalesHeader.CalcFields("Amount Including VAT");
        OriginalAmount := SalesHeader."Amount Including VAT";

        // Pre-Exercise
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        PrepaymentAmount := CalculateTotalPrepaymentAmount(SalesHeader);

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Bill);
        CarteraDoc.SetRange("Account No.", Customer."No.");
        CarteraDoc.FindFirst();
        CarteraDoc.TestField("Remaining Amount", OriginalAmount - PrepaymentAmount);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LocalCurrencyCode := '';
        IsInitialized := true;
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader,
          SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CalculateTotalPrepaymentAmount(SalesHeader: Record "Sales Header") PrepaymentAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLines(SalesLine, SalesHeader);

        repeat
            PrepaymentAmount += SalesLine."Prepmt. Amt. Incl. VAT";
        until SalesLine.Next() = 0;
    end;

    local procedure FindSalesLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;
}

