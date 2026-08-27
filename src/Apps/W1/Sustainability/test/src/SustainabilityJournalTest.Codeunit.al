namespace Microsoft.Test.Sustainability;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Calculation;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Posting;
using System.TestLibraries.Utilities;

codeunit 148181 "Sustainability Journal Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySustainability: Codeunit "Library - Sustainability";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        OneDefaultTemplateShouldBeCreatedLbl: Label 'One default template should be created after page is opened', Locked = true;
        OneDefaultBatchShouldBeCreatedLbl: Label 'One default batch should be created after page is opened', Locked = true;
        CustomAmountMustBePositiveLbl: Label 'The custom amount must be positive', Locked = true;
        CollectableAmountMustBeEqualLbl: Label 'The collectable amount must exclude the general ledger entries that were already collected', Locked = true;
        RelationMustExistLbl: Label 'A relation between the general ledger entry and the sustainability entry must exist', Locked = true;
        CollectionInfoMustBeClearedLbl: Label 'The collection information must be cleared on the sustainability journal line', Locked = true;

    [Test]
    procedure TestDefaultTemplateAndBatchSuccessfullyInserted()
    var
        SustainabilityJnlTemplate: Record "Sustainability Jnl. Template";
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
    begin
        // [SCENARIO] Test default template and batch creation when Opening the Journal page
        LibrarySustainability.CleanUpBeforeTesting();

        // [WHEN] Opening the Journal page, the procedure `GetASustainabilityJournalBatch` will be called
        SustainabilityJournalMgt.GetASustainabilityJournalBatch(false);

        Clear(SustainabilityJnlTemplate);
        Clear(SustainabilityJnlBatch);

        // [THEN] Exactly one default template and batch should be created
        Assert.AreEqual(1, SustainabilityJnlTemplate.Count(), OneDefaultTemplateShouldBeCreatedLbl);
        Assert.AreEqual(1, SustainabilityJnlBatch.Count(), OneDefaultBatchShouldBeCreatedLbl);
    end;

    [Test]
    procedure TestDefaultTemplateAndBatchRecurringSuccessfullyInserted()
    var
        SustainabilityJnlTemplate: Record "Sustainability Jnl. Template";
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
    begin
        // [SCENARIO] Test default template and batch creation when Opening the Journal page
        LibrarySustainability.CleanUpBeforeTesting();

        // [WHEN] Opening the Journal page, the procedure `GetASustainabilityJournalBatch` will be called
        SustainabilityJournalMgt.GetASustainabilityJournalBatch(true);

        Clear(SustainabilityJnlTemplate);
        Clear(SustainabilityJnlBatch);

        // [THEN] Exactly one default template and batch should be created
        Assert.AreEqual(1, SustainabilityJnlTemplate.Count(), OneDefaultTemplateShouldBeCreatedLbl);
        Assert.AreEqual(1, SustainabilityJnlBatch.Count(), OneDefaultBatchShouldBeCreatedLbl);
    end;

    [Test]
    procedure TestCheckForEmissionScopeMatching()
    var
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
        Category1Tok, Category2Tok : Code[20];
    begin
        // [SCENARIO] Test the check for scope matching works as expected
        // Account Category needs to match the scope of the Batch
        // Unless no scope is defined on the Batch, then the Account Category just needs to be not empty
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] A Sustainability Journal Batch
        SustainabilityJnlBatch := SustainabilityJournalMgt.GetASustainabilityJournalBatch(true);

        // [WHEN] The Default Batch's "Emission Scope" should be empty
        Assert.AreEqual(Enum::"Emission Scope"::" ", SustainabilityJnlBatch."Emission Scope", 'The Default Emission Scope should be empty');

        // [GIVEN] A Account Category with Emission Scope = "Scope 1" and a Batch with Emission Scope = " "
        Category1Tok := 'Test Category 1';
        LibrarySustainability.InsertAccountCategory(Category1Tok, '', Enum::"Emission Scope"::"Scope 1", Enum::"Calculation Foundation"::"Fuel/Electricity", true, true, true, '', false);

        SustainabilityJournalLine.Validate("Journal Template Name", SustainabilityJnlBatch."Journal Template Name");
        SustainabilityJournalLine.Validate("Journal Batch Name", SustainabilityJnlBatch.Name);
        SustainabilityJournalLine.Validate("Line No.", 1000);
        SustainabilityJournalLine.Validate("Account Category", Category1Tok);
        SustainabilityJournalLine.Insert(true);

        // [THEN] The Check should pass
        SustainabilityJournalMgt.CheckScopeMatchWithBatch(SustainabilityJournalLine);


        // [GIVEN] A Account Category with Emission Scope = "Scope 2" and a Batch with Emission Scope = "Scope 1"
        Category2Tok := 'Test Category 2';
        LibrarySustainability.InsertAccountCategory(Category2Tok, '', Enum::"Emission Scope"::"Scope 2", Enum::"Calculation Foundation"::"Fuel/Electricity", true, true, true, '', false);

        SustainabilityJnlBatch."Emission Scope" := Enum::"Emission Scope"::"Scope 1";
        SustainabilityJnlBatch.Modify(true);

        SustainabilityJournalLine.Validate("Journal Template Name", SustainabilityJnlBatch."Journal Template Name");
        SustainabilityJournalLine.Validate("Journal Batch Name", SustainabilityJnlBatch.Name);
        SustainabilityJournalLine.Validate("Line No.", 2000);
        SustainabilityJournalLine.Validate("Account Category", Category2Tok);
        SustainabilityJournalLine.Insert(true);

        // [THEN] The Check should fail
        asserterror SustainabilityJournalMgt.CheckScopeMatchWithBatch(SustainabilityJournalLine);
    end;

    [Test]
    procedure TestCustomAmountIsPositiveForNegativeTotalOfGL()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJouralLine: Record "Gen. Journal Line";
        SustainabilityCalcMgt: Codeunit "Sustainability Calc. Mgt.";
        GenJournalTemplateCode: Code[10];
        GLAccountNo: Code[20];
        GLAmount, CustomAmount : Decimal;
    begin
        // [SCENARIO 540221] Test that the custom amount is positive when the total of the GL is negative

        // [GIVEN] G/L Account exists
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [GIVEN] G/L Batch and Template exist
        GenJournalTemplateCode := LibraryERM.SelectGenJnlTemplate();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateCode);

        // [GIVEN] G/L Entry with Amount = -1000 for the G/L Account
        GLAmount := -LibraryRandom.RandDec(1000, 2);
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJouralLine, GenJournalTemplateCode, GenJournalBatch.Name, GenJouralLine."Document Type"::Payment, GenJouralLine."Account Type"::"G/L Account", GLAccountNo, GenJouralLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), GLAmount);
        LibraryERM.PostGeneralJnlLine(GenJouralLine);

        // [GIVEN] Sustain Account Category with the G/L Account calculation foundation
        SustainAccountCategory := CreateSustAccountCategoryWithGLAccountNo(GLAccountNo);

        // [WHEN] Getting the collectable amount for sustanability account category
        CustomAmount := SustainabilityCalcMgt.GetCollectableGLAmount(SustainAccountCategory, 0D, 0D);

        // [THEN] The custom amount = 1000
        Assert.AreEqual(Abs(GLAmount), CustomAmount, CustomAmountMustBePositiveLbl);
    end;

    [Test]
    procedure TestSustainabilityJournalFormulaInputEditabilityMatrix()
    var
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 641058] Formula inputs on sustainability journals are editable only when the calculation uses them.
        Initialize();

        // [GIVEN] Sustainability journal setup is clean and one journal batch is available for all matrix cases.
        SustainabilityJnlBatch := SustainabilityJournalMgt.GetASustainabilityJournalBatch(false);

        // [WHEN] Journal lines are opened for each supported and unsupported matrix combination.

        // [THEN] Each line exposes only the formula inputs used by its scope and calculation foundation.
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 1", "Calculation Foundation"::"Fuel/Electricity", true, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 1", "Calculation Foundation"::Distance, false, true, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 1", "Calculation Foundation"::Installations, false, false, true, true, true);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 1", "Calculation Foundation"::Custom, false, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 2", "Calculation Foundation"::"Fuel/Electricity", true, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 2", "Calculation Foundation"::Distance, false, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 2", "Calculation Foundation"::Installations, false, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 2", "Calculation Foundation"::Custom, false, false, true, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 3", "Calculation Foundation"::"Fuel/Electricity", true, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 3", "Calculation Foundation"::Distance, false, true, false, true, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 3", "Calculation Foundation"::Installations, false, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 3", "Calculation Foundation"::Custom, false, false, true, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Water/Waste", "Calculation Foundation"::"Fuel/Electricity", false, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Water/Waste", "Calculation Foundation"::Distance, false, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Water/Waste", "Calculation Foundation"::Installations, false, false, false, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Water/Waste", "Calculation Foundation"::Custom, false, false, true, false, false);
        VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch, "Emission Scope"::"Scope 1", "Calculation Foundation"::" ", false, false, false, false, false);
    end;

    [Test]
    procedure TestSustainabilityJournalFormulaInputEditabilityFallbacks()
    var
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 641058] Incomplete journal account context disables formula inputs without making the unit read-only.
        Initialize();

        // [GIVEN] Sustainability journal setup is clean and one journal batch is available for all fallback cases.
        SustainabilityJnlBatch := SustainabilityJournalMgt.GetASustainabilityJournalBatch(false);

        // [WHEN] Journal lines are opened with a blank scope, missing category, or blank account.

        // [THEN] All numeric formula inputs are disabled and Unit of Measure remains editable.
        VerifySustainabilityJournalBlankScopeFormulaInputEditability(SustainabilityJnlBatch);
        VerifySustainabilityJournalMissingCategoryFormulaInputEditability(SustainabilityJnlBatch);
        VerifySustainabilityJournalBlankAccountFormulaInputEditability(SustainabilityJnlBatch);
    end;

    [Test]
    procedure TestSustainabilityJournalFormulaInputEditabilityRefresh()
    var
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
        Scope1SustainabilityAccount: Record "Sustainability Account";
        Scope3SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
        SustainabilityJournal: TestPage "Sustainability Journal";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 641058] Account and Manual Input changes refresh journal formula editability immediately.
        Initialize();

        // [GIVEN] A journal line uses a Scope 1 Fuel/Electricity account and a Scope 3 Distance account exists.
        SustainabilityJnlBatch := SustainabilityJournalMgt.GetASustainabilityJournalBatch(false);
        Scope1SustainabilityAccount := CreateSustainabilityAccount("Emission Scope"::"Scope 1", "Calculation Foundation"::"Fuel/Electricity");
        Scope3SustainabilityAccount := CreateSustainabilityAccount("Emission Scope"::"Scope 3", "Calculation Foundation"::Distance);
        SustainabilityJournalLine := LibrarySustainability.InsertSustainabilityJournalLine(
            SustainabilityJnlBatch, Scope1SustainabilityAccount, GetNewSustainabilityJournalLineNo(SustainabilityJnlBatch));

        // [WHEN] The journal line is opened.
        SustainabilityJournal.OpenEdit();
        SustainabilityJournal.Filter.SetFilter("Journal Template Name", SustainabilityJournalLine."Journal Template Name");
        SustainabilityJournal.Filter.SetFilter("Journal Batch Name", SustainabilityJournalLine."Journal Batch Name");
        SustainabilityJournal.Filter.SetFilter("Line No.", Format(SustainabilityJournalLine."Line No."));
        Assert.IsTrue(SustainabilityJournal.First(), 'The Sustainability Journal line must be available.');

        // [THEN] Only Fuel/Electricity is editable.
        AssertSustainabilityJournalFormulaInputEditability(SustainabilityJournal, true, false, false, false, false);

        // [WHEN] The account is changed to Scope 3 Distance.
        SustainabilityJournal."Sustainability Account No.".SetValue(Scope3SustainabilityAccount."No.");

        // [THEN] Distance and Installation Multiplier become editable.
        AssertSustainabilityJournalFormulaInputEditability(SustainabilityJournal, false, true, false, true, false);

        // [WHEN] Manual Input is enabled.
        SustainabilityJournal."Manual Input".SetValue(true);

        // [THEN] All numeric formula inputs are disabled.
        AssertSustainabilityJournalFormulaInputEditability(SustainabilityJournal, false, false, false, false, false);

        // [WHEN] Manual Input is disabled.
        SustainabilityJournal."Manual Input".SetValue(false);

        // [THEN] The Scope 3 Distance editability is restored.
        AssertSustainabilityJournalFormulaInputEditability(SustainabilityJournal, false, true, false, true, false);

        // [WHEN] The sustainability account is cleared.
        SustainabilityJournal."Sustainability Account No.".SetValue('');

        // [THEN] All numeric formula inputs are disabled.
        AssertSustainabilityJournalFormulaInputEditability(SustainabilityJournal, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CollectableGLAmountExcludesEntriesAlreadyCollected()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustainabilityCalcMgt: Codeunit "Sustainability Calc. Mgt.";
        GLAccountNo: Code[20];
        FirstDate, SecondDate, ThirdDate : Date;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Collecting an overlapping period returns only the amount of the general ledger entries that were not collected before.
        Initialize();

        // [GIVEN] G/L account "G" and a sustainability category collecting from "G".
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);

        // [GIVEN] Three posted G/L entries on "G": 1000, 500 and 2000 on three consecutive dates.
        FirstDate := WorkDate();
        SecondDate := WorkDate() + 1;
        ThirdDate := WorkDate() + 2;
        PostGLEntry(GLAccountNo, FirstDate, 1000, '');
        PostGLEntry(GLAccountNo, SecondDate, 500, '');
        PostGLEntry(GLAccountNo, ThirdDate, 2000, '');

        // [GIVEN] A sustainability journal line that collected the first two dates for 1500 and was posted.
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, FirstDate, SecondDate);
        Assert.AreEqual(1500, SustainabilityJnlLine."Custom Amount", CollectableAmountMustBeEqualLbl);
        PostSustainabilityJnlLine(SustainabilityJnlLine);

        // [WHEN] The collectable amount is calculated for the overlapping period that also covers the first two dates.
        // [THEN] The collectable amount is 2000 and not 3500.
        Assert.AreEqual(
            2000, SustainabilityCalcMgt.GetCollectableGLAmount(SustainAccountCategory, FirstDate, ThirdDate), CollectableAmountMustBeEqualLbl);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CollectableGLAmountIsZeroWhenAllEntriesAreCollected()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustainabilityCalcMgt: Codeunit "Sustainability Calc. Mgt.";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Repeating the same collection after posting returns zero.
        Initialize();

        // [GIVEN] G/L account "G" with one posted G/L entry of 1000 and a sustainability category collecting from "G".
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        PostGLEntry(GLAccountNo, WorkDate(), 1000, '');

        // [GIVEN] A sustainability journal line that collected the full period and was posted.
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, WorkDate(), WorkDate());
        PostSustainabilityJnlLine(SustainabilityJnlLine);

        // [WHEN] The collectable amount is calculated for the same period again.
        // [THEN] The collectable amount is 0.
        Assert.AreEqual(
            0, SustainabilityCalcMgt.GetCollectableGLAmount(SustainAccountCategory, WorkDate(), WorkDate()), CollectableAmountMustBeEqualLbl);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CollectableGLAmountIncludesGLEntriesPostedAfterCollection()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustainabilityCalcMgt: Codeunit "Sustainability Calc. Mgt.";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Only the general ledger entries posted after the previous collection are collectable.
        Initialize();

        // [GIVEN] G/L account "G" with one posted G/L entry of 1000 collected and posted on a sustainability journal line.
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        PostGLEntry(GLAccountNo, WorkDate(), 1000, '');
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, WorkDate(), WorkDate() + 2);
        PostSustainabilityJnlLine(SustainabilityJnlLine);

        // [WHEN] A new G/L entry of 300 is posted on "G" and the collectable amount is calculated for the same period.
        PostGLEntry(GLAccountNo, WorkDate() + 1, 300, '');

        // [THEN] The collectable amount is 300.
        Assert.AreEqual(
            300, SustainabilityCalcMgt.GetCollectableGLAmount(SustainAccountCategory, WorkDate(), WorkDate() + 2), CollectableAmountMustBeEqualLbl);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure PostingCollectedJnlLineCreatesGLEntryRelations()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        GLAccountNo: Code[20];
        FirstGLEntryNo, SecondGLEntryNo, SustLedgerEntryNo : Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Posting a collected journal line links every consumed general ledger entry to the new sustainability entry.
        Initialize();

        // [GIVEN] G/L account "G" with two posted G/L entries of 1000 and 500 and a sustainability category collecting from "G".
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        FirstGLEntryNo := PostGLEntry(GLAccountNo, WorkDate(), 1000, '');
        SecondGLEntryNo := PostGLEntry(GLAccountNo, WorkDate() + 1, 500, '');

        // [GIVEN] A sustainability journal line whose custom amount was collected from "G".
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, WorkDate(), WorkDate() + 1);

        // [WHEN] The journal is posted.
        SustLedgerEntryNo := PostSustainabilityJnlLine(SustainabilityJnlLine);

        // [THEN] Two relation records exist for the new sustainability entry and both G/L entries are flagged as collected.
        SustGLSustLedgerRel.SetRange("Sust. Ledger Entry No.", SustLedgerEntryNo);
        Assert.RecordCount(SustGLSustLedgerRel, 2);
        VerifyGLEntryRelation(FirstGLEntryNo, SustLedgerEntryNo, SustainAccountCategory.Code, 1000);
        VerifyGLEntryRelation(SecondGLEntryNo, SustLedgerEntryNo, SustainAccountCategory.Code, 500);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure PostingCollectedJnlLineFlowsCollectionInfoToLedgerEntry()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        GLAccountNo: Code[20];
        SustLedgerEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The collection information of the journal line is copied to the sustainability ledger entry.
        Initialize();

        // [GIVEN] G/L account "G" with one posted G/L entry of 1000 and a sustainability category collecting from "G".
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        PostGLEntry(GLAccountNo, WorkDate(), 1000, '');

        // [GIVEN] A sustainability journal line that collected a two day period.
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, WorkDate(), WorkDate() + 1);

        // [WHEN] The journal is posted.
        SustLedgerEntryNo := PostSustainabilityJnlLine(SustainabilityJnlLine);

        // [THEN] The sustainability ledger entry carries the collection flag and the collected period.
        SustainabilityLedgerEntry.Get(SustLedgerEntryNo);
        VerifyCollectionInformation(
            SustainabilityLedgerEntry."Collected from G/L Entries", SustainabilityLedgerEntry."Collect From Date",
            SustainabilityLedgerEntry."Collect To Date", true, WorkDate(), WorkDate() + 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure PostingNonCollectedJnlLineCreatesNoGLEntryRelations()
    var
        GLEntry: Record "G/L Entry";
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        SustainabilityCalcMgt: Codeunit "Sustainability Calc. Mgt.";
        GLAccountNo: Code[20];
        GLEntryNo, SustLedgerEntryNo : Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A journal line with a manually entered custom amount consumes no general ledger entries.
        Initialize();

        // [GIVEN] G/L account "G" with one posted G/L entry of 1000 and a sustainability category collecting from "G".
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        GLEntryNo := PostGLEntry(GLAccountNo, WorkDate(), 1000, '');

        // [GIVEN] A sustainability journal line with a custom amount that was typed instead of collected.
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        SustainabilityJnlLine.Validate("Custom Amount", 900);
        SustainabilityJnlLine.Modify(true);

        // [WHEN] The journal is posted.
        SustLedgerEntryNo := PostSustainabilityJnlLine(SustainabilityJnlLine);

        // [THEN] No relation record is created and the G/L entry is not flagged as collected.
        SustGLSustLedgerRel.SetRange("Sust. Ledger Entry No.", SustLedgerEntryNo);
        Assert.RecordIsEmpty(SustGLSustLedgerRel);
        GLEntry.Get(GLEntryNo);
        Assert.IsFalse(GLEntry."Sust. Collected", CollectableAmountMustBeEqualLbl);

        // [THEN] The G/L entry remains collectable.
        Assert.AreEqual(
            1000, SustainabilityCalcMgt.GetCollectableGLAmount(SustainAccountCategory, WorkDate(), WorkDate()), CollectableAmountMustBeEqualLbl);
    end;

    [Test]
    procedure CollectableGLAmountRespectsDateFilter()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityCalcMgt: Codeunit "Sustainability Calc. Mgt.";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The date filter still restricts the collectable general ledger entries after the collected filter was added.
        Initialize();

        // [GIVEN] G/L account "G" with posted G/L entries of 1000 and 2000 on two dates, none of them collected.
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        PostGLEntry(GLAccountNo, WorkDate(), 1000, '');
        PostGLEntry(GLAccountNo, WorkDate() + 2, 2000, '');

        // [WHEN] The collectable amount is calculated for the first date only.
        // [THEN] The collectable amount is 1000.
        Assert.AreEqual(
            1000, SustainabilityCalcMgt.GetCollectableGLAmount(SustainAccountCategory, WorkDate(), WorkDate()), CollectableAmountMustBeEqualLbl);
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CollectableGLAmountRespectsGlobalDimensionFilter()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustainabilityCalcMgt: Codeunit "Sustainability Calc. Mgt.";
        GLAccountNo: Code[20];
        OutOfScopeGLEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The global dimension filter of the category still restricts the collectable general ledger entries.
        Initialize();

        // [GIVEN] G/L account "G" with a posted G/L entry of 400 carrying dimension value "D1" and one of 700 carrying "D2".
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Global Dimension 1 Code");
        PostGLEntry(GLAccountNo, WorkDate(), 400, DimensionValue[1].Code);
        OutOfScopeGLEntryNo := PostGLEntry(GLAccountNo, WorkDate(), 700, DimensionValue[2].Code);

        // [GIVEN] The category is filtered on "D1".
        SustainAccountCategory."Global Dimension 1 Filter" := DimensionValue[1].Code;
        SustainAccountCategory.Modify(true);

        // [WHEN] The collectable amount is calculated for the whole period.
        // [THEN] The collectable amount is 400.
        Assert.AreEqual(
            400, SustainabilityCalcMgt.GetCollectableGLAmount(SustainAccountCategory, WorkDate(), WorkDate()), CollectableAmountMustBeEqualLbl);

        // [THEN] The entry carrying "D2" is not flagged as collected after posting.
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, WorkDate(), WorkDate());
        PostSustainabilityJnlLine(SustainabilityJnlLine);
        GLEntry.Get(OutOfScopeGLEntryNo);
        Assert.IsFalse(GLEntry."Sust. Collected", CollectableAmountMustBeEqualLbl);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler')]
    procedure TypingCustomAmountClearsCollectionInfoOnJnlLine()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustainabilityJournal: TestPage "Sustainability Journal";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Overwriting the collected amount by hand makes the line stop consuming the collected general ledger entries.
        Initialize();

        // [GIVEN] G/L account "G" with a posted G/L entry of 1000 and a sustainability journal line that collected it.
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        PostGLEntry(GLAccountNo, WorkDate(), 1000, '');
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, WorkDate(), WorkDate());

        // [WHEN] The user types a different custom amount on the sustainability journal page.
        OpenSustainabilityJournalOnLine(SustainabilityJournal, SustainabilityJnlLine);
        SustainabilityJournal."Custom Amount".SetValue(900);
        SustainabilityJournal.Close();

        // [THEN] The collection information is cleared on the journal line.
        GetSustainabilityJnlLine(SustainabilityJnlLine);
        VerifyCollectionInformation(
            SustainabilityJnlLine."Collected from G/L Entries", SustainabilityJnlLine."Collect From Date",
            SustainabilityJnlLine."Collect To Date", false, 0D, 0D);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler')]
    procedure ManualInputClearsCollectionInfoOnJnlLine()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Switching a collected line to manual input clears the collection information.
        Initialize();

        // [GIVEN] G/L account "G" with a posted G/L entry of 1000 and a sustainability journal line that collected it.
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        PostGLEntry(GLAccountNo, WorkDate(), 1000, '');
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, WorkDate(), WorkDate());

        // [WHEN] Manual Input is enabled on the journal line.
        SustainabilityJnlLine.Validate("Manual Input", true);
        SustainabilityJnlLine.Modify(true);

        // [THEN] The collection information is cleared on the journal line.
        VerifyCollectionInformation(
            SustainabilityJnlLine."Collected from G/L Entries", SustainabilityJnlLine."Collect From Date",
            SustainabilityJnlLine."Collect To Date", false, 0D, 0D);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler')]
    procedure ChangingAccountNoClearsCollectionInfoOnJnlLine()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        OtherSustainabilityAccount: Record "Sustainability Account";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        GLAccountNo: Code[20];
        OtherGLAccountNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Moving a collected line to another sustainability account clears the collection information.
        Initialize();

        // [GIVEN] G/L account "G" with a posted G/L entry of 1000 and a sustainability journal line on account "A1" that collected it.
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        PostGLEntry(GLAccountNo, WorkDate(), 1000, '');
        CreateSustainabilityJnlLine(SustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SustainabilityJnlLine, WorkDate(), WorkDate());

        // [WHEN] The sustainability account of the line is changed to "A2".
        CreateGLCollectionSetup(OtherGLAccountNo, SustainAccountCategory, OtherSustainabilityAccount);
        GetSustainabilityJnlLine(SustainabilityJnlLine);
        SustainabilityJnlLine.Validate("Account No.", OtherSustainabilityAccount."No.");
        SustainabilityJnlLine.Modify(true);

        // [THEN] The collection information is cleared on the journal line.
        VerifyCollectionInformation(
            SustainabilityJnlLine."Collected from G/L Entries", SustainabilityJnlLine."Collect From Date",
            SustainabilityJnlLine."Collect To Date", false, 0D, 0D);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CollectAmountFromGLEntryModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure PostingBatchCollectsEachGLEntryOnlyOnce()
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        FirstSustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SecondSustainabilityJnlLine: Record "Sustainability Jnl. Line";
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        GLAccountNo: Code[20];
        FirstGLEntryNo, SecondGLEntryNo : Integer;
        FirstSustLedgerEntryNo, SecondSustLedgerEntryNo : Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Two collected lines in the same batch never consume the same general ledger entry.
        Initialize();

        // [GIVEN] G/L account "G" with posted G/L entries of 100 and 200 on two consecutive dates.
        CreateGLCollectionSetup(GLAccountNo, SustainAccountCategory, SustainabilityAccount);
        FirstGLEntryNo := PostGLEntry(GLAccountNo, WorkDate(), 100, '');
        SecondGLEntryNo := PostGLEntry(GLAccountNo, WorkDate() + 1, 200, '');

        // [GIVEN] Line 1 collected the first date only and line 2 collected both dates in the same batch.
        CreateSustainabilityJnlLine(FirstSustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(FirstSustainabilityJnlLine, WorkDate(), WorkDate());

        CreateSustainabilityJnlLine(SecondSustainabilityJnlLine, SustainabilityAccount);
        CollectAmountFromGL(SecondSustainabilityJnlLine, WorkDate(), WorkDate() + 1);
        Assert.AreEqual(300, SecondSustainabilityJnlLine."Custom Amount", CollectableAmountMustBeEqualLbl);

        // [WHEN] The batch is posted.
        PostSustainabilityJnlBatch(FirstSustainabilityJnlLine);

        // [THEN] Each G/L entry is linked to one sustainability entry only.
        GetTwoSustLedgerEntryNos(FirstSustainabilityJnlLine, FirstSustLedgerEntryNo, SecondSustLedgerEntryNo);
        VerifyGLEntryRelation(FirstGLEntryNo, FirstSustLedgerEntryNo, SustainAccountCategory.Code, 100);
        VerifyGLEntryRelation(SecondGLEntryNo, SecondSustLedgerEntryNo, SustainAccountCategory.Code, 200);

        SustGLSustLedgerRel.SetRange("G/L Entry No.", FirstGLEntryNo);
        Assert.RecordCount(SustGLSustLedgerRel, 1);
        SustGLSustLedgerRel.SetRange("G/L Entry No.", SecondGLEntryNo);
        Assert.RecordCount(SustGLSustLedgerRel, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
    begin
        SustainabilityJournalLine.DeleteAll();
        LibrarySustainability.CleanUpBeforeTesting();
    end;

    local procedure GetNewSustainabilityJournalLineNo(SustainabilityJnlBatch: Record "Sustainability Jnl. Batch"): Integer
    var
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
    begin
        SustainabilityJournalLine."Journal Template Name" := SustainabilityJnlBatch."Journal Template Name";
        SustainabilityJournalLine."Journal Batch Name" := SustainabilityJnlBatch.Name;
        exit(LibraryUtility.GetNewRecNo(SustainabilityJournalLine, SustainabilityJournalLine.FieldNo("Line No.")));
    end;

    local procedure VerifySustainabilityJournalFormulaInputEditability(SustainabilityJnlBatch: Record "Sustainability Jnl. Batch"; Scope: Enum "Emission Scope"; CalcFoundation: Enum "Calculation Foundation"; ExpectedFuelElectricityEditable: Boolean; ExpectedDistanceEditable: Boolean; ExpectedCustomAmountEditable: Boolean; ExpectedInstallationMultiplierEditable: Boolean; ExpectedTimeFactorEditable: Boolean)
    var
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
        SustainabilityJournal: TestPage "Sustainability Journal";
    begin
        SustainabilityAccount := CreateSustainabilityAccount(Scope, CalcFoundation);
        SustainabilityJournalLine := LibrarySustainability.InsertSustainabilityJournalLine(
            SustainabilityJnlBatch, SustainabilityAccount, GetNewSustainabilityJournalLineNo(SustainabilityJnlBatch));

        SustainabilityJournal.OpenEdit();
        SustainabilityJournal.Filter.SetFilter("Journal Template Name", SustainabilityJournalLine."Journal Template Name");
        SustainabilityJournal.Filter.SetFilter("Journal Batch Name", SustainabilityJournalLine."Journal Batch Name");
        SustainabilityJournal.Filter.SetFilter("Line No.", Format(SustainabilityJournalLine."Line No."));
        Assert.IsTrue(SustainabilityJournal.First(), 'The Sustainability Journal line must be available.');

        AssertSustainabilityJournalFormulaInputEditability(
            SustainabilityJournal, ExpectedFuelElectricityEditable, ExpectedDistanceEditable, ExpectedCustomAmountEditable,
            ExpectedInstallationMultiplierEditable, ExpectedTimeFactorEditable);
        SustainabilityJournal.Close();
    end;

    local procedure VerifySustainabilityJournalBlankScopeFormulaInputEditability(SustainabilityJnlBatch: Record "Sustainability Jnl. Batch")
    var
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
        SustainabilityJournal: TestPage "Sustainability Journal";
    begin
        SustainabilityAccount := CreateSustainabilityAccount("Emission Scope"::"Scope 1", "Calculation Foundation"::Custom);
        SustainabilityJournalLine := LibrarySustainability.InsertSustainabilityJournalLine(
            SustainabilityJnlBatch, SustainabilityAccount, GetNewSustainabilityJournalLineNo(SustainabilityJnlBatch));
        SustainAccountCategory.Get(SustainabilityAccount.Category);
        SustainAccountCategory."Emission Scope" := "Emission Scope"::" ";
        SustainAccountCategory.Modify(false);

        SustainabilityJournal.OpenEdit();
        SustainabilityJournal.Filter.SetFilter("Journal Template Name", SustainabilityJournalLine."Journal Template Name");
        SustainabilityJournal.Filter.SetFilter("Journal Batch Name", SustainabilityJournalLine."Journal Batch Name");
        SustainabilityJournal.Filter.SetFilter("Line No.", Format(SustainabilityJournalLine."Line No."));
        Assert.IsTrue(SustainabilityJournal.First(), 'The Sustainability Journal line must be available.');

        AssertSustainabilityJournalFormulaInputEditability(SustainabilityJournal, false, false, false, false, false);
        SustainabilityJournal.Close();
    end;

    local procedure VerifySustainabilityJournalMissingCategoryFormulaInputEditability(SustainabilityJnlBatch: Record "Sustainability Jnl. Batch")
    var
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
        SustainabilityJournal: TestPage "Sustainability Journal";
    begin
        SustainabilityAccount := CreateSustainabilityAccount("Emission Scope"::"Scope 1", "Calculation Foundation"::"Fuel/Electricity");
        SustainabilityJournalLine := LibrarySustainability.InsertSustainabilityJournalLine(
            SustainabilityJnlBatch, SustainabilityAccount, GetNewSustainabilityJournalLineNo(SustainabilityJnlBatch));
        SustainabilityJournalLine."Account Category" := 'MISSING';
        SustainabilityJournalLine.Modify(false);

        SustainabilityJournal.OpenEdit();
        SustainabilityJournal.Filter.SetFilter("Journal Template Name", SustainabilityJournalLine."Journal Template Name");
        SustainabilityJournal.Filter.SetFilter("Journal Batch Name", SustainabilityJournalLine."Journal Batch Name");
        SustainabilityJournal.Filter.SetFilter("Line No.", Format(SustainabilityJournalLine."Line No."));
        Assert.IsTrue(SustainabilityJournal.First(), 'The Sustainability Journal line must be available.');

        AssertSustainabilityJournalFormulaInputEditability(SustainabilityJournal, false, false, false, false, false);
        SustainabilityJournal.Close();
    end;

    local procedure VerifySustainabilityJournalBlankAccountFormulaInputEditability(SustainabilityJnlBatch: Record "Sustainability Jnl. Batch")
    var
        SustainabilityAccount: Record "Sustainability Account";
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
        SustainabilityJournal: TestPage "Sustainability Journal";
    begin
        SustainabilityAccount := CreateSustainabilityAccount("Emission Scope"::"Scope 1", "Calculation Foundation"::"Fuel/Electricity");
        SustainabilityJournalLine := LibrarySustainability.InsertSustainabilityJournalLine(
            SustainabilityJnlBatch, SustainabilityAccount, GetNewSustainabilityJournalLineNo(SustainabilityJnlBatch));
        SustainabilityJournalLine.Validate("Account No.", '');
        SustainabilityJournalLine.Modify(true);

        SustainabilityJournal.OpenEdit();
        SustainabilityJournal.Filter.SetFilter("Journal Template Name", SustainabilityJournalLine."Journal Template Name");
        SustainabilityJournal.Filter.SetFilter("Journal Batch Name", SustainabilityJournalLine."Journal Batch Name");
        SustainabilityJournal.Filter.SetFilter("Line No.", Format(SustainabilityJournalLine."Line No."));
        Assert.IsTrue(SustainabilityJournal.First(), 'The Sustainability Journal line must be available.');

        AssertSustainabilityJournalFormulaInputEditability(SustainabilityJournal, false, false, false, false, false);
        SustainabilityJournal.Close();
    end;

    local procedure CreateSustainabilityAccount(Scope: Enum "Emission Scope"; CalcFoundation: Enum "Calculation Foundation") SustainabilityAccount: Record "Sustainability Account"
    var
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountCode: Code[20];
        TracksEmissions: Boolean;
    begin
        CategoryCode := LibraryUtility.GenerateGUID();
        SubcategoryCode := LibraryUtility.GenerateGUID();
        AccountCode := LibraryUtility.GenerateGUID();
        TracksEmissions := Scope <> "Emission Scope"::"Water/Waste";
        LibrarySustainability.InsertAccountCategory(
            CategoryCode, CategoryCode, Scope, CalcFoundation, TracksEmissions, TracksEmissions, TracksEmissions, '', false);
        LibrarySustainability.InsertAccountSubcategory(CategoryCode, SubcategoryCode, SubcategoryCode, 1, 1, 1, false);
        SustainabilityAccount := LibrarySustainability.InsertSustainabilityAccount(
            AccountCode, AccountCode, CategoryCode, SubcategoryCode, "Sustainability Account Type"::Posting, '', true);
    end;

    local procedure AssertSustainabilityJournalFormulaInputEditability(var SustainabilityJournal: TestPage "Sustainability Journal"; ExpectedFuelElectricityEditable: Boolean; ExpectedDistanceEditable: Boolean; ExpectedCustomAmountEditable: Boolean; ExpectedInstallationMultiplierEditable: Boolean; ExpectedTimeFactorEditable: Boolean)
    begin
        AssertFormulaInputEditability(
            ExpectedFuelElectricityEditable, ExpectedDistanceEditable, ExpectedCustomAmountEditable,
            ExpectedInstallationMultiplierEditable, ExpectedTimeFactorEditable,
            SustainabilityJournal."Fuel/Electricity".Editable(), SustainabilityJournal.Distance.Editable(),
            SustainabilityJournal."Custom Amount".Editable(), SustainabilityJournal."Installation Multiplier".Editable(),
            SustainabilityJournal."Time Factor".Editable());
        Assert.IsTrue(SustainabilityJournal."Unit of Measure".Editable(), 'Unit of Measure must remain editable.');
        Assert.AreEqual(1, SustainabilityJournal."Installation Multiplier".AsDecimal(), 'Installation Multiplier must retain its default value.');
    end;

    local procedure AssertFormulaInputEditability(ExpectedFuelElectricityEditable: Boolean; ExpectedDistanceEditable: Boolean; ExpectedCustomAmountEditable: Boolean; ExpectedInstallationMultiplierEditable: Boolean; ExpectedTimeFactorEditable: Boolean; ActualFuelElectricityEditable: Boolean; ActualDistanceEditable: Boolean; ActualCustomAmountEditable: Boolean; ActualInstallationMultiplierEditable: Boolean; ActualTimeFactorEditable: Boolean)
    begin
        Assert.AreEqual(ExpectedFuelElectricityEditable, ActualFuelElectricityEditable, 'Unexpected Fuel/Electricity editability.');
        Assert.AreEqual(ExpectedDistanceEditable, ActualDistanceEditable, 'Unexpected Distance editability.');
        Assert.AreEqual(ExpectedCustomAmountEditable, ActualCustomAmountEditable, 'Unexpected Custom Amount editability.');
        Assert.AreEqual(ExpectedInstallationMultiplierEditable, ActualInstallationMultiplierEditable, 'Unexpected Installation Multiplier editability.');
        Assert.AreEqual(ExpectedTimeFactorEditable, ActualTimeFactorEditable, 'Unexpected Time Factor editability.');
    end;

    local procedure CreateSustAccountCategoryWithGLAccountNo(GLAccountNo: Code[20]) SustainAccountCategory: Record "Sustain. Account Category"
    begin
        SustainAccountCategory := LibrarySustainability.InsertAccountCategory(LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), Enum::"Emission Scope"::"Scope 2", Enum::"Calculation Foundation"::Custom, true, true, true, 'GL', true);
        SustainAccountCategory."G/L Account Filter" := GLAccountNo;
        SustainAccountCategory.Modify(true);
    end;

    local procedure CreateGLCollectionSetup(var GLAccountNo: Code[20]; var SustainAccountCategory: Record "Sustain. Account Category"; var SustainabilityAccount: Record "Sustainability Account")
    var
        SubcategoryCode: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        SustainAccountCategory := CreateSustAccountCategoryWithGLAccountNo(GLAccountNo);

        SubcategoryCode := LibraryUtility.GenerateGUID();
        LibrarySustainability.InsertAccountSubcategory(SustainAccountCategory.Code, SubcategoryCode, SubcategoryCode, 1, 0, 0, false);
        SustainabilityAccount := LibrarySustainability.InsertSustainabilityAccount(
            LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), SustainAccountCategory.Code, SubcategoryCode,
            Enum::"Sustainability Account Type"::Posting, '', true);
    end;

    local procedure PostGLEntry(GLAccountNo: Code[20]; PostingDate: Date; EntryAmount: Decimal; GlobalDimension1Code: Code[20]): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GenJournalTemplateCode: Code[10];
    begin
        GenJournalTemplateCode := LibraryERM.SelectGenJnlTemplate();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateCode);
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(
            GenJournalLine, GenJournalTemplateCode, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), EntryAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Shortcut Dimension 1 Code", GlobalDimension1Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindLast();
        exit(GLEntry."Entry No.");
    end;

    local procedure CreateSustainabilityJnlLine(var SustainabilityJnlLine: Record "Sustainability Jnl. Line"; SustainabilityAccount: Record "Sustainability Account")
    var
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        UnitOfMeasure: Record "Unit of Measure";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
    begin
        SustainabilityJnlBatch := SustainabilityJournalMgt.GetASustainabilityJournalBatch(false);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        SustainabilityJnlLine := LibrarySustainability.InsertSustainabilityJournalLine(
            SustainabilityJnlBatch, SustainabilityAccount, GetNewSustainabilityJournalLineNo(SustainabilityJnlBatch));
        SustainabilityJnlLine.Validate(
            "Document No.",
            SustainabilityJournalMgt.GetDocumentNo(false, SustainabilityJnlBatch, '', SustainabilityJnlLine."Posting Date"));
        SustainabilityJnlLine.Validate(Description, LibraryUtility.GenerateGUID());
        SustainabilityJnlLine.Validate("Unit of Measure", UnitOfMeasure.Code);
        SustainabilityJnlLine.Modify(true);
    end;

    local procedure CollectAmountFromGL(var SustainabilityJnlLine: Record "Sustainability Jnl. Line"; FromDate: Date; ToDate: Date)
    var
        SustainabilityCalcMgt: Codeunit "Sustainability Calc. Mgt.";
    begin
        LibraryVariableStorage.Enqueue(FromDate);
        LibraryVariableStorage.Enqueue(ToDate);
        SustainabilityCalcMgt.CollectGeneralLedgerAmount(SustainabilityJnlLine);
        SustainabilityJnlLine.Modify(true);
    end;

    local procedure PostSustainabilityJnlLine(var SustainabilityJnlLine: Record "Sustainability Jnl. Line"): Integer
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
    begin
        SustainabilityJnlLine.SetRange("Line No.", SustainabilityJnlLine."Line No.");
        PostSustainabilityJnlBatch(SustainabilityJnlLine);

        FilterSustLedgerEntryOnBatch(SustainabilityLedgerEntry, SustainabilityJnlLine);
        SustainabilityLedgerEntry.FindLast();
        exit(SustainabilityLedgerEntry."Entry No.");
    end;

    local procedure PostSustainabilityJnlBatch(var SustainabilityJnlLine: Record "Sustainability Jnl. Line")
    begin
        SustainabilityJnlLine.SetRange("Journal Template Name", SustainabilityJnlLine."Journal Template Name");
        SustainabilityJnlLine.SetRange("Journal Batch Name", SustainabilityJnlLine."Journal Batch Name");
        Codeunit.Run(Codeunit::"Sustainability Jnl.-Post", SustainabilityJnlLine);
    end;

    local procedure GetTwoSustLedgerEntryNos(SustainabilityJnlLine: Record "Sustainability Jnl. Line"; var FirstEntryNo: Integer; var SecondEntryNo: Integer)
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
    begin
        // Entries are numbered in the order the journal lines were posted, so the primary key order matches the line order.
        FilterSustLedgerEntryOnBatch(SustainabilityLedgerEntry, SustainabilityJnlLine);
        SustainabilityLedgerEntry.FindSet();
        FirstEntryNo := SustainabilityLedgerEntry."Entry No.";
        Assert.AreEqual(1, SustainabilityLedgerEntry.Next(), 'A second sustainability ledger entry must exist.');
        SecondEntryNo := SustainabilityLedgerEntry."Entry No.";
    end;

    local procedure FilterSustLedgerEntryOnBatch(var SustainabilityLedgerEntry: Record "Sustainability Ledger Entry"; SustainabilityJnlLine: Record "Sustainability Jnl. Line")
    begin
        SustainabilityLedgerEntry.SetRange("Journal Template Name", SustainabilityJnlLine."Journal Template Name");
        SustainabilityLedgerEntry.SetRange("Journal Batch Name", SustainabilityJnlLine."Journal Batch Name");
    end;

    local procedure GetSustainabilityJnlLine(var SustainabilityJnlLine: Record "Sustainability Jnl. Line")
    begin
        SustainabilityJnlLine.Get(
            SustainabilityJnlLine."Journal Template Name", SustainabilityJnlLine."Journal Batch Name", SustainabilityJnlLine."Line No.");
    end;

    local procedure OpenSustainabilityJournalOnLine(var SustainabilityJournal: TestPage "Sustainability Journal"; SustainabilityJnlLine: Record "Sustainability Jnl. Line")
    begin
        SustainabilityJournal.OpenEdit();
        SustainabilityJournal.Filter.SetFilter("Journal Template Name", SustainabilityJnlLine."Journal Template Name");
        SustainabilityJournal.Filter.SetFilter("Journal Batch Name", SustainabilityJnlLine."Journal Batch Name");
        SustainabilityJournal.Filter.SetFilter("Line No.", Format(SustainabilityJnlLine."Line No."));
        Assert.IsTrue(SustainabilityJournal.First(), 'The Sustainability Journal line must be available.');
    end;

    local procedure VerifyGLEntryRelation(GLEntryNo: Integer; SustLedgerEntryNo: Integer; ExpectedCategoryCode: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
    begin
        Assert.IsTrue(SustGLSustLedgerRel.Get(GLEntryNo, SustLedgerEntryNo), RelationMustExistLbl);

        GLEntry.Get(GLEntryNo);
        Assert.AreEqual(ExpectedCategoryCode, SustGLSustLedgerRel."Account Category", RelationMustExistLbl);
        Assert.AreEqual(ExpectedAmount, SustGLSustLedgerRel."Collected Amount", RelationMustExistLbl);
        Assert.AreEqual(GLEntry."Posting Date", SustGLSustLedgerRel."Posting Date", RelationMustExistLbl);
        Assert.IsTrue(GLEntry."Sust. Collected", RelationMustExistLbl);
    end;

    local procedure VerifyCollectionInformation(ActualCollected: Boolean; ActualFromDate: Date; ActualToDate: Date; ExpectedCollected: Boolean; ExpectedFromDate: Date; ExpectedToDate: Date)
    begin
        Assert.AreEqual(ExpectedCollected, ActualCollected, CollectionInfoMustBeClearedLbl);
        Assert.AreEqual(ExpectedFromDate, ActualFromDate, CollectionInfoMustBeClearedLbl);
        Assert.AreEqual(ExpectedToDate, ActualToDate, CollectionInfoMustBeClearedLbl);
    end;

    [ModalPageHandler]
    procedure CollectAmountFromGLEntryModalPageHandler(var CollectAmountfromGLEntry: TestPage "Collect Amount from G/L Entry")
    begin
        CollectAmountfromGLEntry.FromDate.SetValue(LibraryVariableStorage.DequeueDate());
        CollectAmountfromGLEntry.ToDate.SetValue(LibraryVariableStorage.DequeueDate());
        CollectAmountfromGLEntry.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}
