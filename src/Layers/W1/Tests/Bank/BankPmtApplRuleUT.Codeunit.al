codeunit 134260 "Bank Pmt. Appl. Rule UT"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Payment Application] [Rule] [UT]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        MinPriority: Integer;
        MaxPriority: Integer;
        MatchConfidenceOptionsCount: Integer;
        ConfidenceScoreRange: Integer;

    local procedure Initialize()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        RecordRef: RecordRef;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Bank Pmt. Appl. Rule UT");
        // Lazy Setup.
        BankPmtApplRule.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Bank Pmt. Appl. Rule UT");

        ConfidenceScoreRange := 1000;
        MaxPriority := ConfidenceScoreRange - 1;
        MinPriority := 1;
        RecordRef.GetTable(BankPmtApplRule);
        MatchConfidenceOptionsCount := GetNumberOfOptions(RecordRef.Number, BankPmtApplRule.FieldNo("Match Confidence"));
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Bank Pmt. Appl. Rule UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineUpdatesTheScore()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        Initialize();

        InsertRule(BankPmtApplRule, AnyConfidence());

        Assert.AreEqual(
          CalculateScore(BankPmtApplRule), BankPmtApplRule.Score, 'Score was not updated correctly  after inserting a record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamingLineUpdatesTheScore()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Score: Integer;
    begin
        Initialize();

        InsertRule(BankPmtApplRule, AnyConfidence());
        Score := BankPmtApplRule.Score;

        BankPmtApplRule.Rename(BankPmtApplRule."Match Confidence", BankPmtApplRule.Priority - 1);

        Assert.AreEqual(CalculateScore(BankPmtApplRule), BankPmtApplRule.Score, 'Score was not updated after renaming a record');
        Assert.AreNotEqual(Score, BankPmtApplRule.Score, 'Score should have been changed by renaming a record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLinesWithSameConfidenceDifferentPriorities()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
    begin
        Initialize();

        InsertRule(BankPmtApplRule, AnyConfidence());
        InsertRule(BankPmtApplRule2, BankPmtApplRule."Match Confidence");

        Assert.AreEqual(
          CalculateScore(BankPmtApplRule2), BankPmtApplRule2.Score, 'Score was not updated correctly after inserting a record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingPrioritySmallerThanMinimumValueRaisesAnError()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        Initialize();
        InsertRule(BankPmtApplRule, AnyConfidence());

        asserterror BankPmtApplRule.Validate(Priority, MinPriority - 1);
        Assert.ExpectedError(StrSubstNo('The %1 you entered is invalid', BankPmtApplRule.FieldCaption(Priority)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingPriorityLargerThanMaximumValueRaisesAnError()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        Initialize();
        InsertRule(BankPmtApplRule, AnyConfidence());

        asserterror BankPmtApplRule.Validate(Priority, MaxPriority + 1);
        Assert.ExpectedError(StrSubstNo('The %1 you entered is invalid', BankPmtApplRule.FieldCaption(Priority)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingPriorityToACorrectValueDoesnotRaiseAnError()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        PriorityToSet: Integer;
    begin
        Initialize();
        BankPmtApplRule.Init();
        PriorityToSet := LibraryRandom.RandIntInRange(MinPriority, MaxPriority);

        BankPmtApplRule.Validate(Priority, PriorityToSet);

        Assert.AreEqual(PriorityToSet, BankPmtApplRule.Priority, 'Priority value was not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestScoreCalculationTest()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        I: Integer;
        PreviousScore: Integer;
    begin
        Initialize();
        PreviousScore := 0;
        for I := 0 to MatchConfidenceOptionsCount - 1 do begin
            InsertRule(BankPmtApplRule, I);
            Assert.AreEqual(BankPmtApplRule.Score, CalculateScore(BankPmtApplRule), 'Score was not calculate correctly');

            if I <> 0 then
                Assert.IsTrue(
                  BankPmtApplRule.Score - PreviousScore > 0, 'Score was higher or equal than the score for higher match confidence');
            PreviousScore := BankPmtApplRule.Score;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBestMatchScoreNoMatchesFound()
    var
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        MatchScore: Integer;
    begin
        Initialize();
        InsertRule(BankPmtApplRule, AnyConfidence());
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        BankPmtApplRule.Modify(true);

        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched",
          ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);

        TempBankPmtApplRule.LoadRules();
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);
        Assert.AreEqual(0, MatchScore, 'Wrong rule was selected, expected no rules found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBestMatchScoreOnEmptyTable()
    var
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        MatchScore: Integer;
    begin
        Initialize();
        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);

        TempBankPmtApplRule.LoadRules();
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        Assert.AreEqual(0, MatchScore, 'Wrong rule was selected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBestMatchScoreOneRowFound()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, AnyConfidence());
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        BankPmtApplRule.Modify(true);

        InsertRule(BankPmtApplRule2, AnyConfidence());
        BankPmtApplRule2.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);
        BankPmtApplRule2.Modify(true);

        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);

        // Execute
        TempBankPmtApplRule.LoadRules();
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule2.Score, MatchScore, 'Wrong rule was selected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBestMatchScoreMultipleRowsFound()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule3: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        BankPmtApplRule.Modify(true);

        // Lower priority rule is inserted first to validate the sorting
        InsertRule(BankPmtApplRule3, BankPmtApplRule."Match Confidence"::Low);
        BankPmtApplRule3.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);
        BankPmtApplRule3.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::Fully);
        BankPmtApplRule3.Modify(true);

        InsertRule(BankPmtApplRule2, BankPmtApplRule."Match Confidence"::Medium);
        BankPmtApplRule2.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);
        BankPmtApplRule2.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::"Not Considered");
        BankPmtApplRule2.Modify(true);

        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);
        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);

        // Execute
        TempBankPmtApplRule.LoadRules();
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule2.Score, MatchScore,
          'Wrong rule was selected, Rule 2 should be selected since it has the highest priority');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBestMatchScoreSkipRuleIncluded()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered");
        BankPmtApplRule.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::"Not Considered");
        BankPmtApplRule.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered");
        BankPmtApplRule.Modify(true);

        InsertRule(BankPmtApplRule2, BankPmtApplRule."Match Confidence"::Medium);
        BankPmtApplRule2.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        BankPmtApplRule2.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::Partially);
        BankPmtApplRule2.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");
        BankPmtApplRule2.Modify(true);

        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        ParameterBankPmtApplRule.Validate("Related Party Matched", ParameterBankPmtApplRule."Related Party Matched"::Partially);
        ParameterBankPmtApplRule.Validate(
          "Amount Incl. Tolerance Matched", ParameterBankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        // Execute
        TempBankPmtApplRule.LoadRules();
        Assert.AreEqual(TempBankPmtApplRule.Count, 2, 'Wrong number of rules was found in the rule table');
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule.Score, MatchScore,
          'Wrong rule was selected, Rule 1 should be selected since it has the highest priority, Skip fields should be included');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBestMatchDocumentNoFilterIsSet()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);
        BankPmtApplRule.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::"Not Considered");
        BankPmtApplRule.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered");
        BankPmtApplRule.Modify(true);

        InsertRule(BankPmtApplRule2, BankPmtApplRule."Match Confidence"::Medium);
        BankPmtApplRule2.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        BankPmtApplRule2.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::"Not Considered");
        BankPmtApplRule2.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered");
        BankPmtApplRule2.Modify(true);

        // Parameter must include rule 2, since algorithm uses find first. If filer is not set test will have false positive.
        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        ParameterBankPmtApplRule.Validate("Related Party Matched", ParameterBankPmtApplRule."Related Party Matched"::Partially);
        ParameterBankPmtApplRule.Validate(
          "Amount Incl. Tolerance Matched", ParameterBankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        // Execute
        TempBankPmtApplRule.LoadRules();
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule2.Score, MatchScore,
          'Wrong rule was selected, Rule 2 should be selected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBestMatchRelatedPartyIdentifiedFilterIsSet()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered");
        BankPmtApplRule.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::No);
        BankPmtApplRule.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered");
        BankPmtApplRule.Modify(true);

        InsertRule(BankPmtApplRule2, BankPmtApplRule."Match Confidence"::Medium);
        BankPmtApplRule2.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered");
        BankPmtApplRule2.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::Partially);
        BankPmtApplRule2.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered");
        BankPmtApplRule2.Modify(true);

        // Parameter must include rule 2, since algorithm uses find first. If filer is not set test will have false positive.
        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        ParameterBankPmtApplRule.Validate("Related Party Matched", ParameterBankPmtApplRule."Related Party Matched"::Partially);
        ParameterBankPmtApplRule.Validate(
          "Amount Incl. Tolerance Matched", ParameterBankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        // Execute
        TempBankPmtApplRule.LoadRules();
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule2.Score, MatchScore,
          'Wrong rule was selected, Rule 1 should be selected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBestMatchAmountInclToleranceFilterIsSet()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered");
        BankPmtApplRule.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::"Not Considered");
        BankPmtApplRule.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");
        BankPmtApplRule.Modify(true);

        InsertRule(BankPmtApplRule2, BankPmtApplRule."Match Confidence"::Medium);
        BankPmtApplRule2.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered");
        BankPmtApplRule2.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched"::"Not Considered");
        BankPmtApplRule2.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");
        BankPmtApplRule2.Modify(true);

        // Parameter must include rule 2, since algorithm uses find first. If filer is not set test will have false positive.
        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        ParameterBankPmtApplRule.Validate("Related Party Matched", ParameterBankPmtApplRule."Related Party Matched"::Partially);
        ParameterBankPmtApplRule.Validate(
          "Amount Incl. Tolerance Matched", ParameterBankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches");

        // Execute
        TempBankPmtApplRule.LoadRules();
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule2.Score, MatchScore,
          'Wrong rule was selected, Rule 1 should be selected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCallingGetBestMatchScoreMultipleTimesWithoutReset()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        BankPmtApplRule.Modify(true);

        InsertRule(BankPmtApplRule2, BankPmtApplRule2."Match Confidence"::Medium);
        BankPmtApplRule2.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);
        BankPmtApplRule2.Modify(true);

        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched",
          ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);

        TempBankPmtApplRule.LoadRules();

        // Execute
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule2.Score, MatchScore,
          'Wrong rule was selected, Rule 2 should be selected since it has the highest priority, Skip fields should be included');

        // Execute to match rule 1
        Clear(ParameterBankPmtApplRule);
        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched",
          ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);

        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule.Score, MatchScore,
          'Wrong rule was selected, Rule should be selected since it has the highest priority, Skip fields should be included');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCallingLoadOnNonTemporaryRecordThrowsError()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        Initialize();
        asserterror BankPmtApplRule.LoadRules();

        Assert.ExpectedError('Programming error: The LoadRules function can only be called from temporary records');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCallingLoadMultipleTimesUpdatesResults()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        BankPmtApplRule.Modify(true);

        // Execute
        TempBankPmtApplRule.LoadRules();

        // Verify
        Assert.AreEqual(TempBankPmtApplRule.Count, 1, 'Wrong number of rules has been added');

        // Verify another call updates values
        InsertRule(BankPmtApplRule2, BankPmtApplRule."Match Confidence"::Medium);
        BankPmtApplRule2.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No);
        BankPmtApplRule2.Modify(true);

        TempBankPmtApplRule.LoadRules();
        Assert.AreEqual(TempBankPmtApplRule.Count, 2, 'Wrong number of rules has been added');

        // Verify call can remove values
        Clear(BankPmtApplRule);
        BankPmtApplRule.DeleteAll();
        TempBankPmtApplRule.LoadRules();

        Assert.IsTrue(TempBankPmtApplRule.IsEmpty, 'Rules table should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTextMapperScoreOverridesMediumConfidenceRule()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        Initialize();

        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::Medium);
        BankPmtApplRule.Rename(BankPmtApplRule."Match Confidence"::Medium, 1);

        Assert.IsTrue(
          BankPmtApplRule.GetTextMapperScore() > BankPmtApplRule.Score,
          'Text mapper rule must have higher score than best Medium confidence rule');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotCosideredMatchesDocumentNoMultiple()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered");
        BankPmtApplRule.Modify(true);

        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple");
        ParameterBankPmtApplRule.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched");
        ParameterBankPmtApplRule.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched");

        // Execute
        TempBankPmtApplRule.LoadRules();
        Assert.AreEqual(TempBankPmtApplRule.Count, 1, 'Wrong number of rules was found in the rule table');
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(BankPmtApplRule.Score, MatchScore, 'Document Matched Multiple should be selected by the Not Considered');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocumentMatchedYesDoesntIncludeMultiple()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchScore: Integer;
    begin
        Initialize();

        // Setup
        InsertRule(BankPmtApplRule, BankPmtApplRule."Match Confidence"::High);
        BankPmtApplRule.Validate("Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple");
        BankPmtApplRule.Modify(true);

        ParameterBankPmtApplRule.Validate(
          "Doc. No./Ext. Doc. No. Matched", ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes);
        ParameterBankPmtApplRule.Validate("Related Party Matched", BankPmtApplRule."Related Party Matched");
        ParameterBankPmtApplRule.Validate("Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched");

        // Execute
        TempBankPmtApplRule.LoadRules();
        Assert.AreEqual(TempBankPmtApplRule.Count, 1, 'Wrong number of rules was found in the rule table');
        MatchScore := TempBankPmtApplRule.GetBestMatchScore(ParameterBankPmtApplRule);

        // Verify
        Assert.AreEqual(0, MatchScore, 'Document matched yes should not hit multiple rule');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineInvalidPriorityRaisesError()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        // [SCENARIO 274504] Inserting line raises error if priority is invalid
        Initialize();

        asserterror InsertRuleWithPriority(BankPmtApplRule, AnyConfidence(), MinPriority - 1);
        Assert.ExpectedError(StrSubstNo('The %1 you entered is invalid', BankPmtApplRule.FieldCaption(Priority)));
    end;

    local procedure CalculateScore(BankPmtApplRule: Record "Bank Pmt. Appl. Rule"): Integer
    begin
        exit((BankPmtApplRule."Match Confidence" + 1) * ConfidenceScoreRange - BankPmtApplRule.Priority);
    end;

    local procedure InsertRule(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; MatchConfidence: Option)
    begin
        InsertRuleWithPriority(BankPmtApplRule, MatchConfidence, LibraryRandom.RandIntInRange(MinPriority + 1, MaxPriority - 1));
    end;

    local procedure InsertRuleWithPriority(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; MatchConfidence: Option; Priority: Integer)
    begin
        BankPmtApplRule.Init();
        BankPmtApplRule."Match Confidence" := MatchConfidence;
        BankPmtApplRule.Priority := Priority;
        BankPmtApplRule.Insert(true);
    end;

    local procedure AnyConfidence(): Integer
    begin
        exit(LibraryRandom.RandIntInRange(0, MatchConfidenceOptionsCount));
    end;

    local procedure GetNumberOfOptions(TableID: Integer; FieldNo: Integer): Integer
    var
        "Field": Record "Field";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        OptionStringCommas: Text[30];
    begin
        RecordRef.Open(TableID);
        FieldRef := RecordRef.Field(FieldNo);
        Field.Get(RecordRef.Number, FieldRef.Number);
        if Field.Type <> Field.Type::Option then
            exit(0);
        OptionStringCommas := DelChr(FieldRef.OptionMembers, '=', DelChr(FieldRef.OptionMembers, '=', ','));
        if (StrLen(OptionStringCommas) = 0) and (StrLen(FieldRef.OptionMembers) = 0) then
            exit(0);
        exit(StrLen(OptionStringCommas) + 1);
    end;
}

