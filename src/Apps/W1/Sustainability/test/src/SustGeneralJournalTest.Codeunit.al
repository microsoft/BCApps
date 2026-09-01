namespace Microsoft.Test.Sustainability;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Vendor;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;

codeunit 148188 "Sust. General Journal Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySustainability: Codeunit "Library - Sustainability";
        AccountCodeLbl: Label 'AccountCode%1', Locked = true, Comment = '%1 = Number';
        CategoryCodeLbl: Label 'CategoryCode%1', Locked = true, Comment = '%1 = Number';
        SubcategoryCodeLbl: Label 'SubcategoryCode%1', Locked = true, Comment = '%1 = Number';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        InvalidDocumentTypeErr: Label 'You can only specify Sustainability Accounts for lines of type blank, invoice and credit memo for Journal Template Name=%1 ,Journal Batch Name=%2 ,Line No.=%3.', Comment = '%1 = Journal Template Name , %2 = Journal Batch Name , %3 = Line No.';

    [Test]
    procedure VerifySustainabilityLedgerEntryShouldBeCreatedWhenGenJournalLineIsPostedWithInvoice()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Sustainability Ledger entry should be created when the General Journal Line is posted with Document Type "Invoice".
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine.Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine.Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine.Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine.Modify(true);

        // [WHEN] Post General Jnl Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [VERIFY] Verify Sustainability Ledger entry should be created when the General Journal Line is posted.
        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        SustainabilityLedgerEntry.FindFirst();
        Assert.AreEqual(
            EmissionCO2,
            SustainabilityLedgerEntry."Emission CO2",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission CO2"), EmissionCO2, SustainabilityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            EmissionCH4,
            SustainabilityLedgerEntry."Emission CH4",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission CH4"), EmissionCO2, SustainabilityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            EmissionN2O,
            SustainabilityLedgerEntry."Emission N2O",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission N2O"), EmissionN2O, SustainabilityLedgerEntry.TableCaption()));
    end;

    [Test]
    procedure VerifySustainabilityLedgerEntryShouldBeCreatedWhenGenJournalLineIsPostedWithBalancingForInvoice()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Sustainability Ledger entry should be created when the General Journal Line is posted with Balancing for Document Type "Invoice".
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Invoice,
            GenJournalLine[1]."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine[1].Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine[1].Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine[1].Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine[1].Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine[1].Modify(true);

        // [GIVEN] Create another Balancing General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Invoice,
            GenJournalLine[2]."Account Type"::"Bank Account",
            BankAccount."No.",
           -GenJournalLine[1].Amount);
        GenJournalLine[2].Validate("Document No.", GenJournalLine[1]."Document No.");
        GenJournalLine[2].Modify(true);

        // [WHEN] Post General Jnl Line.
        GenJournalLine[1].SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine[1].SetRange("Journal Batch Name", GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [VERIFY] Verify Sustainability Ledger entry should be created when the General Journal Line is posted.
        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine[1]."Document No.");
        SustainabilityLedgerEntry.FindFirst();
        Assert.AreEqual(
            EmissionCO2,
            SustainabilityLedgerEntry."Emission CO2",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission CO2"), EmissionCO2, SustainabilityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            EmissionCH4,
            SustainabilityLedgerEntry."Emission CH4",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission CH4"), EmissionCO2, SustainabilityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            EmissionN2O,
            SustainabilityLedgerEntry."Emission N2O",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission N2O"), EmissionN2O, SustainabilityLedgerEntry.TableCaption()));
    end;

    [Test]
    procedure VerifySustainabilityLedgerEntryShouldBeCreatedWhenGenJournalLineIsPostedWithCreditMemo()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Sustainability Ledger entry should be created when the General Journal Line is posted with Document Type "Credit Memo".
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine.Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine.Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine.Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine.Modify(true);

        // [WHEN] Post General Jnl Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [VERIFY] Verify Sustainability Ledger entry should be created when the General Journal Line is posted.
        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        SustainabilityLedgerEntry.FindFirst();
        Assert.AreEqual(
            -EmissionCO2,
            SustainabilityLedgerEntry."Emission CO2",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission CO2"), EmissionCO2, SustainabilityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -EmissionCH4,
            SustainabilityLedgerEntry."Emission CH4",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission CH4"), EmissionCO2, SustainabilityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -EmissionN2O,
            SustainabilityLedgerEntry."Emission N2O",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission N2O"), EmissionN2O, SustainabilityLedgerEntry.TableCaption()));
    end;

    [Test]
    procedure VerifySustainabilityLedgerEntryShouldBeCreatedWhenGenJournalLineIsPostedWithBalancingForCreditMemo()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Sustainability Ledger entry should be created when the General Journal Line is posted with Balancing for Document Type "Credit Memo".
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::"Credit Memo",
            GenJournalLine[1]."Account Type"::Vendor,
            Vendor."No.",
            LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine[1].Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine[1].Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine[1].Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine[1].Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine[1].Modify(true);

        // [GIVEN] Create another Balancing General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::"Credit Memo",
            GenJournalLine[2]."Account Type"::"Bank Account",
            BankAccount."No.",
           -GenJournalLine[1].Amount);
        GenJournalLine[2].Validate("Document No.", GenJournalLine[1]."Document No.");
        GenJournalLine[2].Modify(true);

        // [WHEN] Post General Jnl Line.
        GenJournalLine[1].SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine[1].SetRange("Journal Batch Name", GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [VERIFY] Verify Sustainability Ledger entry should be created when the General Journal Line is posted.
        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine[1]."Document No.");
        SustainabilityLedgerEntry.FindFirst();
        Assert.AreEqual(
            -EmissionCO2,
            SustainabilityLedgerEntry."Emission CO2",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission CO2"), EmissionCO2, SustainabilityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -EmissionCH4,
            SustainabilityLedgerEntry."Emission CH4",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission CH4"), EmissionCO2, SustainabilityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -EmissionN2O,
            SustainabilityLedgerEntry."Emission N2O",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Emission N2O"), EmissionN2O, SustainabilityLedgerEntry.TableCaption()));
    end;

    [Test]
    procedure TestDocumentTypeCannotBeChangeWhenGenJournalLineContainSustAccNo()
    var
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Document Type cannot be change except blank, invoice, Credit Memo When Gen Jnl Line contains "Sust. Account No.".
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine.Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine.Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine.Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine.Modify(true);

        // [WHEN] Change Document Type.
        asserterror GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);

        // [VERIFY] Verify Document Type cannot be change except blank, invoice and Credit Memo When Gen Jnl Line contains "Sust. Account No.".
        Assert.ExpectedError(StrSubstNo(InvalidDocumentTypeErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    [Test]
    procedure VerifyPostedGenJournalLineShouldBeCreatedWhenGenJournalLineIsPostedWithInvoice()
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Posted General Line should be created when the General Journal Line is posted with Document Type "Invoice".
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template with "Copy to Posted Jnl. Lines".
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", true);
        GenJournalTemplate.Modify(true);

        // [GIVEN] Create a Gen Journal Batch with "Copy to Posted Jnl. Lines".
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy to Posted Jnl. Lines", true);
        GenJournalBatch.Modify(true);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine.Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine.Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine.Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine.Modify(true);

        // [WHEN] Post General Jnl Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [VERIFY] Verify Posted General Line should be created when the General Journal Line is posted with Document Type "Invoice".
        PostedGenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
        PostedGenJournalLine.FindFirst();
        Assert.AreEqual(
            SustainabilityAccount."No.",
            PostedGenJournalLine."Sust. Account No.",
            StrSubstNo(ValueMustBeEqualErr, PostedGenJournalLine.FieldCaption("Sust. Account No."), SustainabilityAccount."No.", PostedGenJournalLine.TableCaption()));
        Assert.AreEqual(
            EmissionCO2,
            PostedGenJournalLine."Total Emission CO2",
            StrSubstNo(ValueMustBeEqualErr, PostedGenJournalLine.FieldCaption("Total Emission CO2"), EmissionCO2, PostedGenJournalLine.TableCaption()));
        Assert.AreEqual(
            EmissionCH4,
            PostedGenJournalLine."Total Emission CH4",
            StrSubstNo(ValueMustBeEqualErr, PostedGenJournalLine.FieldCaption("Total Emission CH4"), EmissionCO2, PostedGenJournalLine.TableCaption()));
        Assert.AreEqual(
            EmissionN2O,
            PostedGenJournalLine."Total Emission N2O",
            StrSubstNo(ValueMustBeEqualErr, PostedGenJournalLine.FieldCaption("Total Emission N2O"), EmissionN2O, PostedGenJournalLine.TableCaption()));
    end;

    [Test]
    procedure VerifyPostedGenJournalLineShouldBeCreatedWhenGenJournalLineIsPostedWithCreditMemo()
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Posted General Line should be created when the General Journal Line is posted with Document Type "Credit Memo".
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template with "Copy to Posted Jnl. Lines".
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", true);
        GenJournalTemplate.Modify(true);

        // [GIVEN] Create a Gen Journal Batch with "Copy to Posted Jnl. Lines".
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy to Posted Jnl. Lines", true);
        GenJournalBatch.Modify(true);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine.Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine.Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine.Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine.Modify(true);

        // [WHEN] Post General Jnl Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [VERIFY] Verify Posted General Line should be created when the General Journal Line is posted with Document Type "Credit Memo".
        PostedGenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
        PostedGenJournalLine.FindFirst();
        Assert.AreEqual(
            SustainabilityAccount."No.",
            PostedGenJournalLine."Sust. Account No.",
            StrSubstNo(ValueMustBeEqualErr, PostedGenJournalLine.FieldCaption("Sust. Account No."), SustainabilityAccount."No.", PostedGenJournalLine.TableCaption()));
        Assert.AreEqual(
            EmissionCO2,
            PostedGenJournalLine."Total Emission CO2",
            StrSubstNo(ValueMustBeEqualErr, PostedGenJournalLine.FieldCaption("Total Emission CO2"), EmissionCO2, PostedGenJournalLine.TableCaption()));
        Assert.AreEqual(
            EmissionCH4,
            PostedGenJournalLine."Total Emission CH4",
            StrSubstNo(ValueMustBeEqualErr, PostedGenJournalLine.FieldCaption("Total Emission CH4"), EmissionCO2, PostedGenJournalLine.TableCaption()));
        Assert.AreEqual(
            EmissionN2O,
            PostedGenJournalLine."Total Emission N2O",
            StrSubstNo(ValueMustBeEqualErr, PostedGenJournalLine.FieldCaption("Total Emission N2O"), EmissionN2O, PostedGenJournalLine.TableCaption()));
    end;

    [Test]
    procedure VerifyMultipleSustainabilityLedgerEntryShouldBeCreatedWhenGenJournalLineIsPostedWithInvoice()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify multiple Sustainability Ledger entry should be created when the General Journal Line is posted with Document Type "Invoice".
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Invoice,
            GenJournalLine[1]."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine[1].Validate("Bal. Account Type", GenJournalLine[1]."Bal. Account Type"::"Bank Account");
        GenJournalLine[1].Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine[1].Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine[1].Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine[1].Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine[1].Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine[1].Modify(true);

        // [GIVEN] Create another General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Invoice,
            GenJournalLine[2]."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine[2].Validate("Bal. Account Type", GenJournalLine[1]."Bal. Account Type"::"Bank Account");
        GenJournalLine[2].Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine[2].Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine[2].Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine[2].Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine[2].Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine[2].Modify(true);

        // [WHEN] Post General Jnl Line.
        GenJournalLine[1].SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine[1].SetRange("Journal Batch Name", GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [VERIFY] Verify multiple Sustainability Ledger entry should be created when the General Journal Line is posted.
        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine[1]."Document No.", GenJournalLine[2]."Document No.");
        Assert.RecordCount(SustainabilityLedgerEntry, 2);
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewHandler')]
    procedure VerifySustainabilityLedgerEntryShouldBeCreatedDuringPreviewPostingOfGenJournal()
    var
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Sustainability Ledger Entry should be created during Preview Posting of Gen Journal.
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Invoice,
            GenJournalLine[1]."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine[1].Validate("Bal. Account Type", GenJournalLine[1]."Bal. Account Type"::"Bank Account");
        GenJournalLine[1].Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine[1].Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine[1].Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine[1].Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine[1].Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine[1].Modify(true);

        // [GIVEN] Create another General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Invoice,
            GenJournalLine[2]."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine[2].Validate("Bal. Account Type", GenJournalLine[1]."Bal. Account Type"::"Bank Account");
        GenJournalLine[2].Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine[2].Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine[2].Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine[2].Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine[2].Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine[2].Modify(true);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Preview General Jnl Line.
        GenJournalLine[1].SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine[1].SetRange("Journal Batch Name", GenJournalBatch.Name);
        asserterror GenJnlPost.Preview(GenJournalLine[1]);

        // [VERIFY] No errors occured - preview mode error only.
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('NavigateFindEntriesHandler')]
    procedure VerifySustainabilityLedgerEntryShouldBeShownWhenNavigating()
    var
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        Navigate: Page Navigate;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
    begin
        // [SCENARIO 496545] Verify Sustainability Ledger Entry should be shown when navigating through NavigateFindEntriesHandler handler.
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template with "Copy to Posted Jnl. Lines".
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", true);
        GenJournalTemplate.Modify(true);

        // [GIVEN] Create a Gen Journal Batch with "Copy to Posted Jnl. Lines".
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy to Posted Jnl. Lines", true);
        GenJournalBatch.Modify(true);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Update Sustainability Account No.,Total Emission CO2,Total Emission CH4,Total Emission N2O.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Sust. Account No.", SustainabilityAccount."No.");
        GenJournalLine.Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine.Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine.Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine.Modify(true);

        // [WHEN] Preview General Jnl Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [VERIFY] Verify Sustainability Ledger Entry should be shown when navigating through NavigateFindEntriesHandler handler.
        Navigate.SetDoc(GenJournalLine."Posting Date", GenJournalLine."Document No.");
        Navigate.Run();
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewSingleEntryHandler')]
    procedure VerifyPreviewPostingOfGenJournalDoesNotConsumeSustainabilityLedgerEntryNo()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BaselineGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
        BaselineEntryNo: Integer;
        Index: Integer;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
    begin
        // [SCENARIO 640599] Preview Posting of a General Journal Line must not consume the Sustainability Ledger Entry identity.
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account whose posting group has a G/L account so the line can post.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateBankAccount(BankAccount, GLAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Post a baseline General Journal Line to observe the committed Sustainability Ledger Entry identity.
        CreateGenJournalLineWithEmission(
            BaselineGenJournalLine, GenJournalBatch, Vendor."No.", BankAccount."No.", SustainabilityAccount."No.",
            EmissionCO2, EmissionCH4, EmissionN2O);
        LibraryERM.PostGeneralJnlLine(BaselineGenJournalLine);

        // [GIVEN] Record the committed baseline Entry No.
        SustainabilityLedgerEntry.SetRange("Document No.", BaselineGenJournalLine."Document No.");
        SustainabilityLedgerEntry.FindLast();
        BaselineEntryNo := SustainabilityLedgerEntry."Entry No.";

        // [GIVEN] Prepare a single General Journal Line with Sustainability emissions.
        CreateGenJournalLineWithEmission(
            GenJournalLine, GenJournalBatch, Vendor."No.", BankAccount."No.", SustainabilityAccount."No.",
            EmissionCO2, EmissionCH4, EmissionN2O);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Preview the General Journal Line three times.
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        for Index := 1 to 3 do begin
            asserterror GenJnlPost.Preview(GenJournalLine);
            Assert.ExpectedError('');
        end;

        // [WHEN] Post the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The committed Sustainability Ledger Entry equals the baseline plus one, proving the three previews consumed no identity.
        SustainabilityLedgerEntry.Reset();
        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        SustainabilityLedgerEntry.FindLast();
        Assert.AreEqual(
            BaselineEntryNo + 1,
            SustainabilityLedgerEntry."Entry No.",
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Entry No."), BaselineEntryNo + 1, SustainabilityLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewResetKeyDrillDownHandler')]
    procedure VerifyRepeatedGenJournalPreviewResetsNegativeTemporaryKeys()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
        Index: Integer;
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
    begin
        // [SCENARIO 640599] Every repeated General Journal preview reuses the same reset pair of negative temporary Entry No. values.
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Create a Sustainability Account.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);

        // [GIVEN] Generate Emission.
        EmissionCO2 := LibraryRandom.RandInt(20);
        EmissionCH4 := LibraryRandom.RandInt(5);
        EmissionN2O := LibraryRandom.RandInt(5);

        // [GIVEN] Create a Bank Account whose posting group has a G/L account so the line can post.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateBankAccount(BankAccount, GLAccount);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Prepare two General Journal Lines each producing a preview Sustainability Ledger Entry.
        CreateGenJournalLineWithEmission(
            GenJournalLine[1], GenJournalBatch, Vendor."No.", BankAccount."No.", SustainabilityAccount."No.",
            EmissionCO2, EmissionCH4, EmissionN2O);
        CreateGenJournalLineWithEmission(
            GenJournalLine[2], GenJournalBatch, Vendor."No.", BankAccount."No.", SustainabilityAccount."No.",
            EmissionCO2, EmissionCH4, EmissionN2O);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Preview the General Journal Lines multiple times.
        GenJournalLine[1].SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine[1].SetRange("Journal Batch Name", GenJournalBatch.Name);
        for Index := 1 to 2 do begin
            // [THEN] The drilldown handler asserts the same reset key pair (-1999999999 then -2000000000) on every preview run.
            asserterror GenJnlPost.Preview(GenJournalLine[1]);
            Assert.ExpectedError('');
        end;

        // [THEN] No physical preview Sustainability Ledger Entry persists in the real table.
        SustainabilityLedgerEntry.Reset();
        Assert.RecordIsEmpty(SustainabilityLedgerEntry);
    end;

    [Test]
    procedure VerifySustainabilityLedgerEntryIsReversedWhenGLTransactionIsReversed()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        ReversalSustLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        BalGLAccount: Record "G/L Account";
        ReversalEntry: Record "Reversal Entry";
        OriginalEntryNo: Integer;
        OriginalCO2e: Decimal;
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 640775] The sustainability part is reversed when the related G/L transaction is reversed.
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] A Sustainability Account and emissions.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);
        EmissionCO2 := LibraryRandom.RandIntInRange(10, 20);
        EmissionCH4 := LibraryRandom.RandIntInRange(1, 5);
        EmissionN2O := LibraryRandom.RandIntInRange(1, 5);

        // [GIVEN] Two G/L Accounts and a Gen. Journal Batch.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(BalGLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] A posted General Journal Line with a Sustainability Account, creating a Sustainability Ledger Entry linked to the G/L transaction.
        CreateGLGenJournalLineWithEmission(
            GenJournalLine, GenJournalBatch, GLAccount."No.", BalGLAccount."No.", SustainabilityAccount."No.",
            EmissionCO2, EmissionCH4, EmissionN2O);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        SustainabilityLedgerEntry.FindFirst();
        OriginalEntryNo := SustainabilityLedgerEntry."Entry No.";
        OriginalCO2e := SustainabilityLedgerEntry."CO2e Emission";

        // [WHEN] The G/L transaction is reversed.
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseTransaction(GLEntry."Transaction No.");

        // [THEN] The original Sustainability Ledger Entry is marked as reversed.
        SustainabilityLedgerEntry.Get(OriginalEntryNo);
        Assert.IsTrue(SustainabilityLedgerEntry."Reversed", 'Original sustainability entry should be marked as Reversed.');
        Assert.AreNotEqual(0, SustainabilityLedgerEntry."Reversed by Entry No.", 'Reversed by Entry No. should be populated.');

        // [THEN] A reversal Sustainability Ledger Entry exists with negated CO2e referencing the original entry.
        ReversalSustLedgerEntry.Get(SustainabilityLedgerEntry."Reversed by Entry No.");
        Assert.AreEqual(
            -OriginalCO2e,
            ReversalSustLedgerEntry."CO2e Emission",
            StrSubstNo(ValueMustBeEqualErr, ReversalSustLedgerEntry.FieldCaption("CO2e Emission"), -OriginalCO2e, ReversalSustLedgerEntry.TableCaption()));
        Assert.AreEqual(
            OriginalEntryNo,
            ReversalSustLedgerEntry."Reversed Entry No.",
            StrSubstNo(ValueMustBeEqualErr, ReversalSustLedgerEntry.FieldCaption("Reversed Entry No."), OriginalEntryNo, ReversalSustLedgerEntry.TableCaption()));
    end;

    [Test]
    procedure VerifySustainabilityLedgerEntryIsNotReversedTwiceWhenAlreadyReversedBeforeGLReversal()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityAccount: Record "Sustainability Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        BalGLAccount: Record "G/L Account";
        ReversalEntry: Record "Reversal Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
        EmissionCO2: Decimal;
        EmissionCH4: Decimal;
        EmissionN2O: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 640775] Reversing the G/L transaction does not reverse the sustainability part again when it was already reversed manually.
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] A Sustainability Account and emissions.
        CreateSustainabilityAccount(AccountCode, CategoryCode, SubcategoryCode, LibraryRandom.RandInt(10));
        SustainabilityAccount.Get(AccountCode);
        EmissionCO2 := LibraryRandom.RandIntInRange(10, 20);
        EmissionCH4 := LibraryRandom.RandIntInRange(1, 5);
        EmissionN2O := LibraryRandom.RandIntInRange(1, 5);

        // [GIVEN] Two G/L Accounts and a Gen. Journal Batch.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(BalGLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] A posted General Journal Line with a Sustainability Account.
        CreateGLGenJournalLineWithEmission(
            GenJournalLine, GenJournalBatch, GLAccount."No.", BalGLAccount."No.", SustainabilityAccount."No.",
            EmissionCO2, EmissionCH4, EmissionN2O);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] The sustainability part is already reversed manually.
        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        SustainabilityLedgerEntry.FindFirst();
        SustEntryReverseMgt.ReverseEntry(SustainabilityLedgerEntry);

        // [WHEN] The G/L transaction is reversed.
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseTransaction(GLEntry."Transaction No.");

        // [THEN] Only the original entry and its single manual reversal exist (the G/L reversal did not reverse the sustainability part again).
        SustainabilityLedgerEntry.Reset();
        SustainabilityLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        Assert.AreEqual(
            2,
            SustainabilityLedgerEntry.Count(),
            StrSubstNo(ValueMustBeEqualErr, SustainabilityLedgerEntry.FieldCaption("Entry No."), 2, SustainabilityLedgerEntry.TableCaption()));
    end;

    local procedure CreateGenJournalLineWithEmission(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; BankAccountNo: Code[20]; SustAccountNo: Code[20]; EmissionCO2: Decimal; EmissionCH4: Decimal; EmissionN2O: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor,
            VendorNo,
            -LibraryRandom.RandIntInRange(100, 200));

        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Sust. Account No.", SustAccountNo);
        GenJournalLine.Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine.Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine.Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLGenJournalLineWithEmission(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GLAccountNo: Code[20]; BalGLAccountNo: Code[20]; SustAccountNo: Code[20]; EmissionCO2: Decimal; EmissionCH4: Decimal; EmissionN2O: Decimal)
    begin
        // Use a blank document type G/L-to-G/L line so the transaction is reversible in all localizations (e.g. IT blocks reversing invoice documents).
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            GLAccountNo,
            LibraryRandom.RandIntInRange(100, 200));

        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalGLAccountNo);
        GenJournalLine.Validate("Sust. Account No.", SustAccountNo);
        GenJournalLine.Validate("Total Emission CH4", EmissionCH4);
        GenJournalLine.Validate("Total Emission N2O", EmissionN2O);
        GenJournalLine.Validate("Total Emission CO2", EmissionCO2);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateSustainabilityAccount(var AccountCode: Code[20]; var CategoryCode: Code[20]; var SubcategoryCode: Code[20]; i: Integer): Record "Sustainability Account"
    begin
        CreateSustainabilitySubcategory(CategoryCode, SubcategoryCode, i);
        AccountCode := StrSubstNo(AccountCodeLbl, i);
        exit(LibrarySustainability.InsertSustainabilityAccount(
          AccountCode, '', CategoryCode, SubcategoryCode, Enum::"Sustainability Account Type"::Posting, '', true));
    end;

    local procedure CreateSustainabilitySubcategory(var CategoryCode: Code[20]; var SubcategoryCode: Code[20]; i: Integer)
    begin
        CategoryCode := StrSubstNo(CategoryCodeLbl, i);
        CreateSustainabilityCategory(CategoryCode, i);

        SubcategoryCode := StrSubstNo(SubcategoryCodeLbl, i);
        LibrarySustainability.InsertAccountSubcategory(CategoryCode, SubcategoryCode, SubcategoryCode, 1, 2, 3, false);
    end;

    local procedure CreateSustainabilityCategory(var CategoryCode: Code[20]; i: Integer)
    begin
        CategoryCode := StrSubstNo(CategoryCodeLbl, i);
        LibrarySustainability.InsertAccountCategory(
            CategoryCode, CategoryCode, Enum::"Emission Scope"::"Scope 1", Enum::"Calculation Foundation"::"Fuel/Electricity",
            true, true, true, '', false);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Sustainability Ledger Entry"));
        GLPostingPreview."No. of Records".AssertEquals(2);
        GLPostingPreview.OK().Invoke();
    end;

    [PageHandler]
    procedure GLPostingPreviewSingleEntryHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Sustainability Ledger Entry"));
        GLPostingPreview."No. of Records".AssertEquals(1);
        GLPostingPreview.OK().Invoke();
    end;

    [PageHandler]
    procedure GLPostingPreviewResetKeyDrillDownHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    var
        SustainabilityLedgerEntries: TestPage "Sustainability Ledger Entries";
    begin
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Sustainability Ledger Entry"));
        GLPostingPreview."No. of Records".AssertEquals(2);

        // Drill down to the temporary preview Sustainability Ledger Entries page (descending Entry No. order).
        SustainabilityLedgerEntries.Trap();
        GLPostingPreview."No. of Records".DrillDown();

        SustainabilityLedgerEntries.First();
        SustainabilityLedgerEntries."Entry No.".AssertEquals(-1999999999);
        SustainabilityLedgerEntries.Next();
        SustainabilityLedgerEntries."Entry No.".AssertEquals(-2000000000);
        SustainabilityLedgerEntries.Close();

        GLPostingPreview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigateFindEntriesHandler(var Navigate: TestPage Navigate)
    begin
        Navigate.Filter.SetFilter("Table ID", Format(Database::"Sustainability Ledger Entry"));
        Navigate."No. of Records".AssertEquals(1);
        Navigate.OK().Invoke();
    end;
}
