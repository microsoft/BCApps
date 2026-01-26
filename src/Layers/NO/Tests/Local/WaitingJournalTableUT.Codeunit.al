codeunit 144123 "WaitingJournalTable UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Waiting Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        DimensionManagement: Codeunit DimensionManagement;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure WaitingJournalOnDelete()
    var
        ReturnError: Record "Return Error";
        WaitingJournal: Record "Waiting Journal";
    begin
        // Purpose of the test is to validate Trigger OnDelete

        WaitingJournal.DeleteAll();
        ReturnError.DeleteAll();

        WaitingJournal.Reference := LibraryRandom.RandInt(10);
        WaitingJournal.Insert();
        ReturnError."Waiting Journal Reference" := WaitingJournal.Reference;
        ReturnError.Insert();

        WaitingJournal.Delete(true);

        Assert.IsFalse(ReturnError.Get(ReturnError."Waiting Journal Reference"), 'Return Error record not delted as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountNoOnValidate()
    var
        WaitingJournal: Record "Waiting Journal";
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // Purpose of the test is to validate Trigger Account No. OnValidate

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        FindDimensionAndValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension,
          DATABASE::"G/L Account",
          GLAccount."No.",
          DimensionValue."Dimension Code",
          DimensionValue.Code);

        // Exercise
        WaitingJournal.Validate("Account No.", GLAccount."No.");

        // Verify
        VerifyDimensions(WaitingJournal, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalAccountNoOnValidate()
    var
        WaitingJournal: Record "Waiting Journal";
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // Purpose of the test is to validate Trigger Account No. OnValidate

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        FindDimensionAndValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension,
          DATABASE::"G/L Account",
          GLAccount."No.",
          DimensionValue."Dimension Code",
          DimensionValue.Code);

        // Exercise
        WaitingJournal.Validate("Bal. Account No.", GLAccount."No.");

        // Verify
        VerifyDimensions(WaitingJournal, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShortcutDimensionOnValidate()
    var
        WaitingJournal: Record "Waiting Journal";
        GLSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        // Purpose of the test is to validate Trigger ShortcutDimension1 OnValidate

        asserterror WaitingJournal.Validate("Shortcut Dimension 1 Code", 'SomeNonExistingCode');
        Assert.AreEqual('DB:NothingInsideFilter', GetLastErrorCode, 'Expected OnValidate to fail when dimension value does not exist');

        WaitingJournal.Init();
        asserterror WaitingJournal.Validate("Shortcut Dimension 2 Code", 'SomeNonExistingCode');
        Assert.AreEqual('DB:NothingInsideFilter', GetLastErrorCode, 'Expected OnValidate to fail when dimension value does not exist');

        GLSetup.FindFirst();

        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Shortcut Dimension 1 Code");
        WaitingJournal.Init();
        WaitingJournal."Check Printed" := false;
        WaitingJournal.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Shortcut Dimension 2 Code");
        WaitingJournal.Init();
        WaitingJournal."Check Printed" := false;
        WaitingJournal.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);

        WaitingJournal.Init();
        WaitingJournal."Check Printed" := true;
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Shortcut Dimension 1 Code");
        asserterror WaitingJournal.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        Assert.AreEqual('TestField', GetLastErrorCode, 'Expected OnValudate to fail when Check Printed is true');

        WaitingJournal.Reset();
        WaitingJournal."Check Printed" := true;
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Shortcut Dimension 2 Code");
        asserterror WaitingJournal.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        Assert.AreEqual('TestField', GetLastErrorCode, 'Expected OnValudate to fail when Check Printed is true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPersPurchCodeOnValidate()
    var
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        WaitingJournal: Record "Waiting Journal";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Purpose of the test is to validate Trigger Salespers./Purch. Code OnValidate

        // Setup
        LibrarySales.CreateSalesperson(SalesPersonPurchaser);
        FindDimensionAndValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension,
          DATABASE::"Salesperson/Purchaser",
          SalesPersonPurchaser.Code,
          DimensionValue."Dimension Code",
          DimensionValue.Code);

        // Exercise
        WaitingJournal.Validate("Salespers./Purch. Code", SalesPersonPurchaser.Code);

        // Verify
        VerifyDimensions(WaitingJournal, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobNoOnValidate()
    var
        WaitingJournal: Record "Waiting Journal";
        Job: Record Job;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        JobsUtil: Codeunit "Library - Job";
    begin
        // Purpose of the test is to validate Trigger Job No. OnValidate

        // Setup
        JobsUtil.CreateJob(Job);
        FindDimensionAndValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension,
          DATABASE::Job,
          Job."No.",
          DimensionValue."Dimension Code",
          DimensionValue.Code);

        // Exercise
        WaitingJournal.Validate("Job No.", Job."No.");

        // Verify
        VerifyDimensions(WaitingJournal, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CampaignNoOnValidate()
    var
        WaitingJournal: Record "Waiting Journal";
        Campaign: Record Campaign;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        // Purpose of the test is to validate Trigger Job No. OnValidate

        // Setup
        LibraryMarketing.CreateCampaign(Campaign);
        FindDimensionAndValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension,
          DATABASE::Campaign,
          Campaign."No.",
          DimensionValue."Dimension Code",
          DimensionValue.Code);

        // Exercise
        WaitingJournal.Validate("Campaign No.", Campaign."No.");

        // Verify
        VerifyDimensions(WaitingJournal, DimensionValue);
    end;

    [Test]
    [HandlerFunctions('HandleLookupShortcutDimCode')]
    [Scope('OnPrem')]
    procedure LookupShortcutDimCode()
    var
        WaitingJournal: Record "Waiting Journal";
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        ShortcutDimCode: Code[10];
    begin
        WaitingJournal."Check Printed" := true;
        asserterror WaitingJournal.LookupShortcutDimCode(1, ShortcutDimCode);
        Assert.AreEqual('TestField', GetLastErrorCode, 'Expected LookupShortcutDimCode to fail when Check Printed is true');

        WaitingJournal.Init();
        WaitingJournal.LookupShortcutDimCode(1, ShortcutDimCode);

        GLSetup.FindFirst();
        DimensionValue.SetFilter("Dimension Code", '=%1', GLSetup."Shortcut Dimension 1 Code");
        DimensionValue.SetFilter(Blocked, '=%1', false);
        DimensionValue.SetFilter(Code, ShortcutDimCode);
        DimensionValue.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WaitingCopyLineDimensions()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT] [Dimension]
        // [SCENARIO 233377] Value of "Dimension Set ID" is copying from "Gen. Journal Line" to "Waiting Journal" when invoke "Waitning Journal"."CopyLineDimensions"

        // [GIVEN] "Gen. Journal Line" with "Dimension Set ID" = 17
        GenJournalLine.Init();
        GenJournalLine."Dimension Set ID" := LibraryRandom.RandInt(10);

        // [WHEN] Invoke "Waiting Journal"."CopyLineDimensions"
        WaitingJournal.CopyLineDimensions(GenJournalLine);

        // [THEN] "Waiting Journal"."Dimension Set ID" = 17
        WaitingJournal.TestField("Dimension Set ID", GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WaitingJournalRecreateLineDimension()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT] [Dimension]
        // [SCENARIO 233377] Value of "Dimension Set ID" is copying from "Waiting Journal" to "Gen. Journal Line" when invoke "Waiting Journal"."RecreateLineDimensions"

        // [GIVEN] "Waiting Journal" with "Dimension Set ID" = 17
        WaitingJournal.Init();
        WaitingJournal."Dimension Set ID" := LibraryRandom.RandInt(10);
        GenJournalLine.Init();
        GenJournalLine.Insert();

        // [WHEN] Invoke "Waiting Journal"."RecreateLineDimensions"
        WaitingJournal.RecreateLineDimensions(GenJournalLine);

        // [THEN] "Gen. Journal Line"."Dimension Set ID" = 17
        GenJournalLine.TestField("Dimension Set ID", WaitingJournal."Dimension Set ID");
    end;

    [Test]
    procedure WaitingJournalDescriptionReadWrite()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 395366] TAB 15000004 "Waiting Journal" Read\Write Description methods
        GenJournalLine.Description :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GenJournalLine.Description)), 1, MaxStrLen(GenJournalLine.Description));

        WaitingJournal.WriteDescription(GenJournalLine.Description);
        Assert.AreEqual(GenJournalLine.Description, WaitingJournal.ReadDescription(), 'ReadDescription');

        WaitingJournal.WriteDescription('');
        WaitingJournal.PerformTransferFieldsFromGenJournalLine(GenJournalLine);
        Assert.AreEqual(GenJournalLine.Description, WaitingJournal.ReadDescription(), 'PerformTransferFieldsFromGenJournalLine');
    end;

    [Test]
    procedure WaitingJournalDescriptionUI()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        WaitingJournalPage: TestPage "Waiting Journal";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 395366] PAG 15000005 "Waiting Journal" Description field on the page
        GenJournalLine.Description :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GenJournalLine.Description)), 1, MaxStrLen(GenJournalLine.Description));

        WaitingJournal.WriteDescription(GenJournalLine.Description);
        WaitingJournal.Insert();
        WaitingJournalPage.OpenEdit();
        WaitingJournalPage.GoToRecord(WaitingJournal);
        Assert.IsTrue(WaitingJournalPage.DescriptionField.Visible(), 'DescriptionField');
        WaitingJournalPage.DescriptionField.AssertEquals(GenJournalLine.Description);
        WaitingJournalPage.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleLookupShortcutDimCode(var DimensionValueList: TestPage "Dimension Value List")
    begin
        DimensionValueList.OK().Invoke();
    end;

    local procedure VerifyDimensions(var WaitingJournal: Record "Waiting Journal"; DimensionValue: Record "Dimension Value")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        Assert.AreNotEqual(0, WaitingJournal."Dimension Set ID", 'No dimension set id assigned');
        DimensionManagement.GetDimensionSet(TempDimSetEntry, WaitingJournal."Dimension Set ID");
        Assert.AreEqual(TempDimSetEntry."Dimension Code", DimensionValue."Dimension Code", 'Did not find the correct dimension code');
        Assert.AreEqual(TempDimSetEntry."Dimension Value Code", DimensionValue.Code, 'Did not find the correct dimension value code');
    end;

    local procedure FindDimensionAndValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
    end;
}

