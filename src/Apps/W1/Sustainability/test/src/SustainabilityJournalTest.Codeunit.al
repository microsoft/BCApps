namespace Microsoft.Test.Sustainability;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Calculation;
using Microsoft.Sustainability.Journal;

codeunit 148181 "Sustainability Journal Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySustainability: Codeunit "Library - Sustainability";
        LibraryUtility: Codeunit "Library - Utility";
        OneDefaultTemplateShouldBeCreatedLbl: Label 'One default template should be created after page is opened', Locked = true;
        OneDefaultBatchShouldBeCreatedLbl: Label 'One default batch should be created after page is opened', Locked = true;
        CustomAmountMustBePositiveLbl: Label 'The custom amount must be positive', Locked = true;

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
}
