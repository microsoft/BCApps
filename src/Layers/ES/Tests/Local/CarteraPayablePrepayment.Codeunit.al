codeunit 147507 "Cartera Payable Prepayment"
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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        LocalCurrencyCode: Code[10];
        RecordFoundErr: Label '%1 was found.';

    [Test]
    [Scope('OnPrem')]
    procedure PrepaidAmountNotShowingInCartera()
    var
        CarteraDoc: Record "Cartera Doc.";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, LocalCurrencyCode);
        Vendor.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        Vendor.Modify(true);

        // Setup
        CreatePurchaseOrder(PurchaseHeader, Vendor."No.");

        // Exercise
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Post-Exercise
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::"Pending Prepayment");

        // Verify
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.SetRange("Account No.", Vendor."No.");
        Assert.IsTrue(CarteraDoc.IsEmpty, StrSubstNo(RecordFoundErr, CarteraDoc.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountShowingInCarteraAsInvoice()
    var
        CarteraDoc: Record "Cartera Doc.";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        OriginalAmount: Decimal;
        PrepaymentAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, LocalCurrencyCode);
        Vendor.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        Vendor.Modify(true);

        // Setup
        CreatePurchaseOrder(PurchaseHeader, Vendor."No.");
        PurchaseHeader.CalcFields("Amount Including VAT");
        OriginalAmount := PurchaseHeader."Amount Including VAT";

        // Pre-Exercise
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PrepaymentAmount := CalculateTotalPrepaymentAmount(PurchaseHeader);

        // Exercise
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.SetRange("Account No.", Vendor."No.");
        CarteraDoc.FindFirst();
        CarteraDoc.TestField("Remaining Amount", OriginalAmount - PrepaymentAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountShowingInCarteraAsBill()
    var
        CarteraDoc: Record "Cartera Doc.";
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        OriginalAmount: Decimal;
        PrepaymentAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraReceivables.CreateBillToCarteraPaymentMethod(PaymentMethod);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, LocalCurrencyCode, PaymentMethod.Code);
        Vendor.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        Vendor.Modify(true);

        // Setup
        CreatePurchaseOrder(PurchaseHeader, Vendor."No.");
        PurchaseHeader.CalcFields("Amount Including VAT");
        OriginalAmount := PurchaseHeader."Amount Including VAT";

        // Pre-Exercise
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PrepaymentAmount := CalculateTotalPrepaymentAmount(PurchaseHeader);

        // Exercise
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Bill);
        CarteraDoc.SetRange("Account No.", Vendor."No.");
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

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibrarySales.FindItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CalculateTotalPrepaymentAmount(PurchaseHeader: Record "Purchase Header") PrepaymentAmount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLines(PurchaseLine, PurchaseHeader);

        repeat
            PrepaymentAmount += PurchaseLine."Prepmt. Amt. Incl. VAT";
        until PurchaseLine.Next() = 0;
    end;

    local procedure FindPurchaseLines(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
    end;
}

