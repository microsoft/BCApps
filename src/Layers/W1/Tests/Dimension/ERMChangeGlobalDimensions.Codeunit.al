codeunit 134483 "ERM Change Global Dimensions"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Change Global Dimensions]
    end;

    var
        TempChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry" temporary;
        TempCounterLineNumberBuffer: Record "Line Number Buffer" temporary;
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryUtility: Codeunit "Library - Utility";
        DimIsUsedInGLSetupErr: Label 'The dimension %1 is used in General Ledger Setup window as a shortcut dimension.', Comment = '%1 - a dimension code, like PROJECT';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        FailOnModifyTAB134483: Boolean;
        CloseActiveSessionsMsg: Label 'Close all other active sessions.';
        CurrSessionIsActiveOnly: Boolean;
        TAB134483OnBeforeModifyErr: Label 'TAB134483.OnBeforeModify';
        InsertRecToEmptyTable134482: Boolean;
        UnexpectedTableErr: Label 'Unexpected table in the list: %1', Comment = '%1 - a number.';
        SessionUpdateRequiredMsg: Label 'All records were successfully updated. To apply the updates, close the General Ledger Setup page.';
        RemoveDim1FieldOnTAB134482: Boolean;
        RemoveDim2FieldOnTAB134482: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T100_ActionChangeGlobalDimOnGLSetupPageIsNotVisibleInBasicExp()
    var
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [UI]
        // LibraryLowerPermissions.SetOutsideO365Scope();  TODO: Uncomment this when fixing the test
        Initialize();
        // LibraryLowerPermissions.SetO365BusFull(); TODO: Uncomment this when fixing the test
        // [GIVEN] 'Basic' experience
        LibraryApplicationArea.EnableBasicSetup();
        // [WHEN] Open page "General Ledger Setup"
        GeneralLedgerSetupPage.OpenEdit();
        // [THEN] Action 'Change Global Dimensions' is not available
        asserterror GeneralLedgerSetupPage.ChangeGlobalDimensions.Invoke();
        Assert.ExpectedError('The action with ID = 2138997011 is not found on the page.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T101_ActionChangeGlobalDimOnGLSetupPageOpensPage577inEssentialExp()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();
        // [GIVEN] 'Suite' experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        // [GIVEN] Open page "General Ledger Setup"
        GeneralLedgerSetupPage.OpenEdit();
        // [WHEN] Run action "Change Global Dimensions"
        ChangeGlobalDimensionsPage.Trap();
        GeneralLedgerSetupPage.ChangeGlobalDimensions.Invoke();
        // [WHEN] "Parallel Processing" is set to 'Yes'
        ChangeGlobalDimensionsPage."Parallel Processing".SetValue(Format(true));
        // [THEN] Page 577 is open, where are visible, editable "Global Dimension 1 Code" and "Global Dimension 2 Code"
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 1 Code".Visible(), 'Global Dimension 1 Code should be visible');
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 2 Code".Visible(), 'Global Dimension 2 Code should be visible');
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 1 Code".Editable(), 'Global Dimension 1 Code should be editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 2 Code".Editable(), 'Global Dimension 2 Code should be editable');
        // [THEN] "Parallel Processing" is 'Yes', the control is visible and editable
        Assert.IsTrue(ChangeGlobalDimensionsPage."Parallel Processing".Editable(), 'Parallel Processing should be editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage."Parallel Processing".Visible(), 'Parallel Processing should be visible');
        ChangeGlobalDimensionsPage."Parallel Processing".AssertEquals(Format(true));
        // [THEN] Action "Prepare" is visible, but disabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Prepare.Visible(), 'Action Prepare should be visible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled');
        // [THEN] Action "Reset" is visible, but disabled
        Assert.IsFalse(ChangeGlobalDimensionsPage.Reset.Enabled(), 'Action Reset should be disabled');
        Assert.IsTrue(ChangeGlobalDimensionsPage.Reset.Visible(), 'Action Reset should be visible');
        // [THEN] Action "Start" is visible, but disabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Start.Visible(), 'Action Start should be visible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.Start.Enabled(), 'Action Start should be disabled');
        // [THEN] Part "Log Lines" is empty and not editable.
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.First(), 'Log Lines should be empty');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.Editable(), 'Log Lines should be not editable');
        // [THEN] "Table ID", "Table Name", "Total Records", "Progress", "Status", "Remaining Duration" are enabled, but not editable
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines."Table ID".Enabled(), 'Table ID column to be enabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines."Table ID".Editable(), 'Table ID column to be not editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines."Table Name".Enabled(), 'Table Name column to be enabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines."Table Name".Editable(), 'Table Name column to be not editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines."Total Records".Enabled(), 'Total Records column to be enabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines."Total Records".Editable(), 'Total Records column to be not editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.Progress.Enabled(), 'Progress column to be enabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.Progress.Editable(), 'Progress column to be not editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.Status.Enabled(), 'Status column to be enabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.Status.Editable(), 'Status column to be not editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines."Remaining Duration".Enabled(), 'Remaining Duration column to be enabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines."Remaining Duration".Editable(), 'Remaining Duration column to be not editable');
        ChangeGlobalDimensionsPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T105_ParallelProcessingDisabledByDefault()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Sequential Processing] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        ChangeGlobalDimHeader.DeleteAll();
        LibraryLowerPermissions.SetO365BusFull();
        LibraryLowerPermissions.AddO365GlobalDimMgt();
        // [WHEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();
        // [THEN] "Parallel Processing" is 'No'
        ChangeGlobalDimensionsPage."Parallel Processing".AssertEquals(Format(false));
        // [THEN] Action "Prepare" is visible, but disabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Prepare.Visible(), 'Action Prepare should be visible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled');
        // [THEN] Action "Reset" is visible, but disabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Reset.Visible(), 'Action Reset should be visible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.Reset.Enabled(), 'Action Reset should be disabled');
        // [THEN] Action "Start" (Parallel) is visible, but disabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Start.Visible(), 'Action Start(Parallel) should be visible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.Start.Enabled(), 'Action Start(Parallel) should be disabled');
        // [THEN] Action "Start" (Sequential) is visible, but disabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.StartSequential.Visible(), 'Action Start(Sequential) should be visible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.StartSequential.Enabled(), 'Action Start(Sequential) should be disabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T106_ActionSequentialStartUpdatesDimsIfAllTablesEmpty()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Sequential Processing] [UI]
        Initialize();
        // [GIVEN] Empty tables 134483, 134484, 134485 are in the list for change
        BindSubscription(ERMChangeGlobalDimensions);
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Detailed Entry With Global Dim");
        // [GIVEN] Open page "Change Global Dimensions" and
        ChangeGlobalDimensionsPage.OpenEdit();
        // [GIVEN] Swap "Global Dimension 1 Code" and "Global Dimension 2 Code"
        SwapGlobalDimsOnPage(ChangeGlobalDimensionsPage, DimensionValue);
        // [GIVEN] Action "Start" (Sequential) is visible and enabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.StartSequential.Visible(), 'Action Start(Sequential) should be visible');
        Assert.IsTrue(ChangeGlobalDimensionsPage.StartSequential.Enabled(), 'Action Start(Sequential) should be enabled');

        // [WHEN] Run Action "Start" (Sequential)
        ChangeGlobalDimensionsPage.StartSequential.Invoke();

        // [THEN] Correct message should appear after processing
        Assert.ExpectedMessage(SessionUpdateRequiredMsg, LibraryVariableStorage.DequeueText()); // from Message handler
        // [THEN] The list is empty
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
        // [THEN] Global Dimensions are updated in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        // [THEN] Action "Start" (Sequential) is visible, but disabled (as dimension codes are refreshed)
        Assert.IsFalse(ChangeGlobalDimensionsPage.StartSequential.Enabled(), 'Action Start (Sequential) should be disabled');
        Assert.IsTrue(ChangeGlobalDimensionsPage.StartSequential.Visible(), 'Action Start (Sequential) should be visible');
        // [THEN] gobal dimension codes are swapped and controls are editable
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 1 Code".Editable(), 'GlobalDimension1Code should be editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 2 Code".Editable(), 'GlobalDimension2Code should be editable');
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".AssertEquals(DimensionValue[2]."Dimension Code");
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".AssertEquals(DimensionValue[1]."Dimension Code");
        ChangeGlobalDimensionsPage."Old Global Dimension 1 Code".AssertEquals(DimensionValue[2]."Dimension Code");
        ChangeGlobalDimensionsPage."Old Global Dimension 2 Code".AssertEquals(DimensionValue[1]."Dimension Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T107_ActionSequentialStartRunsWholeProcess()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        JobTask: Record "Job Task";
        TableWithDefaultDim: Record "Table With Default Dim";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DtldEntryWithGlobalDim2: Record "Dtld. Entry With Global Dim 2";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Sequential Processing]
        Initialize();
        // [GIVEN] General Ledger Setup, where "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] Filled tables 134483, 134484, 134485, 134486 are in the list
        BindSubscription(ERMChangeGlobalDimensions);
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        TableWithDefaultDim.Insert();
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        TableWithDimensionSetID.Insert();
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Detailed Entry With Global Dim");
        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DetailedEntryWithGlobalDim.Insert();
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Dtld. Entry With Global Dim 2");
        DtldEntryWithGlobalDim2."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DtldEntryWithGlobalDim2.Insert();
        // [GIVEN] Empty table 1001 is in the list
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Job Task");
        JobTask.DeleteAll();

        // [GIVEN] Open page "Change Global Dimensions" and
        // [GIVEN] Swap "Global Dimension 1 Code" and "Global Dimension 2 Code"
        SwapGlobalDimensions(ChangeGlobalDimensions);

        // [WHEN] Run Action "Start" (Sequential)
        ChangeGlobalDimensions.StartSequential();

        // [THEN] The list is empty
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
        // [THEN] Global Dimensions are updated in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T108_SequentialStartDoesNotCommitTillEnd()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TableWithDefaultDim: Record "Table With Default Dim";
        DimensionValue: array[2] of Record "Dimension Value";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        Counter: Integer;
    begin
        // [FEATURE] [Sequential Processing] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] General Ledger Setup, where "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] 101 records in TAB134482 and
        TableWithDimensionSetID."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDimensionSetID."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDimensionSetID.Insert();
        for Counter := 1 to 100 do begin
            TableWithDimensionSetID."Entry No." := 0;
            TableWithDimensionSetID.Insert();
        end;
        // [GIVEN] 1 record in TAB134483, where "Global Dimension 1 Code" = 'A', "Shortcut Dimension 2 Code" = 'B'
        TableWithDefaultDim."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDefaultDim."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDefaultDim.Insert();
        // [GIVEN] TAB134482 and TAB134483 to be updated, but will fail on TAB134483
        BindSubscription(ERMChangeGlobalDimensions);
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");

        // [GIVEN] Swap "Global Dimension 1 Code" and "Global Dimension 2 Code"
        SwapGlobalDimensions(ChangeGlobalDimensions);
        Commit();
        // [GIVEN] Run Action "Start" (Sequential)
        ChangeGlobalDimensions.StartSequential();
        // [WHEN] Error happens in the end of the update
        asserterror Error(TAB134483OnBeforeModifyErr);

        // [THEN] Error message: 'TAB134483.OnBeforeModify'
        Assert.ExpectedError(TAB134483OnBeforeModifyErr);
        // [THEN] The list is empty
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
        // [THEN] Global Dimensions are NOT updated in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", DimensionValue[1]."Dimension Code");
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", DimensionValue[2]."Dimension Code");
        // [THEN] TableWithDefaultDim and TableWithDimensionSetID are not modified
        TableWithDimensionSetID.Find();
        TableWithDimensionSetID.TestField("Global Dimension 1 Code", DimensionValue[1].Code);
        TableWithDimensionSetID.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        TableWithDefaultDim.Find();
        TableWithDefaultDim.TestField("Global Dimension 1 Code", DimensionValue[1].Code);
        TableWithDefaultDim.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T109_SequentialStartCompleteEmptyTables()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        JobTask: Record "Job Task";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DtldEntryWithGlobalDim2: Record "Dtld. Entry With Global Dim 2";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Sequential Processing]
        Initialize();
        // [GIVEN] General Ledger Setup, where "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] Filled tables 134483, 134485, 134486 are in the list
        BindSubscription(ERMChangeGlobalDimensions);
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        TableWithDimensionSetID.Insert();
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Detailed Entry With Global Dim");
        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DetailedEntryWithGlobalDim.Insert();
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Dtld. Entry With Global Dim 2");
        DtldEntryWithGlobalDim2."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DtldEntryWithGlobalDim2.Insert();
        // [GIVEN] Empty table 134482 is in the list, but will get one record inserted during update
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        ERMChangeGlobalDimensions.SetInsertRecToEmptyTable();
        // [GIVEN] Empty table 1001 is in the list
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Job Task");
        JobTask.DeleteAll();

        // [GIVEN] Open page "Change Global Dimensions" and
        // [GIVEN] Swap "Global Dimension 1 Code" and "Global Dimension 2 Code"
        SwapGlobalDimensions(ChangeGlobalDimensions);

        // [WHEN] Run Action "Start" (Sequential)
        ChangeGlobalDimensions.StartSequential();

        // [THEN] Table 134482 is not empty
        Assert.TableIsNotEmpty(DATABASE::"Table With Default Dim");
        // [THEN] The list is empty
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
        // [THEN] Global Dimensions are updated in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T111_ActionPrepareFillsTableList()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Prepare] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryERMCountryData.InsertRecordsToProtectedTables();
        LibraryLowerPermissions.SetO365BusFull();
        LibraryLowerPermissions.AddO365GlobalDimMgt();
        // [GIVEN] Global Dimensions are set as 'A' and 'B'
        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimHeader.DeleteAll();
        ChangeGlobalDimensionsPage.OpenEdit();
        // [GIVEN] "Parallel Processing" set to 'Yes'
        ChangeGlobalDimensionsPage."Parallel Processing".SetValue(true);
        // [GIVEN] Set "Global Dimension 1 Code" = 'B', "Global Dimension 2 Code" = 'A'
        SwapGlobalDimsOnPage(ChangeGlobalDimensionsPage, DimensionValue);
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        BindSubscription(ERMChangeGlobalDimensions);
        // [WHEN] Run Action "Prepare"
        ChangeGlobalDimensionsPage.Prepare.Invoke();

        // [THEN] Part "Log Lines" gets filled by tables, both with default and global dimensions, and Table "Job Task"
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.FindFirstField("Table ID", DATABASE::"Job Task"), '1001');
        // [THEN] Action "Rerun" is disabled, as all lines in <blank> Status
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.Rerun.Enabled(), 'Action Rerun should be disabled');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.FindFirstField("Table ID", DATABASE::"Table With Default Dim"), '134482');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.FindFirstField("Table ID", DATABASE::"Table With Dimension Set ID"), '134483');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.FindFirstField("Table ID", DATABASE::"Table With Dim Flowfilter"), '134484');
        // [THEN] Action "Prepare" is disabled
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled.');
        // [THEN] Action "Reset" is visible and enabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Reset.Visible(), 'Action Reset should be visible.');
        Assert.IsTrue(ChangeGlobalDimensionsPage.Reset.Enabled(), 'Action Reset should be enabled.');
        // [THEN] Action "Start" (Parallle) is enabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Start.Enabled(), 'Action Start (Parallel) should be enabled.');
        // [THEN] Action "Start" (Sequential) is visible, but disabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.StartSequential.Visible(), 'Action Start(Sequential) should be visible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.StartSequential.Enabled(), 'Action Start(Sequential) should be disabled');
        // [THEN] G/L Setup is not changed, "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", DimensionValue[1]."Dimension Code");
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", DimensionValue[2]."Dimension Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T112_NewDimCodesAreRestoredOnPageReopen()
    var
        Dimension: array[2] of Record Dimension;
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Prepare] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] There is no other active session
        MockActiveSessions(0);
        // [GIVEN] Open page "Change Global Dimensions"
        LibraryLowerPermissions.SetO365BusFull();
        LibraryLowerPermissions.AddO365GlobalDimMgt();
        // [GIVEN] "Parallel Processing" is set to 'Yes'
        OpenPageForParalllelProcessing(ChangeGlobalDimensionsPage);
        // [GIVEN] Set new "Global Dimension 1 Code" and "Global Dimension 2 Code" of maximum length
        LibraryDimension.CreateDimension(Dimension[1]);
        Assert.AreEqual(MaxStrLen(Dimension[1].Code), StrLen(Dimension[1].Code), 'Dim1 code is not of maximum length');
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".SetValue(Dimension[1].Code);
        LibraryDimension.CreateDimension(Dimension[2]);
        Assert.AreEqual(MaxStrLen(Dimension[2].Code), StrLen(Dimension[2].Code), 'Dim2 code is not of maximum length');
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".SetValue(Dimension[2].Code);

        // [GIVEN] run Action "Prepare"
        ChangeGlobalDimensionsPage.Prepare.Invoke();
        // [GIVEN] Close the page
        ChangeGlobalDimensionsPage.Close();

        // [WHEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [THEN] The list is filled with lines of <blank> Status
        Assert.TableIsNotEmpty(DATABASE::"Change Global Dim. Log Entry");
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.First(), 'Should be lines.');
        Assert.AreNotEqual(0, ChangeGlobalDimensionsPage.LogLines."Table ID".AsInteger(), 'First line Table ID.');
        Assert.AreEqual(0, ChangeGlobalDimensionsPage.LogLines.Status.AsDecimal(), 'Status should be blank.');
        // [THEN] "Parallel Processing" is 'Yes'
        ChangeGlobalDimensionsPage."Parallel Processing".AssertEquals(Format(true));
        // [THEN] Action "Prepare" is disabled, action 'Reset' is visible
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled');
        Assert.IsTrue(ChangeGlobalDimensionsPage.Reset.Visible(), 'Action Reset should be visible');
        // [THEN] Global dimension codes set to new values and controls are not editable
        Assert.IsFalse(ChangeGlobalDimensionsPage."Global Dimension 1 Code".Editable(), 'GlobalDimension1Code should not be editable');
        Assert.IsFalse(ChangeGlobalDimensionsPage."Global Dimension 2 Code".Editable(), 'GlobalDimension1Code should not be editable');
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".AssertEquals(Dimension[1].Code);
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".AssertEquals(Dimension[2].Code);
    end;

    [Test]
    [HandlerFunctions('SendCloseSessionsNotificationHandlerWithActionClick,RecallCloseSessionsNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T113_ActionPrepareOpensSessionListPagefromNotification()
    var
        ActiveSession: Record "Active Session";
        ExperienceTierSetup: Record "Experience Tier Setup";
        DimensionValue: array[2] of Record "Dimension Value";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
        ConcurrentSessionListPage: TestPage "Concurrent Session List";
        ActiveSessionNo: Integer;
    begin
        // [FEATURE] [Prepare] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] There is another active session
        ActiveSessionNo := MockActiveSessions(1);
        // [GIVEN] Open page "Change Global Dimensions"
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        OpenPageForParalllelProcessing(ChangeGlobalDimensionsPage);
        // [GIVEN] Swap "Global Dimension 1 Code" and "Global Dimension 2 Code"
        SwapGlobalDimsOnPage(ChangeGlobalDimensionsPage, DimensionValue);

        // [WHEN] run Action "Prepare"
        ConcurrentSessionListPage.Trap();
        ChangeGlobalDimensionsPage.Prepare.Invoke();

        // [THEN] Notification is shown: "Close all other active sessions"
        Assert.ExpectedMessage(CloseActiveSessionsMsg, LibraryVariableStorage.DequeueText()); // from Notification handler
        // [THEN] "Concurrent Session List" page open on click on "Details" action
        // [THEN] There is the first line, where "Current Session" is 'No', "Client Type" is 'Background'
        ConcurrentSessionListPage.FindFirstField("Session ID", ActiveSessionNo);
        ConcurrentSessionListPage.CurrentSession.AssertEquals(Format(false));
        ConcurrentSessionListPage."Client Type".AssertEquals(ActiveSession."Client Type"::Background);
        ConcurrentSessionListPage.Next();
        // [THEN] The secont line, where "Current Session" is 'Yes', "User ID", "Client Computer Name" are shown.
        ConcurrentSessionListPage.FindFirstField("Session ID", SessionId());
        ConcurrentSessionListPage.CurrentSession.AssertEquals(Format(true));
        ConcurrentSessionListPage."Session ID".AssertEquals(SessionId());
        ConcurrentSessionListPage."User ID".AssertEquals(UserId);
        Assert.IsTrue(ConcurrentSessionListPage."Client Computer Name".Visible(), 'Client Computer Name is not visible.');
        Assert.IsFalse(ConcurrentSessionListPage.Next(), 'should be two sessions in the list.');
        ConcurrentSessionListPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T114_ActionPrepareUpdatesDimsIfAllTablesEmpty()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Prepare] [UI]
        // [SCENARIO 255725] Action "Prepare" updates dimensions and cleans up the list if no related records to update.
        Initialize();
        // [GIVEN] Current Session is active only
        BindSubscription(ERMChangeGlobalDimensions);
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        // [GIVEN] One empty table is in the list to update
        MockNullTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        // [GIVEN] Open page "Change Global Dimensions"
        LibraryLowerPermissions.SetO365BusFull();
        LibraryLowerPermissions.AddO365GlobalDimMgt();
        OpenPageForParalllelProcessing(ChangeGlobalDimensionsPage);
        // [GIVEN] Swap "Global Dimension 1 Code" and "Global Dimension 2 Code"
        SwapGlobalDimsOnPage(ChangeGlobalDimensionsPage, DimensionValue);
        // [WHEN] run Action "Prepare"
        ChangeGlobalDimensionsPage.Prepare.Invoke();

        // [THEN] The list is empty
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
        // [THEN] Global Dimensions are updated in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        // [THEN] Action "Prepare" is disabled, action 'Reset' is visible, but disabled
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled');
        Assert.IsTrue(ChangeGlobalDimensionsPage.Reset.Visible(), 'Action Reset should be visible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.Reset.Enabled(), 'Action Reset should not be enabled');
        // [THEN] gobal dimension codes are swapped and controls are editable
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 1 Code".Editable(), 'GlobalDimension1Code should be editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 2 Code".Editable(), 'GlobalDimension2Code should be editable');
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".AssertEquals(DimensionValue[2]."Dimension Code");
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".AssertEquals(DimensionValue[1]."Dimension Code");
        ChangeGlobalDimensionsPage."Old Global Dimension 1 Code".AssertEquals(DimensionValue[2]."Dimension Code");
        ChangeGlobalDimensionsPage."Old Global Dimension 2 Code".AssertEquals(DimensionValue[1]."Dimension Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T115_ActionPrepareDisabledIfDimCodesAreNotChanged()
    var
        Dimension: Record Dimension;
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
        OriginalDimCode: array[2] of Code[20];
    begin
        // [FEATURE] [Prepare] [UI]
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();
        // [GIVEN] Open page "Change Global Dimensions", where "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        OpenPageForParalllelProcessing(ChangeGlobalDimensionsPage);
        OriginalDimCode[1] := ChangeGlobalDimensionsPage."Global Dimension 1 Code".Value();
        OriginalDimCode[2] := ChangeGlobalDimensionsPage."Global Dimension 2 Code".Value();
        // [WHEN] Set "Global Dimension 1 Code" to 'X'
        LibraryDimension.CreateDimension(Dimension);
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".SetValue(Dimension.Code);
        // [THEN] Action "Prepare" is enabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be enabled (by Dim1).');
        // [THEN] Current Global Dimension Codes are 'A' and 'B', disabled
        Assert.IsFalse(ChangeGlobalDimensionsPage."Old Global Dimension 1 Code".Enabled(), 'CurrGlobalDimension1Code should be disabled');
        Assert.AreEqual(OriginalDimCode[1], ChangeGlobalDimensionsPage."Old Global Dimension 1 Code".Value, 'CurrGlobalDimension1Code');
        Assert.IsFalse(ChangeGlobalDimensionsPage."Old Global Dimension 2 Code".Enabled(), 'CurrGlobalDimension2Code should be disabled');
        Assert.AreEqual(OriginalDimCode[2], ChangeGlobalDimensionsPage."Old Global Dimension 2 Code".Value, 'CurrGlobalDimension2Code');

        // [WHEN] Set "Global Dimension 2 Code" to 'X'
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".SetValue(OriginalDimCode[1]);
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".SetValue(Dimension.Code);
        // [THEN] Action "Prepare" is enabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be enabled (by Dim2).');
        // [WHEN] Set "Global Dimension 1 Code" and "Global Dimension 2 Code" to 'A' and 'B'
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".SetValue(OriginalDimCode[1]);
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".SetValue(OriginalDimCode[2]);
        // [THEN] Action "Prepare" is disabled
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T116_ActionPrepareDisabledIfLogEntriesAreInNotBlankStatus()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: Record "Dimension Value";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Prepare] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        // [GIVEN] Log Entry record for table "Job Task", where Status = "Scheduled"
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Job Task";
        ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::Scheduled;
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry.Insert();
        // [GIVEN] Open page "Change Global Dimensions"
        LibraryLowerPermissions.SetO365BusFull();
        LibraryLowerPermissions.AddO365GlobalDimMgt();
        ChangeGlobalDimensionsPage.OpenEdit();
        // [WHEN] modify "Global Dimension 2 Code"
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".SetValue(DimensionValue."Dimension Code");

        // [THEN] Action "Prepare" is disabled, controls "Global Dimension 1/2 Code" are disabled
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage."Global Dimension 1 Code".Editable(), 'GlobalDimension1Code should be not editable');
        Assert.IsFalse(ChangeGlobalDimensionsPage."Global Dimension 2 Code".Editable(), 'GlobalDimension2Code should be not editable');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T117_ActionPrepareDisabledIfLogEntriesAreInBlankStatus()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        DimensionValue: Record "Dimension Value";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Prepare] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        ChangeGlobalDimHeader.DeleteAll();
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        // [GIVEN] Open page "Change Global Dimensions"
        LibraryLowerPermissions.SetO365BusFull();
        LibraryLowerPermissions.AddO365GlobalDimMgt();
        OpenPageForParalllelProcessing(ChangeGlobalDimensionsPage);
        // [GIVEN] modify "Global Dimension 1 Code"
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".SetValue(DimensionValue."Dimension Code");
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        BindSubscription(ERMChangeGlobalDimensions);

        // [WHEN] run Action "Prepare"
        ChangeGlobalDimensionsPage.Prepare.Invoke();

        // [THEN] Action "Prepare" is disabled, controls "Global Dimension 1/2 Code" are disabled
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage."Global Dimension 1 Code".Editable(), 'GlobalDimension1Code should be not editable');
        Assert.IsFalse(ChangeGlobalDimensionsPage."Global Dimension 2 Code".Editable(), 'GlobalDimension2Code should be not editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_ActionResetRemovesAllLinesRestoresDimCodes()
    var
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Reset] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Log lines are created by "Prepare" action
        MockPreparedLines(DATABASE::"Salesperson/Purchaser", DATABASE::"Cust. Ledger Entry");
        // [GIVEN] Open page "Change Global Dimensions"
        OpenPageForParalllelProcessing(ChangeGlobalDimensionsPage);
        Assert.IsTrue(ChangeGlobalDimensionsPage.Reset.Enabled(), 'Action Reset should be enabled initially');

        // [WHEN] Run action "Reset"
        ChangeGlobalDimensionsPage.Reset.Invoke();

        // [THEN] The table list is empty
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
        // [THEN] Action "Reset" is visible, but disabled, Action "Prepare" is enabled
        Assert.IsTrue(ChangeGlobalDimensionsPage.Reset.Visible(), 'Action Reset should be invisible');
        Assert.IsFalse(ChangeGlobalDimensionsPage.Reset.Enabled(), 'Action Reset should be disabled');
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled');
        // [THEN] New Dim codes are editable and equal to the current Dim codes
        Assert.AreEqual(
          ChangeGlobalDimensionsPage."Global Dimension 1 Code".Value,
          ChangeGlobalDimensionsPage."Old Global Dimension 1 Code".Value, 'GlobalDimension1Code');
        Assert.AreEqual(
          ChangeGlobalDimensionsPage."Global Dimension 2 Code".Value,
          ChangeGlobalDimensionsPage."Old Global Dimension 2 Code".Value, 'GlobalDimension2Code');
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 1 Code".Editable(), 'GlobalDimension1Code should be editable');
        Assert.IsTrue(ChangeGlobalDimensionsPage."Global Dimension 2 Code".Editable(), 'GlobalDimension2Code should be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_ActionResetUnbindsCOD484Subscription()
    var
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
    begin
        // [FEATURE] [Reset]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        ChangeGlobalDimensions.ResetState();
        // [GIVEN] Log lines are created by "Prepare" action
        MockPreparedLines(DATABASE::"Salesperson/Purchaser", DATABASE::"Cust. Ledger Entry");
        // [GIVEN] COD484 is subscribed on session start
        ChangeGlobalDimensions.RefreshHeader();

        // [WHEN] Run action "Reset"
        ChangeGlobalDimensions.ResetState();

        // [THEN] The table list is empty
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T130_ActionStartUpdatesGLSetupAndDimValues()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Start] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        ChangeGlobalDimensions.ResetState();
        // [GIVEN] Open page "Change Global Dimensions" and set "Parallel Processing" to 'Yes'
        OpenPageForParalllelProcessing(ChangeGlobalDimensionsPage);
        // [GIVEN] Global Dimensions are set as 'A' and 'B', swap "Global Dimension 1 Code" and "Global Dimension 2 Code" on the page
        SwapGlobalDimsOnPage(ChangeGlobalDimensionsPage, DimensionValue);
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        BindSubscription(ERMChangeGlobalDimensions);
        // [GIVEN] Action "Prepare" filled the list of tables
        ChangeGlobalDimensionsPage.Prepare.Invoke();

        // [WHEN] Run Action "Start"
        ChangeGlobalDimensionsPage.Start.Invoke();

        // [THEN] G/L Setup , where "Global Dimension 1 Code" = 'B', "Global Dimension 2 Code" = 'A'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        // [THEN] Dimension Values, where "Dimension Code" = 'A' have "Global Dimension No." = 2
        DimensionValue[1].Find();
        DimensionValue[1].TestField("Global Dimension No.", 2);
        // [THEN] Dimension Values, where "Dimension Code" = 'B' have "Global Dimension No." = 1
        DimensionValue[2].Find();
        DimensionValue[2].TestField("Global Dimension No.", 1);
        // [THEN] "Parallel Processing" is 'Yes'
        ChangeGlobalDimensionsPage."Parallel Processing".AssertEquals(Format(true));
        // [THEN] Action "Prepare" is disabled, Old Global Dimension Codes are equal to Global Dimension Codes
        Assert.IsFalse(ChangeGlobalDimensionsPage.Prepare.Enabled(), 'Action Prepare should be disabled.');
        Assert.AreEqual(
          ChangeGlobalDimensionsPage."Global Dimension 1 Code".Value,
          ChangeGlobalDimensionsPage."Old Global Dimension 1 Code".Value, 'OldGlobalDimension1Code <> GlobalDimension1Code');
        Assert.AreEqual(
          ChangeGlobalDimensionsPage."Global Dimension 2 Code".Value,
          ChangeGlobalDimensionsPage."Old Global Dimension 2 Code".Value, 'OldGlobalDimension2Code <> GlobalDimension2Code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T140_ActionRerunEnabledForIncompleteOrBlankJob()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ChangeGlobalDimLogEntry: array[5] of Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Rerun] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 'Suite' experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        // [GIVEN] 5 log entries in different statuses:
        // [GIVEN] Line for TAB21 is in <blank> status
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[1], DATABASE::"Cust. Ledger Entry", 0, 1);
        Clear(ChangeGlobalDimLogEntry[1]."Task ID");
        ChangeGlobalDimLogEntry[1].Status := ChangeGlobalDimLogEntry[3].Status::" ";
        ChangeGlobalDimLogEntry[1].Modify();
        // [GIVEN] Line for TAB25 is in "Scheduled" status
        BindSubscription(ERMChangeGlobalDimensions);
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Vendor Ledger Entry");
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[2], DATABASE::"Vendor Ledger Entry", 0, 1);
        // [GIVEN] Line for TAB1001 is in "In Progress" status
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[3], 1001, 0, 1);
        ChangeGlobalDimLogEntry[3]."Completed Records" := 1;
        ChangeGlobalDimLogEntry[3]."Server Instance ID" := ServiceInstanceId();
        ChangeGlobalDimLogEntry[3]."Session ID" := SessionId();
        ChangeGlobalDimLogEntry[3].Status := ChangeGlobalDimLogEntry[3].Status::"In Progress";
        ChangeGlobalDimLogEntry[3].Modify();
        // [GIVEN] Line for TAB134482 is in "Completed" status
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[4], 134482, 0, 1);
        MockCompletedLogEntry(ChangeGlobalDimLogEntry[4]);
        // [GIVEN] Line for TAB134483 is in "Incomplete" status
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[5], 134483, 0, 1);
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry[5]);
        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [WHEN] Going through all lines
        // [THEN] Actions "Rerun" and "Show Error" are enabled for TAB21, where is <blank> status
        ChangeGlobalDimensionsPage.LogLines.First();
        Assert.AreEqual(
          Format(ChangeGlobalDimLogEntry[1].Status::" "), Format(ChangeGlobalDimensionsPage.LogLines.Status), 'TAB21: Status');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.Rerun.Enabled(), 'TAB21: Rerun');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.ShowError.Enabled(), 'TAB21: ShowError');
        // [THEN] Actions "Rerun" and "Show Error" are enabled for TAB25, where is 'Scheduled' status
        ChangeGlobalDimensionsPage.LogLines.Next();
        Assert.AreEqual(
          Format(ChangeGlobalDimLogEntry[2].Status::Scheduled), Format(ChangeGlobalDimensionsPage.LogLines.Status), 'TAB25: Status');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.Rerun.Enabled(), 'TAB25: Rerun');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.ShowError.Enabled(), 'TAB25: ShowError');
        // [THEN] Actions "Rerun" and "Show Error" are disabled for TAB1001, where is 'In Progress' status
        ChangeGlobalDimensionsPage.LogLines.Next();
        Assert.AreEqual(
          Format(ChangeGlobalDimLogEntry[3].Status::"In Progress"), Format(ChangeGlobalDimensionsPage.LogLines.Status), 'TAB1001: Status');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.Rerun.Enabled(), 'TAB1001: Rerun');
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.ShowError.Enabled(), 'TAB1001: ShowError');
        // [THEN] Actions "Rerun" and "Show Error" are enabled for TAB134483, where is 'Incomplete' status
        ChangeGlobalDimensionsPage.LogLines.Next();
        Assert.AreEqual(
          Format(ChangeGlobalDimLogEntry[5].Status::Incomplete), Format(ChangeGlobalDimensionsPage.LogLines.Status), 'TAB134483: Status');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.Rerun.Enabled(), 'TAB134483: Rerun');
        Assert.IsTrue(ChangeGlobalDimensionsPage.LogLines.ShowError.Enabled(), 'TAB134483: ShowError');
        // [THEN] 'Completed' line is removed
        Assert.IsFalse(ChangeGlobalDimensionsPage.LogLines.Next(), 'There should be 4 lines');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T141_ActionRerunReschedulesIncompleteJob()
    var
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        xChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
        TaskID: Guid;
        CurrDT: DateTime;
    begin
        // [FEATURE] [Rerun] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 'Suite' experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        // [GIVEN] 2 records of table 134482
        TableWithDefaultDim."No." := '1';
        TableWithDefaultDim.Insert();
        TableWithDefaultDim."No." := '2';
        TableWithDefaultDim.Insert();
        // [GIVEN] Log Entry, where status is "Incomplete", "Completed records" = 1, "Total Records" = 2.
        ChangeGlobalDimLogEntry.DeleteAll();
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim", 0, 1);
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry);
        xChangeGlobalDimLogEntry := ChangeGlobalDimLogEntry;
        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [WHEN] run action "Rerun"
        BindSubscription(ERMChangeGlobalDimensions);
        TaskID := MockTaskScheduling(ERMChangeGlobalDimensions, ChangeGlobalDimLogEntry."Table ID");
        CurrDT := CurrentDateTime;
        ChangeGlobalDimensionsPage.LogLines.Rerun.Invoke();

        // [THEN] Log entry, where Status is "Scheduled", "Task ID" is new, "Completed records" = 1, "Total Records" = 2.
        ChangeGlobalDimLogEntry.Find();
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.TestField("Total Records", xChangeGlobalDimLogEntry."Total Records");
        ChangeGlobalDimLogEntry.TestField("Completed Records", xChangeGlobalDimLogEntry."Completed Records");
        ChangeGlobalDimLogEntry.TestField("Task ID", TaskID);
        // [THEN] "Earliest Start Date/Time" is delayed for 2 seconds
        Assert.AreEqual(
          2000, Round(ChangeGlobalDimLogEntry."Earliest Start Date/Time" - CurrDT, 1000), 'Earliest Start Date/Time shift');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T142_ActionRerunSchedulesBlankJob()
    var
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        xChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
        TaskID: Guid;
    begin
        // [FEATURE] [Rerun] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 'Suite' experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        // [GIVEN] 2 records of table 134482
        TableWithDefaultDim."No." := '1';
        TableWithDefaultDim.Insert();
        TableWithDefaultDim."No." := '2';
        TableWithDefaultDim.Insert();
        // [GIVEN] Log Entry for TAB134483, where status is in "Incomplete" status
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, DATABASE::"Table With Dimension Set ID", 0, 1);
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry);
        // [GIVEN] Log Entry, where status is in <blank> status, "Completed records" = 0, "Total Records" = 2.
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim", 0, 1);
        Clear(ChangeGlobalDimLogEntry."Task ID");
        ChangeGlobalDimLogEntry.UpdateStatus();
        ChangeGlobalDimLogEntry.Modify();
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::" ");
        xChangeGlobalDimLogEntry := ChangeGlobalDimLogEntry;
        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [WHEN] run action "Rerun" for table 134482
        BindSubscription(ERMChangeGlobalDimensions);
        TaskID := MockTaskScheduling(ERMChangeGlobalDimensions, ChangeGlobalDimLogEntry."Table ID");
        ChangeGlobalDimensionsPage.LogLines.Rerun.Invoke();

        // [THEN] Log entry, where Status is "Scheduled", "Task ID" is new, "Completed records" = 0, "Total Records" = 2.
        ChangeGlobalDimLogEntry.Find();
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.TestField("Total Records", xChangeGlobalDimLogEntry."Total Records");
        ChangeGlobalDimLogEntry.TestField("Completed Records", 0);
        ChangeGlobalDimLogEntry.TestField("Task ID", TaskID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T143_ActionRerunReschedulesScheduledJob()
    var
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
        TaskID: Guid;
        CurrDT: DateTime;
    begin
        // [FEATURE] [Rerun] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 'Suite' experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        // [GIVEN] 2 records of table 134482
        TableWithDefaultDim."No." := '1';
        TableWithDefaultDim.Insert();
        TableWithDefaultDim."No." := '2';
        TableWithDefaultDim.Insert();
        // [GIVEN] Log Entry, where status is in 'Scheduled' status, "Completed records" = 0, "Total Records" = 2.
        BindSubscription(ERMChangeGlobalDimensions);
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim", 0, 1);
        ChangeGlobalDimLogEntry.UpdateStatus();
        ChangeGlobalDimLogEntry."Earliest Start Date/Time" := CreateDateTime(Today, Time - 10000);
        ChangeGlobalDimLogEntry.Modify();
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [WHEN] run action "Rerun" for table 134482
        TaskID := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        CurrDT := CurrentDateTime;
        ChangeGlobalDimensionsPage.LogLines.Rerun.Invoke();

        // [THEN] Log entry, where Status is "Scheduled", "Task ID" is new
        ChangeGlobalDimLogEntry.Find();
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.TestField("Task ID", TaskID);
        // [THEN] "Earliest Start Date/Time" is delayed for 2 seconds
        Assert.AreEqual(
          2000, Round(ChangeGlobalDimLogEntry."Earliest Start Date/Time" - CurrDT, 1000), 'Earliest Start Date/Time shift');
    end;

    [Test]
    [HandlerFunctions('JobQueueLogEntriesModalHandler')]
    [Scope('OnPrem')]
    procedure T150_ActionShowErrorOpensJobQueueLogEntriesByTaskID()
    var
        JobQueueLogEntry: array[3] of Record "Job Queue Log Entry";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Error] [UI]
        // [SCENARIO] "Show Error" shows Job Queue Log Entry, where ID is equal to non-null "Task ID"
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 'Suite' experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        // [GIVEN] 2 records of table 134482
        TableWithDefaultDim."No." := '1';
        TableWithDefaultDim.Insert();
        TableWithDefaultDim."No." := '2';
        TableWithDefaultDim.Insert();
        // [GIVEN] Log Entry, where status is "Incomplete", "Task ID" = 'X'.
        ChangeGlobalDimLogEntry.DeleteAll();
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim", 0, 1);
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry);
        // [GIVEN] Job Queue Log Entry 'A', where "Object ID to Run" = 485, "Status" = 'Error', "Description" = 'Table X', "ID" = 'X'
        // [GIVEN] Job Queue Log Entry 'B', where "Object ID to Run" = 485, "Status" = 'Success', "Description" = 'Table Name', "ID" = 'X'
        // [GIVEN] Job Queue Log Entry 'C', where "Object ID to Run" = 485, "Status" = 'Error', "Description" = 'Table Name', "ID" = 'Y'
        MockJobQueueLogEntries(JobQueueLogEntry, ChangeGlobalDimLogEntry);

        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [WHEN] run action "Show Error"
        ChangeGlobalDimensionsPage.LogLines.ShowError.Invoke();

        // [THEN] Page "Job Queue Log Entres" shows entry 'A'.
        Assert.AreEqual('Table X', LibraryVariableStorage.DequeueText(), 'Description'); // from JobQueueLogEntriesModalHandler
    end;

    [Test]
    [HandlerFunctions('JobQueueLogEntriesModalHandler')]
    [Scope('OnPrem')]
    procedure T151_ActionShowErrorOpensJobQueueLogEntriesByTableName()
    var
        JobQueueLogEntry: array[3] of Record "Job Queue Log Entry";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Error] [UI]
        // [SCENARIO] "Show Error" shows Job Queue Log Entry, where "Description" contains the table name.
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 'Suite' experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        // [GIVEN] 2 records of table 134482
        TableWithDefaultDim."No." := '1';
        TableWithDefaultDim.Insert();
        TableWithDefaultDim."No." := '2';
        TableWithDefaultDim.Insert();
        // [GIVEN] Log Entry, where status is "Incomplete", "Task ID" = <null>.
        ChangeGlobalDimLogEntry.DeleteAll();
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim", 0, 1);
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry);
        Clear(ChangeGlobalDimLogEntry."Task ID");
        ChangeGlobalDimLogEntry.Modify();
        // [GIVEN] Job Queue Log Entry 'A', where "Object ID to Run" = 485, "Status" = 'Error', "Description" = 'Table X', "ID" = 'X'
        // [GIVEN] Job Queue Log Entry 'B', where "Object ID to Run" = 485, "Status" = 'Success', "Description" = 'Table Name', "ID" = 'X'
        // [GIVEN] Job Queue Log Entry 'C', where "Object ID to Run" = 485, "Status" = 'Error', "Description" = 'Table Name', "ID" = 'Y'
        MockJobQueueLogEntries(JobQueueLogEntry, ChangeGlobalDimLogEntry);

        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [WHEN] run action "Show Error"
        ChangeGlobalDimensionsPage.LogLines.ShowError.Invoke();

        // [THEN] Page "Job Queue Log Entres" shows entry 'C'.
        Assert.AreEqual(ChangeGlobalDimLogEntry."Table Name", LibraryVariableStorage.DequeueText(), 'Description'); // from JobQueueLogEntriesModalHandler
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T155_ErrorHandlerCreatesJobQueueLogEntry()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Error] [UT]
        Initialize();
        // [GIVEN] Job is failed with the error message: 'Err'
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        ClearLastError();
        asserterror Error(ExpectedErrorMsg);
        // [GIVEN] ChangeGlobalDimLogEntry is in progress, where "Task ID" = 'X', "Table Name" = 'T'
        ChangeGlobalDimLogEntry.DeleteAll();
        ChangeGlobalDimLogEntry.Init();
        ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::"In Progress";
        ChangeGlobalDimLogEntry."Completed Records" := 0;
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"G/L Entry";
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Table Name" := LibraryUtility.GenerateGUID();
        ChangeGlobalDimLogEntry.Insert();

        // [WHEN] Run "Change Global Dim Err. Handler" for ChangeGlobalDimLogEntry
        CODEUNIT.Run(CODEUNIT::"Change Global Dim Err. Handler", ChangeGlobalDimLogEntry);

        // [THEN] ChangeGlobalDimLogEntry got Status 'Incomplete'
        ChangeGlobalDimLogEntry.Find();
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Incomplete);

        // [THEN] Job Queue Log Entry, where "Object ID to Run" = 483, "ID" = 'X', "Status" = 'Error', "Error Message" = 'Err', Description = 'T'
        Assert.IsTrue(JobQueueLogEntry.FindLast(), 'not inserted JobQueueLogEntry');
        JobQueueLogEntry.TestField(ID, ChangeGlobalDimLogEntry."Task ID");
        JobQueueLogEntry.TestField("Object Type to Run", JobQueueLogEntry."Object Type to Run"::Codeunit);
        JobQueueLogEntry.TestField("Object ID to Run", CODEUNIT::"Change Global Dimensions");
        JobQueueLogEntry.TestField(Status, JobQueueLogEntry.Status::Error);
        JobQueueLogEntry.TestField(Description, ChangeGlobalDimLogEntry."Table Name");
        Assert.AreEqual(ExpectedErrorMsg, JobQueueLogEntry."Error Message", 'Error message');
        // [THEN] "Start Date/Time" and "End Date/Time" are equal, "User ID" is the current user id.
        JobQueueLogEntry.TestField("Start Date/Time");
        JobQueueLogEntry.TestField("End Date/Time", JobQueueLogEntry."Start Date/Time");
        JobQueueLogEntry.TestField("User ID", UserId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T160_GlobalDimCodeControlIsFilledFromGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: array[2] of Record "Dimension Value";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] GLSetup, where "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);

        // [WHEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [THEN] Page is open, where "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        GeneralLedgerSetup.Get();
        Assert.AreEqual(
          GeneralLedgerSetup."Global Dimension 1 Code",
          ChangeGlobalDimensionsPage."Global Dimension 1 Code".Value, 'Global Dimension 1 Code');
        Assert.AreEqual(
          GeneralLedgerSetup."Global Dimension 2 Code",
          ChangeGlobalDimensionsPage."Global Dimension 2 Code".Value, 'Global Dimension 2 Code');
    end;

    [Test]
    [HandlerFunctions('DimListModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T161_GlobalDimCode1EqualToDim2BlanksDim2()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Open page "Change Global Dimensions", where "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [WHEN] Set "Global Dimension 1 Code" to 'B'
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".SetValue(DimensionValue[2]."Dimension Code");

        // [THEN] "Global Dimension 1 Code" = 'B', "Global Dimension 2 Code" = <blank>
        Assert.AreEqual(
          DimensionValue[2]."Dimension Code", ChangeGlobalDimensionsPage."Global Dimension 1 Code".Value, 'Global Dimension 1 Code');
        Assert.AreEqual(
          '', ChangeGlobalDimensionsPage."Global Dimension 2 Code".Value, 'Global Dimension 2 Code');
        // [THEN] Lookup on "Global Dimension 1 Code" opens page "Dimension List"
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".Lookup(); // handled by DimListModalHandler
    end;

    [Test]
    [HandlerFunctions('DimListModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T162_GlobalDimCode2EqualToDim1BlanksDim1()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Open page "Change Global Dimensions", where "Global Dimension 1 Code" = 'A', "Global Dimension 2 Code" = 'B'
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [WHEN] Set "Global Dimension 2 Code" to 'A'
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".SetValue(DimensionValue[1]."Dimension Code");

        // [THEN] "Global Dimension 1 Code" = <blank>, "Global Dimension 2 Code" = 'A'
        Assert.AreEqual(
          '', ChangeGlobalDimensionsPage."Global Dimension 1 Code".Value, 'Global Dimension 1 Code');
        Assert.AreEqual(
          DimensionValue[1]."Dimension Code", ChangeGlobalDimensionsPage."Global Dimension 2 Code".Value, 'Global Dimension 2 Code');
        // [THEN] Lookup on "Global Dimension 2 Code" opens page "Dimension List"
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".Lookup(); // handled by DimListModalHandler
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T170_ShortcutDimCannotBeSetAsGlobalDim()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: array[3] of Record "Dimension Value";
    begin
        // [FEATURE] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Dimensions 'A' and 'B' are global
        CreateDimSet(DimensionValue);
        // [GIVEN] Dimension 'C' is "Shortcut Dimension 3 Code"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Shortcut Dimension 3 Code" := DimensionValue[3]."Dimension Code";
        GeneralLedgerSetup.Modify();
        ChangeGlobalDimHeader.Insert();
        ChangeGlobalDimHeader.Refresh();

        // [WHEN] Set 'C' as a global dimension 1
        asserterror ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", DimensionValue[3]."Dimension Code");
        // [THEN] Error message: "Shortcut Cannot Be Global Dim"
        Assert.ExpectedError(StrSubstNo(DimIsUsedInGLSetupErr, DimensionValue[3]."Dimension Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T200_COD408DefaultDimObjectNoListCollectsAllTablesWithDefaultDims()
    var
        AllObj: Record AllObj;
        TempAllObjWithCaptionByCOD408: Record AllObjWithCaption temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        // [FEATURE] [Default Dimension]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Table 134482 mocks a table with default dimension
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Default Dim");
        // [GIVEN] Table 134483 mocks a table with "Dimension Set Id"
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Dimension Set ID");
        // [GIVEN] Table 134484 mocks a table with dimension fields flowfilters
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Dim Flowfilter");
        // [GIVEN] Table 134485 mocks a dependent table with dimension fields
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Detailed Entry With Global Dim");
        // [GIVEN] Table 134486 mocks the second dependent table with dimension fields
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Dtld. Entry With Global Dim 2");

        // [WHEN] COD408.DefaultDimObjectNoWithGlobalDimsList() returns a list of tables 'A'
        DimensionManagement.DefaultDimObjectNoWithGlobalDimsList(TempAllObjWithCaptionByCOD408);
        // [THEN] The list 'A' contains 134482, but not 134483, 134484, 134485, 134486.
        // [THEN] The list 'A' does not contain: 349, 379, 380, 397, 5223, 8383.
        // [THEN] The list 'A' does not contain exceptions: 98, 1001.
        Assert.IsTrue(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Table With Default Dim"), '134482');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Table With Dimension Set ID"), '134483');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Table With Dim Flowfilter"), '134484');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Detailed Entry With Global Dim"), '134485');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Dtld. Entry With Global Dim 2"), '134486');
        // Exceptions in W1
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Dimension Value"), '349');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Detailed Cust. Ledg. Entry"), '379');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Detailed Vendor Ledg. Entry"), '380');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Detailed Employee Ledger Entry"), '5223');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Dimensions Field Map"), '8383');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"General Ledger Setup"), '98');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Job Task"), '1001');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Change Global Dim. Header"), '484');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T201_COD408GlobalDimObjectNoListCollectsAllTablesWithDimSetIDAndDependentTables()
    var
        AllObj: Record AllObj;
        TempAllObjWithCaptionByCOD408: Record AllObjWithCaption temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        // [FEATURE] [Parent Table]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Table 134482 mocks a table with default dimension
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Default Dim");
        // [GIVEN] Table 134483 mocks a table with "Dimension Set Id"
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Dimension Set ID");
        // [GIVEN] Table 134484 mocks a table with dimension fields flowfilters
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Dim Flowfilter");
        // [GIVEN] Table 134485 mocks a dependent table with dimension fields
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Detailed Entry With Global Dim");
        // [GIVEN] Table 134486 mocks the second dependent table with dimension fields
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Dtld. Entry With Global Dim 2");

        // [WHEN] COD408.GlobalDimObjectNoList() returns a list of tables 'A'
        DimensionManagement.GlobalDimObjectNoList(TempAllObjWithCaptionByCOD408);
        // [THEN] The list 'A' contains 134483, 134485 and 134486, but not 134482 nor 134484
        // [THEN] The list 'A' does contain: 379, 380, 5223.
        // [THEN] The list 'A' does not contain exceptions: 98, 1001.
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Table With Default Dim"), '134482');
        Assert.IsTrue(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Table With Dimension Set ID"), '134483');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Table With Dim Flowfilter"), '134484');
        Assert.IsTrue(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Detailed Entry With Global Dim"), '134485');
        Assert.IsTrue(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Dtld. Entry With Global Dim 2"), '134486');
        // Dependent tables
        Assert.IsTrue(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Detailed Cust. Ledg. Entry"), '379');
        Assert.IsTrue(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Detailed Vendor Ledg. Entry"), '380');
        Assert.IsTrue(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Detailed Employee Ledger Entry"), '5223');

        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"General Ledger Setup"), '98');
        Assert.IsFalse(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Job Task"), '1001');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T202_COD408JobTaskDimObjectNoListCollectsJobTaskTable()
    var
        TempAllObjWithCaptionByCOD408: Record AllObjWithCaption temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        // [FEATURE] [Job Task]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [WHEN] COD408.JobTaskDimObjectNoList() returns a list of tables
        DimensionManagement.JobTaskDimObjectNoList(TempAllObjWithCaptionByCOD408);
        // [THEN] The list contains one table "Job Task"
        Assert.IsTrue(TempAllObjWithCaptionByCOD408.Get(TempAllObjWithCaptionByCOD408."Object Type"::Table, DATABASE::"Job Task"), '1001');
        Assert.AreEqual(1, TempAllObjWithCaptionByCOD408.Count, 'total count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T203_ListOfTablesIncludesAllTablesWithGlobalAndDefaultDimFields()
    var
        AllObj: Record AllObj;
        JobTask: Record "Job Task";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDefaultDim: Record "Table With Default Dim";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        I: Integer;
    begin
        // [FEATURE] [Log]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Table 134482 mocks a table with default dimension, COUNT = 1
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Default Dim");
        TableWithDefaultDim."No." := '1';
        TableWithDefaultDim.Insert();
        // [GIVEN] Table 134483 mocks a table with "Dimension Set Id", COUNT = 2
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Dimension Set ID");
        TableWithDimensionSetID."Entry No." := 1;
        TableWithDimensionSetID.Insert();
        TableWithDimensionSetID."Entry No." := 2;
        TableWithDimensionSetID.Insert();
        // [GIVEN] Table 134484 mocks a table with dimension fields flowfilters
        AllObj.Get(AllObj."Object Type"::Table, DATABASE::"Table With Dim Flowfilter");
        // [GIVEN] Table "Job Task" contains 3 records
        JobTask.DeleteAll();
        for I := 1 to 3 do begin
            JobTask."Job Task No." := Format(I);
            JobTask.Insert();
        end;
        // [WHEN] run InitTableList()
        ChangeGlobalDimensions.InitTableList();
        // [THEN] The list contains tables 1001, 134482, 134483, but not 134484
        Assert.IsTrue(ChangeGlobalDimLogEntry.Get(DATABASE::"Job Task"), 'Table 1001 is not found');
        ChangeGlobalDimLogEntry.TestField("Total Records", 3);
        Assert.IsTrue(ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Default Dim"), 'Table 134482 is not found');
        ChangeGlobalDimLogEntry.TestField("Total Records", 1);
        ChangeGlobalDimLogEntry.TestField("Dim. Set ID Field No.", 0);
        ChangeGlobalDimLogEntry.TestField("Primary Key Field No.", 1);
        Assert.IsTrue(ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID"), 'Table 134483 is not found');
        ChangeGlobalDimLogEntry.TestField("Total Records", 2);
        ChangeGlobalDimLogEntry.TestField("Dim. Set ID Field No.", TableWithDimensionSetID.FieldNo("Dimension Set ID"));
        ChangeGlobalDimLogEntry.TestField("Primary Key Field No.", 0);
        Assert.IsFalse(ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dim Flowfilter"), 'Table 134484 is found');
        // [THEN] There are dependent tables in the list
        ChangeGlobalDimLogEntry.SetFilter("Table ID", '>0');
        ChangeGlobalDimLogEntry.SetFilter("Parent Table ID", '>0');
        Assert.AreNotEqual(0, ChangeGlobalDimLogEntry.Count, 'total count of dependent tables');
        // [THEN] All global dim tables are in the list
        ChangeGlobalDimLogEntry.SetRange("Parent Table ID");
        CountGlobalDimTables(ChangeGlobalDimLogEntry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T205_TablesAreSortedByProgress()
    var
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Log] [Progress] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        // [GIVEN] Log entries for tables with different progress: 13 - 100%, 15 - 100%, 21 - 50%, 25 - 10%,
        MockLogEntryWithProgress(DATABASE::"Salesperson/Purchaser", 10000);
        MockLogEntryWithProgress(DATABASE::"G/L Account", 10000);
        MockLogEntryWithProgress(DATABASE::"Cust. Ledger Entry", 5000);
        MockLogEntryWithProgress(DATABASE::"Vendor Ledger Entry", 1000);

        // [WHEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenView();

        // [THEN] lines are sorted by "Progress", then by "Table ID": 25, 21, 13, 15
        Assert.AreEqual(25, ChangeGlobalDimensionsPage.LogLines."Table ID".AsDecimal(), '1st');
        ChangeGlobalDimensionsPage.LogLines.Next();
        Assert.AreEqual(21, ChangeGlobalDimensionsPage.LogLines."Table ID".AsDecimal(), '2nd');
        ChangeGlobalDimensionsPage.LogLines.Next();
        Assert.AreEqual(13, ChangeGlobalDimensionsPage.LogLines."Table ID".AsDecimal(), '3rd');
        ChangeGlobalDimensionsPage.LogLines.Next();
        Assert.AreEqual(15, ChangeGlobalDimensionsPage.LogLines."Table ID".AsDecimal(), '4th');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T210_CalcProgressFor0of0()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Log] [Progress] [UT]
        ChangeGlobalDimLogEntry."Total Records" := 0;
        ChangeGlobalDimLogEntry.Validate("Completed Records", 0);
        Assert.AreEqual(10000, ChangeGlobalDimLogEntry.Progress, '0 of 0 should give 100%');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T211_CalcProgressFor0of100()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Log] [Progress] [UT]
        ChangeGlobalDimLogEntry."Total Records" := 100;
        ChangeGlobalDimLogEntry.Validate("Completed Records", 0);
        Assert.AreEqual(0, ChangeGlobalDimLogEntry.Progress, '0 of 100 should give 0%');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T212_CalcProgressFor100of100()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Log] [Progress] [UT]
        ChangeGlobalDimLogEntry."Total Records" := 100;
        ChangeGlobalDimLogEntry.Validate("Completed Records", 100);
        Assert.AreEqual(10000, ChangeGlobalDimLogEntry.Progress, '100 of 100 should give 100%');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T213_CalcProgressFor101of100()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Log] [Progress] [UT]
        ChangeGlobalDimLogEntry."Total Records" := 100;
        ChangeGlobalDimLogEntry.Validate("Completed Records", 101);
        Assert.AreEqual(10000, ChangeGlobalDimLogEntry.Progress, '101 of 100 should give 100%');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T215_CountRecordsOnLogEntryInsert()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        JobTask: Record "Job Task";
    begin
        // [FEATURE] [Log] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        ChangeGlobalDimLogEntry.DeleteAll();
        // [GIVEN] zero records in table 1001
        JobTask.DeleteAll();
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Job Task";
        // [WHEN] Insert LogEntry for table 1001
        InsertChangeGlobalDimLogEntry(ChangeGlobalDimLogEntry);
        // [THEN] "Total Records" = 0
        ChangeGlobalDimLogEntry.TestField("Total Records", 0);

        // [GIVEN] 1 record in table 1001
        ChangeGlobalDimLogEntry.DeleteAll();
        JobTask.Insert();
        // [WHEN] Insert LogEntry for table 1001
        InsertChangeGlobalDimLogEntry(ChangeGlobalDimLogEntry);
        // [THEN] "Total Records" = 1
        ChangeGlobalDimLogEntry.TestField("Total Records", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T216_FillFieldNumbersForDefaultDimTable()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDefaultDim: Record "Table With Default Dim";
    begin
        // [FEATURE] [Log] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Table With Default Dim";
        InsertChangeGlobalDimLogEntry(ChangeGlobalDimLogEntry);
        ChangeGlobalDimLogEntry.TestField("Global Dim.1 Field No.", TableWithDefaultDim.FieldNo("Global Dimension 1 Code"));
        ChangeGlobalDimLogEntry.TestField("Global Dim.2 Field No.", TableWithDefaultDim.FieldNo("Shortcut Dimension 2 Code"));
        ChangeGlobalDimLogEntry.TestField("Dim. Set ID Field No.", 0);
        ChangeGlobalDimLogEntry.TestField("Primary Key Field No.", TableWithDefaultDim.FieldNo("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T217_FillFieldNumbersForGlobalDimTable()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
    begin
        // [FEATURE] [Log] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Table With Dimension Set ID";
        InsertChangeGlobalDimLogEntry(ChangeGlobalDimLogEntry);
        ChangeGlobalDimLogEntry.TestField("Global Dim.1 Field No.", TableWithDimensionSetID.FieldNo("Global Dimension 1 Code"));
        ChangeGlobalDimLogEntry.TestField("Global Dim.2 Field No.", TableWithDimensionSetID.FieldNo("Shortcut Dimension 2 Code"));
        ChangeGlobalDimLogEntry.TestField("Dim. Set ID Field No.", TableWithDimensionSetID.FieldNo("Dimension Set ID"));
        ChangeGlobalDimLogEntry.TestField("Primary Key Field No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T218_FillFieldNumbersForFlowfieldDimTable()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimFlowfilter: Record "Table With Dim Flowfilter";
    begin
        // [FEATURE] [Log] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Table With Dim Flowfilter";
        InsertChangeGlobalDimLogEntry(ChangeGlobalDimLogEntry);
        ChangeGlobalDimLogEntry.TestField("Global Dim.1 Field No.", 0);
        ChangeGlobalDimLogEntry.TestField("Global Dim.2 Field No.", 0);
        ChangeGlobalDimLogEntry.TestField("Dim. Set ID Field No.", TableWithDimFlowfilter.FieldNo("Dimension Set ID"));
        ChangeGlobalDimLogEntry.TestField("Primary Key Field No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T250_RunTaskCommitsStatusChangeBeforeExecutingDataUpdate()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Log] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 1 record in TAB134483
        TableWithDimensionSetID.Insert();
        // [GIVEN] The Log line for TAB134483, where "Status" is "Scheduled", "Session ID" is 0, "Total Records" = 1
        BindSubscription(ERMChangeGlobalDimensions);
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, DATABASE::"Table With Dimension Set ID", 0, 1);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.TestField("Total Records", 1);
        ChangeGlobalDimLogEntry.TestField("Session ID", 0);

        // [WHEN] run RunTask() but fail on TAB134483 update
        ERMChangeGlobalDimensions.SetFailOnModifyTAB134483();
        asserterror RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Error message: 'TAB134483.OnBeforeModify'
        Assert.ExpectedError(TAB134483OnBeforeModifyErr);
        // [THEN] The log line is updated: "Status" is "In Progress", "Session ID" is filled, "Total Records" = 1
        ChangeGlobalDimLogEntry.Find();
        ChangeGlobalDimLogEntry.TestField("Total Records", 1);
        ChangeGlobalDimLogEntry.TestField("Session ID");
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::"In Progress");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T300_ChangeWithTypeNoneDoesNothing()
    var
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Global Dim codes are not changed
        ChangeGlobalDimensions.RefreshHeader();
        // [WHEN] Run Prepare() and Start()
        ChangeGlobalDimensions.Prepare();
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Table "Change Global Dim. Log Entry" is still empty
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T301_BlankGlobalDim1ChangeTypeBlankNone()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[2] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ExpectedTaskID: array[2] of Guid;
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] Tables "Table With Default Dim" and "Table With Dimension Set ID" are not empty
        TableWithDefaultDim.Insert();
        TableWithDimensionSetID.Insert();
        // [GIVEN] "Global Dimension 1 Code" is set to <blank>
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", '');
        ChangeGlobalDimHeader.Modify();
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        // [GIVEN] Run Prepare()
        BindSubscription(ERMChangeGlobalDimensions);
        ExpectedTaskID[1] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        ExpectedTaskID[2] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start()
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Log entries got "Task ID" values, "Change Type 1" is 'Blank',"Change Type 2" is 'None', "Status" is 'Scheduled'
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Default Dim");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[1]);
        ChangeGlobalDimLogEntry.TestField("Change Type 1", ChangeGlobalDimLogEntry."Change Type 1"::Blank);
        ChangeGlobalDimLogEntry.TestField("Change Type 2", ChangeGlobalDimLogEntry."Change Type 2"::None);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[2]);
        ChangeGlobalDimLogEntry.TestField("Change Type 1", ChangeGlobalDimLogEntry."Change Type 1"::Blank);
        ChangeGlobalDimLogEntry.TestField("Change Type 2", ChangeGlobalDimLogEntry."Change Type 2"::None);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T302_ReplaceGlobalDim2ChangeTypeBlankReplace()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[2] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ExpectedTaskID: array[2] of Guid;
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] Tables "Table With Default Dim" and "Table With Dimension Set ID" are not empty
        TableWithDefaultDim.Insert();
        TableWithDimensionSetID.Insert();
        // [GIVEN] "Global Dimension 2 Code" is set to "Global Dimension 1 Code"
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        ChangeGlobalDimHeader.Modify();

        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        // [GIVEN] Run Prepare()
        BindSubscription(ERMChangeGlobalDimensions);
        ExpectedTaskID[1] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        ExpectedTaskID[2] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start()
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Log entries got "Task ID" values, "Change Type 1" is 'Blank',"Change Type 2" is 'Replace', "Status" is 'Scheduled'
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Default Dim");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[1]);
        ChangeGlobalDimLogEntry.TestField("Change Type 1", ChangeGlobalDimLogEntry."Change Type 1"::Blank);
        ChangeGlobalDimLogEntry.TestField("Change Type 2", ChangeGlobalDimLogEntry."Change Type 2"::Replace);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[2]);
        ChangeGlobalDimLogEntry.TestField("Change Type 1", ChangeGlobalDimLogEntry."Change Type 1"::Blank);
        ChangeGlobalDimLogEntry.TestField("Change Type 2", ChangeGlobalDimLogEntry."Change Type 2"::Replace);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T303_BlankBothGlobalDimsChangeTypeBlankBlank()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[2] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ExpectedTaskID: array[2] of Guid;
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] Tables "Table With Default Dim" and "Table With Dimension Set ID" are not empty
        TableWithDefaultDim.Insert();
        TableWithDimensionSetID.Insert();
        // [GIVEN] "Global Dimension 1 Code" and "Global Dimension 2 Code" are both set to <blank>
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", '');
        ChangeGlobalDimHeader.Validate("Global Dimension 2 Code", '');
        ChangeGlobalDimHeader.Modify();

        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        // [GIVEN] Run Prepare()
        BindSubscription(ERMChangeGlobalDimensions);
        ExpectedTaskID[1] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        ExpectedTaskID[2] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start()
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Log entries got "Task ID" values and "Change Type 1" and "Change Type 2" are 'Blank'
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Default Dim");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[1]);
        ChangeGlobalDimLogEntry.TestField("Change Type 1", ChangeGlobalDimLogEntry."Change Type 1"::Blank);
        ChangeGlobalDimLogEntry.TestField("Change Type 2", ChangeGlobalDimLogEntry."Change Type 2"::Blank);
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[2]);
        ChangeGlobalDimLogEntry.TestField("Change Type 1", ChangeGlobalDimLogEntry."Change Type 1"::Blank);
        ChangeGlobalDimLogEntry.TestField("Change Type 2", ChangeGlobalDimLogEntry."Change Type 2"::Blank);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T304_SwapGlobalDimsChangeTypeReplaceReplace()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[2] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ExpectedTaskID: array[2] of Guid;
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] Tables "Table With Default Dim" and "Table With Dimension Set ID" are not empty
        TableWithDefaultDim.Insert();
        TableWithDimensionSetID.Insert();
        // [GIVEN] "Global Dimension 1 Code" and "Global Dimension 2 Code" are swapped
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        ChangeGlobalDimHeader.Validate("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        ChangeGlobalDimHeader.Modify();

        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        // [GIVEN] Run Prepare()
        BindSubscription(ERMChangeGlobalDimensions);
        ExpectedTaskID[1] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        ExpectedTaskID[2] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start()
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Log entries got "Task ID" values and "Change Type 1" and "Change Type 2" are 'Replace'
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Default Dim");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[1]);
        ChangeGlobalDimLogEntry.TestField("Change Type 1", ChangeGlobalDimLogEntry."Change Type 1"::Replace);
        ChangeGlobalDimLogEntry.TestField("Change Type 2", ChangeGlobalDimLogEntry."Change Type 2"::Replace);
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[2]);
        ChangeGlobalDimLogEntry.TestField("Change Type 1", ChangeGlobalDimLogEntry."Change Type 1"::Replace);
        ChangeGlobalDimLogEntry.TestField("Change Type 2", ChangeGlobalDimLogEntry."Change Type 2"::Replace);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T305_DependentTableIsNotScheduledSeparately()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DimensionValue: array[2] of Record "Dimension Value";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Log] [Parent Table] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] One record in table "Detailed Entry With GlobalDim"
        DetailedEntryWithGlobalDim.Insert();
        TableWithDimensionSetID.Insert();
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        BindSubscription(ERMChangeGlobalDimensions);
        // [GIVEN] Run Prepare()
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        ChangeGlobalDimHeader.Validate("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        ChangeGlobalDimHeader.Modify();
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start()
        MockTaskScheduling(
          ERMChangeGlobalDimensions, DATABASE::"Detailed Entry With Global Dim");
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Log entry for table 134485 is not scheduled
        ChangeGlobalDimLogEntry.Get(DATABASE::"Detailed Entry With Global Dim");
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::" ");
        Assert.IsTrue(IsNullGuid(ChangeGlobalDimLogEntry."Task ID"), 'Task ID should be null');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T306_DependentTableIsScheduledByParentTable()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DtldEntryWithGlobalDim2: Record "Dtld. Entry With Global Dim 2";
        DimensionValue: array[2] of Record "Dimension Value";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Log] [Parent Table] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] One record in table "Table With Dimension Set ID"
        TableWithDimensionSetID.Insert();
        // [GIVEN] One related record in table "Detailed Entry With GlobalDim"
        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DetailedEntryWithGlobalDim.Insert();
        // [GIVEN] Another related record in table "Dtld. Entry With GlobalDim 2"
        DtldEntryWithGlobalDim2."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DtldEntryWithGlobalDim2.Insert();
        // [GIVEN] Gobal dimensions are swapped
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        ChangeGlobalDimHeader.Validate("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        ChangeGlobalDimHeader.Modify();

        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        // [GIVEN] Run Prepare()
        BindSubscription(ERMChangeGlobalDimensions);
        ExpectedTaskID :=
          MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        MockTaskScheduling(
          ERMChangeGlobalDimensions, DATABASE::"Detailed Entry With Global Dim");
        MockTaskScheduling(
          ERMChangeGlobalDimensions, DATABASE::"Dtld. Entry With Global Dim 2");
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start()
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Log entry for table 134483 is scheduled and its "Task ID" = 'X'
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID);
        ChangeGlobalDimLogEntry.TestField("Is Parent Table", true);
        // [THEN] Log entry for table 134485 is scheduled and its "Task ID" = 'X'
        ChangeGlobalDimLogEntry.Get(DATABASE::"Detailed Entry With Global Dim");
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID);
        ChangeGlobalDimLogEntry.TestField("Parent Table ID", DATABASE::"Table With Dimension Set ID");
        // [THEN] Log entry for table 134486 is scheduled and its "Task ID" = 'X'
        ChangeGlobalDimLogEntry.Get(DATABASE::"Dtld. Entry With Global Dim 2");
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID);
        ChangeGlobalDimLogEntry.TestField("Parent Table ID", DATABASE::"Table With Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T307_DependentTableIsNotScheduledIfParentNotScheduled()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DimensionValue: array[2] of Record "Dimension Value";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Log] [Parent Table] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] One record in table "Table With Dimension Set ID"
        TableWithDimensionSetID.Insert();
        // [GIVEN] One related record in table "Detailed Entry With GlobalDim"
        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DetailedEntryWithGlobalDim.Insert();
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        BindSubscription(ERMChangeGlobalDimensions);
        // [GIVEN] Run Prepare()
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        ChangeGlobalDimHeader.Validate("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        ChangeGlobalDimHeader.Modify();
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start(), but scheduling failed
        ExpectedTaskID :=
          MockNullTaskScheduling(
            ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        MockTaskScheduling(
          ERMChangeGlobalDimensions, DATABASE::"Detailed Entry With Global Dim");
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Log entry for table 134483 is not scheduled and its "Task ID" = <null>
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::" ");
        Assert.IsTrue(IsNullGuid(ChangeGlobalDimLogEntry."Task ID"), 'Task ID should be null');
        // [THEN] Log entry for table 134485 is not scheduled and its "Task ID" = <null>
        ChangeGlobalDimLogEntry.Get(DATABASE::"Detailed Entry With Global Dim");
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::" ");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T308_DependentTableRerunWithParentTable()
    var
        ChangeGlobalDimLogEntry: array[3] of Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
    begin
        // [FEATURE] [Rerun] [Parent Table]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] One record in table "Table With Dimension Set ID"
        TableWithDimensionSetID.Insert();
        // [GIVEN] Two related records in table "Detailed Entry With GlobalDim"
        DetailedEntryWithGlobalDim."Entry No." := 0;
        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DetailedEntryWithGlobalDim.Insert();
        DetailedEntryWithGlobalDim."Entry No." := 0;
        DetailedEntryWithGlobalDim.Insert();
        // [GIVEN] Job for "Table With Dimension Set ID" was incomplete, "Is Parent Table" is 'Yes'
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[1], DATABASE::"Table With Dimension Set ID", 0, 1);
        ChangeGlobalDimLogEntry[1]."Is Parent Table" := true;
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry[1]);
        // [GIVEN] Job for "Detailed Entry With GlobalDim" was incomplete
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[2], DATABASE::"Detailed Entry With Global Dim", 0, 1);
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry[2]);
        // [GIVEN] Job for "Dtld. Entry With GlobalDim 2" was incomplete
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[3], DATABASE::"Dtld. Entry With Global Dim 2", 0, 1);
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry[3]);

        // [WHEN] Rerun on "Detailed Entry With GlobalDim"
        BindSubscription(ERMChangeGlobalDimensions);
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Detailed Entry With Global Dim");
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Dtld. Entry With Global Dim 2");
        ChangeGlobalDimensions.Rerun(ChangeGlobalDimLogEntry[2]);

        // [THEN] Jobs for three tables, where "Completed Records" = 0, "Status" is "Scheduled"
        ChangeGlobalDimLogEntry[1].Find();
        ChangeGlobalDimLogEntry[1].TestField(Status, ChangeGlobalDimLogEntry[1].Status::Scheduled);
        ChangeGlobalDimLogEntry[1].TestField("Completed Records", 0);
        ChangeGlobalDimLogEntry[2].Find();
        ChangeGlobalDimLogEntry[2].TestField(Status, ChangeGlobalDimLogEntry[1].Status::Scheduled);
        ChangeGlobalDimLogEntry[2].TestField("Completed Records", 0);
        ChangeGlobalDimLogEntry[3].Find();
        ChangeGlobalDimLogEntry[3].TestField(Status, ChangeGlobalDimLogEntry[1].Status::Scheduled);
        ChangeGlobalDimLogEntry[3].TestField("Completed Records", 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T309_DetailedEntryTablesGetParentTableID()
    begin
        // [FEATURE] [Log] [Parent Table] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        Assert.AreEqual(
          DATABASE::"Table With Dimension Set ID", GetParentTableNo(DATABASE::"Detailed Entry With Global Dim"), 'Parent for 134485');
        Assert.AreEqual(
          DATABASE::"Table With Dimension Set ID", GetParentTableNo(DATABASE::"Dtld. Entry With Global Dim 2"), 'Parent for 134486');
        Assert.AreEqual(DATABASE::"Cust. Ledger Entry", GetParentTableNo(DATABASE::"Detailed Cust. Ledg. Entry"), 'Parent for 379');
        Assert.AreEqual(DATABASE::"Vendor Ledger Entry", GetParentTableNo(DATABASE::"Detailed Vendor Ledg. Entry"), 'Parent for 380');
        Assert.AreEqual(
          DATABASE::"Employee Ledger Entry", GetParentTableNo(DATABASE::"Detailed Employee Ledger Entry"), 'Parent for 5223');
        Assert.AreEqual(0, GetParentTableNo(DATABASE::"CV Ledger Entry Buffer"), 'Parent for 382');
        Assert.AreEqual(0, GetParentTableNo(DATABASE::"Detailed CV Ledg. Entry Buffer"), 'Parent for 383');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T310_RemovalOfCompletedParentRemovesCompletedDependentTables()
    var
        ChangeGlobalDimLogEntry: array[2] of Record "Change Global Dim. Log Entry";
        ParentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DtldEntryWithGlobalDim2: Record "Dtld. Entry With Global Dim 2";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        TaskID: Guid;
    begin
        // [FEATURE] [Log] [Parent Table] [UT]
        Initialize();
        // [GIVEN] One record in table "Table With Dimension Set ID"
        TableWithDimensionSetID.Insert();
        // [GIVEN] One related record in table "Detailed Entry With GlobalDim"
        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DetailedEntryWithGlobalDim.Insert();
        // [GIVEN] One related record in table "Dtld. Entry With Global Dim 2"
        DtldEntryWithGlobalDim2."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DtldEntryWithGlobalDim2.Insert();

        // [GIVEN] Parent entry, where "Table ID" = 134483, "Status" = 'Scheduled'
        BindSubscription(ERMChangeGlobalDimensions);
        TaskID := MockTaskScheduling(ERMChangeGlobalDimensions, ChangeGlobalDimLogEntry[1]."Table ID");
        MockScheduledLogEntry(
          ParentChangeGlobalDimLogEntry, DATABASE::"Table With Dimension Set ID", 0, 1);
        ParentChangeGlobalDimLogEntry."Is Parent Table" := true;
        ParentChangeGlobalDimLogEntry."Task ID" := TaskID;
        ParentChangeGlobalDimLogEntry.UpdateStatus();
        ParentChangeGlobalDimLogEntry.Modify();
        // [GIVEN] First Dependent entry, where "Table ID" = 134485, "Parent Table ID" = 134483, "Status" = 'Scheduled'
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry[1], DATABASE::"Detailed Entry With Global Dim", 0, 1);
        ChangeGlobalDimLogEntry[1]."Task ID" := TaskID;
        ChangeGlobalDimLogEntry[1].UpdateStatus();
        ChangeGlobalDimLogEntry[1].Modify();
        // [GIVEN] Second Dependent entry, where "Table ID" = 134486, "Parent Table ID" = 134483, "Status" = 'Scheduled'
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry[2], DATABASE::"Dtld. Entry With Global Dim 2", 0, 1);
        ChangeGlobalDimLogEntry[2]."Task ID" := TaskID;
        ChangeGlobalDimLogEntry[2].UpdateStatus();
        ChangeGlobalDimLogEntry[2].Modify();

        // [WHEN] RunTask() on Parent entry
        RunChangeGlobalDimensionsInParallel(ParentChangeGlobalDimLogEntry);

        // [THEN] Both Parent and Dependent entries are removed
        Assert.IsFalse(ParentChangeGlobalDimLogEntry.Find(), 'Parent entry must be deleted.');
        Assert.IsFalse(ChangeGlobalDimLogEntry[1].Find(), '1st Dependent entry must be deleted.');
        Assert.IsFalse(ChangeGlobalDimLogEntry[2].Find(), '2nd Dependent entry must be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T311_RemovalOfCompletedParentNotRemoveIncompleteDependentTables()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ParentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        TaskID: Guid;
    begin
        // [FEATURE] [Log] [Parent Table] [UT]
        Initialize();
        // [GIVEN] Two records in table "Table With Dimension Set ID"
        // [GIVEN] Two related records in table "Detailed Entry With GlobalDim"
        TableWithDimensionSetID.Insert();
        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DetailedEntryWithGlobalDim.Insert();
        TableWithDimensionSetID."Entry No." := 0;
        TableWithDimensionSetID.Insert();
        DetailedEntryWithGlobalDim."Entry No." := 0;
        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
        DetailedEntryWithGlobalDim.Insert();

        // [GIVEN] Parent entry, where "Table ID" = 134483, "Status" = 'Scheduled', "Completed Records" = 1
        BindSubscription(ERMChangeGlobalDimensions);
        TaskID := MockTaskScheduling(ERMChangeGlobalDimensions, ChangeGlobalDimLogEntry."Table ID");
        MockScheduledLogEntry(
          ParentChangeGlobalDimLogEntry, DATABASE::"Table With Dimension Set ID", 0, 1);
        ParentChangeGlobalDimLogEntry."Is Parent Table" := true;
        ParentChangeGlobalDimLogEntry."Task ID" := TaskID;
        ParentChangeGlobalDimLogEntry."Completed Records" := 1;
        ParentChangeGlobalDimLogEntry.UpdateStatus();
        ParentChangeGlobalDimLogEntry.Modify();
        // [GIVEN] Dependent entry, where "Table ID" = 134485, "Parent Table ID" = 134483, "Status" = 'Scheduled'
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Detailed Entry With Global Dim", 0, 1);
        ChangeGlobalDimLogEntry."Task ID" := TaskID;
        ChangeGlobalDimLogEntry.UpdateStatus();
        ChangeGlobalDimLogEntry.Modify();

        // [WHEN] RunTask on Parent entry
        RunChangeGlobalDimensionsInParallel(ParentChangeGlobalDimLogEntry);

        // [THEN] Dependent entry is not removed; both entries are 'Incomplete'
        Assert.IsTrue(ParentChangeGlobalDimLogEntry.Find(), 'Parent entry must not be deleted.');
        ParentChangeGlobalDimLogEntry.TestField(Status, ParentChangeGlobalDimLogEntry.Status::Incomplete);
        Assert.IsTrue(ChangeGlobalDimLogEntry.Find(), 'Dependent entry must not be deleted.');
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Incomplete);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T320_NotScheduledTableHasUndefinedStatus()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[2] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        ExpectedTaskID: array[2] of Guid;
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        // [GIVEN] "Global Dimension 1 Code" is set to <blank>
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", '');
        ChangeGlobalDimHeader.Modify();
        // [GIVEN] Tables "Table With Default Dim" and "Table With Dimension Set ID" are not empty
        TableWithDefaultDim.Insert();
        TableWithDimensionSetID.Insert();
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        // [GIVEN] Run Prepare()
        BindSubscription(ERMChangeGlobalDimensions);
        MockNullTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        ExpectedTaskID[2] := MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start(), but scheduling for "Table With Default Dim" didn't happen
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] "Table With Default Dim" log entry, where "Task ID" is <null>,  "Status" is ' '
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Default Dim");
        Assert.IsTrue(IsNullGuid(ChangeGlobalDimLogEntry."Task ID"), 'Task ID should be null');
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::" ");
        // [THEN] "Table With Dimension Set ID" log entry , where "Task ID" is 'X', "Status" is 'Scheduled'
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimLogEntry.TestField("Task ID", ExpectedTaskID[2]);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T321_StatusIsInProgressIfNotAllRecsCompletedSessionIsActive()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Log Entry, where "Server Instance ID" and "Session ID" are current, "Task ID" = 'X'
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Session ID" := SessionId();
        ChangeGlobalDimLogEntry."Server Instance ID" := ServiceInstanceId();
        // [GIVEN] "Completed Records" = 0, "Total Records" > 0
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry."Completed Records" := 0;
        ChangeGlobalDimLogEntry.Insert();

        // [WHEN] run UpdateStatus()
        ChangeGlobalDimLogEntry.UpdateStatus();

        // [THEN] "Status" is "In Progress"
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::"In Progress");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T322_StatusIsIncompleteIfNotAllRecsCompletedSessionIsNotActive()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Log Entry, where "Session ID" = X (not active), "Task ID" = 'A',
        // [GIVEN] "Completed Records" = 1, "Total Records" = 2
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Session ID" := -1; // to make sure it is not active
        ChangeGlobalDimLogEntry."Total Records" := 2;
        ChangeGlobalDimLogEntry."Completed Records" := 1;
        ChangeGlobalDimLogEntry.Insert();

        // [WHEN] run UpdateStatus()
        ChangeGlobalDimLogEntry.UpdateStatus();

        // [THEN] "Status" is "Incomplete", "Session ID" is -1, "Server Instance ID" is -1
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Incomplete);
        ChangeGlobalDimLogEntry.TestField("Session ID", -1);
        ChangeGlobalDimLogEntry.TestField("Server Instance ID", -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T323_StatusIsCompletedIfAllRecordsCompleted()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Log Entry, where "Completed Records" = "Total Records"
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry."Completed Records" := ChangeGlobalDimLogEntry."Total Records";
        ChangeGlobalDimLogEntry.Insert();

        // [WHEN] run UpdateStatus()
        ChangeGlobalDimLogEntry.UpdateStatus();

        // [THEN] "Status" is "Completed", "Session ID" = -1, "Server Instance ID" is -1
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Completed);
        ChangeGlobalDimLogEntry.TestField("Session ID", -1);
        ChangeGlobalDimLogEntry.TestField("Server Instance ID", -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T324_StatusIsScheduledIfTaskIDIsSetButSessionIDIsZero()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Log Entry, where Session ID = 0, "Task ID" = 'X', "Completed Records" = 0, "Total Records" > 0
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Session ID" := 0;
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry."Completed Records" := 0;
        ChangeGlobalDimLogEntry.Insert();
        // [GIVEN] Task 'X' is scheduled
        BindSubscription(ERMChangeGlobalDimensions); // to mock TASKEXIST call

        // [WHEN] run UpdateStatus()
        ChangeGlobalDimLogEntry.UpdateStatus();

        // [THEN] "Status" is "Scheduled"
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Scheduled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T325_StatusIsUndefinedIfTaskIDIsBlank()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Log Entry, where Session ID = 0, "Task ID" = <null>, "Completed Records" = 0, "Total Records" > 0
        Clear(ChangeGlobalDimLogEntry."Task ID");
        ChangeGlobalDimLogEntry."Session ID" := 0;
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry."Completed Records" := 0;
        ChangeGlobalDimLogEntry.Insert();

        // [WHEN] run UpdateStatus()
        ChangeGlobalDimLogEntry.UpdateStatus();

        // [THEN] "Status" is <blank>
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T326_StatusIsCompletedIfAllRecordsCompletedFor0Recs()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 0 records in "Table With Default Dim"
        TableWithDefaultDim.DeleteAll();
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        BindSubscription(ERMChangeGlobalDimensions);
        // [GIVEN] Run Prepare()
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", ChangeGlobalDimHeader."Global Dimension 2 Code");
        ChangeGlobalDimHeader.Modify();
        ChangeGlobalDimensions.Prepare();

        // [WHEN] Run Start()
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        StartChangeGlobalDims(ChangeGlobalDimensions);

        // [THEN] Log entries do exist
        Assert.TableIsNotEmpty(DATABASE::"Change Global Dim. Log Entry");
        // [THEN] but entry for "Table With Default Dim" is deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Default Dim"), 'Entry should be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T327_StatusIsCompletedIfAllRecordsCompletedFor1Rec()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 1 record in table "Table With Dimension Set ID"
        TableWithDimensionSetID.DeleteAll();
        TableWithDimensionSetID.Insert();
        // [GIVEN] Log Entry for "Table With Default Dim", where Session ID = 0, "Task ID" = 'X'
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Table With Dimension Set ID";
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Session ID" := 0;
        ChangeGlobalDimLogEntry.Insert();

        // [WHEN] Run task for "Table With Default Dim"
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log Entry is completed and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T328_StatusIncompleteIfTaskNotExistForScheduledLine()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Status] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Log Entry for "Table With Default Dim", where Session ID = 0, Status = "Scheduled"
        // [GIVEN] "Task ID" = 'X' and task does not exist.
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Table With Dimension Set ID";
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::Scheduled;
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Session ID" := 0;
        ChangeGlobalDimLogEntry.Insert();
        // [WHEN] UpdateStatus()
        ChangeGlobalDimLogEntry.UpdateStatus();

        // [THEN] "Status" is "Incomplete"
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Incomplete);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T329_StatusGetsIncompleteOnPageRefresh()
    var
        ChangeGlobalDimLogEntry: array[3] of Record "Change Global Dim. Log Entry";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Status] [UI]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        ChangeGlobalDimLogEntry[1].DeleteAll();
        // [GIVEN] 2 Log Entries, where "Session ID" = X (not active), "Task ID" is not <null> ,
        // [GIVEN] "Status" = "In Progress", "Completed Records" = 1, "Total Records" = 2
        ChangeGlobalDimLogEntry[1]."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry[1]."Session ID" := -1; // to make sure it is not active
        ChangeGlobalDimLogEntry[1]."Total Records" := 2;
        ChangeGlobalDimLogEntry[1]."Completed Records" := 1;
        ChangeGlobalDimLogEntry[1].Status := ChangeGlobalDimLogEntry[1].Status::"In Progress";
        ChangeGlobalDimLogEntry[1].Insert();
        ChangeGlobalDimLogEntry[2] := ChangeGlobalDimLogEntry[1];
        ChangeGlobalDimLogEntry[2]."Table ID" += 1;
        ChangeGlobalDimLogEntry[2].Insert();
        // [GIVEN] 3rd Log entry, where "Total Records" = 0, "Status" = "Completed"
        ChangeGlobalDimLogEntry[3] := ChangeGlobalDimLogEntry[2];
        Clear(ChangeGlobalDimLogEntry[3]."Task ID");
        ChangeGlobalDimLogEntry[3]."Table ID" += 1;
        ChangeGlobalDimLogEntry[3]."Total Records" := 0;
        ChangeGlobalDimLogEntry[3]."Completed Records" := 0;
        ChangeGlobalDimLogEntry[3].Status := ChangeGlobalDimLogEntry[3].Status::Completed;
        ChangeGlobalDimLogEntry[3].Progress := 10000;
        ChangeGlobalDimLogEntry[3].Insert();

        // [GIVEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenEdit();

        // [THEN] "Status" is "Incomplete" in the first record on the page
        Assert.AreEqual(
          ChangeGlobalDimLogEntry[1].Status::Incomplete,
          ChangeGlobalDimensionsPage.LogLines.Status.AsInteger(), '1st Status');
        // [THEN] "Status" is "Completed" in the 3rd record on the page
        ChangeGlobalDimensionsPage.LogLines.Last();
        Assert.AreEqual(
          ChangeGlobalDimLogEntry[3]."Table ID",
          ChangeGlobalDimensionsPage.LogLines."Table ID".AsInteger(), '3rd Table ID');
        Assert.AreEqual(
          ChangeGlobalDimLogEntry[3].Status::Completed,
          ChangeGlobalDimensionsPage.LogLines.Status.AsInteger(), '3rd Status');
        ChangeGlobalDimensionsPage.Close();
        // [THEN] "Status" is "In Progress" on both records
        ChangeGlobalDimLogEntry[1].Find();
        ChangeGlobalDimLogEntry[1].TestField(Status, ChangeGlobalDimLogEntry[1].Status::"In Progress");
        ChangeGlobalDimLogEntry[2].Find();
        ChangeGlobalDimLogEntry[2].TestField(Status, ChangeGlobalDimLogEntry[2].Status::"In Progress");
        // [THEN] "Status" is "Completed" on 3rd records
        ChangeGlobalDimLogEntry[3].Find();
        ChangeGlobalDimLogEntry[3].TestField(Status, ChangeGlobalDimLogEntry[3].Status::Completed);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T330_SetSessionInProgress()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // [FEATURE] [Log] [UT]
        Initialize();
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Salesperson/Purchaser";
        ChangeGlobalDimLogEntry.Insert();

        ChangeGlobalDimLogEntry.SetSessionInProgress();

        ChangeGlobalDimLogEntry.Find();
        ChangeGlobalDimLogEntry.TestField("Session ID", SessionId());
        ChangeGlobalDimLogEntry.TestField("Server Instance ID", ServiceInstanceId());
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::"In Progress");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T335_TotalRecordUpdatedOnEqualTotalRecNo()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        TotalRecords: Integer;
    begin
        Initialize();
        // [GIVEN] Log Entry, where "Total Records" = 100, "Completed Records" = 99, Status = 'In Progress'
        TotalRecords := SalespersonPurchaser.Count();
        CreateLogEntryNearlyCompleted(ChangeGlobalDimLogEntry, TotalRecords);
        // [GIVEN] Added 1 more record
        SalespersonPurchaser.Code := LibraryUtility.GenerateGUID();
        SalespersonPurchaser.Insert(true);

        // [WHEN] run LogEntry.Update(100,0)
        ChangeGlobalDimLogEntry.Update(TotalRecords, 0);

        // [THEN] "Total Records" = 101, "Completed Records" = 100, Status = 'In Progress'
        ChangeGlobalDimLogEntry.TestField("Total Records", TotalRecords + 1);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::"In Progress");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T336_TotalRecordUpdatedOnExceededTotalRecNo()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        TotalRecords: Integer;
    begin
        Initialize();
        // [GIVEN] Log Entry, where "Total Records" = 100, "Completed Records" = 99, Status = 'In Progress'
        TotalRecords := SalespersonPurchaser.Count();
        CreateLogEntryNearlyCompleted(ChangeGlobalDimLogEntry, TotalRecords);
        // [GIVEN] Added 2 more records
        SalespersonPurchaser.Code := LibraryUtility.GenerateGUID();
        SalespersonPurchaser.Insert(true);
        SalespersonPurchaser.Code := LibraryUtility.GenerateGUID();
        SalespersonPurchaser.Insert(true);

        // [WHEN] run LogEntry.Update(101,0)
        ChangeGlobalDimLogEntry.Update(TotalRecords + 1, 0);

        // [THEN] "Total Records" = 102, "Completed Records" = 101, Status = 'In Progress'
        ChangeGlobalDimLogEntry.TestField("Total Records", TotalRecords + 2);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::"In Progress");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T340_LogModifyCalled1TimeFor10Records()
    var
        ChangeGlobalDimLogEntry: array[2] of Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Performance]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 10 records in table "Table With Dimension Set ID" with "Detailed Entry With Global Dim"
        // [GIVEN] Log Entry for "Table With Dimension Set ID"
        CreateRecords(ChangeGlobalDimLogEntry[1], DATABASE::"Detailed Entry With Global Dim", ChangeGlobalDimLogEntry[2], 10);
        // [WHEN] Run task for "Table With Dimension Set ID"
        DisableEntriesDeletion();
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry[1]);
        // [THEN] 1 Entry.MODIFY call is executed, "Status" is "Completed"
        VerifyModifyCount(
          ChangeGlobalDimLogEntry[1], 1, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Table With Dimension Set ID"));
        VerifyModifyCount(
          ChangeGlobalDimLogEntry[2], 1, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Detailed Entry With Global Dim"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T341_LogModifyCalled2TimesFor11Records()
    var
        ChangeGlobalDimLogEntry: array[2] of Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Performance]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 11 records in table "Table With Dimension Set ID" with "Detailed Entry With Global Dim"
        // [GIVEN] Log Entry for "Table With Dimension Set ID"
        CreateRecords(ChangeGlobalDimLogEntry[1], DATABASE::"Detailed Entry With Global Dim", ChangeGlobalDimLogEntry[2], 11);
        // [WHEN] Run task for "Table With Dimension Set ID"
        DisableEntriesDeletion();
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry[1]);
        // [THEN] 2 Entry.MODIFY calls are executed, "Status" is "Completed"
        VerifyModifyCount(
          ChangeGlobalDimLogEntry[1], 2, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Table With Dimension Set ID"));
        VerifyModifyCount(
          ChangeGlobalDimLogEntry[2], 2, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Detailed Entry With Global Dim"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T342_LogModifyCalledMax100TimesFor1000PlusRecords()
    var
        ChangeGlobalDimLogEntry: array[2] of Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Performance]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 1100 records in table "Table With Dimension Set ID" with "Detailed Entry With Global Dim"
        // [GIVEN] Log Entry for "Table With Dimension Set ID"
        CreateRecords(ChangeGlobalDimLogEntry[1], DATABASE::"Detailed Entry With Global Dim", ChangeGlobalDimLogEntry[2], 1100);
        // [WHEN] Run task for "Table With Dimension Set ID"
        DisableEntriesDeletion();
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry[1]);
        // [THEN] 100 Entry.MODIFY calls are executed, "Status" is "Completed"
        VerifyModifyCount(
          ChangeGlobalDimLogEntry[1], 100, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Table With Dimension Set ID"));
        VerifyModifyCount(
          ChangeGlobalDimLogEntry[2], 100, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Detailed Entry With Global Dim"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T343_LogModifyCalled3TimesFor31RecordsOnPartialRerun()
    var
        ChangeGlobalDimLogEntry: array[2] of Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Rerun] [Performance]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] 31 records in table "Table With Dimension Set ID" with "Detailed Entry With Global Dim"
        // [GIVEN] Log Entry for "Table With Dimension Set ID", where "Completed Records" = 1 of "Total Records" = 31
        CreateRecords(ChangeGlobalDimLogEntry[1], DATABASE::"Detailed Entry With Global Dim", ChangeGlobalDimLogEntry[2], 31);
        ChangeGlobalDimLogEntry[1].Validate("Completed Records", 1);
        ChangeGlobalDimLogEntry[1].Modify();
        ChangeGlobalDimLogEntry[2].Validate("Completed Records", 1);
        ChangeGlobalDimLogEntry[2].Modify();
        // [WHEN] Run task for "Table With Dimension Set ID"
        DisableEntriesDeletion();
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry[1]);
        // [THEN] 3 Entry.MODIFY calls are executed, "Status" is "Completed"
        VerifyModifyCount(
          ChangeGlobalDimLogEntry[1], 3, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Table With Dimension Set ID"));
        VerifyModifyCount(
          ChangeGlobalDimLogEntry[2], 3, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Detailed Entry With Global Dim"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T350_UpdateWithCommitForInProgressRec()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Log] [UT]
        Initialize();
        // [GIVEN] One record of TableWithDimensionSetID
        // [GIVEN] LogEntry, where "Status" = 'In Progress', "Total Records" = 1, "Completed Records" = 0
        MockLogEntryForUpdate(ChangeGlobalDimLogEntry, 0, ChangeGlobalDimLogEntry.Status::"In Progress");
        // [WHEN] UpdateWithCommit(1,0)
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        Assert.IsTrue(ChangeGlobalDimLogEntry.UpdateWithCommit(1, 0), 'Completed');

        // [THEN] LogEntry, where "Completed Records" = 1, "Status" = 'Completed'; number of MODIFY calls is 1
        VerifyLogEntryAfterUpdate(ChangeGlobalDimLogEntry, 1, ERMChangeGlobalDimensions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T351_UpdateWithCommitForCompletedRec()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Log] [UT]
        Initialize();
        // [GIVEN] One record of TableWithDimensionSetID
        // [GIVEN] LogEntry, where "Status" = 'Completed', "Total Records" = 1, "Completed Records" = 1
        MockLogEntryForUpdate(ChangeGlobalDimLogEntry, 1, ChangeGlobalDimLogEntry.Status::Completed);

        // [WHEN] UpdateWithCommit(1,0)
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        Assert.IsTrue(ChangeGlobalDimLogEntry.UpdateWithCommit(1, 0), 'Completed');

        // [THEN] LogEntry, where "Completed Records" = 1, "Status" = 'Completed'; number of MODIFY calls is 0
        VerifyLogEntryAfterUpdate(ChangeGlobalDimLogEntry, 0, ERMChangeGlobalDimensions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T352_UpdateWithCommitForInProgressRecWithError()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Log] [UT]
        Initialize();
        // [GIVEN] One record of TableWithDimensionSetID
        // [GIVEN] LogEntry, where "Status" = 'In Progress', "Total Records" = 1, "Completed Records" = 0
        MockLogEntryForUpdate(ChangeGlobalDimLogEntry, 0, ChangeGlobalDimLogEntry.Status::"In Progress");
        // [GIVEN] UpdateWithCommit(1,0)
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        Assert.IsTrue(ChangeGlobalDimLogEntry.UpdateWithCommit(1, 0), 'Completed');

        // [WHEN] Error is thrown
        asserterror Error('');

        // [THEN] LogEntry, where "Completed Records" = 1, "Status" = 'Completed'
        ChangeGlobalDimLogEntry.Find();
        ChangeGlobalDimLogEntry.TestField("Completed Records", 1);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Completed);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T355_UpdateWithoutCommitForInProgressRec()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Log] [UT]
        Initialize();
        // [GIVEN] One record of TableWithDimensionSetID
        // [GIVEN] LogEntry, where "Status" = 'In Progress', "Total Records" = 1, "Completed Records" = 0
        MockLogEntryForUpdate(ChangeGlobalDimLogEntry, 0, ChangeGlobalDimLogEntry.Status::"In Progress");

        // [WHEN] UpdateWithoutCommit(1,0)
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        Assert.IsTrue(ChangeGlobalDimLogEntry.UpdateWithoutCommit(1, 0), 'Completed');

        // [THEN] LogEntry, where "Completed Records" = 1, "Status" = 'Completed'; number of MODIFY calls is 1
        VerifyLogEntryAfterUpdate(ChangeGlobalDimLogEntry, 1, ERMChangeGlobalDimensions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T356_UpdateWithoutCommitForCompletedRec()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Log] [UT]
        Initialize();
        // [GIVEN] One record of TableWithDimensionSetID
        // [GIVEN] LogEntry, where "Status" = 'Completed', "Total Records" = 1, "Completed Records" = 1
        MockLogEntryForUpdate(ChangeGlobalDimLogEntry, 1, ChangeGlobalDimLogEntry.Status::Completed);

        // [WHEN] UpdateWithoutCommit(1,0)
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        Assert.IsTrue(ChangeGlobalDimLogEntry.UpdateWithoutCommit(1, 0), 'Completed');

        // [THEN] LogEntry, where "Completed Records" = 1, "Status" = 'Completed'; number of MODIFY calls is 0
        VerifyLogEntryAfterUpdate(ChangeGlobalDimLogEntry, 0, ERMChangeGlobalDimensions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T357_UpdateWithoutCommitForInProgressRecWithError()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Log] [UT]
        Initialize();
        // [GIVEN] One record of TableWithDimensionSetID
        // [GIVEN] LogEntry, where "Status" = 'In Progress', "Total Records" = 1, "Completed Records" = 0
        MockLogEntryForUpdate(ChangeGlobalDimLogEntry, 0, ChangeGlobalDimLogEntry.Status::"In Progress");
        Commit();
        // [GIVEN] UpdateWithoutCommit(1,0)
        BindSubscription(ERMChangeGlobalDimensions); // subscribe to count MODIFY's
        Assert.IsTrue(ChangeGlobalDimLogEntry.UpdateWithoutCommit(1, 0), 'Completed');

        // [WHEN] Error is thrown
        asserterror Error('');

        // [THEN] LogEntry, where "Completed Records" = 0, "Status" = 'In Progress'
        ChangeGlobalDimLogEntry.Find();
        ChangeGlobalDimLogEntry.TestField("Completed Records", 0);
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::"In Progress");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T400_ChangeTypeNewNoneUpdatesDim1()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Table With Default Dim", where Global Dim Codes are 'A' and 'B'
        TableWithDefaultDim."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDefaultDim."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDefaultDim.Insert();
        // [GIVEN] Record has non-global default dimension 'X' with value 'Y'
        CreateDefaultDimensions(DATABASE::"Table With Default Dim", TableWithDefaultDim."No.", DimensionValue);

        // [GIVEN] "Global Dim 1" is changed to 'X'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 1 Code" := DimensionValue[3]."Dimension Code";
        GeneralLedgerSetup.Modify();

        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "New"
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim", ChangeGlobalDimLogEntry."Change Type 1"::New, 0);

        // [WHEN] Run task
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log entry is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        // [THEN] TableWithDefaultDim, where "Global Dimension 1 Code" is 'X', "Shortcut Dimension 2 Code" is 'B'
        TableWithDefaultDim.Find();
        TableWithDefaultDim.TestField("Global Dimension 1 Code", DimensionValue[3].Code);
        TableWithDefaultDim.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T401_ChangeTypeNoneNewUpdatesDim2()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DimSetID: Integer;
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] One record in table "Table With Dimension Set ID", where Global Dim Codes are 'A' and 'B'
        DimSetID := CreateDimSet(DimensionValue);
        TableWithDimensionSetID."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDimensionSetID."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        // [GIVEN] Record has non-global dimension 'X' with value 'Y'
        TableWithDimensionSetID."Dimension Set ID" := DimSetID;
        TableWithDimensionSetID.Insert();
        // [GIVEN] G/L Setup "Global Dimension 2 Code" is changed to 'X'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 2 Code" := DimensionValue[3]."Dimension Code";
        GeneralLedgerSetup.Modify();

        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 2" is "New"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Table With Dimension Set ID", 0, ChangeGlobalDimLogEntry."Change Type 1"::New);

        // [WHEN] Run task
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log entry is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        // [THEN] TableWithDefaultDim, where "Global Dimension 1 Code" is 'A', "Shortcut Dimension 2 Code" is 'Y'
        TableWithDimensionSetID.Find();
        TableWithDimensionSetID.TestField("Global Dimension 1 Code", DimensionValue[1].Code);
        TableWithDimensionSetID.TestField("Shortcut Dimension 2 Code", DimensionValue[3].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T402_ChangeTypeNewBlankUpdatesBothDims()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Table With Default Dim", where Global Dim Codes are 'A' and 'B'
        TableWithDefaultDim."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDefaultDim."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDefaultDim.Insert();
        // [GIVEN] Record has non-global default dimension 'X' with value 'Y'
        CreateDefaultDimensions(DATABASE::"Table With Default Dim", TableWithDefaultDim."No.", DimensionValue);

        // [GIVEN] "Global Dim 1" is changed to 'X', "Global Dim 2" is changed to <blank>
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", DimensionValue[3]."Dimension Code");
        GeneralLedgerSetup.Validate("Global Dimension 2 Code", '');
        GeneralLedgerSetup.Modify();

        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "New", "Change Type 2" is "Blank"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim",
          ChangeGlobalDimLogEntry."Change Type 1"::New, ChangeGlobalDimLogEntry."Change Type 2"::Blank);

        // [WHEN] Run task
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log entry is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        // [THEN] TableWithDefaultDim, where "Global Dimension 1 Code" is 'Y', "Shortcut Dimension 2 Code" is <blank>
        TableWithDefaultDim.Find();
        TableWithDefaultDim.TestField("Global Dimension 1 Code", DimensionValue[3].Code);
        TableWithDefaultDim.TestField("Shortcut Dimension 2 Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T403_ChangeTypeBlankReplaceUpdatesBothDims()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Table With Default Dim", where Global Dim Codes are 'A' and 'B'
        TableWithDefaultDim."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDefaultDim."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDefaultDim.Insert();
        // [GIVEN] Record has non-global default dimension 'X' with value 'Y'
        CreateDefaultDimensions(DATABASE::"Table With Default Dim", TableWithDefaultDim."No.", DimensionValue);

        // [GIVEN] "Global Dim 1" is changed to <blank>, "Global Dim 2" is changed to 'A'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", '');
        GeneralLedgerSetup.Validate("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        GeneralLedgerSetup.Modify();

        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "Blank", "Change Type 2" is "Replace"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim",
          ChangeGlobalDimLogEntry."Change Type 1"::Blank, ChangeGlobalDimLogEntry."Change Type 2"::Replace);

        // [WHEN] Run task
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log entry is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        // [THEN] TableWithDefaultDim, where "Global Dimension 1 Code" is <blank>, "Shortcut Dimension 2 Code" is 'A'
        TableWithDefaultDim.Find();
        TableWithDefaultDim.TestField("Global Dimension 1 Code", '');
        TableWithDefaultDim.TestField("Shortcut Dimension 2 Code", DimensionValue[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T404_ChangeTypeReplaceReplaceUpdatesDimsBySwapping()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DimSetID: Integer;
    begin
        // [FEATURE] [Change Type]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] One record in table "Table With Dimension Set ID", where Global Dim Codes are 'A' and 'B'
        DimSetID := CreateDimSet(DimensionValue);
        TableWithDimensionSetID."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDimensionSetID."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        // [GIVEN] Record has non-global dimension 'X' with value 'Y'
        TableWithDimensionSetID."Dimension Set ID" := DimSetID;
        TableWithDimensionSetID.Insert();
        // [GIVEN] "Global Dimension 1 Code" is changed to 'B', "Global Dimension 2 Code" is changed to 'A'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 1 Code" := DimensionValue[2]."Dimension Code";
        GeneralLedgerSetup."Global Dimension 2 Code" := DimensionValue[1]."Dimension Code";
        GeneralLedgerSetup.Modify();
        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "Replace","Change Type 2" is "Replace"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Table With Dimension Set ID",
          ChangeGlobalDimLogEntry."Change Type 1"::Replace, ChangeGlobalDimLogEntry."Change Type 2"::Replace);

        // [WHEN] Run task
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log entry is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        // [THEN] TableWithDefaultDim, where "Global Dimension 1 Code" is 'B', "Shortcut Dimension 2 Code" is 'A'
        TableWithDimensionSetID.Find();
        TableWithDimensionSetID.TestField("Dimension Set ID", DimSetID);
        TableWithDimensionSetID.TestField("Global Dimension 1 Code", DimensionValue[2].Code);
        TableWithDimensionSetID.TestField("Shortcut Dimension 2 Code", DimensionValue[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T405_GlobalDimCodeIsBlankInDefaultDimTableByNewDim()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
    begin
        // [FEATURE] [Default Dimension]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Table With Default Dim", where Global Dim Codes are 'A' and 'B'
        TableWithDefaultDim."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDefaultDim."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDefaultDim.Insert();
        // [GIVEN] New Dimension 'Z' is set as a "Global Dimension 1 Code"
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);
        // [GIVEN] "Global Dimension 1 Code" is changed to 'Z'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", NewDimensionValue."Dimension Code");
        GeneralLedgerSetup.Modify();
        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "New"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim", ChangeGlobalDimLogEntry."Change Type 1"::New, 0);

        // [WHEN] Run task
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log entry is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        // [THEN] TableWithDefaultDim, where "Global Dimension 1 Code" is <blank>, "Shortcut Dimension 2 Code" is 'B'
        TableWithDefaultDim.Find();
        TableWithDefaultDim.TestField("Global Dimension 1 Code", '');
        TableWithDefaultDim.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T406_GlobalDimCodeIsBlankInDimSetIdTableByNewDim()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DimSetID: Integer;
    begin
        // [FEATURE] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        DimSetID := CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Table With Dimension Set ID", where Global Dim Codes are 'A' and 'B'
        TableWithDimensionSetID."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDimensionSetID."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDimensionSetID."Dimension Set ID" := DimSetID;
        TableWithDimensionSetID.Insert();
        // [GIVEN] New Dimension 'Z' is set as a "Global Dimension 1 Code"
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);
        // [GIVEN] "Global Dimension 1 Code" is changed to 'Z'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", NewDimensionValue."Dimension Code");
        GeneralLedgerSetup.Modify();
        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "New"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Table With Dimension Set ID", ChangeGlobalDimLogEntry."Change Type 1"::New, 0);

        // [WHEN] Run task
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log entry is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        // [THEN] TableWithDimensionSetID, where "Global Dimension 1 Code" is <blank>, "Shortcut Dimension 2 Code" is 'B'
        TableWithDimensionSetID.Find();
        TableWithDimensionSetID.TestField("Global Dimension 1 Code", '');
        TableWithDimensionSetID.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T407_GlobalDimCodeIsBlankInJobTaskTableByNewDim()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
    begin
        // [FEATURE] [Job Task]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Job Task", where Global Dim Codes are 'A' and 'B'
        JobTask.DeleteAll();
        CreateJobTask(JobTask, DimensionValue);
        // [GIVEN] New Dimension 'Z' is set as a "Global Dimension 1 Code"
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);
        // [GIVEN] "Global Dimension 1 Code" is changed to 'Z'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", NewDimensionValue."Dimension Code");
        GeneralLedgerSetup.Modify();
        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "New"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Job Task", ChangeGlobalDimLogEntry."Change Type 1"::New, 0);

        // [WHEN] Run task
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry);

        // [THEN] Log entry is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        // [THEN] Job Task, where "Global Dimension 1 Code" is <blank>, "Shortcut Dimension 2 Code" is 'B'
        JobTask.Find();
        JobTask.TestField("Global Dimension 1 Code", '');
        JobTask.TestField("Global Dimension 2 Code", DimensionValue[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T408_DependentTableGetsDimCodesFromParent()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: array[3] of Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DimSetID: Integer;
    begin
        // [FEATURE] [Log] [Parent Table] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] One record in table "Table With Dimension Set ID", where Global Dim Codes are 'A' and 'B'
        DimSetID := CreateDimSet(DimensionValue);
        TableWithDimensionSetID."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDimensionSetID."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDimensionSetID."Dimension Set ID" := DimSetID;
        TableWithDimensionSetID.Insert();
        // [GIVEN] 3 dependent records (1st table), where Global Dim Codes are 'A' and 'B'
        CreateDependentRecords(TableWithDimensionSetID, DATABASE::"Detailed Entry With Global Dim", 3);
        // [GIVEN] 4 dependent records (2nd table), where Global Dim Codes are 'A' and 'B'
        CreateDependentRecords(TableWithDimensionSetID, DATABASE::"Dtld. Entry With Global Dim 2", 4);
        // [GIVEN] "Global Dimension 1 Code" is changed to 'B', "Global Dimension 2 Code" is changed to 'A'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 1 Code" := DimensionValue[2]."Dimension Code";
        GeneralLedgerSetup."Global Dimension 2 Code" := DimensionValue[1]."Dimension Code";
        GeneralLedgerSetup.Modify();
        // [GIVEN] ChangeGlobalDimLogEntry for table "Table With Dimension Set ID", where "Status" is "Scheduled","Is Parent Table" is 'Yes'
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry[1], DATABASE::"Table With Dimension Set ID",
          ChangeGlobalDimLogEntry[1]."Change Type 1"::Replace, ChangeGlobalDimLogEntry[1]."Change Type 2"::Replace);
        ChangeGlobalDimLogEntry[1]."Is Parent Table" := true;
        ChangeGlobalDimLogEntry[1].Modify();
        // [GIVEN] ChangeGlobalDimLogEntry for 1st dependent table, where "Status" is " "
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[2], DATABASE::"Detailed Entry With Global Dim", 0, 0);
        ChangeGlobalDimLogEntry[2].Status := ChangeGlobalDimLogEntry[2].Status::" ";
        ChangeGlobalDimLogEntry[2].Modify();
        // [GIVEN] ChangeGlobalDimLogEntry for 2nd dependent table, where "Status" is " "
        MockScheduledLogEntry(ChangeGlobalDimLogEntry[3], DATABASE::"Dtld. Entry With Global Dim 2", 0, 0);
        ChangeGlobalDimLogEntry[3].Status := ChangeGlobalDimLogEntry[3].Status::" ";
        ChangeGlobalDimLogEntry[3].Modify();

        // [WHEN] Run task for table "Table With Dimension Set ID"
        DisableEntriesDeletion();
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry[1]);

        // [THEN] ChangeGlobalDimLogEntry for "Table With Dimension Set ID" is 'Completed' and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry[1].Find(), 'LogEntry should be deleted');
        // [THEN] ChangeGlobalDimLogEntry for dependent table, where "Status" is "Completed" and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry[2].Find(), '1st Dependent LogEntry should be deleted');
        // [THEN] ChangeGlobalDimLogEntry for dependent table, where "Status" is "Completed" and deleted
        Assert.IsFalse(ChangeGlobalDimLogEntry[3].Find(), '2nd Dependent LogEntry should be deleted');
        // [THEN] Records of dependent table gets global dim codes from parent table
        TableWithDimensionSetID.Find();
        VerifyDependentRecords(TableWithDimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T410_FindDimValueCodeForDefaultDimTable()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ActualDimensionValue: array[3] of Record "Dimension Value";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Default Dimension]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Table With Default Dim", where Global Dim Codes are 'A' and 'B'
        TableWithDefaultDim."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDefaultDim."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDefaultDim.Insert();
        RecRef.GetTable(TableWithDefaultDim);
        // [GIVEN] Record has non-global default dimension 'X' with value 'Y'
        CreateDefaultDimensions(DATABASE::"Table With Default Dim", TableWithDefaultDim."No.", DimensionValue);
        // [GIVEN] G/L Setup "Global Dimension 2 Code" is changed to 'X'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 2 Code" := DimensionValue[3]."Dimension Code";
        GeneralLedgerSetup.Modify();
        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 2" is "New"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Table With Default Dim", 0, ChangeGlobalDimLogEntry."Change Type 2"::New);

        // [WHEN] run FindDimensionValueCode for Dimensions 1 and 2.
        ActualDimensionValue[1].Code := ChangeGlobalDimLogEntry.FindDimensionValueCode(RecRef, 1);
        ActualDimensionValue[2].Code := ChangeGlobalDimLogEntry.FindDimensionValueCode(RecRef, 2);

        // [THEN] result is 'A' and 'X'
        Assert.AreEqual(DimensionValue[1].Code, ActualDimensionValue[1].Code, 'Dim 1');
        Assert.AreEqual(DimensionValue[3].Code, ActualDimensionValue[2].Code, 'Dim 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T411_FindDimValueCodeForDimSetIDTable()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ActualDimensionValue: array[3] of Record "Dimension Value";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        RecRef: RecordRef;
        DimSetID: Integer;
    begin
        // [FEATURE] [UT]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        DimSetID := CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Table With Dimension Set ID", where Global Dim Codes are 'A' and 'B'
        TableWithDimensionSetID."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDimensionSetID."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDimensionSetID."Dimension Set ID" := DimSetID;
        TableWithDimensionSetID.Insert();
        RecRef.GetTable(TableWithDimensionSetID);
        // [GIVEN] G/L Setup "Global Dimension 1 Code" is changed to 'X'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 1 Code" := DimensionValue[3]."Dimension Code";
        GeneralLedgerSetup.Modify();
        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "New"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Table With Dimension Set ID", ChangeGlobalDimLogEntry."Change Type 1"::New, 0);

        // [WHEN] run FindDimensionValueCode for Dimensions 1 and 2.
        ActualDimensionValue[1].Code := ChangeGlobalDimLogEntry.FindDimensionValueCode(RecRef, 1);
        ActualDimensionValue[2].Code := ChangeGlobalDimLogEntry.FindDimensionValueCode(RecRef, 2);

        // [THEN] result is 'X' and 'B'
        Assert.AreEqual(DimensionValue[3].Code, ActualDimensionValue[1].Code, 'Dim 1');
        Assert.AreEqual(DimensionValue[2].Code, ActualDimensionValue[2].Code, 'Dim 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T412_FindDimValueCodeForJobTaskTable()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ActualDimensionValue: array[3] of Record "Dimension Value";
        DimensionValue: array[3] of Record "Dimension Value";
        JobTask: Record "Job Task";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Job Task]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CreateDimSet(DimensionValue);
        // [GIVEN] One record in table "Job Task", where Global Dim Codes are 'A' and 'B'
        JobTask.DeleteAll();
        CreateJobTask(JobTask, DimensionValue);
        RecRef.GetTable(JobTask);
        // [GIVEN] Record has non-global default dimension 'X' with value 'Y'
        CreateJobTaskDimensions(JobTask, DimensionValue);

        // [GIVEN] G/L Setup, "Global Dimension 1 Code" is set to 'X', "Global Dimension 2 Code" is set to 'A'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 1 Code" := DimensionValue[3]."Dimension Code";
        GeneralLedgerSetup."Global Dimension 2 Code" := DimensionValue[1]."Dimension Code";
        GeneralLedgerSetup.Modify();

        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled", "Change Type 1" is "New", "Change Type 2" is "Replace"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry, DATABASE::"Job Task",
          ChangeGlobalDimLogEntry."Change Type 1"::New, ChangeGlobalDimLogEntry."Change Type 2"::Replace);

        // [WHEN] run FindDimensionValueCode for Dimensions 1 and 2.
        ActualDimensionValue[1].Code := ChangeGlobalDimLogEntry.FindDimensionValueCode(RecRef, 1);
        ActualDimensionValue[2].Code := ChangeGlobalDimLogEntry.FindDimensionValueCode(RecRef, 2);

        // [THEN] result is 'X' and 'A'
        Assert.AreEqual(DimensionValue[3].Code, ActualDimensionValue[1].Code, 'Dim 1');
        Assert.AreEqual(DimensionValue[1].Code, ActualDimensionValue[2].Code, 'Dim 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T500_LastCompletedTaskRemovesOthersIfAllCompleted()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        DimSetID: Integer;
    begin
        // [FEATURE] [Log]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] Current Session is active only
        ERMChangeGlobalDimensions.SetCurrSessionIsActiveOnly();
        // [GIVEN] One record in table "Table With Dimension Set ID", where Global Dim Codes are 'A' and 'B'
        DimSetID := CreateDimSet(DimensionValue);
        TableWithDimensionSetID."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDimensionSetID."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDimensionSetID."Dimension Set ID" := DimSetID;
        TableWithDimensionSetID.Insert();
        // [GIVEN] "Global Dimension 1 Code" and "Global Dimension 1 Code" are swapped
        SwapGlobalDimensions(ChangeGlobalDimensions);
        // [GIVEN] ChangeGlobalDimLogEntry for table 134483, where "Status" is "Scheduled"
        BindSubscription(ERMChangeGlobalDimensions);
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Job Task");
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Default Dim");
        MockTaskScheduling(ERMChangeGlobalDimensions, DATABASE::"Table With Dimension Set ID");
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimensions.Prepare();
        // [GIVEN] New session, where COD484 is subscribed to OnDatabase triggers
        ChangeGlobalDimLogMgt.ClearBuffer();
        // [GIVEN] 2 ChangeGlobalDimLogEntries for tables 1001 and 134482, where "Status" is "Completed"
        ChangeGlobalDimensions.Start();
        ChangeGlobalDimLogEntry.Get(DATABASE::"Job Task");
        MockCompletedLogEntry(ChangeGlobalDimLogEntry);

        // [WHEN] Run task for table 134483
        ChangeGlobalDimLogEntry.Get(DATABASE::"Table With Dimension Set ID");
        CODEUNIT.Run(CODEUNIT::"Change Global Dimensions", ChangeGlobalDimLogEntry);

        // [THEN] All log entries are deleted
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T501_LastCompletedTaskLeavesOthersIfNotCompleted()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: array[2] of Record "Change Global Dim. Log Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DimSetID: Integer;
    begin
        // [FEATURE] [Log]
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        // [GIVEN] One record in table "Table With Dimension Set ID", where Global Dim Codes are 'A' and 'B'
        DimSetID := CreateDimSet(DimensionValue);
        TableWithDimensionSetID."Global Dimension 1 Code" := DimensionValue[1].Code;
        TableWithDimensionSetID."Shortcut Dimension 2 Code" := DimensionValue[2].Code;
        TableWithDimensionSetID."Dimension Set ID" := DimSetID;
        TableWithDimensionSetID.Insert();
        // [GIVEN] "Global Dimension 1 Code" and "Global Dimension 1 Code" are swapped
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", DimensionValue[2]."Dimension Code");
        GeneralLedgerSetup.Validate("Global Dimension 2 Code", DimensionValue[1]."Dimension Code");
        GeneralLedgerSetup.Modify();
        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Incomplete"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry[1], DATABASE::"Table With Default Dim",
          ChangeGlobalDimLogEntry[1]."Change Type 1"::Replace, ChangeGlobalDimLogEntry[1]."Change Type 2"::Replace);
        MockIncompleteLogEntry(ChangeGlobalDimLogEntry[1]);
        // [GIVEN] ChangeGlobalDimLogEntry, where "Status" is "Scheduled"
        MockScheduledLogEntry(
          ChangeGlobalDimLogEntry[2], DATABASE::"Table With Dimension Set ID",
          ChangeGlobalDimLogEntry[2]."Change Type 1"::Replace, ChangeGlobalDimLogEntry[2]."Change Type 2"::Replace);

        // [WHEN] Run task
        RunChangeGlobalDimensionsInParallel(ChangeGlobalDimLogEntry[2]);

        // [THEN] One log entry, where "Status" is 'Incomplete'.
        Assert.RecordCount(ChangeGlobalDimLogEntry[1], 1);
        Assert.IsTrue(ChangeGlobalDimLogEntry[1].Find(), 'LogEntry[1]');
        ChangeGlobalDimLogEntry[1].TestField(Status, ChangeGlobalDimLogEntry[1].Status::Incomplete);
        // [THEN] The scheduled log entry is completed and removed.
        Assert.IsFalse(ChangeGlobalDimLogEntry[2].Find(), 'LogEntry[2] should be removed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T510_AutoResetOnOpenPageIfAllCompleted()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions";
    begin
        // [FEATURE] [Log] [UI]
        // [SCENARIO 261674] Log Entries should be deleted on open "Change Global Dimensions" page if all 'Completed'
        Initialize();
        // [GIVEN] Two log entries and both are 'Completed'
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, 134482, 0, 1);
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, 134483, 0, 1);
        // [GIVEN] COD484 is subscribed to OnDatabase triggers
        ChangeGlobalDimLogMgt.ClearBuffer();

        // [WHEN] Open page "Change Global Dimensions"
        ChangeGlobalDimensionsPage.OpenView();

        // [THEN] All log entries are deleted
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderCreatedWithSalespersonDimension()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: Record "Dimension Value";
        ServiceHeader: Record "Service Header";
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Salesperson] [Service] [User]
        // [SCENARIO 327294] User is able to create Service Order if they are assigned a Salesperson in User Setup linked to a Dimension
        Initialize();

        // [GIVEN] Created User Setup with assigned Salesperson linked to a Default Dimension
        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, UserId);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", UserSetup."Salespers./Purch. Code",
          DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Create Service Order
        LibraryService.SetupServiceMgtNoSeries();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [THEN] Generated Dimension Set Entry holds correct values
        DimensionSetEntry.SetRange("Dimension Set ID", ServiceHeader."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetNewGlobalDimsWhenTableDoNotHaveDim2Field()
    var
        Dimension: array[2] of Record Dimension;
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Sequential Processing]
        // [SCENARIO 377171] Set new Global Dimension 1 Code and Global Dimension 2 Code when table has field "Global Dimension 1 Code" and does not have "Global/Shortcut Dimension 2 Code".
        Initialize();
        MockTaskScheduling(ERMChangeGlobalDimensions, Database::"Table With Default Dim");

        // [GIVEN] Table "Table with Default Dim" with record 'R'.
        // [GIVEN] Record 'R' has nonempty Global Dimension 1 Code.
        CreateTableWithDefaultDimRecord(TableWithDefaultDim);

        // [GIVEN] Two Dimensions 'A' and 'B' that are different from the current Global Dimensions.
        // [GIVEN] Default Dimension with Dimension Value Code 'DDA' for record 'R' and Dimension 'A'.
        LibraryDimension.CreateDimension(Dimension[1]);
        LibraryDimension.CreateDimension(Dimension[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension[1].Code);
        CreateDefaultDimension(Database::"Table With Default Dim", TableWithDefaultDim."No.", DimensionValue);

        // [GIVEN] Table "Table with Default Dim" has only one field with Dimension - "Global Dimension 1 Code".
        // [GIVEN] It is emulated by setting "Global Dim.2 Field No." = 0 in "Change Global Dim. Log Entry" table for "Table with Default Dim".
        BindSubscription(ERMChangeGlobalDimensions);
        ERMChangeGlobalDimensions.SetRemoveDim2FieldOnTAB134482();

        // [GIVEN] Set Global Dimension 1 Code = 'A' and Global Dimension 2 Code = 'B' on page Change Global Dimensions.
        UpdateGlobalDimensions(ChangeGlobalDimensions, Dimension[1].Code, Dimension[2].Code);

        // [WHEN] Run Action "Start" (Sequential).
        ChangeGlobalDimensions.StartSequential();

        // [THEN] Field value "Global Dimension 1 Code" of record 'R' was set to 'DDA'.
        TableWithDefaultDim.Get(TableWithDefaultDim."No.");
        TableWithDefaultDim.TestField("Global Dimension 1 Code", DimensionValue.Code);

        // [THEN] Table "Change Global Dim. Log Entry" is empty.
        Assert.TableIsEmpty(Database::"Change Global Dim. Log Entry");

        // [THEN] Global Dimensions are updated in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", Dimension[1].Code);
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", Dimension[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetBlankGlobalDimsWhenTableDoNotHaveDim2Field()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Sequential Processing]
        // [SCENARIO 377171] Set blank Global Dimension 1 Code and Global Dimension 2 Code when table has field "Global Dimension 1 Code" and does not have "Global/Shortcut Dimension 2 Code".
        Initialize();
        MockTaskScheduling(ERMChangeGlobalDimensions, Database::"Table With Default Dim");

        // [GIVEN] Table "Table with Default Dim" with record 'R'.
        // [GIVEN] Record 'R' has nonempty Global Dimension 1 Code.
        CreateTableWithDefaultDimRecord(TableWithDefaultDim);

        // [GIVEN] Table "Table with Default Dim" has only one field with Dimension - "Global Dimension 1 Code".
        // [GIVEN] It is emulated by setting "Global Dim.2 Field No." = 0 in "Change Global Dim. Log Entry" table for "Table with Default Dim".
        BindSubscription(ERMChangeGlobalDimensions);
        ERMChangeGlobalDimensions.SetRemoveDim2FieldOnTAB134482();

        // [GIVEN] Set Global Dimension 1 Code = '' and Global Dimension 2 Code = '' on page Change Global Dimensions.
        UpdateGlobalDimensions(ChangeGlobalDimensions, '', '');

        // [WHEN] Run Action "Start" (Sequential).
        ChangeGlobalDimensions.StartSequential();

        // [THEN] Field "Global Dimension 1 Code" of record 'R' has blank value.
        TableWithDefaultDim.Get(TableWithDefaultDim."No.");
        TableWithDefaultDim.TestField("Global Dimension 1 Code", '');

        // [THEN] Table "Change Global Dim. Log Entry" is empty.
        Assert.TableIsEmpty(Database::"Change Global Dim. Log Entry");

        // [THEN] Global Dimensions are updated in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", '');
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SwapGlobalDimsWhenTableDoNotHaveDim2Field()
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        OldDim1Code: Code[20];
        OldDim2Code: Code[20];
    begin
        // [FEATURE] [Sequential Processing]
        // [SCENARIO 377171] Swap Global Dimensions when table has field "Global Dimension 1 Code" and does not have "Global/Shortcut Dimension 2 Code".
        Initialize();
        MockTaskScheduling(ERMChangeGlobalDimensions, Database::"Table With Default Dim");

        // [GIVEN] Table "Table with Default Dim" with record 'R'.
        // [GIVEN] Record 'R' has nonempty Global Dimension 1 Code.
        CreateTableWithDefaultDimRecord(TableWithDefaultDim);

        // [GIVEN] Current Global Dimension 1 Code 'GD1' and Global Dimension 2 Code 'GD2'.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        OldDim1Code := DimensionValue."Dimension Code";
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        OldDim2Code := DimensionValue."Dimension Code";

        // [GIVEN] Table "Table with Default Dim" has only one field with Dimension - "Global Dimension 1 Code".
        // [GIVEN] It is emulated by setting "Global Dim.2 Field No." = 0 in "Change Global Dim. Log Entry" table for "Table with Default Dim".
        BindSubscription(ERMChangeGlobalDimensions);
        ERMChangeGlobalDimensions.SetRemoveDim2FieldOnTAB134482();

        // [GIVEN] Set Global Dimension 1 Code = 'GD2' and Global Dimension 2 Code = 'GD1' on page Change Global Dimensions.
        UpdateGlobalDimensions(ChangeGlobalDimensions, OldDim2Code, OldDim1Code);

        // [WHEN] Run Action "Start" (Sequential).
        ChangeGlobalDimensions.StartSequential();

        // [THEN] Field "Global Dimension 1 Code" of record 'R' has blank value.
        TableWithDefaultDim.Get(TableWithDefaultDim."No.");
        TableWithDefaultDim.TestField("Global Dimension 1 Code", '');

        // [THEN] Table "Change Global Dim. Log Entry" is empty.
        Assert.TableIsEmpty(Database::"Change Global Dim. Log Entry");

        // [THEN] Global Dimensions are updated in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", OldDim2Code);
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", OldDim1Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetNewGlobalDimsWhenTableDoNotHaveDim1Field()
    var
        Dimension: array[2] of Record Dimension;
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Sequential Processing]
        // [SCENARIO 377171] Set new Global Dimension 1 Code and Global Dimension 2 Code when table does not have field "Global Dimension 1 Code" and has "Global/Shortcut Dimension 2 Code".
        Initialize();
        MockTaskScheduling(ERMChangeGlobalDimensions, Database::"Table With Default Dim");

        // [GIVEN] Table "Table with Default Dim" with record 'R'.
        // [GIVEN] Record 'R' has nonempty Shortcut Dimension 2 Code.
        CreateTableWithDefaultDimRecord(TableWithDefaultDim);

        // [GIVEN] Two Dimensions 'A' and 'B' that are different from the current Global Dimensions.
        // [GIVEN] Default Dimension with Dimension Value Code 'DDB' for record 'R' and Dimension 'B'.
        LibraryDimension.CreateDimension(Dimension[1]);
        LibraryDimension.CreateDimension(Dimension[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension[2].Code);
        CreateDefaultDimension(Database::"Table With Default Dim", TableWithDefaultDim."No.", DimensionValue);

        // [GIVEN] Table "Table with Default Dim" has only one field with Dimension - "Shortcut Dimension 2 Code".
        // [GIVEN] It is emulated by setting "Global Dim.1 Field No." = 0 in "Change Global Dim. Log Entry" table for "Table with Default Dim".
        BindSubscription(ERMChangeGlobalDimensions);
        ERMChangeGlobalDimensions.SetRemoveDim1FieldOnTAB134482();

        // [GIVEN] Set Global Dimension 1 Code = 'A' and Global Dimension 2 Code = 'B' on page Change Global Dimensions.
        UpdateGlobalDimensions(ChangeGlobalDimensions, Dimension[1].Code, Dimension[2].Code);

        // [WHEN] Run Action "Start" (Sequential).
        ChangeGlobalDimensions.StartSequential();

        // [THEN] Field value "Shortcut Dimension 2 Code" of record 'R' was set to 'DDB'.
        TableWithDefaultDim.Get(TableWithDefaultDim."No.");
        TableWithDefaultDim.TestField("Shortcut Dimension 2 Code", DimensionValue.Code);

        // [THEN] Table "Change Global Dim. Log Entry" is empty.
        Assert.TableIsEmpty(Database::"Change Global Dim. Log Entry");

        // [THEN] Global Dimensions are updated in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", Dimension[1].Code);
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", Dimension[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetBlankGlobalDimsWhenTableDoNotHaveDim1Field()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
    begin
        // [FEATURE] [Sequential Processing]
        // [SCENARIO 377171] Set blank Global Dimension 1 Code and Global Dimension 2 Code when table does not have field "Global Dimension 1 Code" and has "Global/Shortcut Dimension 2 Code".
        Initialize();
        MockTaskScheduling(ERMChangeGlobalDimensions, Database::"Table With Default Dim");

        // [GIVEN] Table "Table with Default Dim" with record 'R'.
        // [GIVEN] Record 'R' has nonempty Shortcut Dimension 2 Code.
        CreateTableWithDefaultDimRecord(TableWithDefaultDim);

        // [GIVEN] Table "Table with Default Dim" has only one field with Dimension - "Shortcut Dimension 2 Code".
        // [GIVEN] It is emulated by setting "Global Dim.1 Field No." = 0 in "Change Global Dim. Log Entry" table for "Table with Default Dim".
        BindSubscription(ERMChangeGlobalDimensions);
        ERMChangeGlobalDimensions.SetRemoveDim1FieldOnTAB134482();

        // [GIVEN] Set Global Dimension 1 Code = '' and Global Dimension 2 Code = '' on page Change Global Dimensions.
        UpdateGlobalDimensions(ChangeGlobalDimensions, '', '');

        // [WHEN] Run Action "Start" (Sequential).
        ChangeGlobalDimensions.StartSequential();

        // [THEN] Field "Shortcut Dimension 2 Code" of record 'R' has blank value.
        TableWithDefaultDim.Get(TableWithDefaultDim."No.");
        TableWithDefaultDim.TestField("Shortcut Dimension 2 Code", '');

        // [THEN] Table "Change Global Dim. Log Entry" is empty.
        Assert.TableIsEmpty(Database::"Change Global Dim. Log Entry");

        // [THEN] Global Dimensions are updated in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", '');
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SwapGlobalDimsWhenTableDoNotHaveDim1Field()
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TableWithDefaultDim: Record "Table With Default Dim";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions";
        OldDim1Code: Code[20];
        OldDim2Code: Code[20];
    begin
        // [FEATURE] [Sequential Processing]
        // [SCENARIO 377171] Swap Global Dimensions when table does not have field "Global Dimension 1 Code" and has "Global/Shortcut Dimension 2 Code".
        Initialize();
        MockTaskScheduling(ERMChangeGlobalDimensions, Database::"Table With Default Dim");

        // [GIVEN] Table "Table with Default Dim" with record 'R'.
        // [GIVEN] Record 'R' has nonempty Shortcut Dimension 2 Code.
        CreateTableWithDefaultDimRecord(TableWithDefaultDim);

        // [GIVEN] Current Global Dimension 1 Code 'GD1' and Global Dimension 2 Code 'GD2'.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        OldDim1Code := DimensionValue."Dimension Code";
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        OldDim2Code := DimensionValue."Dimension Code";

        // [GIVEN] Table "Table with Default Dim" has only one field with Dimension - "Shortcut Dimension 2 Code".
        // [GIVEN] It is emulated by setting "Global Dim.1 Field No." = 0 in "Change Global Dim. Log Entry" table for "Table with Default Dim".
        BindSubscription(ERMChangeGlobalDimensions);
        ERMChangeGlobalDimensions.SetRemoveDim1FieldOnTAB134482();

        // [GIVEN] Set Global Dimension 1 Code = 'GD2' and Global Dimension 2 Code = 'GD1' on page Change Global Dimensions.
        UpdateGlobalDimensions(ChangeGlobalDimensions, OldDim2Code, OldDim1Code);

        // [WHEN] Run Action "Start" (Sequential).
        ChangeGlobalDimensions.StartSequential();

        // [THEN] Field "Shortcut Dimension 2 Code" of record 'R' has blank value.
        TableWithDefaultDim.Get(TableWithDefaultDim."No.");
        TableWithDefaultDim.TestField("Shortcut Dimension 2 Code", '');

        // [THEN] Table "Change Global Dim. Log Entry" is empty.
        Assert.TableIsEmpty(Database::"Change Global Dim. Log Entry");

        // [THEN] Global Dimensions are updated in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", OldDim2Code);
        GeneralLedgerSetup.TestField("Global Dimension 2 Code", OldDim1Code);
    end;

    local procedure Initialize()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        TableWithDefaultDim: Record "Table With Default Dim";
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DtldEntryWithGlobalDim2: Record "Dtld. Entry With Global Dim 2";
        UserSetup: Record "User Setup";
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Change Global Dimensions");
        ChangeGlobalDimHeader.DeleteAll();
        ChangeGlobalDimensions.ResetState();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        TableWithDefaultDim.DeleteAll();
        TableWithDimensionSetID.DeleteAll();
        DetailedEntryWithGlobalDim.DeleteAll();
        DtldEntryWithGlobalDim2.DeleteAll();
        UserSetup.DeleteAll();
        UnbindSubscription(ChangeGlobalDimLogMgt);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Change Global Dimensions");

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Change Global Dimensions");
    end;

    local procedure InsertChangeGlobalDimLogEntry(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(ChangeGlobalDimLogEntry."Table ID");
        ChangeGlobalDimLogEntry.FillData(RecRef);
        ChangeGlobalDimLogEntry.Insert();
        RecRef.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimListModalHandler(var DimensionList: TestPage "Dimension List")
    begin
    end;

    local procedure DisableEntriesDeletion()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        // Insert an entry to avoid deletion after the task completion
        ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::" ";
        ChangeGlobalDimLogEntry.Insert();
    end;

    local procedure CreateDefaultDimension(TableNo: Integer; PKey: Code[20]; DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", TableNo);
        DefaultDimension.DeleteAll();
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, TableNo, PKey, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateDefaultDimensions(TableNo: Integer; PKey: Code[20]; DimensionValue: array[3] of Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
        DimNo: Integer;
    begin
        DefaultDimension.SetRange("Table ID", TableNo);
        DefaultDimension.DeleteAll();
        for DimNo := 1 to 3 do
            LibraryDimension.CreateDefaultDimension(
              DefaultDimension, TableNo, PKey, DimensionValue[DimNo]."Dimension Code", DimensionValue[DimNo].Code);
    end;

    local procedure CreateDimSet(var DimensionValue: array[3] of Record "Dimension Value") DimSetID: Integer
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        DimSetID := LibraryDimension.CreateDimSet(0, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[3], Dimension.Code);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue[3]."Dimension Code", DimensionValue[3].Code);
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task"; DimensionValue: array[2] of Record "Dimension Value")
    begin
        JobTask.Init();
        JobTask."Job No." := LibraryUtility.GenerateGUID();
        JobTask."Job Task No." := LibraryUtility.GenerateGUID();
        JobTask."Global Dimension 1 Code" := DimensionValue[1].Code;
        JobTask."Global Dimension 2 Code" := DimensionValue[2].Code;
        JobTask.Insert();
    end;

    local procedure CreateJobTaskDimensions(JobTask: Record "Job Task"; DimensionValue: array[3] of Record "Dimension Value")
    var
        JobTaskDimension: Record "Job Task Dimension";
        DimNo: Integer;
    begin
        JobTaskDimension.DeleteAll();
        JobTaskDimension."Job No." := JobTask."Job No.";
        JobTaskDimension."Job Task No." := JobTask."Job Task No.";
        for DimNo := 1 to 3 do begin
            JobTaskDimension."Dimension Code" := DimensionValue[DimNo]."Dimension Code";
            JobTaskDimension."Dimension Value Code" := DimensionValue[DimNo].Code;
            JobTaskDimension.Insert();
        end;
    end;

    local procedure CreateLogEntryNearlyCompleted(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; TotalRecords: Integer)
    begin
        ChangeGlobalDimLogEntry.Init();
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Salesperson/Purchaser";
        ChangeGlobalDimLogEntry."Total Records" := TotalRecords;
        ChangeGlobalDimLogEntry."Completed Records" := TotalRecords - 1;
        ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::"In Progress";
        ChangeGlobalDimLogEntry."Earliest Start Date/Time" := CurrentDateTime;
        ChangeGlobalDimLogEntry.Insert();
    end;

    local procedure CreateRecords(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; DependentTableNo: integer; var DependentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; NoOfRecs: Integer)
    var
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DtldEntryWithGlobalDim2: Record "Dtld. Entry With Global Dim 2";
        I: Integer;
    begin
        TableWithDimensionSetID.DeleteAll();
        for I := 1 to NoOfRecs do begin
            TableWithDimensionSetID."Entry No." := I;
            TableWithDimensionSetID.Insert();
            case DependentTableNo of
                DATABASE::"Detailed Entry With Global Dim":
                    begin
                        DetailedEntryWithGlobalDim."Entry No." := 0; // autoinc
                        DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
                        DetailedEntryWithGlobalDim.Insert();
                    end;
                DATABASE::"Dtld. Entry With Global Dim 2":
                    begin
                        DtldEntryWithGlobalDim2."Entry No." := 0; // autoinc
                        DtldEntryWithGlobalDim2."Parent Entry No." := TableWithDimensionSetID."Entry No.";
                        DtldEntryWithGlobalDim2.Insert();
                    end;
            end;
        end;
        DependentChangeGlobalDimLogEntry.Init();
        DependentChangeGlobalDimLogEntry."Table ID" := DependentTableNo;
        DependentChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        DependentChangeGlobalDimLogEntry."Change Type 1" := ChangeGlobalDimLogEntry."Change Type 1"::Blank;
        DependentChangeGlobalDimLogEntry."Session ID" := 0;
        DependentChangeGlobalDimLogEntry."Parent Table ID" := DATABASE::"Table With Dimension Set ID";
        InsertChangeGlobalDimLogEntry(DependentChangeGlobalDimLogEntry);

        ChangeGlobalDimLogEntry.Init();
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Table With Dimension Set ID";
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Change Type 1" := ChangeGlobalDimLogEntry."Change Type 1"::Blank;
        ChangeGlobalDimLogEntry."Session ID" := 0;
        ChangeGlobalDimLogEntry."Is Parent Table" := true;
        InsertChangeGlobalDimLogEntry(ChangeGlobalDimLogEntry);
    end;

    local procedure CreateDependentRecords(TableWithDimensionSetID: Record "Table With Dimension Set ID"; DependentTableNo: integer; NoOfRecords: Integer)
    var
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
        DtldEntryWithGlobalDim2: Record "Dtld. Entry With Global Dim 2";
        RecNo: Integer;
    begin
        case DependentTableNo of
            DATABASE::"Detailed Entry With Global Dim":
                begin
                    DetailedEntryWithGlobalDim."Entry No." := 0;
                    DetailedEntryWithGlobalDim."Parent Entry No." := TableWithDimensionSetID."Entry No.";
                    DetailedEntryWithGlobalDim."Initial Entry Global Dim. 1" := TableWithDimensionSetID."Global Dimension 1 Code";
                    DetailedEntryWithGlobalDim."Initial Entry Global Dim. 2" := TableWithDimensionSetID."Shortcut Dimension 2 Code";
                    DetailedEntryWithGlobalDim.Insert();
                    for RecNo := 2 to NoOfRecords do begin
                        DetailedEntryWithGlobalDim."Entry No." := 0;
                        DetailedEntryWithGlobalDim.Insert();
                    end;
                end;
            DATABASE::"Dtld. Entry With Global Dim 2":
                begin
                    DtldEntryWithGlobalDim2."Entry No." := 0;
                    DtldEntryWithGlobalDim2."Parent Entry No." := TableWithDimensionSetID."Entry No.";
                    DtldEntryWithGlobalDim2."Initial Entry Global Dim. 1" := TableWithDimensionSetID."Global Dimension 1 Code";
                    DtldEntryWithGlobalDim2."Initial Entry Global Dim. 2" := TableWithDimensionSetID."Shortcut Dimension 2 Code";
                    DtldEntryWithGlobalDim2.Insert();
                    for RecNo := 2 to NoOfRecords do begin
                        DtldEntryWithGlobalDim2."Entry No." := 0;
                        DtldEntryWithGlobalDim2.Insert();
                    end;
                end;
        end;
    end;

    local procedure CreateTableWithDefaultDimRecord(var TableWithDefaultDim: Record "Table With Default Dim")
    var
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], DimensionValue[1]."Dimension Code");
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[2]."Dimension Code");

        TableWithDefaultDim.Init();
        TableWithDefaultDim.Validate("No.", LibraryUtility.GenerateGUID());
        TableWithDefaultDim.Validate("Global Dimension 1 Code", DimensionValue[1].Code);
        TableWithDefaultDim.Validate("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        TableWithDefaultDim.Insert(true);
    end;

    local procedure CountGlobalDimTables(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry") Result: Integer
    var
        "Field": Record "Field";
        TableID: Integer;
    begin
        Field.SetFilter(
          TableNo, '<>%1&<>%2&<>%3&<>%4&<>%5&<>%6&<>%7&<>%8&<>%9&<>%10',
          DATABASE::"General Ledger Setup",
          DATABASE::"Detailed CV Ledg. Entry Buffer",
          DATABASE::"Change Global Dim. Header",
          DATABASE::"G/L Account (Analysis View)",
          DATABASE::"Purchase Order Entity Buffer",
          DATABASE::"Purch. Inv. Entity Aggregate",
          DATABASE::"Sales Cr. Memo Entity Buffer",
          DATABASE::"Sales Invoice Entity Aggregate",
          DATABASE::"Sales Order Entity Buffer",
          DATABASE::"Sales Quote Entity Buffer");
        Field.SetFilter(FieldName, '*Shortcut Dim*|*Global Dim*');
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(Type, Field.Type::Code);
        Field.SetRange(Len, 20);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No, Field.ObsoleteState::Pending);
        if Field.FindSet() then
            repeat
                if (TableID <> Field.TableNo) and not IsObsolete(Field.TableNo) then
                    if PKContainsOneField(Field.TableNo) or TableContainsDimSetIDField(Field.TableNo) then
                        if ChangeGlobalDimLogEntry.Get(Field.TableNo) then begin
                            ChangeGlobalDimLogEntry.Delete();
                            TableID := Field.TableNo;
                            Result += 1;
                        end;
            until Field.Next() = 0;
        ChangeGlobalDimLogEntry.SetFilter("Table ID", '<>0&<>%1', DATABASE::"Job Task");
        if ChangeGlobalDimLogEntry.FindFirst() then
            Error(UnexpectedTableErr, ChangeGlobalDimLogEntry."Table ID");
    end;

    local procedure GetParentTableNo(TableNo: Integer): Integer
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ChangeGlobalDimLogEntry."Table ID" := TableNo;
        InsertChangeGlobalDimLogEntry(ChangeGlobalDimLogEntry);
        exit(ChangeGlobalDimLogEntry."Parent Table ID");
    end;

    local procedure IsObsolete(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.ObsoleteState = TableMetadata.ObsoleteState::Removed);
    end;

    local procedure MockActiveSessions(NoOfSessions: Integer) LastSessionID: Integer
    var
        ActiveSession: Record "Active Session";
        i: Integer;
    begin
        ActiveSession.SetFilter("Session ID", '<>%1', SessionId());
        ActiveSession.DeleteAll();
        ActiveSession.Reset();
        ActiveSession.FindFirst();
        ActiveSession."Session ID" := 0;
        for ActiveSession."Client Type" := ActiveSession."Client Type"::"Web Service" to ActiveSession."Client Type"::"Management Client" do begin
            ActiveSession."Session ID" -= 1;
            ActiveSession."Session Unique ID" := CreateGuid();
            if ActiveSession."Client Type" <> ActiveSession."Client Type"::Background then
                ActiveSession.Insert();
        end;
        ActiveSession."Client Type" := ActiveSession."Client Type"::Background;
        for i := 1 to NoOfSessions do begin
            ActiveSession."Session ID" -= 1;
            ActiveSession."Session Unique ID" := CreateGuid();
            ActiveSession.Insert();
            ActiveSession."Client Type" := ActiveSession."Client Type"::"Web Client";
        end;
        LastSessionID := ActiveSession."Session ID";
        // Session for another ServiceID
        ActiveSession."Client Type" := ActiveSession."Client Type"::"Web Client";
        ActiveSession."Session ID" := ActiveSession."Session ID";
        ActiveSession."Server Instance ID" := ServiceInstanceId() + 1000;
        ActiveSession."Session Unique ID" := CreateGuid();
        ActiveSession.Insert();
    end;

    local procedure MockJobQueueLogEntries(var JobQueueLogEntry: array[3] of Record "Job Queue Log Entry"; ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
        JobQueueLogEntry[1]."Entry No." := 0;
        JobQueueLogEntry[1]."Object Type to Run" := JobQueueLogEntry[1]."Object Type to Run"::Codeunit;
        JobQueueLogEntry[1]."Object ID to Run" := CODEUNIT::"Change Global Dim Err. Handler";
        JobQueueLogEntry[1].Status := JobQueueLogEntry[1].Status::Error;
        JobQueueLogEntry[1].ID := ChangeGlobalDimLogEntry."Task ID";
        JobQueueLogEntry[1].Description := 'Table X';
        JobQueueLogEntry[1].Insert();
        JobQueueLogEntry[2] := JobQueueLogEntry[1];
        JobQueueLogEntry[2]."Entry No." := 0;
        JobQueueLogEntry[2].Description := ChangeGlobalDimLogEntry."Table Name";
        JobQueueLogEntry[2].Status := JobQueueLogEntry[2].Status::Success;
        JobQueueLogEntry[2].Insert();
        JobQueueLogEntry[3] := JobQueueLogEntry[2];
        JobQueueLogEntry[3]."Entry No." := 0;
        JobQueueLogEntry[3].ID := CreateGuid();
        JobQueueLogEntry[3].Status := JobQueueLogEntry[3].Status::Error;
        JobQueueLogEntry[3].Insert();
    end;

    local procedure MockLogEntryForUpdate(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; CompletedRecs: Integer; Status: Option)
    var
        TableWithDimensionSetID: Record "Table With Dimension Set ID";
    begin
        TableWithDimensionSetID.Insert();
        ChangeGlobalDimLogEntry."Table ID" := DATABASE::"Table With Dimension Set ID";
        ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry."Completed Records" := CompletedRecs;
        ChangeGlobalDimLogEntry.Status := Status;
        ChangeGlobalDimLogEntry.Insert();
    end;

    local procedure MockLogEntryWithProgress(TableID: Integer; Progress: Decimal)
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ChangeGlobalDimLogEntry."Table ID" := TableID;
        ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::"In Progress";
        ChangeGlobalDimLogEntry."Total Records" := 100;
        ChangeGlobalDimLogEntry.Progress := Progress;
        ChangeGlobalDimLogEntry.Insert();
    end;

    local procedure MockNullTaskScheduling(var ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions"; TableNo: Integer) ExpectedTaskID: Guid
    begin
        Clear(ExpectedTaskID);
        ERMChangeGlobalDimensions.SetTaskID(ExpectedTaskID, TableNo);
    end;

    local procedure MockTaskScheduling(var ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions"; TableNo: Integer) ExpectedTaskID: Guid
    begin
        ExpectedTaskID := CreateGuid();
        ERMChangeGlobalDimensions.SetTaskID(ExpectedTaskID, TableNo);
    end;

    local procedure MockCompletedLogEntry(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
        ChangeGlobalDimLogEntry."Session ID" := SessionId();
        ChangeGlobalDimLogEntry.Validate("Completed Records", ChangeGlobalDimLogEntry."Total Records");
        ChangeGlobalDimLogEntry.UpdateStatus();
        ChangeGlobalDimLogEntry.Modify();
        ChangeGlobalDimLogEntry.Delete(true);
    end;

    local procedure MockIncompleteLogEntry(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
        ChangeGlobalDimLogEntry."Session ID" := -1; // inactive session
        ChangeGlobalDimLogEntry.Validate("Completed Records", ChangeGlobalDimLogEntry."Total Records" - 1);
        ChangeGlobalDimLogEntry.UpdateStatus();
        ChangeGlobalDimLogEntry.Modify();
    end;

    local procedure MockScheduledLogEntry(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; TableNo: Integer; ChangeType1: Option; ChangeType2: Option)
    begin
        ChangeGlobalDimLogEntry.Init();
        ChangeGlobalDimLogEntry."Table ID" := TableNo;
        ChangeGlobalDimLogEntry."Table Name" := Format(TableNo);
        InsertChangeGlobalDimLogEntry(ChangeGlobalDimLogEntry);
        ChangeGlobalDimLogEntry."Task ID" := CreateGuid();
        ChangeGlobalDimLogEntry."Change Type 1" := ChangeType1;
        ChangeGlobalDimLogEntry."Change Type 2" := ChangeType2;
        ChangeGlobalDimLogEntry.UpdateStatus();
        if ChangeGlobalDimLogEntry."Total Records" = 0 then
            ChangeGlobalDimLogEntry."Total Records" := 1;
        ChangeGlobalDimLogEntry.Modify();
    end;

    local procedure MockPreparedLines(TableNo1: Integer; TableNo2: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        MockScheduledLogEntry(ChangeGlobalDimLogEntry, TableNo1, 1, 2);
        ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::" ";
        ChangeGlobalDimLogEntry.Modify();
        ChangeGlobalDimLogEntry."Table ID" := TableNo2;
        ChangeGlobalDimLogEntry.Insert();
        // new values stored for page reopening
        GeneralLedgerSetup.Get();
        ChangeGlobalDimLogEntry."Table ID" := 0;
        ChangeGlobalDimLogEntry."Table Name" := StrSubstNo('%1;%2', '', GeneralLedgerSetup."Global Dimension 1 Code");
        ChangeGlobalDimLogEntry.Insert();
    end;

    local procedure OpenPageForParalllelProcessing(var ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions")
    begin
        ChangeGlobalDimensionsPage.OpenEdit();
        ChangeGlobalDimensionsPage."Parallel Processing".SetValue(Format(true));
    end;

    local procedure PKContainsOneField(TableID: Integer) Result: Boolean
    var
        KeyRef: KeyRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        Result := KeyRef.FieldCount = 1;
        RecRef.Close();
    end;

    [Scope('OnPrem')]
    procedure RunChangeGlobalDimensionsInParallel(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    var
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
    begin
        ChangeGlobalDimLogMgt.ClearBuffer();
        ChangeGlobalDimensions.SetParallelProcessing(true);
        ChangeGlobalDimensions.Run(ChangeGlobalDimLogEntry);
    end;

    local procedure StartChangeGlobalDims(var ChangeGlobalDimensions: Codeunit "Change Global Dimensions")
    begin
        ChangeGlobalDimensions.Start();
    end;

    local procedure SwapGlobalDimensions(var ChangeGlobalDimensions: Codeunit "Change Global Dimensions")
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        GlobalDimCode: Code[20];
    begin
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimHeader.Get();
        GlobalDimCode := ChangeGlobalDimHeader."Global Dimension 1 Code";
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", ChangeGlobalDimHeader."Global Dimension 2 Code");
        ChangeGlobalDimHeader.Validate("Global Dimension 2 Code", GlobalDimCode);
        ChangeGlobalDimHeader.Modify();
    end;

    local procedure SwapGlobalDimsOnPage(var ChangeGlobalDimensionsPage: TestPage "Change Global Dimensions"; var DimensionValue: array[2] of Record "Dimension Value")
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
    begin
        ChangeGlobalDimHeader.Get();
        DimensionValue[1]."Dimension Code" := ChangeGlobalDimHeader."Old Global Dimension 1 Code";
        if DimensionValue[1].Find('><') then;
        DimensionValue[2]."Dimension Code" := ChangeGlobalDimHeader."Old Global Dimension 2 Code";
        if DimensionValue[2].Find('><') then;
        ChangeGlobalDimensionsPage."Global Dimension 1 Code".SetValue(DimensionValue[2]."Dimension Code");
        ChangeGlobalDimensionsPage."Global Dimension 2 Code".SetValue(DimensionValue[1]."Dimension Code");
    end;

    local procedure TableContainsDimSetIDField(TableID: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetRange(RelationTableNo, DATABASE::"Dimension Set Entry");
        exit(not Field.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetModifyCount(TableID: Integer): Integer
    begin
        if TempCounterLineNumberBuffer.Get(TableID) then
            exit(TempCounterLineNumberBuffer."New Line Number");
        exit(0);
    end;

    local procedure UpdateGlobalDimensions(var ChangeGlobalDimensions: Codeunit "Change Global Dimensions"; GlobalDim1Code: Code[20]; GlobalDim2Code: Code[20])
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
    begin
        ChangeGlobalDimensions.RefreshHeader();
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader.Validate("Global Dimension 1 Code", GlobalDim1Code);
        ChangeGlobalDimHeader.Validate("Global Dimension 2 Code", GlobalDim2Code);
        ChangeGlobalDimHeader.Modify(true);
    end;

    local procedure VerifyModifyCount(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; ExpectedCount: Integer; ActualCount: Integer)
    begin
        Assert.IsFalse(ChangeGlobalDimLogEntry.Find(), 'LogEntry should be deleted');
        Assert.AreEqual(ExpectedCount, ActualCount, 'Count of MODIFY calls');
    end;

    local procedure VerifyDependentRecords(TableWithDimensionSetID: Record "Table With Dimension Set ID")
    var
        DetailedEntryWithGlobalDim: Record "Detailed Entry With Global Dim";
    begin
        DetailedEntryWithGlobalDim.SetRange("Parent Entry No.", TableWithDimensionSetID."Entry No.");
        DetailedEntryWithGlobalDim.FindSet();
        repeat
            DetailedEntryWithGlobalDim.TestField("Initial Entry Global Dim. 1", TableWithDimensionSetID."Global Dimension 1 Code");
            DetailedEntryWithGlobalDim.TestField("Initial Entry Global Dim. 2", TableWithDimensionSetID."Shortcut Dimension 2 Code");
        until DetailedEntryWithGlobalDim.Next() = 0;
    end;

    local procedure VerifyLogEntryAfterUpdate(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; ModifyCount: Integer; var ERMChangeGlobalDimensions: Codeunit "ERM Change Global Dimensions")
    begin
        Assert.AreEqual(ModifyCount, ERMChangeGlobalDimensions.GetModifyCount(DATABASE::"Table With Dimension Set ID"), 'ModifyCount');
        ChangeGlobalDimLogEntry.TestField("Completed Records", ChangeGlobalDimLogEntry."Total Records");
        ChangeGlobalDimLogEntry.TestField(Status, ChangeGlobalDimLogEntry.Status::Completed);
    end;

    [Scope('OnPrem')]
    procedure SetTaskID(TaskID: Guid; TableNo: Integer)
    begin
        TempChangeGlobalDimLogEntry."Table ID" := TableNo;
        TempChangeGlobalDimLogEntry."Task ID" := TaskID;
        if not TempChangeGlobalDimLogEntry.Insert() then
            TempChangeGlobalDimLogEntry.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Global Dimensions", 'OnAfterGetObjectNoList', '', false, false)]
    local procedure OnAfterGetObjectNoList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
        if not TempChangeGlobalDimLogEntry.IsEmpty() then
            if TempAllObjWithCaption.FindSet() then
                repeat
                    if not TempChangeGlobalDimLogEntry.Get(TempAllObjWithCaption."Object ID") then
                        TempAllObjWithCaption.Delete();
                until TempAllObjWithCaption.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Global Dimensions", 'OnBeforeScheduleTask', '', false, false)]
    local procedure OnBeforeScheduleTask(TableNo: Integer; var DoNotScheduleTask: Boolean; var TaskID: Guid)
    begin
        DoNotScheduleTask := true;
        if TempChangeGlobalDimLogEntry.Get(TableNo) then
            TaskID := TempChangeGlobalDimLogEntry."Task ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Global Dim. Log Entry", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyChangeGlobalDimLogEntry(var Rec: Record "Change Global Dim. Log Entry"; var xRec: Record "Change Global Dim. Log Entry"; RunTrigger: Boolean)
    var
        xChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        if Rec.IsTemporary then
            exit;
        xChangeGlobalDimLogEntry.Get(Rec."Table ID");
        if xChangeGlobalDimLogEntry.Status = xChangeGlobalDimLogEntry.Status::"In Progress" then
            IncModifyCounter(Rec."Table ID");
    end;

    local procedure IncModifyCounter(TableID: Integer)
    begin
        if TempCounterLineNumberBuffer.Get(TableID) then begin
            TempCounterLineNumberBuffer."New Line Number" += 1;
            TempCounterLineNumberBuffer.Modify();
        end else begin
            TempCounterLineNumberBuffer."Old Line Number" := TableID;
            TempCounterLineNumberBuffer."New Line Number" := 1;
            TempCounterLineNumberBuffer.Insert();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobQueueLogEntriesModalHandler(var JobQueueLogEntriesPage: TestPage "Job Queue Log Entries")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        Assert.IsTrue(JobQueueLogEntriesPage.First(), 'empty list');
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntriesPage.Status.AsInteger(), 'Status');
        Assert.AreEqual(
          JobQueueLogEntry."Object Type to Run"::Codeunit, JobQueueLogEntriesPage."Object Type to Run".AsInteger(), 'Object Type to Run');
        Assert.AreEqual(
          CODEUNIT::"Change Global Dim Err. Handler", JobQueueLogEntriesPage."Object ID to Run".AsInteger(), 'Object ID to Run');
        LibraryVariableStorage.Enqueue(JobQueueLogEntriesPage.Description.Value);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallCloseSessionsNotificationHandler(var Notification: Notification): Boolean
    var
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
    begin
        Assert.AreEqual(
          Format(ChangeGlobalDimensions.GetCloseSessionsNotificationID()),
          Format(Notification.Id), 'Notification ID');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendCloseSessionsNotificationHandlerWithActionClick(var Notification: Notification): Boolean
    var
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
    begin
        Assert.AreEqual(
          Format(ChangeGlobalDimensions.GetCloseSessionsNotificationID()),
          Format(Notification.Id), 'Notification ID');
        LibraryVariableStorage.Enqueue(Notification.Message);
        ChangeGlobalDimensions.ShowActiveSessions(Notification); // simulate click on notification action
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Global Dim. Log Entry", 'OnFindingScheduledTask', '', false, false)]
    local procedure OnFindingScheduledTaskHandler(TaskID: Guid; var IsTaskExist: Boolean)
    begin
        IsTaskExist := not IsNullGuid(TaskID);
    end;

    [Scope('OnPrem')]
    procedure SetFailOnModifyTAB134483()
    begin
        FailOnModifyTAB134483 := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Table With Dimension Set ID", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyTAB134483(var Rec: Record "Table With Dimension Set ID"; var xRec: Record "Table With Dimension Set ID"; RunTrigger: Boolean)
    begin
        if FailOnModifyTAB134483 then
            Error(TAB134483OnBeforeModifyErr);
    end;

    [Scope('OnPrem')]
    procedure SetCurrSessionIsActiveOnly()
    begin
        CurrSessionIsActiveOnly := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Global Dimensions", 'OnCountingActiveSessions', '', false, false)]
    local procedure OnCountingActiveSessionsHandler(var IsCurrSessionActiveOnly: Boolean)
    begin
        IsCurrSessionActiveOnly := CurrSessionIsActiveOnly;
    end;

    [Scope('OnPrem')]
    procedure SetInsertRecToEmptyTable()
    begin
        InsertRecToEmptyTable134482 := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Global Dim. Log Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyZeroRec483(var Rec: Record "Change Global Dim. Log Entry"; var xRec: Record "Change Global Dim. Log Entry"; RunTrigger: Boolean)
    var
        TableWithDefaultDim: Record "Table With Default Dim";
    begin
        if InsertRecToEmptyTable134482 then begin
            InsertRecToEmptyTable134482 := false;
            if TableWithDefaultDim.IsEmpty() then
                TableWithDefaultDim.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetRemoveDim1FieldOnTAB134482()
    begin
        RemoveDim1FieldOnTAB134482 := true;
    end;

    [Scope('OnPrem')]
    procedure SetRemoveDim2FieldOnTAB134482()
    begin
        RemoveDim2FieldOnTAB134482 := true;
    end;

    [EventSubscriber(ObjectType::Table, 483, 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertRec483RemoveDim1Field(var Rec: Record "Change Global Dim. Log Entry"; RunTrigger: Boolean)
    begin
        if RemoveDim1FieldOnTAB134482 then
            if Rec."Table ID" = Database::"Table With Default Dim" then begin
                Rec."Global Dim.1 Field No." := 0;
                RemoveDim1FieldOnTAB134482 := false;
            end;
    end;

    [EventSubscriber(ObjectType::Table, 483, 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertRec483RemoveDim2Field(var Rec: Record "Change Global Dim. Log Entry"; RunTrigger: Boolean)
    begin
        if RemoveDim2FieldOnTAB134482 then
            if Rec."Table ID" = Database::"Table With Default Dim" then begin
                Rec."Global Dim.2 Field No." := 0;
                RemoveDim2FieldOnTAB134482 := false;
            end;
    end;
}

