codeunit 144188 "RES Purchase Job IT"
{
    // 1. Verify Job Ledger Entry after posting the Purchase Order with job.
    // 
    // Covers Test Cases for WI - 346320
    // --------------------------------------------
    // Test Function Name                    TFS ID
    // --------------------------------------------
    // JobLedgerEntryUsingPurchaseOrder      201170

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        JobsUtil: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        UnitPriceErr: Label '%1 must be %2 in %3.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure JobLedgerEntryUsingPurchaseOrder()
    var
        PurchaseInvLine: Record "Purch. Inv. Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Verify Job Ledger Entry after posting the Purchase Order with job.

        // Exercise.
        DocumentNo := CreateAndPostPurchaseOrder();

        // Verify: Verify Unit Price in Job Ledger Entry.
        PurchaseInvLine.SetRange("Document No.", DocumentNo);
        PurchaseInvLine.FindFirst();
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("Job No.", PurchaseInvLine."Job No.");
        JobLedgerEntry.FindFirst();
        Assert.AreNearlyEqual(
          PurchaseInvLine."Job Unit Price", JobLedgerEntry."Unit Price", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnitPriceErr, JobLedgerEntry.FieldCaption("Unit Price"), PurchaseInvLine."Job Unit Price", JobLedgerEntry.TableCaption()));
    end;

    local procedure CreateAndPostPurchaseOrder(): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Currency Code", CreateCurrencyAndExchangeRate());
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithJob(
          PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item));
        CreatePurchaseLineWithJob(PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount());
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Using true for receive and invoice.
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", CreateGLAccount());
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", CreateGLAccount());
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        JobsUtil.CreateJob(Job);
        JobsUtil.CreateJobTask(Job, JobTask);
    end;

    local procedure CreatePurchaseLineWithJob(PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
    begin
        CreateJobTask(JobTask);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Using random for quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

