codeunit 144021 "Ref. Payment - Exported Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;

    local procedure CreatePurchaseDocument(var Vendor: Record Vendor; Type: Enum "Purchase Document Type"): Text
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        DocumentNumber: Code[20];
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, Type, Vendor."No.");
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
            PurchaseHeader."Vendor Cr. Memo No." := Format(LibraryRandom.RandInt(1000));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(1000));
        DocumentNumber := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(DocumentNumber);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitTest()
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        RefPaymentExported.Validate("Payment Date", WorkDate());
        RefPaymentExported.Validate("Document No.", '1');
        RefPaymentExported.Validate("Vendor No.", Vendor."No.");
        // Check with no currency
        RefPaymentExported.Validate(Amount, 1.0);
        Assert.AreEqual(RefPaymentExported."Amount (LCY)", RefPaymentExported.Amount, 'Currency convertion failed');
        RefPaymentExported.Validate("Amount (LCY)", 1.0);
        Assert.AreEqual(RefPaymentExported."Amount (LCY)", RefPaymentExported.Amount, 'Currency convertion failed');
        // Check with currency
        RefPaymentExported.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 0.5, 0.5));
        RefPaymentExported.Validate(Amount, 1.0);
        Assert.AreEqual(RefPaymentExported."Amount (LCY)", 2.0, 'Currency convertion failed');
        RefPaymentExported.Validate("Amount (LCY)", 2.0);
        Assert.AreEqual(RefPaymentExported.Amount, 1.0, 'Currency convertion failed');
        RefPaymentExported.Validate("Currency Factor", 2.0);
        // Check Vendor accoubt
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        RefPaymentExported.Validate("Vendor Account", VendorBankAccount.Code);
        // Get coverage on Message Type
        RefPaymentExported.Validate("Message Type", RefPaymentExported."Message Type"::"Reference No.");
        RefPaymentExported.Validate("Message Type", RefPaymentExported."Message Type"::"Invoice Information");
        RefPaymentExported.Validate("Message Type", RefPaymentExported."Message Type"::Message);
        RefPaymentExported.Validate("Message Type", RefPaymentExported."Message Type"::"Long Message");
        RefPaymentExported.Validate("Message Type", RefPaymentExported."Message Type"::"Tax Message");
        // Check Ledger entry
        CreatePurchaseDocument(Vendor, VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry.Open := true;
        // To make the relation work
        VendorLedgerEntry.Modify();
        RefPaymentExported.Validate("Entry No.", VendorLedgerEntry."Entry No.");

        CreatePurchaseDocument(Vendor, VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry.Open := true;
        // To make the relation work
        VendorLedgerEntry.Modify();
        RefPaymentExported.Validate("Entry No.", VendorLedgerEntry."Entry No.");
        // Test global functions
        RefPaymentExported.UpdateLines();
        Assert.IsFalse(RefPaymentExported.ExistsNotTransferred(), 'ExistsNotTransferred should return FALSE');
        RefPaymentExported.SetUsePaymentDisc(true);
        Assert.AreEqual(RefPaymentExported.GetLastLineNo(), 0, 'No lines expected');
        RefPaymentExported.MarkAffiliatedAsTransferred();
    end;
}

