codeunit 144009 "UT Balance Sheet"
{
    // 1. Purpose of the test is to validate Account Schedule Page through Page FR Account Schedule Names.
    // 2. Purpose of the test is to validate Print Action through Page FR Account Schedule.
    // 3. Purpose of the test is to validate OnAfterGetRecord - FR Acc. Schedule Name table code on Report FR Account Schedule.
    // 4. Purpose of the test is to validate OnAfterGetRecord - FR Acc. Schedule Line table code on Report FR Account Schedule.
    // 5. Purpose of the test is to validate OnInsret code for Table 10801 - FR Acc. Schedule Line.
    // 6. Purpose of the test is to validate OnValidate Code of Totaling of Table 10801 - FR Acc. Schedule Line.
    // 7. Purpose of the test is to validate OnValidate Code of Totaling Debtor of Table 10801 - FR Acc. Schedule Line.
    // 8. Purpose of the test is to validate OnValidate Code of Totaling 2 of Table 10801 - FR Acc. Schedule Line.
    // 9. Purpose of the test is to validate OnValidate Code of Totaling Debtor when Totaling Type Row of Table 10801 - FR Acc. Schedule Line.
    // 10. Purpose of the test is to validate OnValidate Code of Totaling 2 when Totaling Type Row of Table 10801 - FR Acc. Schedule Line.
    // 11. Purpose of the test is to validate OnValidate Code of Totaling of Table 10801 - FR Acc. Schedule Line.
    // 12. Purpose of the test is to validate OnValidate Code of Totaling when Totaling Type Row of Table 10801 - FR Acc. Schedule Line.
    // 13. Purpose of the test is to validate OnValidate Code of Totaling Creditor when Totaling Type Row of Table 10801 - FR Acc. Schedule Line.
    // 14. Purpose of the test is to validate maximum field length of Applies-to ID does not cause an overflow in other fields
    // 
    // Covers Test Cases for WI - 345029.
    // -----------------------------------------------------------------
    // Test Function Name                                        TFS ID
    // -----------------------------------------------------------------
    // OnActionEditAccountScheduleFRAccountScheduleNamesPage     153911
    // OnActionPrintFRAccountSchedulePage
    // OnAfterGetRecordFRAccScheduleNameFRAccountSchedule
    // OnAfterGetRecordFRAccScheduleLineFRAccountSchedule
    // OnInsertFRAccScheduleLine
    // OnValidateTotalingFRAccScheduleLine
    // OnValidateTotalingDebtorFRAccScheduleLine
    // OnValidateTotalingTwoFRAccScheduleLine
    // OnValidateTotalingDebtorWithRowFRAccScheduleLine
    // OnValidateTotalingTwoWithRowFRAccountScheduleLine
    // OnValidateTotalingCreditorFRAccScheduleLine
    // OnValidateTotalingWithFRAccScheduleLine
    // OnValidateTotalingCreditorWithRowFRAccScheduleLine

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LengthAppliesToIDErr: Label 'Error validate GLEnty';

    [Test]
    [HandlerFunctions('FRAccountSchedulePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionEditAccScheduleFRAccountScheduleNamesPage()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        FRAccountScheduleNames: TestPage "FR Account Schedule Names";
    begin
        // Purpose of the test is to validate Open Account Schedule Page through Page FR Account Schedule Names.
        // Setup.
        Initialize();
        CreateAndModifyFRAccScheduleLine(
          FRAccScheduleLine, FRAccScheduleLine."Calculate with"::Sign,
          false, FRAccScheduleLine."Totaling Type"::"Posting Accounts");
        FRAccountScheduleNames.OpenEdit();
        FRAccountScheduleNames.FILTER.SetFilter(Name, FRAccScheduleLine."Schedule Name");

        // Enqueue for FRAccountSchedulePageHandler.
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");
        LibraryVariableStorage.Enqueue(FRAccScheduleLine.Description);

        // Exercise.
        FRAccountScheduleNames.EditAccountSchedule.Invoke();  // Opens FRAccountSchedulePageHandler.

        // Verify: Verification done in FRAccountSchedulePageHandler.

        // Teardown.
        FRAccountScheduleNames.Close();
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionPrintFRAccountSchedulePage()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        FRAccountSchedule: TestPage "FR Account Schedule";
    begin
        // Purpose of the test is to validate Print Action through Page FR Account Schedule.
        // Setup.
        Initialize();
        CreateAndModifyFRAccScheduleLine(
          FRAccScheduleLine, FRAccScheduleLine."Calculate with"::Sign,
          false, FRAccScheduleLine."Totaling Type"::"Posting Accounts");
        FRAccountSchedule.OpenEdit();
        FRAccountSchedule.FILTER.SetFilter("Schedule Name", FRAccScheduleLine."Schedule Name");
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");  // Enqueue for FRAccountSchedulePageHandler.

        // Exercise.
        FRAccountSchedule.Print.Invoke();  // Opens FRAccountScheduleForPageRequestPageHandler.

        // Verify: Verify Schedule Name on report FR Account Schedule.
        VerifyValueOnFRAccountScheduleReport(FRAccScheduleLine."Schedule Name");

        // Teardown.
        FRAccountSchedule.Close();
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordFRAccScheduleNameFRAccountSchedule()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - FR Acc. Schedule Name table code on Report FR Account Schedule.
        FRScheduleLineWithTotalingType(
          FRAccScheduleLine."Calculate with"::Sign,
          false, FRAccScheduleLine."Totaling Type"::"Posting Accounts");
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordFRAccScheduleLineFRAccountSchedule()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - FR Acc. Schedule Line table code on Report FR Account Schedule.
        FRScheduleLineWithTotalingType(
          FRAccScheduleLine."Calculate with"::"Opposite Sign",
          true, FRAccScheduleLine."Totaling Type"::"Total Accounts");
    end;

    local procedure FRScheduleLineWithTotalingType(CalculateWith: Option; NewPage: Boolean; TotalingType: Option)
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
    begin
        // Setup.
        Initialize();
        CreateAndModifyFRAccScheduleLine(FRAccScheduleLine, CalculateWith, NewPage, TotalingType);
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");  // Enqueue for FRAccountSchedulePageHandler.

        // Exercise.
        REPORT.Run(REPORT::"FR Account Schedule");

        // Verify: Verify Schedule Name on report FR Account Schedule.
        VerifyValueOnFRAccountScheduleReport(FRAccScheduleLine."Schedule Name");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertFRAccScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
    begin
        // Purpose of the test is to validate OnInsret code for Table 10801 - FR Acc. Schedule Line.
        // Setup.
        Initialize();

        // Exercise.
        FRAccScheduleLine.Insert(true);

        // Verify.
        Assert.IsTrue(
          FRAccScheduleLine.Get(FRAccScheduleLine."Schedule Name", FRAccScheduleLine."Line No."),
          StrSubstNo('%1 must exist', FRAccScheduleLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTotalingFRAccScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate OnValidate Code of Totaling of Table 10801 - FR Acc. Schedule Line.
        // Setup.
        Initialize();
        GLAccount.Get(CreateGLEntry());
        CreateFRAccScheduleLine(FRAccScheduleLine, FRAccScheduleLine."Totaling Type"::"Posting Accounts");
        GLAccount.CalcFields(Balance);
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");  // Enqueue for FRAccountScheduleRequestPageHandler.

        // Exercise And Verify.
        UpdateAndVerifyFRAccScheduleLine(FRAccScheduleLine, FRAccScheduleLine.FieldNo(Totaling), GLAccount."No.", GLAccount.Balance);
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTotalingDebtorFRAccScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
    begin
        // Purpose of the test is to validate OnValidate Code of Totaling Debtor of Table 10801 - FR Acc. Schedule Line.
        FRAccScheduleLineTotalingTwoAndTotalingDebtor(FRAccScheduleLine.FieldNo("Totaling Debtor"));
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTotalingTwoFRAccScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
    begin
        // Purpose of the test is to validate OnValidate Code of Totaling 2 of Table 10801 - FR Acc. Schedule Line.
        FRAccScheduleLineTotalingTwoAndTotalingDebtor(FRAccScheduleLine.FieldNo("Totaling 2"));
    end;

    [TransactionModel(TransactionModel::AutoRollback)]
    local procedure FRAccScheduleLineTotalingTwoAndTotalingDebtor(FieldNo: Integer)
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // Setup.
        Initialize();
        GLAccount.Get(CreateGLEntry());
        GLAccount2.Get(CreateGLEntry());
        CreateFRAccScheduleLine(FRAccScheduleLine, FRAccScheduleLine."Totaling Type"::"Posting Accounts");
        GLAccount.CalcFields(Balance);
        GLAccount2.CalcFields(Balance);
        UpdateFRAccScheduleLine(FRAccScheduleLine."Schedule Name", FRAccScheduleLine.FieldNo(Totaling), GLAccount2."No.");
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");  // Enqueue for FRAccountScheduleRequestPageHandler.

        // Exercise And Verify.
        UpdateAndVerifyFRAccScheduleLine(FRAccScheduleLine, FieldNo, GLAccount."No.", GLAccount.Balance + GLAccount2.Balance);
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTotalingDebtorWithRowFRAccScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
    begin
        // Purpose of the test is to validate OnValidate Code of Totaling Debtor when Totaling Type Row of Table 10801 - FR Acc. Schedule Line.
        FRAccountScheduleLineTotalingDebtorWithRow(FRAccScheduleLine.FieldNo("Totaling Debtor"));
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTotalingTwoWithRowFRAccountScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
    begin
        // Purpose of the test is to validate OnValidate Code of Totaling 2 when Totaling Type Row of Table 10801 - FR Acc. Schedule Line.
        FRAccountScheduleLineTotalingDebtorWithRow(FRAccScheduleLine.FieldNo("Totaling 2"));
    end;

    local procedure FRAccountScheduleLineTotalingDebtorWithRow(FieldNo: Integer)
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        FRAccScheduleLine2: Record "FR Acc. Schedule Line";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // Setup.
        Initialize();
        GLAccount.Get(CreateGLEntry());
        GLAccount2.Get(CreateGLEntry());
        CreateAndUpdateFRAccScheduleLine(FRAccScheduleLine, GLAccount."No.");
        UpdateFRAccScheduleLine(FRAccScheduleLine."Schedule Name", FieldNo, GLAccount2."No.");
        GLAccount.CalcFields(Balance);
        GLAccount2.CalcFields(Balance);
        CreateFRAccScheduleLine(FRAccScheduleLine2, FRAccScheduleLine."Totaling Type"::Rows);
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");  // Enqueue for FRAccountScheduleRequestPageHandler.

        // Exercise And Verify.
        UpdateAndVerifyFRAccScheduleLine(FRAccScheduleLine2, FieldNo, FRAccScheduleLine2."Row No.", GLAccount.Balance + GLAccount2.Balance);
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTotalingCreditorFRAccScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate OnValidate Code of Totaling of Table 10801 - FR Acc. Schedule Line.
        // Setup.
        Initialize();
        GLAccount.Get(CreateGLEntry());
        CreateAndUpdateFRAccScheduleLine(FRAccScheduleLine, GLAccount."No.");
        GLAccount.CalcFields(Balance);
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");  // Enqueue for FRAccountScheduleRequestPageHandler.

        // Exercise And Verify.
        UpdateAndVerifyFRAccScheduleLine(
          FRAccScheduleLine, FRAccScheduleLine.FieldNo("Totaling Creditor"), GLAccount."No.", GLAccount.Balance);
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTotalingWithFRAccScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        FRAccScheduleLine2: Record "FR Acc. Schedule Line";
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate OnValidate Code of Totaling when Totaling Type Row of Table 10801 - FR Acc. Schedule Line.
        // Setup.
        Initialize();
        GLAccount.Get(CreateGLEntry());
        CreateAndUpdateFRAccScheduleLine(FRAccScheduleLine, GLAccount."No.");
        CreateFRAccScheduleLine(FRAccScheduleLine2, FRAccScheduleLine."Totaling Type"::Rows);
        GLAccount.CalcFields(Balance);
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");  // Enqueue for FRAccountScheduleRequestPageHandler.

        // Exercise And Verify.
        UpdateAndVerifyFRAccScheduleLine(
          FRAccScheduleLine2, FRAccScheduleLine2.FieldNo(Totaling), FRAccScheduleLine2."Row No.", GLAccount.Balance);
    end;

    [Test]
    [HandlerFunctions('FRAccountScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTotalingCreditorWithRowFRAccScheduleLine()
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        FRAccScheduleLine2: Record "FR Acc. Schedule Line";
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate OnValidate Code of Totaling Creditor when Totaling Type Row of Table 10801 - FR Acc. Schedule Line.
        // Setup.
        Initialize();
        GLAccount.Get(CreateGLEntry());
        CreateAndUpdateFRAccScheduleLine(FRAccScheduleLine, GLAccount."No.");
        UpdateFRAccScheduleLine(FRAccScheduleLine."Schedule Name", FRAccScheduleLine.FieldNo("Totaling Creditor"), GLAccount."No.");
        CreateFRAccScheduleLine(FRAccScheduleLine2, FRAccScheduleLine."Totaling Type"::Rows);
        GLAccount.CalcFields(Balance);
        LibraryVariableStorage.Enqueue(FRAccScheduleLine."Schedule Name");  // Enqueue for FRAccountScheduleRequestPageHandler.

        // Exercise And Verify.
        UpdateAndVerifyFRAccScheduleLine(
          FRAccScheduleLine2, FRAccScheduleLine2.FieldNo("Totaling Creditor"), FRAccScheduleLine2."Row No.", GLAccount.Balance);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckValidateGLEntry()
    var
        GLEntry: Record "G/L Entry";
        GLEntryApplication: Codeunit "G/L Entry Application";
        GLAccountNo: Code[20];
    begin
        Initialize();
        GLAccountNo := CreateGLEntry();
        FindGLEntryByGLAccNo(GLEntry, GLAccountNo);

        GLEntry."Applies-to ID" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(GLEntry."Applies-to ID"));
        GLEntry.Modify();

        GLEntryApplication.Validate(GLEntry);
        FindGLEntryByGLAccNo(GLEntry, GLAccountNo);

        Assert.AreEqual(GLEntry."Applies-to ID", '', LengthAppliesToIDErr)
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Messale: Text[1024])
    begin
    end;

    local procedure CreateAndUpdateFRAccScheduleLine(var FRAccScheduleLine: Record "FR Acc. Schedule Line"; AccountNo: Code[20])
    begin
        CreateFRAccScheduleLine(FRAccScheduleLine, FRAccScheduleLine."Totaling Type"::"Posting Accounts");
        UpdateFRAccScheduleLine(FRAccScheduleLine."Schedule Name", FRAccScheduleLine.FieldNo(Totaling), AccountNo);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLEntry(): Code[20]
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := CreateGLAccount();
        GLEntry.Amount := LibraryRandom.RandDec(10, 2);
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Insert();
        exit(GLEntry."G/L Account No.");
    end;

    local procedure CreateFRAccScheduleName(): Code[10]
    var
        FRAccScheduleName: Record "FR Acc. Schedule Name";
    begin
        FRAccScheduleName.Name := LibraryUTUtility.GetNewCode10();
        FRAccScheduleName.Insert();
        exit(FRAccScheduleName.Name);
    end;

    local procedure CreateAndModifyFRAccScheduleLine(var FRAccScheduleLine: Record "FR Acc. Schedule Line"; CalculateWith: Option; NewPage: Boolean; TotalingType: Option)
    begin
        CreateFRAccScheduleLine(FRAccScheduleLine, TotalingType);
        FRAccScheduleLine.Description := LibraryUTUtility.GetNewCode();
        FRAccScheduleLine."Date Filter" := WorkDate();
        FRAccScheduleLine."Date Filter 2" := WorkDate();
        FRAccScheduleLine."Calculate with" := CalculateWith;
        FRAccScheduleLine."New Page" := NewPage;
        FRAccScheduleLine.Totaling := CreateGLAccount();
        FRAccScheduleLine."Totaling Debtor" := FRAccScheduleLine.Totaling;
        FRAccScheduleLine."Totaling Creditor" := FRAccScheduleLine.Totaling;
        FRAccScheduleLine."Totaling 2" := FRAccScheduleLine.Totaling;
        FRAccScheduleLine.Modify();
    end;

    local procedure CreateFRAccScheduleLine(var FRAccScheduleLine: Record "FR Acc. Schedule Line"; TotalingType: Option)
    var
        FRAccScheduleLine2: Record "FR Acc. Schedule Line";
    begin
        FRAccScheduleLine2.FindLast();
        FRAccScheduleLine."Schedule Name" := CreateFRAccScheduleName();
        FRAccScheduleLine."Line No." := FRAccScheduleLine2."Line No." + 1;
        FRAccScheduleLine."Totaling Type" := TotalingType;
        FRAccScheduleLine."Row No." := LibraryUTUtility.GetNewCode10();
        FRAccScheduleLine.Insert();
    end;

    local procedure UpdateAndVerifyFRAccScheduleLine(FRAccScheduleLine: Record "FR Acc. Schedule Line"; FieldNo: Integer; AccountNo: Code[20]; Amount: Decimal)
    begin
        // Exercise.
        UpdateFRAccScheduleLine(FRAccScheduleLine."Schedule Name", FieldNo, AccountNo);
        REPORT.Run(REPORT::"FR Account Schedule");

        // Verify.
        VerifyAmountOnFRAccountScheduleReport(Amount);
    end;

    local procedure UpdateFRAccScheduleLine(Name: Code[10]; FieldNo: Integer; FieldValue: Text[250])
    var
        FRAccScheduleLine: Record "FR Acc. Schedule Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        FRAccScheduleLine.SetRange("Schedule Name", Name);
        FRAccScheduleLine.FindFirst();
        RecRef.GetTable(FRAccScheduleLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldValue);
        RecRef.SetTable(FRAccScheduleLine);
        FRAccScheduleLine.Modify();
    end;

    local procedure VerifyValueOnFRAccountScheduleReport(ScheduleName: Code[10])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('FR_Acc__Schedule_Name_Name', ScheduleName);
    end;

    local procedure VerifyAmountOnFRAccountScheduleReport(Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sign_TotalCurrentYear', Amount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FRAccountSchedulePageHandler(var FRAccountSchedule: TestPage "FR Account Schedule")
    var
        Description: Variant;
        ScheduleName: Variant;
    begin
        LibraryVariableStorage.Dequeue(ScheduleName);
        LibraryVariableStorage.Dequeue(Description);
        FRAccountSchedule.CurrentSchedName.SetValue(ScheduleName);
        FRAccountSchedule.Description.AssertEquals(Description);
        FRAccountSchedule.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FRAccountScheduleRequestPageHandler(var FRAccountSchedule: TestRequestPage "FR Account Schedule")
    var
        ScheduleName: Variant;
    begin
        LibraryVariableStorage.Dequeue(ScheduleName);
        FRAccountSchedule."FR Acc. Schedule Name".SetFilter(Name, ScheduleName);
        FRAccountSchedule."FR Acc. Schedule Line".SetFilter("Date Filter", Format(WorkDate()));
        FRAccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure FindGLEntryByGLAccNo(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20])
    begin
        GLEntry.SetFilter("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;
}

