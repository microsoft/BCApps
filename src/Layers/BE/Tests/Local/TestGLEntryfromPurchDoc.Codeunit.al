codeunit 144050 "Test GL Entry from Purch. Doc."
{
    // Test the data on General Ledger entries created when posting purchase order.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGLEntryDataAfterPostingPurchaseOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        Line1Description: Text[50];
        Line2Description: Text[50];
        CompareSecondLineWith: Text[50];
    begin
        // Setup. Create PostigSetups, Vendor, GLAccount.
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, '');

        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGLAccount(GLAccount);

        Line1Description := 'Test Line 1 Description';
        Line2Description := 'Test Line 2 Description';

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Vendor Invoice No." := 'TEST 1';
        PurchaseHeader."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        PurchaseHeader."Gen. Bus. Posting Group" := GenBusinessPostingGroup.Code;
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDec(1000, 2);
        PurchaseLine.Description := Line1Description;
        PurchaseLine."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        PurchaseLine.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDec(1000, 2);
        PurchaseLine.Description := Line2Description;
        PurchaseLine."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        PurchaseLine.Modify();

        // Exersice: Post Purchase header with two lines.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Validate:
        // * There are two G/L Entries for the document with the same G/L Account
        // * Description is transfered from the Purchase Line to the G/L Entry
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        Assert.AreEqual(2, GLEntry.Count, 'Expected both G/L Entry rows to have the same account no');

        GLEntry.FindSet();
        CompareSecondLineWith := 'INVALID';
        if GLEntry.Description = Line1Description then
            CompareSecondLineWith := Line2Description
        else
            if GLEntry.Description = Line2Description then
                CompareSecondLineWith := Line1Description;
        GLEntry.Next();
        Assert.AreEqual(CompareSecondLineWith, GLEntry.Description, 'Expected G/L Entry descriptions to match purcahse line values');
    end;
}

