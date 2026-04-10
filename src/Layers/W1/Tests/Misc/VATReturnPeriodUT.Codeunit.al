codeunit 134281 "VAT Return Period UT"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Return Period] [UT]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryVATReport: Codeunit "Library - VAT Report";
        IsInitialized: Boolean;
        CreateVATReturnQst: Label 'VAT Return %1 has been created. Do you want to open the VAT return card?', Comment = '1 - VAT Return No.';
        NoVATReturnQst: Label 'There is no VAT return for this period. Do you want to create a new one?';
        ManualInsertNotificationMsg: Label 'Insert is only allowed with the Get VAT Return Periods action.';
        FailedJobNotificationMsg: Label 'Auto receive job has failed (executed on %1).', Comment = '1 - datetime';
        TestCodeunitRunMsg: Label 'TestCodeunitRunMessage';
        DeleteExistingVATRetErr: Label 'You cannot delete a VAT return period that has a linked VAT return.';
        PositivePeriodReminderCalcErr: Label 'The Period Reminder Calculation should be a positive formula. For example, "1M" should be used instead of "-1M".';

    [Test]
    [Scope('OnPrem')]
    procedure COD_GetVATReturnPeriods_Negative()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportMgt: Codeunit "VAT Report Mgt.";
    begin
        // [SCENARIO 258181] COD 737 "VAT Report Mgt.".GetVATReturnPeriods() invokes TESTFIELD("Manual Receive Period CU ID")
        Initialize();
        VATReportSetup.Get();
        VATReportSetup.TestField("Manual Receive Period CU ID", 0);

        asserterror VATReportMgt.GetVATReturnPeriods();
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATReportSetup.FieldName("Manual Receive Period CU ID"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure COD_GetVATReturnPeriods()
    var
        VATReportMgt: Codeunit "VAT Report Mgt.";
    begin
        // [SCENARIO 258181] COD 737 "VAT Report Mgt.".GetVATReturnPeriods()
        Initialize();
        SetManualReceivePeriodCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReportMgt.GetVATReturnPeriods();

        Assert.ExpectedMessage(TestCodeunitRunMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD_GetSubmittedVATReturns_Negative()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriod: Record "VAT Return Period";
        VATReportMgt: Codeunit "VAT Report Mgt.";
    begin
        // [SCENARIO 258181] COD 737 "VAT Report Mgt.".GetSubmittedVATReturns() invokes TESTFIELD("Receive Submitted Return CU ID")
        Initialize();
        VATReportSetup.Get();
        VATReportSetup.TestField("Receive Submitted Return CU ID", 0);

        asserterror VATReportMgt.GetSubmittedVATReturns(VATReturnPeriod);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATReportSetup.FieldName("Receive Submitted Return CU ID"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure COD_GetSubmittedVATReturns()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportMgt: Codeunit "VAT Report Mgt.";
    begin
        // [SCENARIO 258181] COD 737 "VAT Report Mgt.".GetSubmittedVATReturns()
        Initialize();
        SetReceiveSubmittedReturnCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReportMgt.GetSubmittedVATReturns(VATReturnPeriod);

        Assert.ExpectedMessage(TestCodeunitRunMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD_DontShowAgainManualInsertNotification()
    var
        MyNotifications: Record "My Notifications";
        VATReportMgt: Codeunit "VAT Report Mgt.";
        DummyNotification: Notification;
    begin
        // [FEATURE] [Notification]
        // [SCENARIO 258181] COD 737 "VAT Report Mgt.".DontShowAgainManualInsertNotification()
        Initialize();
        EnableManualInsertNotification(true);

        VATReportMgt.DontShowAgainManualInsertNotification(DummyNotification);

        MyNotifications.Get(UserId, GetManualInsertNotificationGUID());
        MyNotifications.TestField(Enabled, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD_CreateAndStartJob()
    var
        VATReportSetup: Record "VAT Report Setup";
        JobQueueEntry: Record "Job Queue Entry";
        VATReportMgt: Codeunit "VAT Report Mgt.";
        VATReturnPeriodUT: Codeunit "VAT Return Period UT";
    begin
        // [FEATURE] [Job]
        // [SCENARIO 258181] COD 737 "VAT Report Mgt.".CreateAndStartAutoUpdateVATReturnPeriodJob()
        // [SCENARIO 324828] By default, the Job runs only on working days (Monday-Friday) with max no. of attempts to run = 1
        Initialize();
        SetAutoReceivePeriodCUID(VATReportSetup."Update Period Job Frequency"::Daily, CODEUNIT::TestCodeunitRunMessage);

        VATReportSetup.Get();
        BindSubscription(VATReturnPeriodUT);
        VATReportMgt.CreateAndStartAutoUpdateVATReturnPeriodJob(VATReportSetup);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", VATReportSetup."Auto Receive Period CU ID");
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField("Run on Mondays", true);
        JobQueueEntry.TestField("Run on Tuesdays", true);
        JobQueueEntry.TestField("Run on Wednesdays", true);
        JobQueueEntry.TestField("Run on Thursdays", true);
        JobQueueEntry.TestField("Run on Fridays", true);
        JobQueueEntry.TestField("Run on Saturdays", false);
        JobQueueEntry.TestField("Run on Sundays", false);
        JobQueueEntry.TestField("Maximum No. of Attempts to Run", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB_OnInsert()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportSetup: Record "VAT Report Setup";
    begin
        // [SCENARIO 258181] TAB 737 "VAT Return Period" OnInsert()
        Initialize();
        VATReportSetup.Get();
        VATReportSetup.TestField("VAT Return Period No. Series");

        VATReturnPeriod.Init();
        VATReturnPeriod.Insert(true);
        VATReturnPeriod.TestField("No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB_DiffersFromVATReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReturnPeriod2: Record "VAT Return Period";
    begin
        // [SCENARIO 258181] TAB 737 "VAT Return Period".DiffersFromVATReturnPeriod()
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());

        VATReturnPeriod2 := VATReturnPeriod;
        Assert.IsFalse(VATReturnPeriod.DiffersFromVATReturnPeriod(VATReturnPeriod2), '');

        VATReturnPeriod2.Status := VATReturnPeriod2.Status::Closed;
        Assert.IsTrue(VATReturnPeriod.DiffersFromVATReturnPeriod(VATReturnPeriod2), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB_FindVATReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        // [SCENARIO 258181] TAB 737 "VAT Return Period".FindVATReturnPeriod()
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());

        Assert.IsTrue(
          VATReturnPeriod.FindVATReturnPeriod(VATReturnPeriod, VATReturnPeriod."Start Date", VATReturnPeriod."End Date"), '');
        Assert.IsFalse(
          VATReturnPeriod.FindVATReturnPeriod(VATReturnPeriod, VATReturnPeriod."Start Date", VATReturnPeriod."End Date" + 1), '');
        Assert.IsFalse(
          VATReturnPeriod.FindVATReturnPeriod(VATReturnPeriod, VATReturnPeriod."Start Date" + 1, VATReturnPeriod."End Date"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB_CopyToVATReturn()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        Year: Integer;
    begin
        // [SCENARIO 258181] TAB 737 "VAT Return Period".CopyToVATReturn()
        Initialize();
        Year := Date2DMY(WorkDate(), 3);
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());

        VATReturnPeriod.CopyToVATReturn(VATReportHeader);
        VerifyVATReturnAfterCopyFromReturnPeriod(VATReportHeader, VATReturnPeriod, Year, VATReportHeader."Period Type"::Quarter, 1);

        VATReturnPeriod."End Date" := DMY2Date(31, 1, Date2DMY(WorkDate(), 3));
        VATReturnPeriod.CopyToVATReturn(VATReportHeader);
        VerifyVATReturnAfterCopyFromReturnPeriod(VATReportHeader, VATReturnPeriod, Year, VATReportHeader."Period Type"::Month, 1);

        VATReturnPeriod."End Date" := DMY2Date(31, 12, Date2DMY(WorkDate(), 3));
        VATReturnPeriod.CopyToVATReturn(VATReportHeader);
        VerifyVATReturnAfterCopyFromReturnPeriod(VATReportHeader, VATReturnPeriod, Year, VATReportHeader."Period Type"::Year, Year);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB_CopyToVATReturn_CustomPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        Year: Integer;
    begin
        // [SCENARIO 258181] TAB 737 "VAT Return Period".CopyToVATReturn() in case of custom period
        Initialize();
        Year := Date2DMY(WorkDate(), 3);
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        VATReturnPeriod."Start Date" := DMY2Date(1, 12, Year - 1);
        VATReturnPeriod."End Date" := CalcDate('<3M-1D>', VATReturnPeriod."Start Date");
        VATReturnPeriod.CopyToVATReturn(VATReportHeader);
        VerifyVATReturnAfterCopyFromReturnPeriod(VATReportHeader, VATReturnPeriod, Year, VATReportHeader."Period Type"::" ", 0);

        VATReturnPeriod."End Date" := CalcDate('<2M-1D>', VATReturnPeriod."Start Date");
        VATReturnPeriod.CopyToVATReturn(VATReportHeader);
        VerifyVATReturnAfterCopyFromReturnPeriod(VATReportHeader, VATReturnPeriod, Year, VATReportHeader."Period Type"::" ", 0);

        VATReturnPeriod."End Date" := CalcDate('<10D>', VATReturnPeriod."Start Date");
        VATReturnPeriod.CopyToVATReturn(VATReportHeader);
        VerifyVATReturnAfterCopyFromReturnPeriod(VATReportHeader, VATReturnPeriod, Year - 1, VATReportHeader."Period Type"::" ", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB_VATReturnLinkAfterDeletion()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
    begin
        // [SCENARIO 258181] TAB 737 "VAT Return Period" VAT Return No link is blanked after deletion of TAB 740 "VAT Report Header"
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);
        VATReturnPeriod.TestField("VAT Return No.", VATReportHeader."No.");

        VATReportHeader.Delete(true);
        VATReturnPeriod.Find();

        VATReturnPeriod.TestField("VAT Return No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB_TryToDeleteWhenVATReturnLinkExists()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
    begin
        // [SCENARIO 258181] TAB 737 "VAT Return Period" deletion in case of existing VAT Return No link
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);
        VATReturnPeriod.TestField("VAT Return No.", VATReportHeader."No.");

        asserterror VATReturnPeriod.Delete(true);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(DeleteExistingVATRetErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ManualInsert_BlankedManualReceiveCU()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriod: Record "VAT Return Period";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" manual insert a new record
        // [SCENARIO 258181] in case of VAT Report Setup "Manual Receive Period CU ID" = 0
        Initialize();
        VATReportSetup.Get();
        VATReportSetup.TestField("Manual Receive Period CU ID", 0);

        VATReturnPeriodList.OpenEdit();
        VATReturnPeriodList.New();
        VATReturnPeriodList."Start Date".SetValue(WorkDate() + 1);
        VATReturnPeriodList."End Date".SetValue(WorkDate() + 2);
        VATReturnPeriodList."Due Date".SetValue(WorkDate() + 3);
        VATReturnPeriodList.Close();

        VATReturnPeriod.FindFirst();
        VATReturnPeriod.TestField("Start Date", WorkDate() + 1);
        VATReturnPeriod.TestField("End Date", WorkDate() + 2);
        VATReturnPeriod.TestField("Due Date", WorkDate() + 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ManualInsert_TypedManualReceiveCU()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" manual insert is not possbile
        // [SCENARIO 258181] in case of VAT Report Setup "Manual Receive Period CU ID" <> 0
        Initialize();
        SetManualReceivePeriodCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReturnPeriodList.OpenEdit();
        VATReturnPeriodList.New();
        VATReturnPeriodList."Start Date".SetValue(WorkDate() + 1);
        VATReturnPeriodList."End Date".SetValue(WorkDate() + 2);
        VATReturnPeriodList."Due Date".SetValue(WorkDate() + 3);
        VATReturnPeriodList.Close();

        Assert.RecordIsEmpty(VATReturnPeriod);
    end;

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_ManualInsert_Notification_Enabled()
    var
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [Notification] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" warning notification
        // [SCENARIO 258181] in case of VAT Report Setup "Manual Receive Period CU ID" <> 0 and enabled my notification
        Initialize();
        EnableManualInsertNotification(true);
        SetManualReceivePeriodCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReturnPeriodList.OpenEdit();
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(ManualInsertNotificationMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ManualInsert_Notification_Disabled()
    var
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [Notification] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" no warning notification
        // [SCENARIO 258181] in case of VAT Report Setup "Manual Receive Period CU ID" <> 0 and disabled my notification
        Initialize();
        SetManualReceivePeriodCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReturnPeriodList.OpenEdit();
        VATReturnPeriodList.Close();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_FieldsAndActionsVisibility_List_BlankedManualReceiveCU()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" fields and actions visibility
        // [SCENARIO 258181] in case of VAT Report Setup "Manual Receive Period CU ID" = 0
        Initialize();
        VATReportSetup.Get();
        VATReportSetup.TestField("Manual Receive Period CU ID", 0);

        VATReturnPeriodList.OpenEdit();
        Assert.IsFalse(VATReturnPeriodList."Get VAT Return Periods".Visible(), '');
        Assert.IsTrue(VATReturnPeriodList."Start Date".Editable(), '');
        Assert.IsTrue(VATReturnPeriodList."End Date".Editable(), '');
        Assert.IsTrue(VATReturnPeriodList."Due Date".Editable(), '');
        Assert.IsTrue(VATReturnPeriodList.Status.Editable(), '');
        Assert.IsTrue(VATReturnPeriodList."Received Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodList."VAT Return No.".Editable(), '');
        Assert.IsFalse(VATReturnPeriodList.VATReturnStatus.Editable(), '');
        VATReturnPeriodList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_FieldsAndActionsVisibility_List_TypedManualReceiveCU()
    var
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" fields and actions visibility
        // [SCENARIO 258181] in case of VAT Report Setup "Manual Receive Period CU ID" <> 0
        Initialize();
        SetManualReceivePeriodCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReturnPeriodList.OpenEdit();
        Assert.IsTrue(VATReturnPeriodList."Get VAT Return Periods".Visible(), '');
        Assert.IsFalse(VATReturnPeriodList."Start Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodList."End Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodList."Due Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodList.Status.Editable(), '');
        Assert.IsFalse(VATReturnPeriodList."Received Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodList."VAT Return No.".Editable(), '');
        Assert.IsFalse(VATReturnPeriodList.VATReturnStatus.Editable(), '');
        VATReturnPeriodList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_FieldsAndActionsVisibility_Card_BlankedReceiveSubmittedReturnCU()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" fields and actions visibility
        // [SCENARIO 258181] in case of VAT Report Setup "Receive Submitted Return CU ID" = 0
        Initialize();
        VATReportSetup.Get();
        VATReportSetup.TestField("Receive Submitted Return CU ID", 0);

        VATReturnPeriodCard.OpenEdit();
        Assert.IsFalse(VATReturnPeriodCard."Receive Submitted VAT Returns".Visible(), '');
        Assert.IsFalse(VATReturnPeriodCard."Start Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard."End Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard."Due Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard.Status.Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard."Received Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard."VAT Return No.".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard.VATReturnStatus.Editable(), '');
        VATReturnPeriodCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_FieldsAndActionsVisibility_Card_TypedReceiveSubmittedReturnCU()
    var
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" fields and actions visibility
        // [SCENARIO 258181] in case of VAT Report Setup "Receive Submitted Return CU ID" <> 0
        Initialize();
        SetReceiveSubmittedReturnCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReturnPeriodCard.OpenEdit();
        Assert.IsTrue(VATReturnPeriodCard."Receive Submitted VAT Returns".Visible(), '');
        Assert.IsFalse(VATReturnPeriodCard."Start Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard."End Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard."Due Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard.Status.Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard."Received Date".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard."VAT Return No.".Editable(), '');
        Assert.IsFalse(VATReturnPeriodCard.VATReturnStatus.Editable(), '');
        VATReturnPeriodCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_CreateOrOpenReturnActions_OpenPeriodWithoutLinkedReturn()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737, 738 "VAT Return Period List", "VAT Return Period Card" actions "Create VAT Return" and "Open VAT Return Card"
        // [SCENARIO 258181] in case of open VAT Return Period without linked Return
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        Assert.IsTrue(VATReturnPeriodList."Create VAT Return".Enabled(), '');
        Assert.IsTrue(VATReturnPeriodList."Open VAT Return Card".Enabled(), '');
        VATReturnPeriodList.Close();

        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);
        Assert.IsTrue(VATReturnPeriodCard."Create VAT Return".Enabled(), '');
        Assert.IsTrue(VATReturnPeriodCard."Open VAT Return Card".Enabled(), '');
        VATReturnPeriodCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_CreateOrOpenReturnActions_ClosedPeriodWithoutLinkedReturn()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737, 738 "VAT Return Period List", "VAT Return Period Card" actions "Create VAT Return" and "Open VAT Return Card"
        // [SCENARIO 258181] in case of closed VAT Return Period without linked Return
        Initialize();
        MockClosedVATReturnPeriod(VATReturnPeriod, WorkDate());

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        Assert.IsFalse(VATReturnPeriodList."Create VAT Return".Enabled(), '');
        Assert.IsFalse(VATReturnPeriodList."Open VAT Return Card".Enabled(), '');
        VATReturnPeriodList.Close();

        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);
        Assert.IsFalse(VATReturnPeriodCard."Create VAT Return".Enabled(), '');
        Assert.IsFalse(VATReturnPeriodCard."Open VAT Return Card".Enabled(), '');
        VATReturnPeriodCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_CreateOrOpenReturnActions_OpenPeriodWithLinkedReturn()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737, 738 "VAT Return Period List", "VAT Return Period Card" actions "Create VAT Return" and "Open VAT Return Card"
        // [SCENARIO 258181] in case of open VAT Return Period with linked Return
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        Assert.IsFalse(VATReturnPeriodList."Create VAT Return".Enabled(), '');
        Assert.IsTrue(VATReturnPeriodList."Open VAT Return Card".Enabled(), '');
        VATReturnPeriodList.Close();

        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);
        Assert.IsFalse(VATReturnPeriodCard."Create VAT Return".Enabled(), '');
        Assert.IsTrue(VATReturnPeriodCard."Open VAT Return Card".Enabled(), '');
        VATReturnPeriodCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_CreateOrOpenReturnActions_ClosedPeriodWithLinkedReturn()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737, 738 "VAT Return Period List", "VAT Return Period Card" actions "Create VAT Return" and "Open VAT Return Card"
        // [SCENARIO 258181] in case of closed VAT Return Period with linked Return
        Initialize();
        MockClosedVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        Assert.IsFalse(VATReturnPeriodList."Create VAT Return".Enabled(), '');
        Assert.IsTrue(VATReturnPeriodList."Open VAT Return Card".Enabled(), '');
        VATReturnPeriodList.Close();

        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);
        Assert.IsFalse(VATReturnPeriodCard."Create VAT Return".Enabled(), '');
        Assert.IsTrue(VATReturnPeriodCard."Open VAT Return Card".Enabled(), '');
        VATReturnPeriodCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_CreateReturnAction_List_DenyOpenNewVATReturnCard()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" action "Create VAT Return" (deny open a new VAT Return card)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);

        LibraryVariableStorage.Enqueue(false); // Deny open a new VAT Return Card
        VATReturnPeriodList."Create VAT Return".Invoke();
        VATReportHeader.FindFirst();
        VATReturnPeriodList."VAT Return No.".AssertEquals(VATReportHeader."No.");
        VATReturnPeriodList.VATReturnStatus.AssertEquals('Open');
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(StrSubstNo(CreateVATReturnQst, VATReportHeader."No."), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_CreateReturnAction_List_AcceptNewVATReturnCard()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" action "Create VAT Return" (accept open a new VAT Return card)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);

        LibraryVariableStorage.Enqueue(true); // Accept open a new VAT Return Card
        VATReturnPeriodList."Create VAT Return".Invoke();
        VATReportHeader.FindFirst();
        VATReturnPeriodList."VAT Return No.".AssertEquals(VATReportHeader."No.");
        VATReturnPeriodList.VATReturnStatus.AssertEquals('Open');
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(StrSubstNo(CreateVATReturnQst, VATReportHeader."No."), LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_CreateReturnAction_Card_DenyOpenNewVATReturnCard()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" action "Create VAT Return" (deny open a new VAT Return card)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);

        LibraryVariableStorage.Enqueue(false); // Deny open a new VAT Return Card
        VATReturnPeriodCard."Create VAT Return".Invoke();
        VATReportHeader.FindFirst();
        VATReturnPeriodCard."VAT Return No.".AssertEquals(VATReportHeader."No.");
        VATReturnPeriodCard.VATReturnStatus.AssertEquals('Open');
        VATReturnPeriodCard.Close();

        Assert.ExpectedMessage(StrSubstNo(CreateVATReturnQst, VATReportHeader."No."), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_CreateReturnAction_Card_AcceptNewVATReturnCard()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" action "Create VAT Return" (accept open a new VAT Return card)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);

        LibraryVariableStorage.Enqueue(true); // Accept open a new VAT Return Card
        VATReturnPeriodCard."Create VAT Return".Invoke();
        VATReportHeader.FindFirst();
        VATReturnPeriodCard."VAT Return No.".AssertEquals(VATReportHeader."No.");
        VATReturnPeriodCard.VATReturnStatus.AssertEquals('Open');
        VATReturnPeriodCard.Close();

        Assert.ExpectedMessage(StrSubstNo(CreateVATReturnQst, VATReportHeader."No."), LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_OpenReturnAction_List_WithLinkedReturn()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" action "Open VAT Return Card" with linked Return
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);
        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);

        VATReturnPeriodList."VAT Return No.".AssertEquals(VATReportHeader."No.");
        VATReturnPeriodList.VATReturnStatus.AssertEquals('Open');
        VATReturnPeriodList."Open VAT Return Card".Invoke();
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_OpenReturnAction_List_WithoutLinkedReturn_DenyCreate()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" action "Open VAT Return Card" without linked Return (suggest to create - deny)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);

        LibraryVariableStorage.Enqueue(false); // Deny create a new VAT Return Card
        VATReturnPeriodList."Open VAT Return Card".Invoke();
        VATReturnPeriodList."VAT Return No.".AssertEquals('');
        VATReturnPeriodList.VATReturnStatus.AssertEquals(' ');
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(NoVATReturnQst, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_OpenReturnAction_List_WithoutLinkedReturn_AcceptCreate()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" action "Open VAT Return Card" without linked Return (suggest to create - accept)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);

        LibraryVariableStorage.Enqueue(true); // Accept create a new VAT Return Card
        VATReturnPeriodList."Open VAT Return Card".Invoke();
        VATReportHeader.FindFirst();
        VATReturnPeriodList."VAT Return No.".AssertEquals(VATReportHeader."No.");
        VATReturnPeriodList.VATReturnStatus.AssertEquals('Open');
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(NoVATReturnQst, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_OpenReturnAction_Card_WithLinkedReturn()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" action "Open VAT Return Card" with linked Return
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);
        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);

        VATReturnPeriodCard."VAT Return No.".AssertEquals(VATReportHeader."No.");
        VATReturnPeriodCard.VATReturnStatus.AssertEquals('Open');
        VATReturnPeriodCard."Open VAT Return Card".Invoke();
        VATReturnPeriodCard.Close();

        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_OpenReturnAction_Card_WithoutLinkedReturn_DenyCreate()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" action "Open VAT Return Card" without linked Return (suggest to create - deny)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);

        LibraryVariableStorage.Enqueue(false); // Deny create a new VAT Return Card
        VATReturnPeriodCard."Open VAT Return Card".Invoke();
        VATReturnPeriodCard."VAT Return No.".AssertEquals('');
        VATReturnPeriodCard.VATReturnStatus.AssertEquals(' ');
        VATReturnPeriodCard.Close();

        Assert.ExpectedMessage(NoVATReturnQst, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_OpenReturnAction_Card_WithoutLinkedReturn_AcceptCreate()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" action "Open VAT Return Card" without linked Return (suggest to create - accept)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);

        LibraryVariableStorage.Enqueue(true); // Accept create a new VAT Return Card
        VATReturnPeriodCard."Open VAT Return Card".Invoke();
        VATReportHeader.FindFirst();
        VATReturnPeriodCard."VAT Return No.".AssertEquals(VATReportHeader."No.");
        VATReturnPeriodCard.VATReturnStatus.AssertEquals('Open');
        VATReturnPeriodCard.Close();

        Assert.ExpectedMessage(NoVATReturnQst, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_List_GetVATReturnPeriods()
    var
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" action "Get VAT Return Periods"
        Initialize();
        SetManualReceivePeriodCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReturnPeriodList.OpenEdit();
        VATReturnPeriodList."Get VAT Return Periods".Invoke();
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(TestCodeunitRunMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_Card_ReceiveSubmittedVATReturns()
    var
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" action "Get VAT Return Periods"
        Initialize();
        SetReceiveSubmittedReturnCUID(CODEUNIT::TestCodeunitRunMessage);

        VATReturnPeriodCard.OpenEdit();
        VATReturnPeriodCard."Receive Submitted VAT Returns".Invoke();
        VATReturnPeriodCard.Close();

        Assert.ExpectedMessage(TestCodeunitRunMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_DrillDown_List_VATReturnNo()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" lookup of "VAT Return No." field opens VAT Return card
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);
        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);

        VATReturnPeriodList."VAT Return No.".Lookup();
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_DrillDown_List_VATReturnStatus()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodList: TestPage "VAT Return Period List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" drilldown of "VAT Return Status" field opens VAT Return card
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);
        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);

        VATReturnPeriodList.VATReturnStatus.DrillDown();
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_DrillDown_Card_VATReturnNo()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" lookup of "VAT Return No." field opens VAT Return card
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);
        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);

        VATReturnPeriodCard."VAT Return No.".Lookup();
        VATReturnPeriodCard.Close();

        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_DrillDown_Card_VATReturnStatus()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriodCard: TestPage "VAT Return Period Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 738 "VAT Return Period Card" drilldown of "VAT Return Status" field opens VAT Return card
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);
        OpenVATReturnPeriodCard(VATReturnPeriodCard, VATReturnPeriod);

        VATReturnPeriodCard.VATReturnStatus.DrillDown();
        VATReturnPeriodCard.Close();

        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_Factbox_OverdueOpenVATReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        DueDate: Date;
        DaysCount: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] Warning factbox message for overdue Open VAT Return Period
        Initialize();
        VATReportSetup.Get();

        DaysCount := LibraryRandom.RandIntInRange(10, 20);
        DueDate := WorkDate() - DaysCount;
        MockOpenVATReturnPeriod(VATReturnPeriod, DueDate);

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        VATReturnPeriodList.Control9.WarningText.AssertEquals(
          StrSubstNo('Your VAT return is overdue since %1 (%2 days)', DueDate, DaysCount));
        VATReturnPeriodList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_Factbox_OverdueClosedVATReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        DueDate: Date;
        DaysCount: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] There is no warning factbox message for overdue Closed VAT Return Period
        Initialize();
        VATReportSetup.Get();

        DaysCount := LibraryRandom.RandIntInRange(10, 20);
        DueDate := WorkDate() - DaysCount;
        MockClosedVATReturnPeriod(VATReturnPeriod, DueDate);

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        VATReturnPeriodList.Control9.WarningText.AssertEquals('');
        VATReturnPeriodList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_Factbox_UpcomingOpenVATReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        DueDate: Date;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] Warning factbox message for upcoming Open VAT Return Period
        // [SCENARIO 306583] The calculation is based on VATReportSetup."Period Reminder Calculation"
        Initialize();
        VATReportSetup.Get();

        DueDate := CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate());
        MockOpenVATReturnPeriod(VATReturnPeriod, DueDate);

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        VATReturnPeriodList.Control9.WarningText.AssertEquals(
          StrSubstNo('Your VAT return is due %1 (in %2 days)', DueDate, DueDate - WorkDate()));
        VATReturnPeriodList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_Factbox_NotUpcomingOpenVATReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        DueDate: Date;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] There is no warning factbox message for not upcoming Open VAT Return Period
        // [SCENARIO 306583] The calculation is based on VATReportSetup."Period Reminder Calculation"
        Initialize();
        VATReportSetup.Get();

        DueDate := CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate()) + 1;
        MockOpenVATReturnPeriod(VATReturnPeriod, DueDate);

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        VATReturnPeriodList.Control9.WarningText.AssertEquals('');
        VATReturnPeriodList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_Factbox_UpcomingClosedVATReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        DueDate: Date;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] There is no warning factbox message for upcoming Closed VAT Return Period
        // [SCENARIO 306583] The calculation is based on VATReportSetup."Period Reminder Calculation"
        Initialize();
        VATReportSetup.Get();

        DueDate := CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate());
        MockClosedVATReturnPeriod(VATReturnPeriod, DueDate);

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        VATReturnPeriodList.Control9.WarningText.AssertEquals('');
        VATReturnPeriodList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_Factbox_OverdueAndUpcomingOpenVATReturnPeriods()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        OverdueDueDate: Date;
        OverdueDaysCount: Integer;
        UpcomingDueDate: Date;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] Warning factbox message for overdue Open VAT Return Period and for upcoming Open VAT Return Period records
        // [SCENARIO 306583] The calculation is based on VATReportSetup."Period Reminder Calculation"
        Initialize();
        VATReportSetup.Get();

        OverdueDaysCount := LibraryRandom.RandIntInRange(10, 20);
        OverdueDueDate := WorkDate() - OverdueDaysCount;
        MockOpenVATReturnPeriod(VATReturnPeriod, OverdueDueDate);

        UpcomingDueDate := CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate());
        MockOpenVATReturnPeriod(VATReturnPeriod, UpcomingDueDate);

        OpenVATReturnPeriodList(VATReturnPeriodList, VATReturnPeriod);
        VATReturnPeriodList.First();
        VATReturnPeriodList.Control9.WarningText.AssertEquals(
          StrSubstNo('Your VAT return is overdue since %1 (%2 days)', OverdueDueDate, OverdueDaysCount));

        VATReturnPeriodList.Next();
        VATReturnPeriodList.Control9.WarningText.AssertEquals(
          StrSubstNo('Your VAT return is due %1 (in %2 days)', UpcomingDueDate, UpcomingDueDate - WorkDate()));
        VATReturnPeriodList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_VATReturn_List_ActionsVisibility_LinkedReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReportListPage: TestPage "VAT Report List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 744 "VAT Report List" actions visibility in case of linked VAT Return Period
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);

        OpenVATReportList(VATReportListPage, VATReportHeader);
        Assert.IsTrue(VATReportListPage."Create From VAT Return Period".Visible(), '');
        Assert.IsTrue(VATReportListPage.Card.Visible(), '');
        Assert.IsTrue(VATReportListPage."Open VAT Return Period Card".Visible(), '');
        VATReportListPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_VATReturn_List_ActionsVisibility_NoLinkedReturnPeriod()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportListPage: TestPage "VAT Report List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 744 "VAT Report List" actions visibility in case of no linked VAT Return Period
        Initialize();
        MockVATReturn(VATReportHeader);

        OpenVATReportList(VATReportListPage, VATReportHeader);
        Assert.IsTrue(VATReportListPage."Create From VAT Return Period".Visible(), '');
        Assert.IsTrue(VATReportListPage.Card.Visible(), '');
        Assert.IsFalse(VATReportListPage."Open VAT Return Period Card".Visible(), '');
        VATReportListPage.Close();
    end;

    [Test]
    [HandlerFunctions('VATReturnPeriodCard_MPH')]
    [Scope('OnPrem')]
    procedure UI_VATReturn_List_OpenReturnPeriodCard()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReportListPage: TestPage "VAT Report List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 744 "VAT Report List" action "Open VAT Return Period Card"
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);

        OpenVATReportList(VATReportListPage, VATReportHeader);
        VATReportListPage."Open VAT Return Period Card".Invoke();
        VATReportListPage.Close();

        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_VATReturn_Card_ActionsVisibility_LinkedReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReportCardPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 740 "VAT Report" actions visibility in case of linked VAT Return Period
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);

        OpenVATReportCard(VATReportCardPage, VATReportHeader);
        Assert.IsTrue(VATReportCardPage."Open VAT Return Period Card".Visible(), '');
        Assert.IsFalse(VATReportCardPage."VAT Report Version".Editable(), '');
        VATReportCardPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_VATReturn_Card_ActionsVisibility_NoLinkedReturnPeriod()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportCardPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 740 "VAT Report" actions visibility in case of no linked VAT Return Period
        Initialize();
        MockVATReturn(VATReportHeader);

        OpenVATReportCard(VATReportCardPage, VATReportHeader);
        Assert.IsFalse(VATReportCardPage."Open VAT Return Period Card".Visible(), '');
        Assert.IsTrue(VATReportCardPage."VAT Report Version".Editable(), '');
        VATReportCardPage.Close();
    end;

    [Test]
    [HandlerFunctions('VATReturnPeriodCard_MPH')]
    [Scope('OnPrem')]
    procedure UI_VATReturn_Card_OpenReturnPeriodCard()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReportCardPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 740 "VAT Report" action "Open VAT Return Period Card"
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockLinkedVATReturn(VATReportHeader, VATReturnPeriod);

        OpenVATReportCard(VATReportCardPage, VATReportHeader);
        VATReportCardPage."Open VAT Return Period Card".Invoke();
        VATReportCardPage.Close();

        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReturnPeriodList_Cancel_MPH')]
    [Scope('OnPrem')]
    procedure UI_VATReturn_Card_ValidateReportVersion_DenySelectPeriod()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportHeader: Record "VAT Report Header";
        VATReportCardPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 740 "VAT Report" validation of "VAT Report Version"
        // [SCENARIO 258181] in case of "VAT Report Setup"."VAT Report Version" and deny from period list
        Initialize();
        VATReportSetup.Get();
        MockVATReturn(VATReportHeader);
        OpenVATReportCard(VATReportCardPage, VATReportHeader);

        VATReportCardPage."VAT Report Version".SetValue(VATReportSetup."Report Version");

        Assert.IsTrue(VATReportCardPage."VAT Report Version".Editable(), '');
        Assert.AreEqual(VATReportSetup."Report Version", VATReportCardPage."VAT Report Version".Value, '');
        VATReportCardPage.Close();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReturnPeriodList_Ok_MPH')]
    [Scope('OnPrem')]
    procedure UI_VATReturn_Card_ValidateReportVersion_AcceptSelectPeriod()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReportCardPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 740 "VAT Report" validation of "VAT Report Version"
        // [SCENARIO 258181] in case of "VAT Report Setup"."VAT Report Version" and accept from period list
        Initialize();
        VATReportSetup.Get();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());
        MockVATReturn(VATReportHeader);
        OpenVATReportCard(VATReportCardPage, VATReportHeader);

        VATReportCardPage."VAT Report Version".SetValue(VATReportSetup."Report Version");

        Assert.IsFalse(VATReportCardPage."VAT Report Version".Editable(), '');
        Assert.AreEqual(VATReportSetup."Report Version", VATReportCardPage."VAT Report Version".Value, '');
        VATReportCardPage.ReturnPeriodStatus.AssertEquals(VATReturnPeriod.Status);
        VATReportCardPage.ReturnPeriodDueDate.AssertEquals(VATReturnPeriod."Due Date");
        VATReportCardPage.Close();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReturnPeriodList_Cancel_MPH')]
    [Scope('OnPrem')]
    procedure UI_VATReturn_List_CreateFromPeriodAction_Cancel()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReportListPage: TestPage "VAT Report List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 744 "VAT Report List" action "Create From VAT Return Period" (cancel)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());

        VATReportListPage.OpenEdit();
        VATReportListPage."Create From VAT Return Period".Invoke(); // Cancel reply
        VATReportListPage.Close();

        Assert.RecordIsEmpty(VATReportHeader);
    end;

    [Test]
    [HandlerFunctions('VATReturnPeriodList_Ok_MPH,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_VATReturn_List_CreateFromPeriodAction_Ok_DenyOpen()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReportListPage: TestPage "VAT Report List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 744 "VAT Report List" action "Create From VAT Return Period" (ok, deny open a new return)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());

        VATReportListPage.OpenEdit();
        LibraryVariableStorage.Enqueue(false); // deny open a new VAT Return
        VATReportListPage."Create From VAT Return Period".Invoke(); // Ok reply
        VATReportListPage.Close();

        VATReportHeader.FindFirst();
        Assert.ExpectedMessage(StrSubstNo(CreateVATReturnQst, VATReportHeader."No."), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReturnPeriodList_Ok_MPH,ConfirmHandler,VATReport_MPH')]
    [Scope('OnPrem')]
    procedure UI_VATReturn_List_CreateFromPeriodAction_Ok_AcceptOpen()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATReportListPage: TestPage "VAT Report List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 744 "VAT Report List" action "Create From VAT Return Period" (ok, accept open a new return)
        Initialize();
        MockOpenVATReturnPeriod(VATReturnPeriod, WorkDate());

        VATReportListPage.OpenEdit();
        LibraryVariableStorage.Enqueue(true); // accept open a new VAT Return
        VATReportListPage."Create From VAT Return Period".Invoke(); // Ok reply
        VATReportListPage.Close();

        VATReportHeader.FindFirst();
        Assert.ExpectedMessage(StrSubstNo(CreateVATReturnQst, VATReportHeader."No."), LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(VATReportHeader."No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetup_PeriodJobFrequency_Negative()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // [FEATURE] [Job]
        // [SCENARIO 258181] TAB 743 "VAT Report Setup" validate "Update Period Job Frequency"
        // [SCENARIO 258181] in case of "Auto Receive Period CU ID" = 0
        Initialize();
        VATReportSetup.Get();
        VATReportSetup.TestField("Update Period Job Frequency", VATReportSetup."Update Period Job Frequency"::Never);

        asserterror VATReportSetup.Validate("Update Period Job Frequency", VATReportSetup."Update Period Job Frequency"::Daily);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATReportSetup.FieldName("Auto Receive Period CU ID"));
    end;

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_FailedAutoUpdateJobNotification()
    var
        DummyVATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        JobDateTime: DateTime;
    begin
        // [FEATURE] [Job] [Notification] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" notification about failed auto update job
        Initialize();
        SetAutoReceivePeriodCUID(DummyVATReportSetup."Update Period Job Frequency"::Daily, CODEUNIT::TestCodeunitRunMessage);

        JobDateTime := CreateDateTime(LibraryRandom.RandDate(10), Time);
        MockFailedJobLogEntry(JobDateTime);

        VATReturnPeriodList.OpenEdit();
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(StrSubstNo(FailedJobNotificationMsg, JobDateTime), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_ManualInsertAndFailedAutoUpdateJobNotifications()
    var
        DummyVATReportSetup: Record "VAT Report Setup";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        JobDateTime: DateTime;
    begin
        // [FEATURE] [Job] [Notification] [UI]
        // [SCENARIO 258181] PAG 737 "VAT Return Period List" two notifications: manual insert warning and failed auto update job
        Initialize();
        EnableManualInsertNotification(true);
        SetManualReceivePeriodCUID(CODEUNIT::TestCodeunitRunMessage);
        SetAutoReceivePeriodCUID(DummyVATReportSetup."Update Period Job Frequency"::Daily, CODEUNIT::TestCodeunitRunMessage);

        JobDateTime := CreateDateTime(LibraryRandom.RandDate(10), Time);
        MockFailedJobLogEntry(JobDateTime);

        VATReturnPeriodList.OpenEdit();
        VATReturnPeriodList.Close();

        Assert.ExpectedMessage(ManualInsertNotificationMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(StrSubstNo(FailedJobNotificationMsg, JobDateTime), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('JobQueueEntryCard_MPH')]
    [Scope('OnPrem')]
    procedure UI_OpenVATReturnPeriodJobCard()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DummyVATReportSetup: Record "VAT Report Setup";
        VATReportMgt: Codeunit "VAT Report Mgt.";
        DummyNotification: Notification;
    begin
        // [FEATURE] [Job] [UI]
        // [SCENARIO 258181] COD 737 "VAT Report Mgt.".OpenVATReturnPeriodJobCard()
        Initialize();
        SetAutoReceivePeriodCUID(DummyVATReportSetup."Update Period Job Frequency"::Daily, CODEUNIT::TestCodeunitRunMessage);

        MockJobQueueEntry(JobQueueEntry, CODEUNIT::TestCodeunitRunMessage);
        VATReportMgt.OpenVATReturnPeriodJobCard(DummyNotification);

        Assert.AreEqual(CODEUNIT::TestCodeunitRunMessage, LibraryVariableStorage.DequeueInteger(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetup_IsPeriodReminderCalculation()
    var
        VATReportSetup: Record "VAT Report Setup";
        DummyDateFormula: DateFormula;
    begin
        // [SCENARIO 306583] TAB 743 "VAT Report Setup".IsPeriodReminderCalculation() returns TRUE in case of "Period Reminder Calculation" typed value
        Initialize();

        VATReportSetup.Get();
        VATReportSetup.TestField("Period Reminder Calculation");
        Assert.IsTrue(VATReportSetup.IsPeriodReminderCalculation(), 'VATReportSetup.IsPeriodReminderCalculation()');

        VATReportSetup."Period Reminder Calculation" := DummyDateFormula;
        Assert.IsFalse(VATReportSetup.IsPeriodReminderCalculation(), 'VATReportSetup.IsPeriodReminderCalculation()');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetup_ValidatePeriodReminderCalculation_Positive()
    var
        VATReportSetup: Record "VAT Report Setup";
        DateFormula: DateFormula;
    begin
        // [SCENARIO 306583] Validate TAB 743 "VAT Report Setup"."Period Reminder Calculation" in case of positive dateformula
        Initialize();
        VATReportSetup.Get();

        Evaluate(DateFormula, '<0D>');
        VATReportSetup.Validate("Period Reminder Calculation", DateFormula);
        VATReportSetup.TestField("Period Reminder Calculation", DateFormula);

        Evaluate(DateFormula, '<-0D>');
        VATReportSetup.Validate("Period Reminder Calculation", DateFormula);
        VATReportSetup.TestField("Period Reminder Calculation", DateFormula);

        Evaluate(DateFormula, '<1D>');
        VATReportSetup.Validate("Period Reminder Calculation", DateFormula);
        VATReportSetup.TestField("Period Reminder Calculation", DateFormula);

        Evaluate(DateFormula, '<1M-1D>');
        VATReportSetup.Validate("Period Reminder Calculation", DateFormula);
        VATReportSetup.TestField("Period Reminder Calculation", DateFormula);

        Evaluate(DateFormula, '<1D-1D>');
        VATReportSetup.Validate("Period Reminder Calculation", DateFormula);
        VATReportSetup.TestField("Period Reminder Calculation", DateFormula);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetup_ValidatePeriodReminderCalculation_Negative()
    var
        VATReportSetup: Record "VAT Report Setup";
        DateFormula: DateFormula;
    begin
        // [SCENARIO 306583] Validate TAB 743 "VAT Report Setup"."Period Reminder Calculation" in case of negative dateformula
        Initialize();
        VATReportSetup.Get();

        Evaluate(DateFormula, '<-1D>');
        asserterror VATReportSetup.Validate("Period Reminder Calculation", DateFormula);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PositivePeriodReminderCalcErr);

        Evaluate(DateFormula, '<1D-1M>');
        asserterror VATReportSetup.Validate("Period Reminder Calculation", DateFormula);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PositivePeriodReminderCalcErr);
    end;

    local procedure Initialize()
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        DummyVATReportSetup: Record "VAT Report Setup";
    begin
        LibraryVariableStorage.Clear();
        VATReturnPeriod.DeleteAll();
        VATReportHeader.DeleteAll();
        SetManualReceivePeriodCUID(0);
        SetReceiveSubmittedReturnCUID(0);
        SetAutoReceivePeriodCUID(DummyVATReportSetup."Update Period Job Frequency"::Never, 0);
        EnableManualInsertNotification(false);

        if IsInitialized then
            exit;
        IsInitialized := true;

        InitVATReportSetup();
        Commit();
    end;

    local procedure MockOpenVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"; NewDueDate: Date)
    var
        DummyVATReturnPeriod: Record "VAT Return Period";
    begin
        MockVATReturnPeriod(VATReturnPeriod, DummyVATReturnPeriod.Status::Open, NewDueDate);
    end;

    local procedure MockClosedVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"; NewDueDate: Date)
    var
        DummyVATReturnPeriod: Record "VAT Return Period";
    begin
        MockVATReturnPeriod(VATReturnPeriod, DummyVATReturnPeriod.Status::Closed, NewDueDate);
    end;

    local procedure MockVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"; NewStatus: Option; NewDueDate: Date)
    begin
        VATReturnPeriod."No." := LibraryUtility.GenerateGUID();
        VATReturnPeriod.Status := NewStatus;
        VATReturnPeriod."Start Date" := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        VATReturnPeriod."End Date" := DMY2Date(31, 3, Date2DMY(WorkDate(), 3));
        VATReturnPeriod."Due Date" := NewDueDate;
        VATReturnPeriod.Insert();
    end;

    local procedure MockLinkedVATReturn(var VATReportHeader: Record "VAT Report Header"; var VATReturnPeriod: Record "VAT Return Period")
    begin
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader."No." := LibraryUtility.GenerateGUID();
        VATReportHeader."Return Period No." := VATReturnPeriod."No.";
        VATReportHeader.Insert(true);
        VATReturnPeriod."VAT Return No." := VATReportHeader."No.";
        VATReturnPeriod.Modify();
    end;

    local procedure MockVATReturn(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader."No." := LibraryUtility.GenerateGUID();
        VATReportHeader.Insert(true);
    end;

    local procedure MockJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; CodeunitID: Integer)
    begin
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitID;
        JobQueueEntry.Insert();
    end;

    local procedure MockFailedJobLogEntry(JobDateTime: DateTime)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        JobQueueLogEntry."Entry No." := LibraryUtility.GetNewRecNo(JobQueueLogEntry, JobQueueLogEntry.FieldNo("Entry No."));
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := VATReportSetup."Auto Receive Period CU ID";
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry."Start Date/Time" := JobDateTime;
        JobQueueLogEntry.Insert();
    end;

    local procedure OpenVATReturnPeriodList(var VATReturnPeriodList: TestPage "VAT Return Period List"; VATReturnPeriod: Record "VAT Return Period")
    begin
        VATReturnPeriodList.Trap();
        PAGE.Run(PAGE::"VAT Return Period List", VATReturnPeriod);
    end;

    local procedure OpenVATReturnPeriodCard(var VATReturnPeriodCard: TestPage "VAT Return Period Card"; VATReturnPeriod: Record "VAT Return Period")
    begin
        VATReturnPeriodCard.Trap();
        PAGE.Run(PAGE::"VAT Return Period Card", VATReturnPeriod);
    end;

    local procedure OpenVATReportList(var VATReportList: TestPage "VAT Report List"; VATReportHeader: Record "VAT Report Header")
    begin
        VATReportList.Trap();
        PAGE.Run(PAGE::"VAT Report List", VATReportHeader);
    end;

    local procedure OpenVATReportCard(var VATReport: TestPage "VAT Report"; VATReportHeader: Record "VAT Report Header")
    begin
        VATReport.Trap();
        PAGE.Run(PAGE::"VAT Report", VATReportHeader);
    end;

    local procedure InitVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup."VAT Return No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        VATReportSetup."VAT Return Period No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        Evaluate(VATReportSetup."Period Reminder Calculation", StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(10, 20)));
        VATReportSetup."Report Version" := LibraryVATReport.CreateVATReportConfigurationNo();
        VATReportSetup."Update Period Job Frequency" := VATReportSetup."Update Period Job Frequency"::Never;
        VATReportSetup."Manual Receive Period CU ID" := 0;
        VATReportSetup."Receive Submitted Return CU ID" := 0;
        VATReportSetup."Auto Receive Period CU ID" := 0;
        VATReportSetup.Modify();
    end;

    local procedure SetManualReceivePeriodCUID(NewManualReceivePeriodCUID: Integer)
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup."Manual Receive Period CU ID" := NewManualReceivePeriodCUID;
        VATReportSetup.Modify();
    end;

    local procedure SetReceiveSubmittedReturnCUID(NewReceiveSubmittedReturnCUID: Integer)
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup."Receive Submitted Return CU ID" := NewReceiveSubmittedReturnCUID;
        VATReportSetup.Modify();
    end;

    local procedure SetAutoReceivePeriodCUID(UpdatePeriodJobFrequency: Option; AutoReceivePeriodCUID: Integer)
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup."Update Period Job Frequency" := UpdatePeriodJobFrequency;
        VATReportSetup."Auto Receive Period CU ID" := AutoReceivePeriodCUID;
        VATReportSetup.Modify();
    end;

    local procedure GetManualInsertNotificationGUID(): Guid
    begin
        exit('93003212-76EA-490F-A5C6-6961656A7CF8');
    end;

    local procedure EnableManualInsertNotification(NewEnabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Get(UserId, GetManualInsertNotificationGUID()) then begin
            MyNotifications."User Id" := UserId;
            MyNotifications."Notification Id" := GetManualInsertNotificationGUID();
            MyNotifications.Insert();
        end;
        MyNotifications.Enabled := NewEnabled;
        MyNotifications.Modify();
    end;

    local procedure VerifyVATReturnAfterCopyFromReturnPeriod(VATReportHeader: Record "VAT Report Header"; VATReturnPeriod: Record "VAT Return Period"; ExpectedPeriodYear: Integer; ExpectedPeriodType: Option; ExpectedPeriodNo: Integer)
    begin
        VATReportHeader.TestField("Return Period No.", VATReturnPeriod."No.");
        VATReportHeader.TestField("Start Date", VATReturnPeriod."Start Date");
        VATReportHeader.TestField("End Date", VATReturnPeriod."End Date");
        VATReportHeader.TestField("Period Year", ExpectedPeriodYear);
        VATReportHeader.TestField("Period Type", ExpectedPeriodType);
        VATReportHeader.TestField("Period No.", ExpectedPeriodNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeScheduleTask', '', false, false)]
    local procedure OnBeforeScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid)
    begin
        TaskGUID := CreateGuid();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReport_MPH(var VATReport: TestPage "VAT Report")
    begin
        LibraryVariableStorage.Enqueue(VATReport."No.".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReturnPeriodCard_MPH(var VATReturnPeriodCard: TestPage "VAT Return Period Card")
    begin
        LibraryVariableStorage.Enqueue(VATReturnPeriodCard."VAT Return No.".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReturnPeriodList_Cancel_MPH(var VATReturnPeriodList: TestPage "VAT Return Period List")
    begin
        VATReturnPeriodList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReturnPeriodList_Ok_MPH(var VATReturnPeriodList: TestPage "VAT Return Period List")
    begin
        VATReturnPeriodList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobQueueEntryCard_MPH(var JobQueueEntryCard: TestPage "Job Queue Entry Card")
    begin
        LibraryVariableStorage.Enqueue(JobQueueEntryCard."Object ID to Run".Value);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationHandler(var TheNotification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(TheNotification.Message);
    end;
}

