codeunit 134803 "Test RED Setup Gen. Jnl."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Revenue Expense Deferral] [Deferral]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryJournals: Codeunit "Library - Journals";
        DeferralUtilities: Codeunit "Deferral Utilities";
        CalcMethod: Enum "Deferral Calculation Method";
        DeferralDocType: Option Purchase,Sales,"G/L";
        StartDate: Enum "Deferral Calculation Start Date";
        isInitialized: Boolean;
        GLAccountOmitErr: Label 'When %1 is selected for';
        DecimalPlacesInDeferralPctErr: Label 'Wrong decimal places count in "Defferal %" field.';
        PostedDeferralHeaderNumberErr: Label 'The number of Posted Deferral Headers with given parameters is not equal to expected.';
        DeferralsPostingDateOutOfRangeErr: Label 'is not within the range of posting dates for deferrals for your company';
        WrongAllowDeferralPostingDatesErr: Label 'The date in the Allow Deferral Posting From field must not be after the date in the Allow Deferral Posting To field.';

    [Test]
    [Scope('OnPrem')]
    procedure TestCreationOfDeferralCode()
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralCode: Code[10];
        GoodAccountNumber: Code[20];
    begin
        // [SCENARIO 127727] Phyllis can setup a Deferral template in the system
        Initialize();

        // Setup
        DeferralCode := LibraryUtility.GenerateRandomCode(DeferralTemplate.FieldNo("Deferral Code"), DATABASE::"Deferral Template");
        GoodAccountNumber := LibraryERM.CreateGLAccountNo();

        // Exercise
        DeferralTemplate.Init();
        DeferralTemplate."Deferral Code" := DeferralCode;

        // Test for error message when trying to use an invalid account
        asserterror DeferralTemplate.Validate("Deferral Account", CopyStr(Format(CreateGuid()), 1, 20));

        DeferralTemplate."Deferral Account" := GoodAccountNumber;
        DeferralTemplate."Calc. Method" := CalcMethod::"Straight-Line";
        DeferralTemplate."Start Date" := StartDate::"Posting Date";

        // Number of periods cannot be less than 1
        asserterror DeferralTemplate.Validate("No. of Periods", 0);
        DeferralTemplate."No. of Periods" := 6;

        DeferralTemplate."Deferral Code" := DeferralCode;
        // Deferral percentage cannot be less than 0
        asserterror DeferralTemplate.Validate("Deferral %", -5.0);

        // Deferral percentage cannot be greater than 100
        asserterror DeferralTemplate.Validate("Deferral %", 105.0);
        DeferralTemplate."Deferral %" := 100.0;
        DeferralTemplate."Period Description" := '%1 Deferral %5';
        DeferralTemplate.Insert();

        DeferralTemplate.Get(DeferralCode);
        DeferralTemplate.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignDefaultCodeToItem()
    var
        DeferralTemplate: Record "Deferral Template";
        Item: Record Item;
        DeferralCode: Code[10];
        ItemNumber: Code[20];
    begin
        Initialize();

        // [SCENARIO 127729] Apply Default template to Item Card
        DeferralCode := CreateDeferralCode();

        ItemNumber := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        Item.Init();
        Item."No." := ItemNumber;
        // Try to insert with an invalid deferral code
        asserterror Item.Validate("Default Deferral Template Code", CopyStr(Format(CreateGuid()), 1, 10));
        Item."Default Deferral Template Code" := DeferralCode;
        Item.Insert();

        // Try to delete the deferral code that is now attached to the item
        if DeferralTemplate.Get(DeferralCode) then
            asserterror DeferralTemplate.Delete();

        Item.Delete();
        if DeferralTemplate.Get(DeferralCode) then
            DeferralTemplate.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignDefaultCodeToAccount()
    var
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        DeferralCode: Code[10];
        AccountNumber: Code[20];
    begin
        Initialize();

        // [SCENARIO 127731] Apply default template to G/L Account card
        DeferralCode := CreateDeferralCode();

        AccountNumber := LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account");
        GLAccount.Init();
        GLAccount."No." := AccountNumber;
        // Try to insert with an invalid deferral code
        asserterror GLAccount.Validate("Default Deferral Template Code", CopyStr(Format(CreateGuid()), 1, 10));
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Insert();

        // Try to delete the deferral code that is now attached to the account
        if DeferralTemplate.Get(DeferralCode) then
            asserterror DeferralTemplate.Delete();

        GLAccount.Delete();
        if DeferralTemplate.Get(DeferralCode) then
            DeferralTemplate.Delete();
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure AssignDefaultCodeToResource()
    var
        DeferralTemplate: Record "Deferral Template";
        Resource: Record Resource;
        DeferralCode: Code[10];
        ResourceNumber: Code[20];
    begin
        Initialize();

        // [SCENARIO 127730] Apply default template to Resource Card
        DeferralCode := CreateDeferralCode();

        ResourceNumber := LibraryUtility.GenerateRandomCode(Resource.FieldNo("No."), DATABASE::Resource);
        Resource.Init();
        Resource."No." := ResourceNumber;
        // Try to insert with an invalid deferral code
        asserterror Resource.Validate("Default Deferral Template Code", CopyStr(Format(CreateGuid()), 1, 10));
        Resource."Default Deferral Template Code" := DeferralCode;
        Resource.Insert();

        // Try to delete the deferral code that is now attached to the resource
        if DeferralTemplate.Get(DeferralCode) then
            asserterror DeferralTemplate.Delete();

        Resource.Delete();
        if DeferralTemplate.Get(DeferralCode) then
            DeferralTemplate.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLTrxandVerifySchedule()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        DeferralHeader: Record "Deferral Header";
        DeferralCode: Code[10];
        DeferralCode99: Code[10];
        DeferralCodeDays: Code[10];
    begin
        Initialize();

        // [SCENARIO 127776] Too many deferrals periods give warning about accounting periods
        // Setup - create deferral codes
        DeferralCode := CreateStraightLine6Periods();
        DeferralCodeDays := CreateDaysPerPeriod6Periods();
        DeferralCode99 := CreateDaysPerPeriod99Periods();

        // Create new GL Account
        LibraryERM.CreateGLAccount(GLAccount);

        // Assign the deferral code to new GL Account
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Modify();

        // Generate GL trx with new account, give it an amount
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);
        CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
            GenJournalBatch."Bal. Account Type", GenJournalBatch."Bal. Account No.", 100.55);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Validate("Deferral Code");
        Commit();
        // Validate : Using a deferral code with too many periods will give warning about accounting periods not being set up
        asserterror GenJournalLine.Validate("Deferral Code", DeferralCode99);
        DeferralCode99 := CreateUserDefinedPeriods(99, "Deferral Calculation Start Date"::"Beginning of Period"); // For code coverage
        asserterror GenJournalLine.Validate("Deferral Code", DeferralCode99);
        GenJournalLine.Modify(true);
        Commit();

        // Validate : Gen Journal Line contains the Deferral Code
        GenJournalLine.TestField("Deferral Code", DeferralCode);

        // Validate : Deferral Schedule Exists given the key values for GL.
        if not DeferralHeader.Get(DeferralDocType::"G/L",
             GenJournalLine."Journal Template Name",
             GenJournalLine."Journal Batch Name", 0, '',
             GenJournalLine."Line No.")
        then
            asserterror;

        // Validate : For positive amount, you cannot enter an amount for the deferral schedule larger than the line amount, or less than 0
        asserterror DeferralHeader.Validate("Amount to Defer", 200);
        asserterror DeferralHeader.Validate("Amount to Defer", -200);
        GenJournalLine.Validate("Deferral Code", DeferralCodeDays); // Code to create deferral using days per period, for code coverage

        // Code coverage for covering the 2 uncovered settings for Start Date
        DeferralCodeDays := CreateDaysPerPeriod6PeriodsEOP();
        GenJournalLine.Validate("Deferral Code", DeferralCodeDays);
        DeferralCodeDays := CreateDaysPerPeriod6PeriodsBONP();
        GenJournalLine.Validate("Deferral Code", DeferralCodeDays);

        DeferralCode := CreateStraightLine6PeriodsEOP();
        GenJournalLine.Validate("Deferral Code", DeferralCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLTrxForNegativeAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        DeferralHeader: Record "Deferral Header";
        DeferralCode: Code[10];
    begin
        Initialize();

        // [SCENARIO 127776] Enter an amount for the deferral schedule larger than\less than
        // Setup - create deferral code
        DeferralCode := CreateStraightLine6Periods();

        // Create new GL Account
        LibraryERM.CreateGLAccount(GLAccount);

        // Assign the deferral code to new GL Account
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Modify();

        // Generate GL trx with new account, give it an amount
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalBatch."Bal. Account Type", GenJournalBatch."Bal. Account No.", -100.0);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Validate("Deferral Code");
        GenJournalLine.Modify(true);
        Commit();

        // Validate : Gen Journal Line contains the Deferral Code
        GenJournalLine.TestField("Deferral Code", DeferralCode);

        // Validate : Deferral Schedule Exists given the key values for GL.
        if not DeferralHeader.Get(DeferralDocType::"G/L",
             GenJournalLine."Journal Template Name",
             GenJournalLine."Journal Batch Name", 0, '',
             GenJournalLine."Line No.")
        then
            asserterror;

        // Validate : For positive amount, you cannot enter an amount for the deferral schedule larger than the line amount, or less than 0
        asserterror DeferralHeader.Validate("Amount to Defer", -200.0);
        asserterror DeferralHeader.Validate("Amount to Defer", 100.0);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateHandler,DeferralScheduleHandler,DocumentNoIsBlankMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateGLTrxandVerifyScheduleUI()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
        GeneralJournal: TestPage "General Journal";
        DeferralCode: Code[10];
    begin
        Initialize();

        // [FEATURE] [UI]
        // [SCENARIO 127776] Deferral schedule from general journal
        // [GIVEN] Created deferral code 'X', where "Start Date" is 'Posting Date'
        DeferralCode := CreateStraightLine6Periods();

        // [GIVEN] Create new GL Account, where "Default Deferral Template Code" is 'X'
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Modify();

        // [GIVEN] Create General Journal Line, where "Posting Date" is '10.01.18'
        CreateGeneralJournalLineByPage(GeneralJournal, GLAccount, GenJournalLine, 100.56);

        // [WHEN] Run "Deferral Schedule" action
        GeneralJournal.DeferralSchedule.Invoke();

        // [THEN] Page "Deferral Schedule" is open, where "Posting Date" is '10.01.18', "Start Date Calc. Method" is 'Posting Date'
        Assert.AreEqual(GenJournalLine."Posting Date", LibraryVariableStorage.DequeueDate(), 'Posting Date');
        DeferralTemplate.Get(DeferralCode);
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start Date method');
        // [THEN] Posting Date of the first schedule line is '10.01.18'
        Assert.AreEqual(GenJournalLine."Posting Date", LibraryVariableStorage.DequeueDate(), 'Posting Date in line');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateHandler,DeferralScheduleHandler,DocumentNoIsBlankMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateGLTrxandVerifyScheduleUINewCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
        GeneralJournal: TestPage "General Journal";
        DeferralCode: Code[10];
    begin
        Initialize();

        // [FEATURE] [UI]
        // [SCENARIO 127776] Create deferral schedule based on transaction and template
        // [GIVEN] Created deferral code 'X', where "Start Date" is 'Beginning of Period'
        DeferralCode := CreateStraightLine2Periods();
        DeferralTemplate.Get(DeferralCode);

        // [GIVEN] Create new GL Account, where "Default Deferral Template Code" is 'X'
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Modify();

        // [GIVEN] Create General Journal Line, where "Posting Date" is '10.01.18'
        CreateGeneralJournalLineByPage(GeneralJournal, GLAccount, GenJournalLine, 100.56);

        // [GIVEN] Removed deferral schedule lines.
        DeferralHeader.Get(
          DeferralDocType::"G/L", GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name", 0, '', GenJournalLine."Line No.");
        DeferralUtilities.RemoveOrSetDeferralSchedule('', DeferralDocType::"G/L", GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name", 0, '', GenJournalLine."Line No.", 0, 0D, '', '', true);
        DeferralHeader."Amount to Defer" := 0;
        DeferralHeader."No. of Periods" := 0;
        DeferralHeader.Insert();

        // [GIVEN] Action "Deferral Schedule" is invoked, but as no schedule, window contains no lines
        GeneralJournal.DeferralSchedule.Invoke();
        Assert.AreEqual(GenJournalLine."Posting Date", LibraryVariableStorage.DequeueDate(), 'Posting Date #1');
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start Date method #1');
        LibraryVariableStorage.AssertEmpty();

        // [GIVEN] Created deferral schedule
        DeferralUtilities.RemoveOrSetDeferralSchedule(DeferralCode, DeferralDocType::"G/L", GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name", 0, '', GenJournalLine."Line No.", GenJournalLine.Amount, GenJournalLine."Posting Date",
          '', GenJournalLine."Currency Code", true);

        // [WHEN] Run "Deferral Schedule" action
        GeneralJournal.DeferralSchedule.Invoke();
        // [THEN] Page "Deferral Schedule" is open, where "Posting Date" is '10.01.18', "Start Date Calc. Method" is 'Beginning of Period'
        Assert.AreEqual(GenJournalLine."Posting Date", LibraryVariableStorage.DequeueDate(), 'Posting Date #2');
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start Date method #2');
        // [THEN] Posting Date of the first schedule line is '01.01.18'
        Assert.AreEqual(CalcDate('<-CM>', GenJournalLine."Posting Date"), LibraryVariableStorage.DequeueDate(), 'Posting Date in line #2');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLTrxandVerifyPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DeferralTemplate: Record "Deferral Template";
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry: Record "G/L Entry";
        DeferralCode: Code[10];
    begin
        Initialize();
        // [SCENARIO 127776] Post general journal line with deferral

        // [GIVEN] General Journal Line with Deferral
        DeferralCode := CreateGenJournalLineWithDeferral(GenJournalLine);

        // [WHEN] Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify the count of posted GL Entries with total number of lines entered for deferral schedule.
        VerifyTotalNumberOfPostedGLEntries(GenJournalLine, 14);
        // [THEN] G/L enties posted with Source Code for deferrals (TFS 422924)
        SourceCodeSetup.Get();
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Source Code", SourceCodeSetup."General Deferral");
        Assert.RecordCount(GLEntry, 12);

        // [THEN] Description in total deferral line matches Gen. Journal Line's Description (TFS 203345)
        DeferralTemplate.Get(DeferralCode);
        VerifyDescriptionOnTotalDeferralLine(
          GenJournalLine."Document No.", DeferralTemplate."Deferral Account", GenJournalLine."Posting Date", GenJournalLine.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLTrxandVerifyPostingAmounts()
    var
        DeferralLine: Record "Deferral Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        DeferralCode: Code[10];
        DeferralAmount: Decimal;
    begin
        Initialize();

        // [SCENARIO 127776] Post general journal after manually typed deferral line
        // Setup - create deferral code
        DeferralCode := CreateEqual5Periods80Percent();

        // Create new GL Account
        LibraryERM.CreateGLAccount(GLAccount);

        // Assign the deferral code to new GL Account
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Modify();

        // Create General Journal Line.
        // Generate GL trx with new account, give it an amount
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);

        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalBatch."Bal. Account Type", GenJournalBatch."Bal. Account No.", 100);
        GenJournalLine.Validate("Bal. Account No.");
        GenJournalLine.Validate("Deferral Code");
        GenJournalLine.Modify(true);
        Commit();

        // Trap the amount created for the Deferral Schedule
        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType::"G/L");
        DeferralLine.SetRange("Gen. Jnl. Template Name", GenJournalLine."Journal Template Name");
        DeferralLine.SetRange("Gen. Jnl. Batch Name", GenJournalLine."Journal Batch Name");
        DeferralLine.SetRange("Document Type", 0);
        DeferralLine.SetRange("Document No.", '');
        DeferralLine.SetRange("Line No.", GenJournalLine."Line No.");
        if DeferralLine.FindFirst() then
            DeferralAmount := DeferralLine.Amount;

        // 2. Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify the count of posted GL Entries with correct value
        // Initial value = 100, 80%=80, each period = 16.00
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange(Amount, DeferralAmount);
        Assert.AreEqual(5, GLEntry.Count, 'An incorrect number of lines was posted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLTrxandVerifyDaysSchedule()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        RunningDeferralTotal: Decimal;
    begin
        Initialize();

        // [SCENARIO TFSID 157047] Incorrect deferral amounts for "Days per Period" in GB Localization
        // Test is valid for all countries.

        // Create new GL Account
        LibraryERM.CreateGLAccount(GLAccount);

        // Assign the deferral code to new GL Account
        GLAccount."Default Deferral Template Code" := CreateDaysPerPeriod6Periods();
        GLAccount.Modify();

        // Generate GL trx with new account, give it an amount
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);

        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalBatch."Bal. Account Type", GenJournalBatch."Bal. Account No.", 100.55);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Validate("Deferral Code");
        Commit();

        // Validate : Deferral Schedule Exists given the key values for GL.
        if not DeferralHeader.Get(DeferralDocType::"G/L",
             GenJournalLine."Journal Template Name",
             GenJournalLine."Journal Batch Name", 0, '',
             GenJournalLine."Line No.")
        then
            asserterror;

        // Validate : Deferral Schedule is not adding their lines together, as per TFSID 157047
        // If this behavior is happening, the last line's amount will be negative and greater than the total deferral amount,
        // or the sum of the lines will not equal the total deferral amount.
        DeferralLine.SetRange("Deferral Doc. Type", DeferralHeader."Deferral Doc. Type");
        DeferralLine.SetRange("Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Template Name");
        DeferralLine.SetRange("Gen. Jnl. Batch Name", DeferralHeader."Gen. Jnl. Batch Name");
        DeferralLine.SetRange("Document Type", DeferralHeader."Document Type");
        DeferralLine.SetRange("Document No.", DeferralHeader."Document No.");
        DeferralLine.SetRange("Line No.", DeferralHeader."Line No.");
        RunningDeferralTotal := 0;
        if DeferralLine.FindSet() then
            repeat
                RunningDeferralTotal := RunningDeferralTotal + DeferralLine.Amount;
            until (DeferralLine.Next() = 0) or (DeferralLine.Amount = 0.0);

        if RunningDeferralTotal > DeferralHeader."Amount to Defer" then
            asserterror;
        if Abs(DeferralLine.Amount) > Abs(DeferralHeader."Amount to Defer") then
            asserterror;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateInvalidPostingDateForLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        DeferralLine: Record "Deferral Line";
        DeferralCode: Code[10];
        OutOfBoundsDate: Date;
    begin
        Initialize();

        // Set a date that is outside of set up accounting periods...20 years should do...
        OutOfBoundsDate := CalcDate('<20Y>', WorkDate());
        // Setup - create deferral code
        DeferralCode := CreateStraightLine6Periods();

        // Create new GL Account
        LibraryERM.CreateGLAccount(GLAccount);

        // Assign the deferral code to new GL Account
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Modify();

        // Generate GL trx with new account, give it an amount
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);

        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalBatch."Bal. Account Type", GenJournalBatch."Bal. Account No.", -100.0);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Validate("Deferral Code");
        GenJournalLine.Modify(true);
        Commit();

        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType::"G/L");
        DeferralLine.SetRange("Gen. Jnl. Template Name", GenJournalLine."Journal Template Name");
        DeferralLine.SetRange("Gen. Jnl. Batch Name", GenJournalLine."Journal Batch Name");
        DeferralLine.SetRange("Document Type", 0);
        DeferralLine.SetRange("Document No.", '');
        DeferralLine.SetRange("Line No.", GenJournalLine."Line No.");
        if DeferralLine.FindLast() then
            // Validate : Changing the posting date to the "out of bounds" date should give an error.
            asserterror DeferralLine.Validate("Posting Date", OutOfBoundsDate);
    end;

    [Test]
    [HandlerFunctions('GLDeferralSummaryReportHandler')]
    [Scope('OnPrem')]
    procedure GLDeferralSummaryReport()
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        DeferralSummaryGL: Report "Deferral Summary - G/L";
        DeferralCode: Code[10];
    begin
        Initialize();

        // [SCENARIO 127756] Phyllis can view a deferral report
        // Test and verify Deferral Summary - G/L Report.

        // 1. Setup: Create Deferral Template, post General Journal entry using this template code
        // Setup - create deferral code
        DeferralCode := CreateEqual5Periods();

        // Create new GL Account
        LibraryERM.CreateGLAccount(GLAccount);

        // Assign the deferral code to new GL Account
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Modify();

        // Create General Journal Line.
        // Generate GL trx with new account, give it an amount
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);

        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalBatch."Bal. Account Type", GenJournalBatch."Bal. Account No.", 100.0);
        GenJournalLine.Validate("Bal. Account No.");
        GenJournalLine.Validate("Deferral Code");
        GenJournalLine.Modify(true);
        Commit();

        // Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Deferral Summary - G/L Report.
        Commit();
        PostedDeferralHeader.SetRange("Deferral Doc. Type", PostedDeferralHeader."Deferral Doc. Type"::"G/L");
        PostedDeferralHeader.SetRange("Gen. Jnl. Document No.", GenJournalLine."Document No.");
        PostedDeferralHeader.SetRange("Account No.", GLAccount."No.");
        PostedDeferralHeader.SetRange("Document Type", 0);
        PostedDeferralHeader.SetRange("Document No.", '');
        PostedDeferralHeader.SetRange("Line No.", GenJournalLine."Line No.");
        Clear(DeferralSummaryGL);
        DeferralSummaryGL.SetTableView(PostedDeferralHeader);
        DeferralSummaryGL.Run();

        // 3. Verify: Verify Values on Deferral Summary - G/L Report.
        PostedDeferralHeader.SetRange("Deferral Doc. Type", PostedDeferralHeader."Deferral Doc. Type"::"G/L");
        PostedDeferralHeader.SetRange("Gen. Jnl. Document No.", GenJournalLine."Document No.");
        PostedDeferralHeader.SetRange("Account No.", GLAccount."No.");
        PostedDeferralHeader.SetRange("Document Type", 0);
        PostedDeferralHeader.SetRange("Document No.", '');
        PostedDeferralHeader.SetRange("Line No.", GenJournalLine."Line No.");
        PostedDeferralHeader.FindFirst();
        VerifyValuesonGLDeferralSummary(PostedDeferralHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemMiniListShowsDeferralTemplateColumn()
    var
        Item: Record Item;
        ItemList: TestPage "Item List";
        DeferralCode: Code[10];
    begin
        Initialize();

        // [SCENARIO 143447] Item List should have Default Deferral Template field displayed.
        DeferralCode := CreateDeferralCode();

        Item.Init();
        Item."Default Deferral Template Code" := DeferralCode;
        Item.Insert(true);

        ItemList.OpenView();
        ItemList.GotoRecord(Item);
        ItemList."Default Deferral Template Code".AssertEquals(Item."Default Deferral Template Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemMiniCardShowsDeferralTemplateColumn()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        DeferralCode: Code[10];
    begin
        Initialize();

        // [SCENARIO 143447] Item Card should have Default Deferral Template field displayed.
        DeferralCode := CreateDeferralCode();

        Item.Init();
        Item."Default Deferral Template Code" := DeferralCode;
        Item.Insert(true);

        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemCard."Default Deferral Template Code".AssertEquals(Item."Default Deferral Template Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralPctUT()
    var
        DummyDeferralTemplate: Record "Deferral Template";
    begin
        Initialize();

        // [FEATURE] [Deferral] [UT]
        // [SCENARIO] "Deferral %" field of Deferral Template must not show empty decimals
        DummyDeferralTemplate.Validate("Deferral %", 10);
        Assert.AreEqual('10', Format(DummyDeferralTemplate."Deferral %"), DecimalPlacesInDeferralPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralPctUIUT()
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralTemplateList: TestPage "Deferral Template List";
    begin
        Initialize();

        // [FEATURE] [Deferral] [UT]
        // [SCENARIO] "Deferral %" field of Deferral Template (1700) must not show empty decimals in Deferral Templates page (1701)
        DeferralTemplate.Init();
        DeferralTemplate.Validate("Deferral %", 10);
        DeferralTemplate.Insert();
        DeferralTemplateList.Trap();
        PAGE.Run(PAGE::"Deferral Template List", DeferralTemplate);
        Assert.AreEqual('10', Format(DeferralTemplateList."Deferral %"), DecimalPlacesInDeferralPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLTrxandVerifyPostingCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 377994] Posted GL trx for Customer must have G/L entry for Customer Posting Group's Receivable Account with the posted amount
        Initialize();

        // [GIVEN] Defferal setup - 5 equal periods
        // [GIVEN] Invoice with Customer Posting Group "G" and Amount = 100
        // [GIVEN] "G"."Receivables Account" = "A"
        CreateSalesInvoiceWithLineDeferral(SalesHeader, SalesLine, CreateEqual5Periods(), SalesHeader."Document Type"::Invoice);

        // [WHEN] Post Sales Invoice.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "G/L Entry" for "G/L Account" "G" created with Amount = 100
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup.GetReceivablesAccount());
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLTrxandVerifyPostingVendor()
    var
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 377994] Posted GL trx for Vendor must have G/L entry for Vendo Posting Group's Receivable Account with the posted amount
        Initialize();

        // [GIVEN] Defferal setup - 5 equal periods
        // [GIVEN] Invoice with Vendor Posting Group "G" and Amount = 100
        // [GIVEN] "G"."Receivaables Account" = "A"
        CreatePurchInvoiceWithLineDeferral(PurchaseHeader, PurchaseLine, CreateEqual5Periods(), PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Post General Journal Line.
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "G/L Entry" for "G/L Account" "G" created with Amount = 100
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup.GetPayablesAccount());
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDeferralCodeWithCustAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 379538] User cannot use deferral code for gen. journal line with Account Type = Customer
        // Unlocking this scenario must extend test case for PostGenJournalForGLAccountWithDifferentSourceCode TFS 217437
        Initialize();

        // [GIVEN] Gen. Journal Line with Account Type = Customer
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);

        // [WHEN] User tries to set Deferral Code
        asserterror GenJournalLine.Validate("Deferral Code", CreateEqual5Periods());

        // [THEN] Error "You cannot specify a deferral code for this type of account." appears
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Account Type"), Format(GenJournalLine."Account Type"::"G/L Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDeferralCodeWithVendAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 379538] User cannot use deferral code for gen. journal line with Account Type = Vendor
        // Unlocking this scenario must extend test case for PostGenJournalForGLAccountWithDifferentSourceCode TFS 217437
        Initialize();

        // [GIVEN] Gen. Journal Line with Account Type = Vendor
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);

        // [WHEN] User tries to set Deferral Code
        asserterror GenJournalLine.Validate("Deferral Code", CreateEqual5Periods());

        // [THEN] Error "You cannot specify a deferral code for this type of account." appears
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Account Type"), Format(GenJournalLine."Account Type"::"G/L Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDeferralCodeWithBankAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 379538] User cannot use deferral code for gen. journal line with Account Type = Bank Account
        // Unlocking this scenario must extend test case for PostGenJournalForGLAccountWithDifferentSourceCode TFS 217437
        Initialize();

        // [GIVEN] Gen. Journal Line with Account Type = Vendor
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");

        // [WHEN] User tries to set Deferral Code
        asserterror GenJournalLine.Validate("Deferral Code", CreateEqual5Periods());

        // [THEN] Error "You cannot specify a deferral code for this type of account." appears
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Account Type"), Format(GenJournalLine."Account Type"::"G/L Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDeferralCodeWithFAAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 379538] User cannot use deferral code for gen. journal line with Account Type = Fixed Asset
        // Unlocking this scenario must extend test case for PostGenJournalForGLAccountWithDifferentSourceCode TFS 217437
        Initialize();

        // [GIVEN] Gen. Journal Line with Account Type = Vendor
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Fixed Asset");

        // [WHEN] User tries to set Deferral Code
        asserterror GenJournalLine.Validate("Deferral Code", CreateEqual5Periods());

        // [THEN] Error "You cannot specify a deferral code for this type of account." appears
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Account Type"), Format(GenJournalLine."Account Type"::"G/L Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDeferralCodeWithICPartnerAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 379538] User cannot use deferral code for gen. journal line with Account Type = IC Partner
        // Unlocking this scenario must extend test case for PostGenJournalForGLAccountWithDifferentSourceCode TFS 217437
        Initialize();

        // [GIVEN] Gen. Journal Line with Account Type = Vendor
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"IC Partner");

        // [WHEN] User tries to set Deferral Code
        asserterror GenJournalLine.Validate("Deferral Code", CreateEqual5Periods());

        // [THEN] Error "You cannot specify a deferral code for this type of account." appears
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Account Type"), Format(GenJournalLine."Account Type"::"G/L Account"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeferralHeaderIsDeletedWhenGLTrxIsReversed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionNo: Integer;
    begin
        Initialize();

        // [FEATURE] [General Journal] [Reverse]
        // [SCENARIO 232837] Posted Deferral Entries are deleted on reversal of posted G/L entries.

        // [GIVEN] General Journal Line with Deferral.
        CreateGenJournalLineWithDeferral(GenJournalLine);

        // [GIVEN] Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Deferral Header "PDH" created for Transaction.
        VerifyPostedDeferralHeadersNumber(GenJournalLine."Document No.", 1);

        // [WHEN] Reverse Transaction.
        TransactionNo := GetTransactionNumberFromGenJournalLine(GenJournalLine);
        LibraryERM.ReverseTransaction(TransactionNo);

        // [THEN] "PDH" is deleted.
        VerifyPostedDeferralHeadersNumber(GenJournalLine."Document No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesGLAccountWithVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [G/L Account] [VAT] [Sales]
        // [SCENARIO 251252] G/L Entry with VAT has been created when post general journal for a sales G/L Account with deferral
        Initialize();

        // [GIVEN] General journal line with sales G/L Account "A" and deferral setup
        CreateSalesGenJournalLineWithDeferral(GenJournalLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] There is a G/L Entry for a posting account "A" with VAT
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyVATGLEntryForPostingAccount(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseGLAccountWithVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [G/L Account] [VAT] [Purchase]
        // [SCENARIO 251252] G/L Entry with VAT has been created when post general journal for a purchase G/L Account with deferral
        Initialize();

        // [GIVEN] General journal line with purchase G/L Account "A" and deferral setup
        CreatePurchaseGenJournalLineWithDeferral(GenJournalLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] There is a G/L Entry for a posting account "A" with VAT
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyVATGLEntryForPostingAccount(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveOrSetDefScheduleGenJournalBatchUT()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SalesHeader: Record "Sales Header";
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        LongDescription: Text[100];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [UT]
        // [SCENARIO 304205] Calling RemoveOrSetDeferralSchedule with GenJournalBatchName <> '' and max length Description creates Deferral Description from these fields
        Initialize();

        // [GIVEN] Deferral Code
        DeferralCode := CreateEqual5Periods80Percent();
        // [GIVEN] Sales Invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);
        // [GIVEN] Gen. Journal Batch with Name = 'ABC'
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] DeferralCodeOnValidate with long description = 'Deferral12346589....112233'
        LongDescription := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(LongDescription)), 1, MaxStrLen(LongDescription));
        DeferralUtilities.RemoveOrSetDeferralSchedule(
          DeferralCode, DeferralDocType::Sales, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, SalesHeader."Document Type".AsInteger(), SalesHeader."No.", 1, 0,
          SalesHeader."Posting Date", LongDescription, '', false);

        // [THEN] Schedule Description = 'ABC-Deferral12346589....11'
        DeferralHeader.Get(
          DeferralDocType::Sales, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, SalesHeader."Document Type", SalesHeader."No.", 1);
        DeferralHeader.TestField(
          "Schedule Description",
          CopyStr(StrSubstNo('%1-%2', GenJournalBatch.Name, LongDescription), 1, MaxStrLen(DeferralHeader."Schedule Description")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveOrSetDefScheduleDocNoUT()
    var
        SalesHeader: Record "Sales Header";
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        LongDescription: Text[100];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [UT]
        // [SCENARIO 304205] Calling RemoveOrSetDeferralSchedule with GenJournalBatchName = '' and max length Description creates Deferral Description with DocNo
        Initialize();

        // [GIVEN] Deferral Code
        DeferralCode := CreateEqual5Periods80Percent();
        // [GIVEN] Sales Invoice with No. = 'INV'
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] DeferralCodeOnValidate with long description = 'Deferral12346589....112233' and GenJnlBatchName = ''
        LongDescription := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(LongDescription)), 1, MaxStrLen(LongDescription));
        DeferralUtilities.RemoveOrSetDeferralSchedule(
          DeferralCode, DeferralDocType::Sales, '', '', SalesHeader."Document Type".AsInteger(),
          SalesHeader."No.", 1, 0, SalesHeader."Posting Date", LongDescription, '', false);

        // [THEN] Schedule Description = 'INV-Deferral12346589....11'
        DeferralHeader.Get(DeferralDocType::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", 1);
        DeferralHeader.TestField(
          "Schedule Description",
          CopyStr(StrSubstNo('%1-%2', SalesHeader."No.", LongDescription), 1, MaxStrLen(DeferralHeader."Schedule Description")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralCodeOnValidateGenJournalBatchUT()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SalesHeader: Record "Sales Header";
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        LongDescription: Text[100];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [UT]
        // [SCENARIO 304205] Calling DeferralCodeOnValidate with GenJournalBatchName <> '' and max length Description creates Deferral Description from these fields
        Initialize();

        // [GIVEN] Deferral Code
        DeferralCode := CreateEqual5Periods80Percent();
        // [GIVEN] Sales Invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);
        // [GIVEN] Gen. Journal Batch with Name = 'ABC'
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] DeferralCodeOnValidate with long description = 'Deferral12346589....112233'
        LongDescription := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(LongDescription)), 1, MaxStrLen(LongDescription));
        DeferralUtilities.DeferralCodeOnValidate(
          DeferralCode, DeferralDocType::Sales, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, SalesHeader."Document Type".AsInteger(), SalesHeader."No.", 1, 0,
          SalesHeader."Posting Date", LongDescription, '');

        // [THEN] Schedule Description = 'ABC-Deferral12346589....11'
        DeferralHeader.Get(
          DeferralDocType::Sales, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, SalesHeader."Document Type", SalesHeader."No.", 1);
        DeferralHeader.TestField(
          "Schedule Description",
          CopyStr(StrSubstNo('%1-%2', GenJournalBatch.Name, LongDescription), 1, MaxStrLen(DeferralHeader."Schedule Description")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralCodeOnValidateDocNoUT()
    var
        SalesHeader: Record "Sales Header";
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        LongDescription: Text[100];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [UT]
        // [SCENARIO 304205] Calling DeferralCodeOnValidate with GenJournalBatchName = '' and max length Description creates Deferral Description with DocNo
        Initialize();

        // [GIVEN] Deferral Code
        DeferralCode := CreateEqual5Periods80Percent();
        // [GIVEN] Sales Invoice with No. = 'INV'
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] DeferralCodeOnValidate with long description = 'Deferral12346589....112233' and GenJnlBatchName = ''
        LongDescription := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(LongDescription)), 1, MaxStrLen(LongDescription));
        DeferralUtilities.DeferralCodeOnValidate(
          DeferralCode, DeferralDocType::Sales, '', '', SalesHeader."Document Type".AsInteger(),
          SalesHeader."No.", 1, 0, SalesHeader."Posting Date", LongDescription, '');

        // [THEN] Schedule Description = 'INV-Deferral12346589....11'
        DeferralHeader.Get(DeferralDocType::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", 1);
        DeferralHeader.TestField(
          "Schedule Description",
          CopyStr(StrSubstNo('%1-%2', SalesHeader."No.", LongDescription), 1, MaxStrLen(DeferralHeader."Schedule Description")));
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure OpenLineScheduleEditGenJournalBatchUT()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SalesHeader: Record "Sales Header";
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        LongDescription: Text[100];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [UT]
        // [SCENARIO 304205] Calling OpenLineScheduleEdit with GenJournalBatchName <> '' and max length Description creates Deferral Description from these fields
        Initialize();

        // [GIVEN] Deferral Code
        DeferralCode := CreateEqual5Periods80Percent();
        // [GIVEN] Sales Invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);
        // [GIVEN] Gen. Journal Batch with Name = 'ABC'
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] DeferralCodeOnValidate with long description = 'Deferral12346589....112233'
        LongDescription := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(LongDescription)), 1, MaxStrLen(LongDescription));
        DeferralUtilities.OpenLineScheduleEdit(
          DeferralCode, DeferralDocType::Sales, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, SalesHeader."Document Type".AsInteger(), SalesHeader."No.", 1, 0,
          SalesHeader."Posting Date", LongDescription, '');

        // [THEN] Schedule Description = 'ABC-Deferral12346589....11'
        DeferralHeader.Get(
          DeferralDocType::Sales, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, SalesHeader."Document Type", SalesHeader."No.", 1);
        DeferralHeader.TestField(
          "Schedule Description",
          CopyStr(StrSubstNo('%1-%2', GenJournalBatch.Name, LongDescription), 1, MaxStrLen(DeferralHeader."Schedule Description")));
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure OpenLineScheduleEditDocNoUT()
    var
        SalesHeader: Record "Sales Header";
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        LongDescription: Text[100];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [UT]
        // [SCENARIO 304205] Calling OpenLineScheduleEdit with GenJournalBatchName = '' and max length Description creates Deferral Description with DocNo
        Initialize();

        // [GIVEN] Deferral Code
        DeferralCode := CreateEqual5Periods80Percent();
        // [GIVEN] Sales Invoice with No. = 'INV'
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] DeferralCodeOnValidate with long description = 'Deferral12346589....112233' and GenJnlBatchName = ''
        LongDescription := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(LongDescription)), 1, MaxStrLen(LongDescription));
        DeferralUtilities.OpenLineScheduleEdit(
          DeferralCode, DeferralDocType::Sales, '', '', SalesHeader."Document Type".AsInteger(),
          SalesHeader."No.", 1, 0, SalesHeader."Posting Date", LongDescription, '');

        // [THEN] Schedule Description = 'INV-Deferral12346589....11'
        DeferralHeader.Get(DeferralDocType::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", 1);
        DeferralHeader.TestField(
          "Schedule Description",
          CopyStr(StrSubstNo('%1-%2', SalesHeader."No.", LongDescription), 1, MaxStrLen(DeferralHeader."Schedule Description")));
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateHandler,DeferralScheduleHandlerSimple')]
    [Scope('OnPrem')]
    procedure AssistEditOnDeferralCodeForNewLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        GeneralJournal: TestPage "General Journal";
        GenJnlManagement: Codeunit GenJnlManagement;
        GLAccountNo: Code[20];
        DeferralCode: Code[10];
        Amount: Decimal;
    begin
        // [FEATURE] [Deferral schedule] [UI]
        // [SCENARIO 348150] Open deferral schedule for not inserted new general journal line
        Initialize();

        // [GIVEN] General Journal with new line that is not inserted and Line No = 0
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJnlManagement.SetJournalSimplePageModePreference(false, Page::"General Journal");
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        DeferralCode := CreateEqual5Periods();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        Commit();

        GeneralJournal.OpenEdit();
        GeneralJournal."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournal."Account No.".SetValue(GLAccountNo);
        GeneralJournal.Amount.SetValue(Amount);
        GeneralJournal."Document No.".SetValue(GenJournalBatch.Name);
        GeneralJournal."Deferral Code".SetValue(DeferralCode);

        // [WHEN] Invoke Assist edit on Deferral Code
        GeneralJournal."Deferral Code".AssistEdit();

        // [THEN] Deferral schedule with lines created for Line No = 10000
        DeferralHeader.Get(
          DeferralHeader."Deferral Doc. Type"::"G/L",
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, 0, '', 10000);

        LibraryERM.FindDeferralLine(
          DeferralLine, DeferralHeader."Deferral Doc. Type"::"G/L",
          GenJournalBatch.Name, GenJournalBatch."Journal Template Name", 0, '', 10000);

        // [THEN] Deferral schedule with lines does not exist for line 0
        asserterror
          DeferralHeader.Get(DeferralHeader."Deferral Doc. Type"::"G/L",
            GenJournalBatch."Journal Template Name", GenJournalBatch.Name, 0, '', 0);
        asserterror
          LibraryERM.FindDeferralLine(
            DeferralLine, DeferralHeader."Deferral Doc. Type"::"G/L",
            GenJournalBatch.Name, GenJournalBatch."Journal Template Name", 0, '', 0);
    end;

    [Test]
    procedure T100_DeferralLinePostingDateInRangeAllowedForDeferralPostingInUserSetup()
    var
        DeferralLine: Record "Deferral Line";
        UserSetup: Record "User Setup";
        DeferralDate: Date;
    begin
        // [SCENARIO 334609] Deferral posting date is in range of deferrals posting date, defined in User Setup.
        Initialize();
        // [GIVEN] G/L Setup has no setup on "Allow Deferrals Posting From/To"
        // [GIVEN] User Setup, where "Allow Posting From" is 010121 "Allow Posting To" 010121,
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting From" := WorkDate();
        UserSetup."Allow Posting To" := WorkDate();
        // [GIVEN] "Allow Deferrals Posting From" is 020121 "Allow Deferrals Posting To" 020121
        DeferralDate := WorkDate() + 1;
        UserSetup."Allow Deferral Posting From" := DeferralDate;
        UserSetup."Allow Deferral Posting To" := DeferralDate;
        UserSetup.Modify();

        // [WHEN] Deferral Line, where "Posting Date" is 020121
        DeferralLine.Validate("Posting Date", DeferralDate);
        // [THEN] No error, "Posting Date" is 020121 ("Allow Posting From/To" is ignored)
        DeferralLine.TestField("Posting Date", DeferralDate);

        UserSetup.Delete();
    end;

    [Test]
    procedure T101_DeferralLinePostingDateOufOfRangeAllowedForDeferralPostingInUserSetup()
    var
        DeferralLine: Record "Deferral Line";
        UserSetup: Record "User Setup";
        DeferralDate: Date;
    begin
        // [SCENARIO 334609] Deferral posting date out of range for allowed deferral posting, defined in User Setup.
        Initialize();
        // [GIVEN] G/L Setup has no setup on "Allow Deferrals Posting From/To"
        // [GIVEN] User Setup, where "Allow Posting From" is 010121 "Allow Posting To" 010121
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting From" := WorkDate();
        UserSetup."Allow Posting To" := WorkDate();
        // [GIVEN] "Allow Deferrals Posting From" is 020121 "Allow Deferrals Posting To" 020121
        DeferralDate := WorkDate() + 1;
        UserSetup."Allow Deferral Posting From" := DeferralDate;
        UserSetup."Allow Deferral Posting To" := DeferralDate;
        UserSetup.Modify();

        // [WHEN] Deferral Line, where "Posting Date" is 010121
        asserterror DeferralLine.Validate("Posting Date", WorkDate());
        // [THEN] Error, "010121 is not within the range..." ("Allow Posting From/To" is ignored)
        Assert.ExpectedError(DeferralsPostingDateOutOfRangeErr);
    end;

    [Test]
    procedure T102_DeferralLinePostingDateInRangeAllowedForDeferralPostingInGLSetup()
    var
        DeferralLine: Record "Deferral Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DeferralDate: Date;
    begin
        // [SCENARIO 334609] Deferral posting date is in the range for allowed deferral posting, defined in G/L Setup.
        Initialize();
        // [GIVEN] User Setup has no setup on "Allow Deferrals Posting From/To"
        // [GIVEN] G/L Setup, where "Allow Posting From" is 010121 "Allow Posting To" 010121,
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := WorkDate();
        GeneralLedgerSetup."Allow Posting To" := WorkDate();
        // [GIVEN] "Allow Deferrals Posting From" is 020121 "Allow Deferrals Posting To" 020121
        DeferralDate := WorkDate() + 1;
        GeneralLedgerSetup."Allow Deferral Posting From" := DeferralDate;
        GeneralLedgerSetup."Allow Deferral Posting To" := DeferralDate;
        GeneralLedgerSetup.Modify();

        // [WHEN] Deferral Line, where "Posting Date" is 020121
        DeferralLine.Validate("Posting Date", DeferralDate);
        // [THEN] No error, "Posting Date" is 020121 ("Allow Posting From/To" is ignored)
        DeferralLine.TestField("Posting Date", DeferralDate);
    end;

    [Test]
    procedure T103_DeferralLinePostingDateOutOfRangeAllowedForDeferralPostingInGLSetup()
    var
        DeferralLine: Record "Deferral Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DeferralDate: Date;
    begin
        // [SCENARIO 334609] Deferral posting date is out of the range for allowed deferral posting, defined in G/L Setup.
        Initialize();
        // [GIVEN] User Setup has no setup on "Allow Deferrals Posting From/To"
        // [GIVEN] G/L Setup, where "Allow Posting From" is 010121 "Allow Posting To" 010121,
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := WorkDate();
        GeneralLedgerSetup."Allow Posting To" := WorkDate();
        // [GIVEN] "Allow Deferrals Posting From" is 020121 "Allow Deferrals Posting To" 020121
        DeferralDate := WorkDate() + 1;
        GeneralLedgerSetup."Allow Deferral Posting From" := DeferralDate;
        GeneralLedgerSetup."Allow Deferral Posting To" := DeferralDate;
        GeneralLedgerSetup.Modify();

        // [WHEN] Deferral Line, where "Posting Date" is 010121
        asserterror DeferralLine.Validate("Posting Date", WorkDate());
        // [THEN] Error, "010121 is not within the range..." ("Allow Posting From/To" is ignored)
        Assert.ExpectedError(DeferralsPostingDateOutOfRangeErr);
    end;

    [Test]
    procedure T105_DeferralLinePostingDateOutOfRangeByGLSetupInRangeByUserSetup()
    var
        DeferralLine: Record "Deferral Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        DeferralDate: Date;
    begin
        // [SCENARIO 334609] Deferral posting date is out of range defined in G/L Setup, but in range defined in User Setup.
        Initialize();
        // [GIVEN] User Setup, where "Allow Deferrals Posting From" is 020121 "Allow Deferrals Posting To" 020121
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        DeferralDate := WorkDate() + 1;
        UserSetup."Allow Deferral Posting From" := DeferralDate;
        UserSetup."Allow Deferral Posting To" := DeferralDate;
        UserSetup.Modify();
        // [GIVEN] G/L Setup, where "Allow Deferrals Posting From" is 010121 "Allow Deferrals Posting To" 010121
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Deferral Posting From" := WorkDate();
        GeneralLedgerSetup."Allow Deferral Posting To" := WorkDate();
        GeneralLedgerSetup.Modify();

        // [WHEN] Deferral Line, where "Posting Date" is 020121
        DeferralLine.Validate("Posting Date", DeferralDate);
        // [THEN] No error, "Posting Date" is 020121, User Setup has priority over G/L Setup.
        DeferralLine.TestField("Posting Date", DeferralDate);

        UserSetup.Delete();
    end;

    [Test]
    procedure T106_DeferralLinePostingDateInRangeByGLSetupOutOfRangeByUserSetup()
    var
        DeferralLine: Record "Deferral Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        DeferralDate: Date;
    begin
        // [SCENARIO 334609] Deferral posting date is in range defined in G/L Setup, but out of range defined in User Setup.
        Initialize();
        // [GIVEN] User Setup, where "Allow Deferrals Posting From" is 020121 "Allow Deferrals Posting To" 020121
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        DeferralDate := WorkDate() + 1;
        UserSetup."Allow Deferral Posting From" := DeferralDate;
        UserSetup."Allow Deferral Posting To" := DeferralDate;
        UserSetup.Modify();
        // [GIVEN] G/L Setup, where "Allow Deferrals Posting From" is 010121 "Allow Deferrals Posting To" 010121
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Deferral Posting From" := WorkDate();
        GeneralLedgerSetup."Allow Deferral Posting To" := WorkDate();
        GeneralLedgerSetup.Modify();

        // [WHEN] Deferral Line, where "Posting Date" is 010121
        asserterror DeferralLine.Validate("Posting Date", WorkDate());
        // [THEN] Error, "010121 is not within the range..."
        Assert.ExpectedError(DeferralsPostingDateOutOfRangeErr);
    end;

    [Test]
    procedure T110_GetDeferralStartDateNextCalendarYear()
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        // [SCENARIO 334609] Deferral date for "Beginning of Next Calendar Year" gives the first day of the next calendar year.
        Initialize();
        // [GIVEN] DeferralTemplate, where "Start Date" is "Beginning of Next Calendar Year"
        DeferralTemplate.Get(CreateDeferralCode());
        DeferralTemplate."Start Date" := "Deferral Calculation Start Date"::"Beginning of Next Calendar Year";
        DeferralTemplate.Modify();

        // [THEN] GetDeferralStartDate returns 01.01.22 (beginning of the next calendar year) for 01.01.21
        Assert.AreEqual(
            20220101D, DeferralUtilities.GetDeferralStartDate(0, 0, '', 0, DeferralTemplate."Deferral Code", 20210101D),
            'Wrong date for 20210101D');
        // [THEN] GetDeferralStartDate returns 01.01.22 (beginning of the next calendar year) for 31.12.21
        Assert.AreEqual(
            20220101D, DeferralUtilities.GetDeferralStartDate(0, 0, '', 0, DeferralTemplate."Deferral Code", 20211231D),
            'Wrong date for 20210101D');
    end;

    [Test]
    procedure T120_AllowDeferralPostingFromToOnGLSetup()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 334609] G/L Setup page has "Allow Deferral Posting From" and "Allow Deferral Posting To" fields.
        Initialize();
        // [GIVEN] Open G/L Setup page
        GeneralLedgerSetup.OpenEdit();
        // [GIVEN] "Allow Deferral Posting From" and "Allow Deferral Posting To" are visible and editable
        Assert.IsTrue(GeneralLedgerSetup."Allow Deferral Posting From".Visible(), '"Allow Deferral Posting From".Visible');
        Assert.IsTrue(GeneralLedgerSetup."Allow Deferral Posting From".Editable(), '"Allow Deferral Posting From".Editable');
        Assert.IsTrue(GeneralLedgerSetup."Allow Deferral Posting To".Visible(), '"Allow Deferral Posting From".Visible');
        Assert.IsTrue(GeneralLedgerSetup."Allow Deferral Posting To".Editable(), '"Allow Deferral Posting From".Editable');

        // [WHEN] Set invalid dates so "From" is later than "To"
        GeneralLedgerSetup."Allow Deferral Posting To".SetValue(WorkDate());
        asserterror GeneralLedgerSetup."Allow Deferral Posting From".SetValue(WorkDate() + 1);

        // [THEN] Error: 'The date in the Allow Deferral Posting From field must not be after ...'
        Assert.ExpectedError(WrongAllowDeferralPostingDatesErr);
    end;

    [Test]
    procedure T121_AllowDeferralPostingFromToOnUserSetup()
    var
        UserSetup: Record "User Setup";
        UserSetupPage: TestPage "User Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 334609] User Setup page has "Allow Deferral Posting From" and "Allow Deferral Posting To" fields.
        Initialize();
        // [GIVEN] Open "User Setup" page
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetupPage.OpenEdit();
        UserSetupPage.Filter.SetFilter("User ID", UserId());
        // [GIVEN] "Allow Deferral Posting From" and "Allow Deferral Posting To" are visible and editable
        Assert.IsTrue(UserSetupPage."Allow Deferral Posting From".Visible(), '"Allow Deferral Posting From".Visible');
        Assert.IsTrue(UserSetupPage."Allow Deferral Posting From".Editable(), '"Allow Deferral Posting From".Editable');
        Assert.IsTrue(UserSetupPage."Allow Deferral Posting To".Visible(), '"Allow Deferral Posting From".Visible');
        Assert.IsTrue(UserSetupPage."Allow Deferral Posting To".Editable(), '"Allow Deferral Posting From".Editable');

        // [WHEN] Set invalid dates so "To" is earlier that "From"
        UserSetupPage."Allow Deferral Posting From".SetValue(WorkDate());
        asserterror UserSetupPage."Allow Deferral Posting To".SetValue(WorkDate() - 1);

        // [THEN] Error: 'The date in the Allow Deferral Posting From field must not be after ...'
        Assert.ExpectedError(WrongAllowDeferralPostingDatesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T130_PostingVendorInvoiceOutOfAllowedDeferralPostingRange()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 334609] Vendor invoice should not be posted if deferrals dates are out of range, defined in G/L Setup.
        Initialize();

        // [GIVEN] Vendor Invoice with Defferal setup (5 periods as "Posting Date")
        CreatePurchInvoiceWithLineDeferral(PurchaseHeader, PurchaseLine, CreateEqual5Periods(), PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] G/L Setup, where "Allow Deferrals Posting From" is 010121 "Allow Deferrals Posting To" 050121
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Deferral Posting From" := WorkDate();
        GeneralLedgerSetup."Allow Deferral Posting To" := WorkDate() + 5;
        GeneralLedgerSetup.Modify();

        // [WHEN] Post General Journal Line.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error, "060121 is not within the range..."
        Assert.ExpectedError(DeferralsPostingDateOutOfRangeErr);
    end;

    [Test]
    procedure T131_PostingGenJournalLineOutOfAllowedDeferralPostingRange()
    var
        GenJournalLine: Record "Gen. Journal Line";
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO 334609] Post general journal line with deferral dates out of range set in user setup.
        Initialize();
        // [GIVEN] General Journal Line with Deferral (5 periods as "Posting Date")
        CreateGenJournalLineWithDeferral(GenJournalLine);

        // [GIVEN] User Setup, where "Allow Deferrals Posting From" is 010121 "Allow Deferrals Posting To" 010121
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Deferral Posting From" := WorkDate();
        UserSetup."Allow Deferral Posting To" := WorkDate() + 5;
        UserSetup.Modify();

        // [WHEN] Post General Journal Lines.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error, "060121 is not within the range..."
        Assert.ExpectedError(DeferralsPostingDateOutOfRangeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalWithBlankDescriptionDeferralAndGLAccountWithOmitDefaultDescriptionEnabled()
    var
        GLAccountPosting: Record "G/L Account";
        GLAccountDeferral: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 422767] Stan can't post Journal with Deferral setup when Deferral Account has enabled "Omit Default Descr. in Jnl." and blank Description Deferral Template
        Initialize();

        GLAccountPosting.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccountPosting."Default Deferral Template Code" := CreateEqual5Periods();
        GLAccountPosting.Modify();

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(
            GLAccountDeferral, GLAccountPosting."Default Deferral Template Code", '', true);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountPosting."No.",
            GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            LibraryRandom.RandDecInRange(100, 200, 2));

        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        Assert.ExpectedError(StrSubstNo(GLAccountOmitErr, GLAccountDeferral.FieldCaption("Omit Default Descr. in Jnl.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalWithBlankDescriptionDeferralAndGLAccountWithOmitDefaultDescriptionDisabled()
    var
        GLAccountPosting: Record "G/L Account";
        GLAccountDeferral: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 422767] Stan can post Journal with Deferral setup when Deferral Account has disabled "Omit Default Descr. in Jnl." and blank Description Deferral Template
        Initialize();

        GLAccountPosting.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccountPosting."Default Deferral Template Code" := CreateEqual5Periods();
        GLAccountPosting.Modify();

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(
            GLAccountDeferral, GLAccountPosting."Default Deferral Template Code", '', false);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountPosting."No.",
            GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            LibraryRandom.RandDecInRange(100, 200, 2));

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        VerifyGLEntriesExistWithBlankDescription(GLAccountDeferral."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalWithDescriptionDeferralAndGLAccountWithOmitDefaultDescriptionEnabled()
    var
        GLAccountPosting: Record "G/L Account";
        GLAccountDeferral: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 422767] Stan can post Journal with Deferral setup when Deferral Account has enabled "Omit Default Descr. in Jnl." and specified Description Deferral Template
        Initialize();

        GLAccountPosting.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccountPosting."Default Deferral Template Code" := CreateEqual5Periods();
        GLAccountPosting.Modify();

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(
            GLAccountDeferral, GLAccountPosting."Default Deferral Template Code", LibraryUtility.GenerateGUID(), true);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountPosting."No.",
            GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            LibraryRandom.RandDecInRange(100, 200, 2));

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        VerifyGLEntriesDoNotExistWithBlankDescription(GLAccountDeferral."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithItemAndUserDefinedDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        SalesInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule]
        // [SCENARIO 543272] Post sales invoice with type = item and with defferals, calc. method = user-defined
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined. deferral calculation start date = posting date
        DeferralCode := CreateUserDefinedPeriods(5, "Deferral Calculation Start Date"::"Posting Date");
        // [GIVEN] Sales Invoice X with item X
        LibrarySales.CreateSalesInvoice(SalesHeader);
        // [GIVEN] Add deferral code X on the sales line, sales invoice X
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Deferral Code", DeferralCode);
        SalesLine.Modify();
        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

        // [WHEN] Post sales invoice X
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        VerifyGLEntries(SalesInvoiceNo, Round(SalesLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithAllocationAccountAndEqualPerPeriodDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        AllocationAccountCode: Code[20];
        SalesInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543272] Post sales invoice with type = allocation account and defferals, calc. method = equal per period
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = equal per period
        DeferralCode := CreateEqual5Periods();
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Sales Invoice X with allocation account X
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));
        // [GIVEN] Add deferral code X on the sales line, sales invoice X
        SalesLine.Validate("Deferral Code", DeferralCode);
        SalesLine.Modify();

        // [WHEN] Post sales invoice X
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTotalAmountOnGLEntries(SalesInvoiceNo, SalesInvoiceHeader."Amount Including VAT");
        VerifyGLEntriesForAllocationAndDeferral(SalesInvoiceNo, AllocationAccountCode, Round(-SalesLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithItemAndEqualPerPeriodDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        SalesInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule]
        // [SCENARIO 543272] Post sales invoice with type = item and defferals, calc. method = equal per period
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = equal per period
        DeferralCode := CreateEqual5Periods();
        // [GIVEN] Sales Invoice X with item X
        LibrarySales.CreateSalesInvoice(SalesHeader);
        // [GIVEN] Add deferral code X on the sales line, sales invoice X
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Deferral Code", DeferralCode);
        SalesLine.Modify();

        // [WHEN] Post sales invoice X
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        VerifyGLEntries(SalesInvoiceNo, Round(SalesLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithAllocationAccountAndUserDefinedBeginingOfPeriodDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        AllocationAccountCode: Code[20];
        SalesInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543272] Post sales invoice with type = allocation account and defferals, calc. method = user-defined, deferral calculation start date = begining of period
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = begining of period
        DeferralCode := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Beginning of Period");
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Sales Invoice X with allocation account X
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));

        // [GIVEN] Add deferral code X on the sales line, sales invoice X
        SalesLine.Validate("Deferral Code", DeferralCode);
        SalesLine.Modify();

        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

        // [WHEN] Post sales invoice X
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTotalAmountOnGLEntries(SalesInvoiceNo, SalesInvoiceHeader."Amount Including VAT");
        VerifyGLEntriesForAllocationAndDeferral(SalesInvoiceNo, AllocationAccountCode, Round(-SalesLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithAllocationAccountAndUserDefinedPostingDateDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        AllocationAccountCode: Code[20];
        SalesInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543272] Post sales invoice with type = allocation account and defferals, calc. method = user-defined, deferral calculation start date = posting date
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = posting date
        DeferralCode := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Posting Date");
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Sales Invoice X with allocation account X
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));

        // [GIVEN] Add deferral code X on the sales line, sales invoice X
        SalesLine.Validate("Deferral Code", DeferralCode);
        SalesLine.Modify();

        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

        // [WHEN] Post sales invoice X
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTotalAmountOnGLEntries(SalesInvoiceNo, SalesInvoiceHeader."Amount Including VAT");
        VerifyGLEntriesForAllocationAndDeferral(SalesInvoiceNo, AllocationAccountCode, Round(-SalesLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithAllocationAccountAndUserDefinedDeferralUsingGenerateLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesAllocAccMgt: Codeunit "Sales Alloc. Acc. Mgt.";
        AllocationAccountCode: Code[20];
        SalesInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543272] Post sales invoice with type = allocation account and defferals, calc. method = user-defined, deferral calculation start date = begining of period
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = begining of period
        DeferralCode := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Beginning of Period");
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Sales Invoice X with allocation account X
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));

        // [GIVEN] Add deferral code X on the sales line, sales invoice X
        SalesLine.Validate("Deferral Code", DeferralCode);
        SalesLine.Modify();

        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

        // [GIVEN] Generate lines from allocation account
        SalesAllocAccMgt.CreateLinesFromAllocationAccountLine(SalesLine);
        SalesLine.Delete();

        // [WHEN] Post sales invoice X
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTotalAmountOnGLEntries(SalesInvoiceNo, SalesInvoiceHeader."Amount Including VAT");
        VerifyGLEntriesForAllocationAndDeferral(SalesInvoiceNo, AllocationAccountCode, Round(-SalesLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithAllocationAccountAndUserDefinedDeferralWithError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AllocationAccountCode: Code[20];
        DeferralCode: Code[10];
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0';
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543272] It is not allowed to post sales invoice with deferral lines where amount = 0
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = posting date, amounts on lines = 0
        DeferralCode := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Posting Date");
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Sales Invoice X with allocation account X
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));

        // [GIVEN] Add deferral code X on the sales line, sales invoice X
        SalesLine.Validate("Deferral Code", DeferralCode);
        SalesLine.Modify();

        // [WHEN] Posting sales invoice X is not allowed with deferral lines with amount = 0
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] The error message popup
        Assert.ExpectedError(ZeroDeferralAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DontCopyDeferralScheduleWhenChangingDeferralCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralCode: array[2] of Code[10];
    begin
        // [FEATURE] [Deferral schedule]
        // [SCENARIO 543272] Change user-defined deferral code on sales invoice without copying deferral schedule
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = posting date, amounts on lines = 0
        DeferralCode[1] := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Posting Date");
        // [GIVEN] Deferral Code Y, calc.method = user-defined, deferral calculation start date = posting date, amounts on lines = 0
        DeferralCode[2] := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Posting Date");

        // [GIVEN] Sales Invoice X with item X
        LibrarySales.CreateSalesInvoice(SalesHeader);
        // [GIVEN] Add deferral code X on the sales line, sales invoice X
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Deferral Code", DeferralCode[1]);
        SalesLine.Modify();

        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

        // [WHEN] Change deferral code
        SalesLine.Validate("Deferral Code", DeferralCode[2]);
        SalesLine.Modify();

        // [THEN] Deferral schedule for deferral code Y doesn't have amounts
        VerifyDeferralSchedule("Deferral Document Type"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithItemAndUserDefinedDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        PurchaseInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule]
        // [SCENARIO 543891] Post purchase invoice with type = item and with defferals, calc. method = user-defined
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined. deferral calculation start date = posting date
        DeferralCode := CreateUserDefinedPeriods(5, "Deferral Calculation Start Date"::"Posting Date");
        // [GIVEN] Purchase invoice X with item X
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        // [GIVEN] Add deferral code X on the purchase line, purchase invoice X
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify();
        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Purchase, PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [WHEN] Post purchase invoice X
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        VerifyGLEntries(PurchaseInvoiceNo, Round(PurchaseLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithAllocationAccountAndEqualPerPeriodDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        AllocationAccountCode: Code[20];
        PurchaseInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543891] Post purchase invoice with type = allocation account and defferals, calc. method = equal per period
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = equal per period
        DeferralCode := CreateEqual5Periods();
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Purchase Invoice X with allocation account X
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        // [GIVEN] Add deferral code X on the purchase line, purchase invoice X
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify();

        // [WHEN] Post purchase invoice X
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        PurchaseInvoiceHeader.Get(PurchaseInvoiceNo);
        PurchaseInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTotalAmountOnGLEntries(PurchaseInvoiceNo, -PurchaseInvoiceHeader."Amount Including VAT");
        VerifyGLEntriesForAllocationAndDeferral(PurchaseInvoiceNo, AllocationAccountCode, Round(PurchaseLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithItemAndEqualPerPeriodDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        PurchaseInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule]
        // [SCENARIO 543891] Post purchase invoice with type = item and defferals, calc. method = equal per period
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = equal per period
        DeferralCode := CreateEqual5Periods();
        // [GIVEN] Purchase Invoice X with item X
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        // [GIVEN] Add deferral code X on the purchase line, purchase invoice X
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify();

        // [WHEN] Post purchase invoice X
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        VerifyGLEntries(PurchaseInvoiceNo, Round(PurchaseLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithAllocationAccountAndUserDefinedBeginingOfPeriodDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        AllocationAccountCode: Code[20];
        PurchaseInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543891] Post purchase invoice with type = allocation account and defferals, calc. method = user-defined, deferral calculation start date = begining of period
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = begining of period
        DeferralCode := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Beginning of Period");
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Purchase Invoice X with allocation account X
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));

        // [GIVEN] Add deferral code X on the purchase line, purchase invoice X
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify();

        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Purchase, PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [WHEN] Post purchase invoice X
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        PurchaseInvoiceHeader.Get(PurchaseInvoiceNo);
        PurchaseInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTotalAmountOnGLEntries(PurchaseInvoiceNo, -PurchaseInvoiceHeader."Amount Including VAT");
        VerifyGLEntriesForAllocationAndDeferral(PurchaseInvoiceNo, AllocationAccountCode, Round(PurchaseLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithAllocationAccountAndUserDefinedPostingDateDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        AllocationAccountCode: Code[20];
        PurchaseInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543891] Post purchase invoice with type = allocation account and defferals, calc. method = user-defined, deferral calculation start date = posting date
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = posting date
        DeferralCode := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Posting Date");
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Purchase Invoice X with allocation account X
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));

        // [GIVEN] Add deferral code X on the purchase line, purchase invoice X
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify();

        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Purchase, PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [WHEN] Post purchase invoice X
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        PurchaseInvoiceHeader.Get(PurchaseInvoiceNo);
        PurchaseInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTotalAmountOnGLEntries(PurchaseInvoiceNo, -PurchaseInvoiceHeader."Amount Including VAT");
        VerifyGLEntriesForAllocationAndDeferral(PurchaseInvoiceNo, AllocationAccountCode, Round(PurchaseLine.Amount / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithAllocationAccountAndUserDefinedDeferralUsingGenerateLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseAllocAccMgt: Codeunit "Purchase Alloc. Acc. Mgt.";
        AllocationAccountCode: Code[20];
        PurchaseInvoiceNo: Code[20];
        DeferralCode: Code[10];
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543891] Post purchase invoice with type = allocation account and defferals, calc. method = user-defined, deferral calculation start date = begining of period
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = begining of period
        DeferralCode := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Beginning of Period");
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Purchase Invoice X with allocation account X
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));

        // [GIVEN] Add deferral code X on the purchase line, purchase invoice X
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify();

        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Purchase, PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [GIVEN] Generate lines from allocation account
        PurchaseAllocAccMgt.CreateLinesFromAllocationAccountLine(PurchaseLine);
        PurchaseLine.Delete();

        // [WHEN] Post purchase invoice X
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify created G/L entries
        DeferralTemplate.Get(DeferralCode);
        PurchaseInvoiceHeader.Get(PurchaseInvoiceNo);
        PurchaseInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTotalAmountOnGLEntries(PurchaseInvoiceNo, -PurchaseInvoiceHeader."Amount Including VAT");
        VerifyGLEntriesForAllocationAndDeferral(PurchaseInvoiceNo, AllocationAccountCode, Round(PurchaseLine."Amount Including VAT" / DeferralTemplate."No. of Periods", LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithAllocationAccountAndUserDefinedDeferralWithError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AllocationAccountCode: Code[20];
        DeferralCode: Code[10];
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0';
    begin
        // [FEATURE] [Deferral schedule] [Allocation Account]
        // [SCENARIO 543891] It is not allowed to post purchase invoice with deferral lines where amount = 0
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = posting date, amounts on lines = 0
        DeferralCode := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Posting Date");
        // [GIVEN] Create Allocation Account with fixed distribution
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();
        // [GIVEN] Purchase Invoice X with allocation account X
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Allocation Account",
            AllocationAccountCode, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));

        // [GIVEN] Add deferral code X on the purchase line, purchase invoice X
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify();

        // [WHEN] Posting purchase invoice X is not allowed with deferral lines with amount = 0
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] The error message popup
        Assert.ExpectedError(ZeroDeferralAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DontCopyDeferralScheduleOnPurchaseInvoiceWhenChangingDeferralCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralCode: array[2] of Code[10];
    begin
        // [FEATURE] [Deferral schedule]
        // [SCENARIO 543891] Change user-defined deferral code on purchase invoice without copying deferral schedule
        Initialize();

        // [GIVEN] Deferral Code X, calc.method = user-defined, deferral calculation start date = posting date, amounts on lines = 0
        DeferralCode[1] := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Posting Date");
        // [GIVEN] Deferral Code Y, calc.method = user-defined, deferral calculation start date = posting date, amounts on lines = 0
        DeferralCode[2] := CreateUserDefinedPeriods(2, "Deferral Calculation Start Date"::"Posting Date");

        // [GIVEN] Purchase Invoice X with item X
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        // [GIVEN] Add deferral code X on the purchase line, purchase invoice X
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Deferral Code", DeferralCode[1]);
        PurchaseLine.Modify();

        // [GIVEN] Insert amounts on deferral schedule
        UpdateAmountOnDeferralSchedule("Deferral Document Type"::Purchase, PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [WHEN] Change deferral code
        PurchaseLine.Validate("Deferral Code", DeferralCode[2]);
        PurchaseLine.Modify();

        // [THEN] Deferral schedule for deferral code Y doesn't have amounts
        VerifyDeferralSchedule("Deferral Document Type"::Purchase, PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    local procedure Initialize()
    var
        AccountingPeriod: Record "Accounting Period";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        GenJnlManagement: Codeunit "GenJnlManagement";
        Index: Integer;
        CurrentPeriod: Date;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test RED Setup Gen. Jnl.");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test RED Setup Gen. Jnl.");
        GenJnlManagement.SetJournalSimplePageModePreference(true, Page::"General Journal");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Source Code Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        // Create the next 5 periods if not exist
        for Index := 1 to 5 do begin
            CurrentPeriod := CalcDate(StrSubstNo('<+%1M>', Index), WorkDate());
            AccountingPeriod.SetRange("Starting Date", CurrentPeriod);
            if not AccountingPeriod.FindFirst() then begin
                AccountingPeriod."Starting Date" := CurrentPeriod;
                AccountingPeriod."New Fiscal Year" := true;
                AccountingPeriod.Insert();
            end;
        end;

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test RED Setup Gen. Jnl.");
    end;

    local procedure CreateDeferralCode() DeferralCode: Code[10]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Init();
        DeferralTemplate."Deferral Code" :=
          LibraryUtility.GenerateRandomCode(DeferralTemplate.FieldNo("Deferral Code"), DATABASE::"Deferral Template");

        DeferralTemplate.Insert();
        DeferralCode := DeferralTemplate."Deferral Code";

        exit(DeferralCode);
    end;

    [Scope('OnPrem')]
    procedure CreateMasterDeferralRecord(CalcMethod: Enum "Deferral Calculation Method"; StartDate: Enum "Deferral Calculation Start Date"; NumOfPeriods: Integer; PeriodDescription: Text[50]; DeferralPercentage: Decimal) "Code": Code[10]
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralCode: Code[10];
        GLAccountNumber: Code[20];
    begin
        // Setup
        DeferralCode := LibraryUtility.GenerateRandomCode(DeferralTemplate.FieldNo("Deferral Code"), DATABASE::"Deferral Template");
        GLAccountNumber := LibraryERM.CreateGLAccountNo();

        DeferralTemplate.Init();
        DeferralTemplate."Deferral Code" := DeferralCode;
        DeferralTemplate."Deferral Account" := GLAccountNumber;
        DeferralTemplate."Calc. Method" := CalcMethod;
        DeferralTemplate."Start Date" := StartDate;
        DeferralTemplate."No. of Periods" := NumOfPeriods;
        DeferralTemplate."Period Description" := PeriodDescription;
        DeferralTemplate."Deferral %" := DeferralPercentage;
        DeferralTemplate.Insert();

        Code := DeferralTemplate."Deferral Code";

        exit(Code);
    end;

    local procedure CreateEqual5Periods80Percent() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Equal per Period", StartDate::"Posting Date", 5, '%1 Deferral %5', 80.0);
        exit(DeferralCode);
    end;

    local procedure CreateEqual5Periods() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Equal per Period", StartDate::"Posting Date", 5, '%1 Deferral %5', 100.0);
        exit(DeferralCode);
    end;

    local procedure CreateStraightLine2Periods() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Straight-Line", StartDate::"Beginning of Period", 2, '%1 Deferral %5', 100.0);
        exit(DeferralCode);
    end;

    local procedure CreateStraightLine6Periods() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Straight-Line", StartDate::"Posting Date", 6, '%1 Deferral %5', 100.0);
        exit(DeferralCode);
    end;

    local procedure CreateStraightLine6PeriodsEOP() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Straight-Line", StartDate::"End of Period", 6, '%1 Deferral %5', 100.0);
        exit(DeferralCode);
    end;

    local procedure CreateDaysPerPeriod6Periods() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Days per Period", StartDate::"Beginning of Period", 6, '%1 Deferral %5', 100.0);
        exit(DeferralCode);
    end;

    local procedure CreateDaysPerPeriod6PeriodsEOP() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Days per Period", StartDate::"End of Period", 6, '%1 Deferral %5', 100.0);
        exit(DeferralCode);
    end;

    local procedure CreateDaysPerPeriod6PeriodsBONP() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Days per Period", StartDate::"Beginning of Next Period", 6, '%1 Deferral %5', 100.0);
        exit(DeferralCode);
    end;

    local procedure CreateDaysPerPeriod99Periods() DeferralCode: Code[10]
    begin
        DeferralCode :=
          CreateMasterDeferralRecord(CalcMethod::"Days per Period", StartDate::"Beginning of Next Period", 99, '%1 Deferral %5', 100.0);
        exit(DeferralCode);
    end;

    local procedure CreateUserDefinedPeriods(NoOfPeriod: Integer; DeferralCalcStartDate: Enum "Deferral Calculation Start Date"): Code[10]
    begin
        exit(
            CreateMasterDeferralRecord(CalcMethod::"User-Defined", DeferralCalcStartDate, NoOfPeriod, '%1 Deferral %5', 100.0));
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalLineByPage(var GeneralJournal: TestPage "General Journal"; GLAccount: Record "G/L Account"; var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Find General Journal Template and Create General Journal Batch.
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        Commit();

        // Create General Journal Line.
        GeneralJournal.OpenEdit();
        GeneralJournal."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournal."Account No.".SetValue(GLAccount."No.");
        GeneralJournal.Amount.SetValue(Amount);
        GeneralJournal."Document No.".SetValue(GenJournalBatch.Name);

        GenJournalLine.Validate("Deferral Code");
        Commit();

        // Create G/L Account No for Bal. Account No.
        GLAccount.SetFilter("No.", '<>%1', GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralJournal."Bal. Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournal."Bal. Account No.".SetValue(GLAccount."No.");

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
    end;

    local procedure CreateSalesInvoiceWithLineDeferral(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DeferralCode: Code[10]; DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandIntInRange(10, 20));

        LibrarySales.CreateSalesHeader(
          SalesHeader,
          DocumentType,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "), 1);

        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Deferral Code", DeferralCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchInvoiceWithLineDeferral(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DeferralCode: Code[10]; DocumentType: Enum "Purchase Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandIntInRange(10, 20));

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader,
          DocumentType,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "), 1);

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGenJournalLineWithDeferral(var GenJournalLine: Record "Gen. Journal Line"): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        DeferralCode: Code[10];
    begin
        // Create Deferral Template with 5 periods
        DeferralCode := CreateEqual5Periods();

        // Create new GL Account
        LibraryERM.CreateGLAccount(GLAccount);

        // Assign the deferral code to new GL Account
        GLAccount."Default Deferral Template Code" := DeferralCode;
        GLAccount.Modify();

        // Create General Journal Line.
        // Generate GL trx with new account, give it an amount
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateSourceCodeInGenJournalTemplate(GenJournalBatch);

        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalBatch."Bal. Account Type", GenJournalBatch."Bal. Account No.", LibraryRandom.RandDec(1000, 2));

        exit(DeferralCode);
    end;

    local procedure CreateSalesGenJournalLineWithDeferral(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount."Default Deferral Template Code" := CreateEqual5Periods();
        GLAccount.Modify();

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
            GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreatePurchaseGenJournalLineWithDeferral(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount."Default Deferral Template Code" := CreateEqual5Periods();
        GLAccount.Modify();

        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
            GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(1000, 2));
    end;

    local procedure UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(var GLAccountDeferral: Record "G/L Account"; DeferralCode: Code[10]; NewDescription: Text[100]; NewOmit: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(DeferralCode);
        DeferralTemplate.Validate("Period Description", NewDescription);
        DeferralTemplate.Modify(true);

        GLAccountDeferral.Get(DeferralTemplate."Deferral Account");
        GLAccountDeferral.Validate(Name, NewDescription);
        GLAccountDeferral.Validate("Omit Default Descr. in Jnl.", NewOmit);
        GLAccountDeferral.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
        RecRef: RecordRef;
    begin
        // Find a balanced template/batch pair.
        GenJournalBatch.Get(JournalTemplateName, JournalBatchName);

        // Create a General Journal Entry.
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", JournalTemplateName);
        GenJournalLine.Validate("Journal Batch Name", JournalBatchName);
        RecRef.GetTable(GenJournalLine);
        GenJournalLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, GenJournalLine.FieldNo("Line No.")));
        GenJournalLine.Insert(true);
        GenJournalLine.Validate("Posting Date", WorkDate());  // Defaults to work date.
        GenJournalLine.Validate("Document Type", DocumentType);
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate(Amount, Amount);
        if NoSeries.Get(GenJournalBatch."No. Series") then
            GenJournalLine.Validate("Document No.", NoSeriesCodeunit.PeekNextNo(GenJournalBatch."No. Series")) // Unused but required field for posting.
        else
            GenJournalLine.Validate(
              "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");  // Unused but required for vendor posting.
        GenJournalLine.Validate("Source Code", LibraryERM.FindGeneralJournalSourceCode());  // Unused but required for AU, NZ builds
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure FilterGLEntryGroups(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry.SetRange("Gen. Posting Type", GenJournalLine."Gen. Posting Type");
        GLEntry.SetRange("VAT Bus. Posting Group", GenJournalLine."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", GenJournalLine."VAT Prod. Posting Group");
        GLEntry.SetRange("Gen. Bus. Posting Group", GenJournalLine."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", GenJournalLine."Gen. Prod. Posting Group");
    end;

    local procedure GetTransactionNumberFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line"): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GenJournalLine."Document Type");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();
        exit(GLEntry."Transaction No.");
    end;

    local procedure VerifyValuesonGLDeferralSummary(PostedDeferralHeader: Record "Posted Deferral Header")
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.SetRange('GenJnlDocNo', PostedDeferralHeader."Gen. Jnl. Document No.");
        LibraryReportDataset.SetRange('No_GLAcc', PostedDeferralHeader."Account No.");
        LibraryReportDataset.SetRange('DocumentType', PostedDeferralHeader."Document Type");
        LibraryReportDataset.GetNextRow();

        if GLAccount.Get(PostedDeferralHeader."Account No.") then
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'AccountName',
              GLAccount.Name);

        if GLEntry.Get(PostedDeferralHeader."Entry No.") then begin
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'PostingDate',
              Format(GLEntry."Posting Date"));

            LibraryReportDataset.AssertCurrentRowValueEquals(
              'DocumentType',
              GLEntry."Document Type");
        end;

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DeferralAccount',
          PostedDeferralHeader."Deferral Account");

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DeferralStartDate',
          Format(PostedDeferralHeader."Start Date"));

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'NumOfPeriods',
          PostedDeferralHeader."No. of Periods");

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'TotalAmtDeferred',
          PostedDeferralHeader."Amount to Defer (LCY)");
    end;

    local procedure VerifyDescriptionOnTotalDeferralLine(DocNo: Code[20]; GLAccNo: Code[20]; PostingDate: Date; DefDescription: Text[100])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.FindFirst();
        GLEntry.TestField(Description, DefDescription);
    end;

    local procedure VerifyTotalNumberOfPostedGLEntries(GenJournalLine: Record "Gen. Journal Line"; ExpectedGLEntriesCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        Assert.RecordCount(GLEntry, ExpectedGLEntriesCount);
    end;

    local procedure VerifyPostedDeferralHeadersNumber(GenJnlDocumentNo: Code[20]; ExpectedNumber: Integer)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
    begin
        PostedDeferralHeader.Reset();
        PostedDeferralHeader.SetRange("Deferral Doc. Type", "Deferral Document Type"::"G/L");
        PostedDeferralHeader.SetRange("Gen. Jnl. Document No.", GenJnlDocumentNo);
        Assert.AreEqual(ExpectedNumber, PostedDeferralHeader.Count, PostedDeferralHeaderNumberErr);
    end;

    local procedure VerifyVATGLEntryForPostingAccount(GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
        DummyGenJournalLine: Record "Gen. Journal Line";
        PairAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", GenJournalLine."Document Type");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("G/L Account No.", GenJournalLine."Account No.");
        GLEntry.SetFilter("VAT Amount", '<>%1', 0);
        FilterGLEntryGroups(GLEntry, GenJournalLine);
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        PairAmount := GLEntry.Amount;
        // Verify paired GLEntry
        GLEntry.SetRange("VAT Amount");
        GLEntry.SetFilter(Amount, '<%1', 0);
        FilterGLEntryGroups(GLEntry, DummyGenJournalLine);
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -PairAmount);
    end;

    local procedure VerifyGLEntriesExistWithBlankDescription(GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.SetFilter(Description, '=%1', '');
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerifyGLEntriesDoNotExistWithBlankDescription(GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.SetFilter(Description, '=%1', '');
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure UpdateSourceCodeInGenJournalTemplate(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if GenJournalBatch."Journal Template Name" = '' then
            exit;

        if not GenJournalTemplate.Get(GenJournalBatch."Journal Template Name") then
            exit;

        if not SourceCodeSetup.Get() then
            exit;

        case
            GenJournalTemplate.Type of
            GenJournalTemplate.Type::General:
                if GenJournalTemplate."Source Code" <> SourceCodeSetup."General Journal" then begin
                    GenJournalTemplate.Validate("Source Code", SourceCodeSetup."General Journal");
                    GenJournalTemplate.Modify(true);
                end;
            GenJournalTemplate.Type::Sales:
                if GenJournalTemplate."Source Code" <> SourceCodeSetup."Sales Journal" then begin
                    GenJournalTemplate.Validate("Source Code", SourceCodeSetup."Sales Journal");
                    GenJournalTemplate.Modify(true);
                end;
            GenJournalTemplate.Type::Purchases:
                if GenJournalTemplate."Source Code" <> SourceCodeSetup."Purchase Journal" then begin
                    GenJournalTemplate.Validate("Source Code", SourceCodeSetup."Purchase Journal");
                    GenJournalTemplate.Modify(true);
                end;
        end;
    end;

    local procedure UpdateAmountOnDeferralSchedule(DeferralDocumentType: Enum "Deferral Document Type"; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        PeriodicCount: Integer;
        AmountToDefer: Decimal;
        RunningDeferralTotal: Decimal;
    begin
        DeferralHeader.Get(DeferralDocumentType, '', '', DocumentType, DocumentNo, LineNo);
        DeferralUtilities.FilterDeferralLines(DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
        DeferralLine.FindSet();
        for PeriodicCount := 1 to DeferralHeader."No. of Periods" do begin
            AmountToDefer := DeferralHeader."Amount to Defer";
            if PeriodicCount > 1 then
                DeferralLine.Next();
            if PeriodicCount <> DeferralHeader."No. of Periods" then begin
                AmountToDefer := Round(AmountToDefer / DeferralHeader."No. of Periods", LibraryERM.GetAmountRoundingPrecision());
                RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
            end else
                AmountToDefer := (DeferralHeader."Amount to Defer" - RunningDeferralTotal);

            DeferralLine.Validate(Amount, AmountToDefer);
            DeferralLine.Modify();
        end;
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(): Code[20]
    var
        AllocationAccount: Record "Allocation Account";
    begin
        AllocationAccount."No." := Format(LibraryRandom.RandText(5));
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Fixed;
        AllocationAccount.Name := Format(LibraryRandom.RandText(10));
        AllocationAccount.Insert();

        CreateGLAccountAllocationForFixedDistrubution(AllocationAccount."No.", LibraryRandom.RandIntInRange(1, 50));
        CreateGLAccountAllocationForFixedDistrubution(AllocationAccount."No.", LibraryRandom.RandIntInRange(1, 50));
        exit(AllocationAccount."No.");
    end;

    local procedure CreateGLAccountAllocationForFixedDistrubution(AllocationAccountNo: Code[20]; Shape: Decimal)
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocAccountDistribution."Allocation Account No." := AllocationAccountNo;
        AllocAccountDistribution."Line No." := LibraryUtility.GetNewRecNo(AllocAccountDistribution, AllocAccountDistribution.FieldNo("Line No."));
        AllocAccountDistribution.Validate("Account Type", AllocAccountDistribution."Account Type"::Fixed);
        AllocAccountDistribution.Validate("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocAccountDistribution.Validate("Destination Account Number", LibraryERM.CreateGLAccountWithSalesSetup());
        AllocAccountDistribution.Validate(Share, Shape);
        AllocAccountDistribution.Insert();
    end;

    local procedure VerifyGLEntriesForAllocationAndDeferral(InvoiceNo: Code[20]; AllocationAccountCode: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        ExpectedAmount: Decimal;
    begin
        AllocAccountDistribution.SetRange("Allocation Account No.", AllocationAccountCode);
        AllocAccountDistribution.FindSet();
        repeat
            ExpectedAmount := Round(AllocAccountDistribution.Percent / 100 * Amount, LibraryERM.GetAmountRoundingPrecision());
            GLEntry.SetRange("Document No.", InvoiceNo);
            GLEntry.SetRange("G/L Account No.", AllocAccountDistribution."Destination Account Number");
            GLEntry.SetRange(Amount, ExpectedAmount);
            Assert.RecordIsNotEmpty(GLEntry);
        until AllocAccountDistribution.Next() = 0;
    end;

    local procedure VerifyGLEntries(InvoiceNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange(Amount, Amount);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerifyTotalAmountOnGLEntries(InvoiceNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange(Amount, Amount);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerifyDeferralSchedule(DeferralDocumentType: Enum "Deferral Document Type"; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        DeferralHeader.Get(DeferralDocumentType, '', '', DocumentType, DocumentNo, LineNo);
        DeferralUtilities.FilterDeferralLines(DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
        DeferralLine.SetFilter(Amount, '<>%1', 0);
        Assert.RecordIsEmpty(DeferralLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateHandler(var GeneralJournalTemplateHandler: TestPage "General Journal Template List")
    begin
        // General Journal Template Name filter with GeneralJournalTemplateName Global Variable.
        GeneralJournalTemplateHandler.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateHandler.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleHandler(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        Assert.IsFalse(DeferralSchedule.PostingDate.Editable(), 'PostingDate.EDITABLE');
        LibraryVariableStorage.Enqueue(DeferralSchedule.PostingDate.AsDate());
        Assert.IsFalse(DeferralSchedule.StartDateCalcMethod.Editable(), 'StartDateCalcMethod.EDITABLE');
        LibraryVariableStorage.Enqueue(DeferralSchedule.StartDateCalcMethod.Value);
        if DeferralSchedule.DeferralSheduleSubform.First() then
            LibraryVariableStorage.Enqueue(DeferralSchedule.DeferralSheduleSubform."Posting Date".AsDate());
        DeferralSchedule.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleHandlerSimple(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        DeferralSchedule."Start Date".SetValue(WorkDate());
        DeferralSchedule.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLDeferralSummaryReportHandler(var DeferralSummaryGL: TestRequestPage "Deferral Summary - G/L")
    begin
        DeferralSummaryGL.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DocumentNoIsBlankMessageHandler(Message: Text[1024])
    begin
    end;
}
