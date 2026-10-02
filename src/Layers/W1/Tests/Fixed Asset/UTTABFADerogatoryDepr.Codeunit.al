// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134166 "UT TAB FA Derogatory Depr."
{
    // [FEATURE] [Fixed Asset] [Derogatory]

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        IsInitialized: Boolean;
        DialogErr: Label 'Dialog';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcFirstAssignmentSucceeds()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A depreciation book accepts its first derogatory relationship
        Initialize();

        // [GIVEN] Normal and tax depreciation books without a derogatory relationship
        CreateDepreciationBook(NormalDepreciationBook);
        CreateDepreciationBook(TaxDepreciationBook);

        // [WHEN] The normal book is assigned as the tax book's derogatory calculation
        TaxDepreciationBook.Validate("Derogatory Calc.", NormalDepreciationBook.Code);

        // [THEN] The tax book contains the assigned relationship
        TaxDepreciationBook.TestField("Derogatory Calc.", NormalDepreciationBook.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcBeforeCodeAssignmentSucceeds()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory relationship can be assigned before the depreciation book code
        Initialize();

        // [GIVEN] A normal depreciation book
        CreateDepreciationBook(NormalDepreciationBook);

        // [WHEN] A new tax book receives the relationship before its code
        TaxDepreciationBook.Init();
        TaxDepreciationBook.Validate("Derogatory Calc.", NormalDepreciationBook.Code);
        TaxDepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        TaxDepreciationBook.Insert();

        // [THEN] The inserted tax book contains the assigned relationship
        TaxDepreciationBook.TestField("Derogatory Calc.", NormalDepreciationBook.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcRelationshipChangeToUsedBookErrors()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        OtherNormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        OtherTaxDepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A tax book cannot change its relationship to a normal book already in use
        Initialize();

        // [GIVEN] Two normal books with separate tax-book relationships
        CreateDepreciationBook(NormalDepreciationBook);
        CreateDepreciationBook(OtherNormalDepreciationBook);
        CreateDepreciationBook(TaxDepreciationBook);
        UpdateDerogatoryCalculationDepreciationBook(TaxDepreciationBook, NormalDepreciationBook.Code);
        CreateDepreciationBook(OtherTaxDepreciationBook);
        UpdateDerogatoryCalculationDepreciationBook(OtherTaxDepreciationBook, OtherNormalDepreciationBook.Code);

        // [WHEN] The first tax book is assigned to the other normal book
        asserterror TaxDepreciationBook.Validate("Derogatory Calc.", OtherNormalDepreciationBook.Code);

        // [THEN] The conflicting relationship is rejected
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveImportedAmbiguousDerogatoryRecordErrors()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        OtherTaxDepreciationBook: Record "Depreciation Book";
        DerogatoryDepreciationBook: Record "Depreciation Book";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An imported ambiguous derogatory relationship cannot be resolved
        Initialize();

        // [GIVEN] Two imported tax books related to the same normal book
        CreateDepreciationBook(NormalDepreciationBook);
        CreateDepreciationBook(TaxDepreciationBook);
        TaxDepreciationBook."Derogatory Calc." := NormalDepreciationBook.Code;
        TaxDepreciationBook.Modify();
        CreateDepreciationBook(OtherTaxDepreciationBook);
        OtherTaxDepreciationBook."Derogatory Calc." := NormalDepreciationBook.Code;
        OtherTaxDepreciationBook.Modify();

        // [WHEN] The derogatory book for the normal book is requested
        asserterror DerogatoryPostingMgt.GetDerogatoryBook(
            NormalDepreciationBook.Code, DerogatoryDepreciationBook);

        // [THEN] The ambiguous relationship is rejected
        Assert.ExpectedError('More than one derogatory depreciation book');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateFALinkRequiresExistingSource()
    var
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An FA ledger link requires an existing source entry
        Initialize();

        // [GIVEN] A counterpart that references a missing source entry
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := GetNextFALedgerEntryNo() + 1;

        // [WHEN] The derogatory link is validated
        asserterror DerogatoryPostingMgt.ValidateDerogatoryLink(DerogatoryFALedgerEntry);

        // [THEN] The missing source entry is reported
        Assert.ExpectedError('does not exist and cannot be used as a derogatory source entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateFALinkRejectsDuplicateCounterpart()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        ExistingCounterpartFALedgerEntry: Record "FA Ledger Entry";
        DuplicateCounterpartFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An FA source entry cannot have duplicate derogatory counterparts
        Initialize();

        // [GIVEN] A source entry with an existing derogatory counterpart
        CreateDepreciationBook(NormalDepreciationBook);
        CreateDepreciationBook(TaxDepreciationBook);
        UpdateDerogatoryCalculationDepreciationBook(TaxDepreciationBook, NormalDepreciationBook.Code);
        CreateFALedgerEntry(SourceFALedgerEntry, NormalDepreciationBook.Code, 0);
        CreateFALedgerEntry(
            ExistingCounterpartFALedgerEntry, TaxDepreciationBook.Code, SourceFALedgerEntry."Entry No.");
        ExistingCounterpartFALedgerEntry."FA No." := SourceFALedgerEntry."FA No.";
        ExistingCounterpartFALedgerEntry.Modify();
        DuplicateCounterpartFALedgerEntry := ExistingCounterpartFALedgerEntry;
        DuplicateCounterpartFALedgerEntry."Entry No." := 0;

        // [WHEN] A duplicate counterpart link is validated
        asserterror DerogatoryPostingMgt.ValidateDerogatoryLink(DuplicateCounterpartFALedgerEntry);

        // [THEN] The duplicate counterpart is rejected
        Assert.ExpectedError('A derogatory counterpart already exists for source entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateMaintenanceLinkRejectsDifferentAsset()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A maintenance entry cannot link to a counterpart for another fixed asset
        Initialize();

        // [GIVEN] A source and counterpart maintenance entry for different fixed assets
        CreateDepreciationBook(NormalDepreciationBook);
        CreateDepreciationBook(TaxDepreciationBook);
        UpdateDerogatoryCalculationDepreciationBook(TaxDepreciationBook, NormalDepreciationBook.Code);
        CreateMaintenanceLedgerEntry(SourceMaintenanceLedgerEntry, NormalDepreciationBook.Code);
        CounterpartMaintenanceLedgerEntry."FA No." := LibraryUTUtility.GetNewCode();
        CounterpartMaintenanceLedgerEntry."Depreciation Book Code" := TaxDepreciationBook.Code;
        CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No." := SourceMaintenanceLedgerEntry."Entry No.";

        // [WHEN] The maintenance link is validated
        asserterror DerogatoryPostingMgt.ValidateDerogatoryLink(CounterpartMaintenanceLedgerEntry);

        // [THEN] The cross-asset link is rejected
        Assert.ExpectedError('cannot be linked to depreciation book');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedMirrorRoleIsNotEligible()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        DerogatoryDepreciationBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A generated mirror cannot generate another derogatory counterpart
        Initialize();

        // [GIVEN] A configured normal-to-tax depreciation book relationship
        CreateDepreciationBook(NormalDepreciationBook);
        CreateDepreciationBook(TaxDepreciationBook);
        UpdateDerogatoryCalculationDepreciationBook(TaxDepreciationBook, NormalDepreciationBook.Code);

        // [WHEN] Eligibility is evaluated for a generated mirror
        // [THEN] The generated mirror is ineligible
        Assert.IsFalse(
            DerogatoryPostingMgt.IsEligible(
                LibraryUTUtility.GetNewCode(), NormalDepreciationBook.Code,
                Enum::"Derogatory Posting Role"::"Generated Mirror", DerogatoryDepreciationBookCode),
            'A generated mirror must not be eligible for another derogatory counterpart.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneralJournalCounterpartUsesPostedSourceAmount()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        TaxFADepreciationBook: Record "FA Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
        SourceGenJournalLine: Record "Gen. Journal Line";
        CounterpartFAJournalLine: Record "FA Journal Line";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        PostedSourceAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A general journal counterpart uses the posted source amount
        Initialize();

        // [GIVEN] An eligible general journal source and a posted amount
        CreateDepreciationBook(NormalDepreciationBook);
        CreateDepreciationBook(TaxDepreciationBook);
        UpdateDerogatoryCalculationDepreciationBook(TaxDepreciationBook, NormalDepreciationBook.Code);
        CreateFADepreciationBook(TaxFADepreciationBook, TaxDepreciationBook.Code);
        FAJournalSetup."Depreciation Book Code" := TaxDepreciationBook.Code;
        FAJournalSetup.Insert();
        SourceGenJournalLine."Account No." := TaxFADepreciationBook."FA No.";
        SourceGenJournalLine."Depreciation Book Code" := NormalDepreciationBook.Code;
        SourceGenJournalLine.Amount := LibraryRandom.RandDec(1000, 2);
        PostedSourceAmount := SourceGenJournalLine.Amount * 2;

        // [WHEN] The derogatory journal counterpart is created
        Assert.IsTrue(
            DerogatoryPostingMgt.MakeDerogatoryJournalLine(
                CounterpartFAJournalLine, SourceGenJournalLine, PostedSourceAmount,
                Enum::"Derogatory Posting Role"::Source),
            'The posted source must produce an eligible counterpart.');

        // [THEN] The counterpart amount equals the posted source amount
        CounterpartFAJournalLine.TestField(Amount, PostedSourceAmount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FAJnlPostBatchCompatibilityDelegateBuildsCounterpart()
    var
        NormalDepreciationBook: Record "Depreciation Book";
        TaxDepreciationBook: Record "Depreciation Book";
        TaxFADepreciationBook: Record "FA Depreciation Book";
        SourceFAJournalLine: Record "FA Journal Line";
        CounterpartFAJournalLine: Record "FA Journal Line";
        FAJnlPostBatch: Codeunit "FA Jnl.-Post Batch";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The FA journal compatibility delegate builds an eligible counterpart
        Initialize();

        // [GIVEN] An FA journal source with a configured derogatory book
        CreateDepreciationBook(NormalDepreciationBook);
        CreateDepreciationBook(TaxDepreciationBook);
        UpdateDerogatoryCalculationDepreciationBook(TaxDepreciationBook, NormalDepreciationBook.Code);
        CreateFADepreciationBook(TaxFADepreciationBook, TaxDepreciationBook.Code);
        SourceFAJournalLine."FA No." := TaxFADepreciationBook."FA No.";
        SourceFAJournalLine."Depreciation Book Code" := NormalDepreciationBook.Code;

        // [WHEN] The compatibility delegate creates the counterpart
        Assert.IsTrue(
            FAJnlPostBatch.MakeDerogatoryFAJnlLine(CounterpartFAJournalLine, SourceFAJournalLine),
            'The compatibility delegate must construct an eligible counterpart.');

        // [THEN] The counterpart uses the tax depreciation book
        CounterpartFAJournalLine.TestField("Depreciation Book Code", TaxDepreciationBook.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FAJnlPostBatchCompatibilityDelegatePreservesSourceWhenIneligible()
    var
        SourceFAJournalLine: Record "FA Journal Line";
        NewFAJournalLine: Record "FA Journal Line";
        FAJnlPostBatch: Codeunit "FA Jnl.-Post Batch";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The FA journal compatibility delegate preserves an ineligible source
        Initialize();

        // [GIVEN] An FA journal source without a derogatory-book relationship
        SourceFAJournalLine."Journal Template Name" := LibraryUTUtility.GetNewCode10();
        SourceFAJournalLine."Journal Batch Name" := LibraryUTUtility.GetNewCode10();
        SourceFAJournalLine."Line No." := LibraryRandom.RandInt(10000);
        SourceFAJournalLine."FA No." := LibraryUTUtility.GetNewCode();
        SourceFAJournalLine."Depreciation Book Code" := LibraryUTUtility.GetNewCode10();
        SourceFAJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        SourceFAJournalLine.Description := LibraryUTUtility.GetNewCode();
        SourceFAJournalLine.Amount := LibraryRandom.RandDec(1000, 2);
        NewFAJournalLine."Journal Template Name" := LibraryUTUtility.GetNewCode10();

        // [WHEN] The compatibility delegate evaluates the source
        Assert.IsFalse(
            FAJnlPostBatch.MakeDerogatoryFAJnlLine(NewFAJournalLine, SourceFAJournalLine),
            'An FA journal line without a derogatory-book relationship must be ineligible.');

        // [THEN] The returned journal line remains equal to the source
        AssertFAJournalLinesEqual(SourceFAJournalLine, NewFAJournalLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcDerogatoryDeprBookExistsError()
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A normal book cannot be assigned to multiple derogatory depreciation books
        Initialize();

        // [GIVEN] A normal book already assigned to a derogatory depreciation book
        CreateDepreciationBook(DepreciationBook);
        UpdateGLIntegrationDepreciationBook(DepreciationBook);
        CreateDepreciationBook(DepreciationBook2);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook2, DepreciationBook.Code);
        CreateDepreciationBook(DepreciationBook3);
        UpdateGLIntegrationDepreciationBook(DepreciationBook3);

        // [WHEN] The normal book is assigned to another derogatory book
        asserterror DepreciationBook3.Validate("Derogatory Calc.", DepreciationBook.Code);

        // [THEN] The duplicate relationship is rejected
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcSameDerogatoryDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A depreciation book cannot be its own derogatory calculation book
        Initialize();

        // [GIVEN] A depreciation book
        CreateDepreciationBook(DepreciationBook);

        // [WHEN] The book is assigned as its own derogatory calculation
        asserterror DepreciationBook.Validate("Derogatory Calc.", DepreciationBook.Code);

        // [THEN] The self-referencing relationship is rejected
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcDerogatoryDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot become the normal book in another relationship
        Initialize();

        // [GIVEN] A book already acting as a derogatory depreciation book
        CreateDepreciationBook(DepreciationBook);
        UpdateGLIntegrationDepreciationBook(DepreciationBook);
        CreateDepreciationBook(DepreciationBook2);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook2, DepreciationBook.Code);
        CreateDepreciationBook(DepreciationBook3);

        // [WHEN] Another book uses that derogatory book as its calculation book
        asserterror DepreciationBook3.Validate("Derogatory Calc.", DepreciationBook2.Code);

        // [THEN] The chained relationship is rejected
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcDerogatoryAccountingDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An accounting book cannot become a derogatory depreciation book
        Initialize();

        // [GIVEN] An accounting book already used by a derogatory depreciation book
        CreateDepreciationBook(DepreciationBook);
        CreateDepreciationBook(DepreciationBook2);
        CreateDepreciationBook(DepreciationBook3);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook3, DepreciationBook.Code);
        DepreciationBook.CalcFields("Derogatory Book Code");

        // [WHEN] The accounting book is assigned as a derogatory book
        asserterror DepreciationBook.Validate("Derogatory Calc.", DepreciationBook2.Code);

        // [THEN] The invalid relationship is rejected
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcAcqCostDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate acquisition cost with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with acquisition-cost integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Acq. Cost"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcGLIntegrationDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate depreciation with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with depreciation integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Depreciation"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcWriteDownDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate write-downs with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with write-down integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Write-Down"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcAppreciationDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate appreciation with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with appreciation integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Appreciation"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcCustom1DeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate custom type 1 with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with custom type 1 integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Custom 1"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcCustom2DeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate custom type 2 with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with custom type 2 integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Custom 2"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcDisposalDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate disposal with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with disposal integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Disposal"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcMaintenanceDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate maintenance with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with maintenance integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Maintenance"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateGLIntegrationDerogatoryCalDepreBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory book cannot integrate derogatory postings with the general ledger
        Initialize();

        // [GIVEN] A depreciation book with derogatory integration enabled
        // [WHEN] The book is assigned as a derogatory calculation book
        // [THEN] The general ledger integration is rejected
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("Integration G/L - Derogatory"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateDerogatoryCalcDeprecBookZeroDerogatoryError()
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A derogatory relationship requires zero existing derogatory amounts
        Initialize();

        // [GIVEN] A prospective derogatory book with an existing derogatory ledger amount
        CreateDepreciationBook(DepreciationBook);
        CreateDepreciationBook(DepreciationBook2);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook, DepreciationBook2.Code);
        CreateDepreciationBook(DepreciationBook3);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook3, LibraryUTUtility.GetNewCode10());
        CreateFADepreciationBook(FADepreciationBook, DepreciationBook3."Derogatory Calc.");
        CreateFALedgerEntry(FADepreciationBook);

        // [WHEN] The book is assigned to a new derogatory relationship
        asserterror DepreciationBook3.Validate("Derogatory Calc.", DepreciationBook."Derogatory Calc.");

        // [THEN] The nonzero derogatory amount is rejected
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateTypesFADateType()
    var
        FADateType: Record "FA Date Type";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] FA date types include the last derogatory date
        Initialize();

        // [GIVEN] The derogatory FA date type entry number
        FADateType."Entry No." := 11;

        // [WHEN] FA date types are created
        FADateType.CreateTypes();

        // [THEN] The date type points to the last derogatory field and caption
        FADateType.TestField("FA Date Type No.", FADepreciationBook.FieldNo("Last Derogatory"));
        FADateType.TestField("FA Date Type Name", FADepreciationBook.FieldCaption("Last Derogatory"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateTypesFAMatrixPostingType()
    var
        FAMatrixPostingType: Record "FA Matrix Posting Type";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] FA matrix posting types include the derogatory amount
        Initialize();

        // [GIVEN] The derogatory FA matrix posting type entry number
        FAMatrixPostingType."Entry No." := 12;

        // [WHEN] FA matrix posting types are created
        FAMatrixPostingType.CreateTypes();

        // [THEN] The posting type uses the derogatory amount caption
        FAMatrixPostingType.TestField("FA Posting Type Name", FADepreciationBook.FieldCaption("Derogatory Amount"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GLIntegrationKeepsLegacyArrayAndAddsDerogatory()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] G/L integration preserves the published array and supports including or excluding additional posting types
        Initialize();

        // [GIVEN] Book "B" integrates acquisition, depreciation, and derogatory postings
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook."G/L Integration - Depreciation" := true;
        DepreciationBook."Integration G/L - Derogatory" := true;

        // [WHEN] The original signature and both overload modes are called
        // [THEN] The original nine values are unchanged and additional integration follows the flag
        VerifyGLIntegrationCompatibility(DepreciationBook);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RelationshipChangeAllowsAllZeroAssetBalances()
    var
        DepreciationBook: Record "Depreciation Book";
        LastFADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A relationship can be removed when every asset has zero derogatory balance
        Initialize();

        // [GIVEN] Book "B" has two assets without derogatory amounts
        CreateRelationshipValidationFixture(DepreciationBook, LastFADepreciationBook);

        // [WHEN] The relationship is removed
        DepreciationBook.Validate("Derogatory Calc.", '');

        // [THEN] The change succeeds
        Assert.AreEqual('', DepreciationBook."Derogatory Calc.", 'Zero balances must permit removal.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RelationshipChangeChecksLaterAssetBalance()
    var
        DepreciationBook: Record "Depreciation Book";
        LastFADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A nonzero balance on a later asset still prevents changing the relationship
        Initialize();

        // [GIVEN] Only the last asset of book "B" has a derogatory balance
        CreateRelationshipValidationFixture(DepreciationBook, LastFADepreciationBook);
        FALedgerEntry."Entry No." := FALedgerEntry.GetLastEntryNo() + 1;
        FALedgerEntry."FA No." := LastFADepreciationBook."FA No.";
        FALedgerEntry."Depreciation Book Code" := LastFADepreciationBook."Depreciation Book Code";
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Derogatory;
        FALedgerEntry.Amount := 100;
        FALedgerEntry.Insert();

        // [WHEN] The relationship is removed
        asserterror DepreciationBook.Validate("Derogatory Calc.", '');

        // [THEN] Validation checks the later asset, not just the first zero balance
        Assert.ExpectedError(LastFADepreciationBook.FieldCaption("Derogatory Amount"));
        Assert.ExpectedErrorCode('TestField');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT TAB FA Derogatory Depr.");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"UT TAB FA Derogatory Depr.");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"UT TAB FA Derogatory Depr.");
    end;

    local procedure AssertFAJournalLinesEqual(ExpectedFAJournalLine: Record "FA Journal Line"; ActualFAJournalLine: Record "FA Journal Line")
    var
        ExpectedRecordRef: RecordRef;
        ActualRecordRef: RecordRef;
        ExpectedFieldRef: FieldRef;
        ActualFieldRef: FieldRef;
        FieldIndex: Integer;
    begin
        ExpectedRecordRef.GetTable(ExpectedFAJournalLine);
        ActualRecordRef.GetTable(ActualFAJournalLine);
        for FieldIndex := 1 to ExpectedRecordRef.FieldCount() do begin
            ExpectedFieldRef := ExpectedRecordRef.FieldIndex(FieldIndex);
            ActualFieldRef := ActualRecordRef.Field(ExpectedFieldRef.Number());
            Assert.AreEqual(
                Format(ExpectedFieldRef.Value()), Format(ActualFieldRef.Value()),
                StrSubstNo('The compatibility delegate must copy field %1 before returning false.', ExpectedFieldRef.Number()));
        end;
    end;

    local procedure CreateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        DepreciationBook.Insert();
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10])
    begin
        FADepreciationBook."FA No." := LibraryUTUtility.GetNewCode();
        FADepreciationBook."Depreciation Book Code" := DepreciationBookCode;
        FADepreciationBook.Insert();
    end;

    local procedure CreateFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; DepreciationBookCode: Code[10]; DerogatorySourceEntryNo: Integer)
    begin
        FALedgerEntry."Entry No." := GetNextFALedgerEntryNo();
        FALedgerEntry."FA No." := LibraryUTUtility.GetNewCode();
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."Derogatory Source Entry No." := DerogatorySourceEntryNo;
        FALedgerEntry.Insert();
    end;

    local procedure CreateFALedgerEntry(FADepreciationBook: Record "FA Depreciation Book")
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
    begin
        FALedgerEntry."Entry No." := 1;
        if FALedgerEntry2.FindLast() then
            FALedgerEntry."Entry No." := FALedgerEntry2."Entry No." + 1;
        FALedgerEntry."FA No." := FADepreciationBook."FA No.";
        FALedgerEntry."Depreciation Book Code" := FADepreciationBook."Depreciation Book Code";
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Derogatory;
        FALedgerEntry."Derogatory Excluded" := false;
        FALedgerEntry.Amount := LibraryRandom.RandDec(10, 2);
        FALedgerEntry.Insert();
    end;

    local procedure CreateMaintenanceLedgerEntry(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; DepreciationBookCode: Code[10])
    var
        LastMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry."Entry No." := 1;
        if LastMaintenanceLedgerEntry.FindLast() then
            MaintenanceLedgerEntry."Entry No." := LastMaintenanceLedgerEntry."Entry No." + 1;
        MaintenanceLedgerEntry."FA No." := LibraryUTUtility.GetNewCode();
        MaintenanceLedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        MaintenanceLedgerEntry.Insert();
    end;

    local procedure CreateRelationshipValidationFixture(var TaxDepreciationBook: Record "Depreciation Book"; var LastFADepreciationBook: Record "FA Depreciation Book")
    var
        NormalDepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        Index: Integer;
    begin
        LibraryFixedAsset.CreateDepreciationBook(NormalDepreciationBook);
        LibraryFixedAsset.CreateDepreciationBook(TaxDepreciationBook);
        TaxDepreciationBook.Validate("Derogatory Calc.", NormalDepreciationBook.Code);
        TaxDepreciationBook.Modify(true);
        for Index := 1 to 2 do begin
            LibraryFixedAsset.CreateFixedAsset(FixedAsset);
            LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", NormalDepreciationBook.Code);
        end;
        LastFADepreciationBook.SetRange("Depreciation Book Code", NormalDepreciationBook.Code);
        LastFADepreciationBook.FindLast();
    end;

    local procedure GetNextFALedgerEntryNo(): Integer
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        exit(FALedgerEntry.GetLastEntryNo() + 1);
    end;

    local procedure OnValidateDerogatoryCalculationDepreciationBook(FieldNo: Integer)
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        CreateDepreciationBook(DepreciationBook);
        DepreciationBook2.Code := LibraryUTUtility.GetNewCode10();
        RecRef.GetTable(DepreciationBook2);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(true);
        RecRef.SetTable(DepreciationBook2);

        asserterror DepreciationBook2.Validate("Derogatory Calc.", DepreciationBook.Code);

        Assert.ExpectedErrorCode(DialogErr);
    end;

    local procedure UpdateDerogatoryCalculationDepreciationBook(var DepreciationBook: Record "Depreciation Book"; DerogatoryCalculation: Code[10])
    begin
        DepreciationBook."Derogatory Calc." := DerogatoryCalculation;
        DepreciationBook.Modify();
    end;

    local procedure UpdateGLIntegrationDepreciationBook(DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook."G/L Integration - Depreciation" := true;
        DepreciationBook."G/L Integration - Write-Down" := true;
        DepreciationBook."G/L Integration - Appreciation" := true;
        DepreciationBook."G/L Integration - Custom 1" := true;
        DepreciationBook."G/L Integration - Custom 2" := true;
        DepreciationBook."G/L Integration - Disposal" := true;
        DepreciationBook."G/L Integration - Maintenance" := true;
        DepreciationBook."Integration G/L - Derogatory" := true;
        DepreciationBook.Modify();
    end;

    local procedure VerifyGLIntegrationCompatibility(DepreciationBook: Record "Depreciation Book")
    var
        DepreciationBookRecordRef: RecordRef;
        LegacyGLIntegration: array[9] of Boolean;
        ExtendedGLIntegration: array[13] of Boolean;
        FrenchGLIntegration: array[13] of Boolean;
        Index: Integer;
    begin
        DepreciationBookRecordRef.GetTable(DepreciationBook);
        if DepreciationBookRecordRef.FieldExist(10802) then begin
            DepreciationBookRecordRef.Field(10802).Value := true;
            DepreciationBookRecordRef.SetTable(DepreciationBook);
            DepreciationBook.IndexGLIntegration(FrenchGLIntegration);
            CopyArray(LegacyGLIntegration, FrenchGLIntegration, 1, 9);
        end else
            DepreciationBook.IndexGLIntegration(LegacyGLIntegration);
        DepreciationBookRecordRef.Close();
        DepreciationBook.IndexGLIntegration(ExtendedGLIntegration, true);
        for Index := 1 to 9 do
            Assert.AreEqual(LegacyGLIntegration[Index], ExtendedGLIntegration[Index], 'The original integration values must not change.');
        Assert.IsTrue(LegacyGLIntegration[1], 'Acquisition integration must remain enabled.');
        Assert.IsTrue(LegacyGLIntegration[2], 'Depreciation integration must remain enabled.');
        Assert.IsTrue(ExtendedGLIntegration[13], 'The extended API must expose derogatory integration.');

        DepreciationBook.IndexGLIntegration(ExtendedGLIntegration, false);
        for Index := 1 to 9 do
            Assert.AreEqual(LegacyGLIntegration[Index], ExtendedGLIntegration[Index], 'Excluding additional types must preserve the original integration values.');
        Assert.IsFalse(ExtendedGLIntegration[13], 'Excluding additional types must clear a previous derogatory integration value.');

        DepreciationBook.IndexGLIntegration(ExtendedGLIntegration, true);
        Assert.IsTrue(ExtendedGLIntegration[13], 'The same buffer must support including additional types again.');
    end;
}
