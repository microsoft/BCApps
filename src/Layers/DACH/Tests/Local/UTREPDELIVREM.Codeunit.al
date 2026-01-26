codeunit 142040 "UT REP DELIVREM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        ReminderNo: Code[20];
        ValueSpecifiedWarning: Label '%1 must be specified.';
        AllowedRangeWarning: Label '%1 is not within your allowed range of posting dates.';

    [Test]
    [HandlerFunctions('DeliveryReminderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestOnAfterGetRecordDeliveryReminderHeaderWarning()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
    begin
        // Purpose of the test is to validate Function OnAfterGetRecord for Dataset DeliveryReminderHeader - Report 5005272 - Delivery Reminder - Test.
        // Setup:  Create Delivery Reminder Header.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        REPORT.Run(REPORT::"Delivery Reminder - Test");

        // Verify: Verify Warning for Vendor No, Posting Date, Document Date Warning on Report Delivery Reminder - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', StrSubstNo(ValueSpecifiedWarning, DeliveryReminderHeader.FieldCaption("Vendor No.")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', StrSubstNo(ValueSpecifiedWarning, DeliveryReminderHeader.FieldCaption("Posting Date")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', StrSubstNo(ValueSpecifiedWarning, DeliveryReminderHeader.FieldCaption("Document Date")));
    end;

    [Test]
    [HandlerFunctions('DeliveryReminderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestOnAfterGetRecordDeliveryReminderHeaderVendorWarning()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Function OnAfterGetRecord for Dataset DeliveryReminderHeader - Report 5005272 - Delivery Reminder - Test.
        // Setup:  Create Delivery Reminder Header with Vendor No without creating Vendor.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        DeliveryReminderHeader."Vendor No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderHeader.Modify();
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        REPORT.Run(REPORT::"Delivery Reminder - Test");

        // Verify: Verify Warning for Vendor No does not exist on Report Delivery Reminder - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo('%1 %2 does not exist.', Vendor.TableCaption(), DeliveryReminderHeader."Vendor No."));
    end;

    [Test]
    [HandlerFunctions('DeliveryReminderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestOnAfterGetRecordDeliveryReminderHeaderCurrencyWarning()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Function OnAfterGetRecord for Dataset DeliveryReminderHeader - Report 5005272 - Delivery Reminder - Test.
        // Setup:  Create Vendor, Delivery Reminder Header with Vendor No and Currency Code.
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();

        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        DeliveryReminderHeader."Vendor No." := Vendor."No.";
        DeliveryReminderHeader."Currency Code" := 'EUR';
        DeliveryReminderHeader.Modify();
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        REPORT.Run(REPORT::"Delivery Reminder - Test");

        // Verify: Verify Warning for Currency Code on Report Delivery Reminder - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo('%1 must be %2.', DeliveryReminderHeader.FieldCaption("Currency Code"), Vendor."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('DeliveryReminderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestOnAfterGetRecordDeliveryReminderHeaderAllowPostingFromWarning()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to validate Function OnAfterGetRecord for Dataset DeliveryReminderHeader - Report 5005272 - Delivery Reminder - Test.
        // Setup: Update General Ledger Setup with Allow Posting From, Create Delivery Reminder Header with Posting Date less than Allow Posting From.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" :=
          CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        GeneralLedgerSetup.Modify();

        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        DeliveryReminderHeader."Posting Date" := WorkDate();
        DeliveryReminderHeader.Modify();
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        REPORT.Run(REPORT::"Delivery Reminder - Test");

        // Verify: Verify Warning for Posting Date range on Report Delivery Reminder - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(AllowedRangeWarning, DeliveryReminderHeader.FieldCaption("Posting Date")));
    end;

    [Test]
    [HandlerFunctions('DeliveryReminderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestOnAfterGetRecordDeliveryReminderHeaderAllowPostingToWarning()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to validate Function OnAfterGetRecord for Dataset DeliveryReminderHeader - Report 5005272 - Delivery Reminder - Test.
        // Setup: Update General Ledger Setup with Allow Posting To, Create Delivery Reminder Header with Posting Date greater than Allow Posting To.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting To" := WorkDate();
        GeneralLedgerSetup.Modify();

        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        DeliveryReminderHeader."Posting Date" :=
          CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', GeneralLedgerSetup."Allow Posting To");
        DeliveryReminderHeader.Modify();
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        REPORT.Run(REPORT::"Delivery Reminder - Test");

        // Verify: Verify Warning for Posting Date range on Report Delivery Reminder - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(AllowedRangeWarning, DeliveryReminderHeader.FieldCaption("Posting Date")));
    end;

    [Test]
    [HandlerFunctions('DeliveryReminderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestOnAfterGetRecordDeliveryReminderLineQuantityWarning()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        DeliveryReminderLine2: Record "Delivery Reminder Line";
    begin
        // Purpose of the test is to validate Function OnAfterGetRecord for Dataset DeliveryReminderLine - Report 5005272 - Delivery Reminder - Test.
        // Setup: Create Delivery Reminder Header, Create multiple Delivery Reminder Line with Type as blank with Quantity and Type as Item.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);

        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.", 1);
        DeliveryReminderLine.Type := DeliveryReminderLine.Type::" ";
        DeliveryReminderLine.Quantity := 1;
        DeliveryReminderLine.Modify();

        CreateDeliveryReminderLine(DeliveryReminderLine2, DeliveryReminderHeader."No.", 2);  // Line required for Generating warning.
        DeliveryReminderLine2.Type := DeliveryReminderLine2.Type::Item;
        DeliveryReminderLine2.Modify();
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        REPORT.Run(REPORT::"Delivery Reminder - Test");

        // Verify: Verify Warning for Quantity on Report Delivery Reminder - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number__Control97',
          StrSubstNo('%1 has to be 0.', DeliveryReminderLine.FieldCaption(Quantity)));
    end;

    [Test]
    [HandlerFunctions('DeliveryReminderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestOnAfterGetRecordDeliveryReminderLinePurchaseOrderWarning()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
    begin
        // Purpose of the test is to validate Function OnAfterGetRecord for Dataset DeliveryReminderLine - Report 5005272 - Delivery Reminder - Test.
        // Setup: Create Delivery Reminder Header, Create Delivery Reminder Line with Type as Item and Order details.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.", 1);
        DeliveryReminderLine.Type := DeliveryReminderLine.Type::Item;
        DeliveryReminderLine."Order No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderLine."Order Line No." := 1;
        DeliveryReminderLine."No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderLine.Description := 'Description';
        DeliveryReminderLine.Modify();
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        REPORT.Run(REPORT::"Delivery Reminder - Test");

        // Verify: Verify Warning for Purchase Order on Report Delivery Reminder - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Delivery_Reminder_Header_No_', DeliveryReminderHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number__Control97', 'Delivery Remainder Line has no valid Purch. Order Line');
    end;

    [Test]
    [HandlerFunctions('IssuedDeliveryReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssuedDeliveryReminder()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        IssuedDelivReminderLine: Record "Issued Deliv. Reminder Line";
        IssuedDelivReminderLine2: Record "Issued Deliv. Reminder Line";
    begin
        // Purpose of the test is to verify Report 5005273 - Issued Delivery Reminder.
        // Setup: Create Issued Delivery Reminder Header, Create Delivery Reminder Line with Type as blank and Type as Item.
        CreateIssuedDelivReminderHeader(IssuedDelivReminderHeader);

        CreateIssuedDelivReminderLine(IssuedDelivReminderLine, IssuedDelivReminderHeader."No.", 1);
        IssuedDelivReminderLine.Type := IssuedDelivReminderLine.Type::" ";
        IssuedDelivReminderLine.Description := 'ReminderLine1Description';
        IssuedDelivReminderLine.Modify();

        CreateIssuedDelivReminderLine(IssuedDelivReminderLine2, IssuedDelivReminderHeader."No.", 2);
        IssuedDelivReminderLine2.Type := IssuedDelivReminderLine.Type::Item;
        IssuedDelivReminderLine2."No." := LibraryUTUtility.GetNewCode();
        IssuedDelivReminderLine2.Description := 'ReminderLine2Description';
        IssuedDelivReminderLine2.Modify();

        Commit();  // commit required due to Function OnRun on Codeunit 5005273 -Iss. Delivery Remind. printed.
        ReminderNo := IssuedDelivReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        REPORT.Run(REPORT::"Issued Delivery Reminder");

        // Verify: Verify Issued Delivery Header and Line Information on Report Issued Delivery Reminder.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Issued_Deliv__Reminder_Header_No_', IssuedDelivReminderHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists('Issued_Deliv__Reminder_Line_Description', IssuedDelivReminderLine.Description);
        LibraryReportDataset.AssertElementWithValueExists('Issued_Deliv__Reminder_Line__No__', IssuedDelivReminderLine2."No.");
        LibraryReportDataset.AssertElementWithValueExists('Issued_Deliv__Reminder_Line_Description', IssuedDelivReminderLine2.Description);
    end;

    [Test]
    [HandlerFunctions('IssueDeliveryReminderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IssueDeliveryReminderOnPreReportError()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
    begin
        // Purpose of the test is to validate Function OnPreReport with Request page Replace Posting Date as True - Report 5005341 - Issue Delivery Reminder.
        // Setup: Create Delivery Reminder Header.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Issue Delivery Reminder");

        // Verify: Verify Posting Date Error Message.
        Assert.ExpectedError('Please enter the posting date.');
    end;

    [Test]
    [HandlerFunctions('IssueDeliveryReminderPrintDocRequestPageHandler,IssuedDeliveryReminderReportHandler')]
    [Scope('OnPrem')]
    procedure IssueDeliveryReminderPrintDocOnRequestPage()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        IssuedDelivReminderLine: Record "Issued Deliv. Reminder Line";
    begin
        // Purpose of the test is to validate Request page Print as True - Report 5005341 - Issue Delivery Reminder.
        // Setup: Create Delivery Reminder Header and Delivery Reminder Line.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        DeliveryReminderHeader."Vendor No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderHeader."Posting Date" := WorkDate();
        DeliveryReminderHeader."Document Date" := WorkDate();
        DeliveryReminderHeader.Modify();
        ReminderNo := DeliveryReminderHeader."No.";  // Assign Global variable for Request Page Handler.

        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.", 1);
        DeliveryReminderLine."Order No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderLine."Order Line No." := 1;
        DeliveryReminderLine.Type := DeliveryReminderLine.Type::Item;
        DeliveryReminderLine."No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderLine.Quantity := 1;
        DeliveryReminderLine.Modify();

        Commit();  // commit required due to Function OnPostReport on Report 5005341 - Issue Delivery Reminder.

        // Exercise.
        REPORT.Run(REPORT::"Issue Delivery Reminder");

        // Verify: Verify new created Issued Delivery Reminder Header and Line and added Report Handler for Report Issued Delivery Reminder Print.
        IssuedDelivReminderHeader.SetRange("Pre-Assigned No.", DeliveryReminderHeader."No.");
        IssuedDelivReminderHeader.FindFirst();
        IssuedDelivReminderHeader.TestField("Vendor No.", DeliveryReminderHeader."Vendor No.");

        IssuedDelivReminderLine.SetRange("Document No.", IssuedDelivReminderHeader."No.");
        IssuedDelivReminderLine.SetRange(Type, IssuedDelivReminderLine.Type::Item);
        IssuedDelivReminderLine.FindFirst();
        IssuedDelivReminderLine.TestField("No.", DeliveryReminderLine."No.");
    end;

    local procedure CreateIssuedDelivReminderHeader(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header")
    begin
        IssuedDelivReminderHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedDelivReminderHeader.Insert();
    end;

    local procedure CreateIssuedDelivReminderLine(var IssuedDelivReminderLine: Record "Issued Deliv. Reminder Line"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        IssuedDelivReminderLine."Document No." := DocumentNo;
        IssuedDelivReminderLine."Line No." := LineNo;
        IssuedDelivReminderLine.Insert();
    end;

    local procedure CreateDeliveryReminderHeader(var DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
        DeliveryReminderHeader."No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderHeader.Insert();
    end;

    local procedure CreateDeliveryReminderLine(var DeliveryReminderLine: Record "Delivery Reminder Line"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        DeliveryReminderLine."Document No." := DocumentNo;
        DeliveryReminderLine."Line No." := LineNo;
        DeliveryReminderLine.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssuedDeliveryReminderRequestPageHandler(var IssuedDeliveryReminder: TestRequestPage "Issued Delivery Reminder")
    begin
        IssuedDeliveryReminder."Issued Deliv. Reminder Header".SetFilter("No.", ReminderNo);
        IssuedDeliveryReminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestRequestPageHandler(var DeliveryReminderTest: TestRequestPage "Delivery Reminder - Test")
    begin
        DeliveryReminderTest."Delivery Reminder Header".SetFilter("No.", ReminderNo);
        DeliveryReminderTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssueDeliveryReminderRequestPageHandler(var IssueDeliveryReminder: TestRequestPage "Issue Delivery Reminder")
    begin
        IssueDeliveryReminder."Delivery Reminder Header".SetFilter("No.", ReminderNo);
        IssueDeliveryReminder.ReplacePostingDate.SetValue(true);
        IssueDeliveryReminder.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssueDeliveryReminderPrintDocRequestPageHandler(var IssueDeliveryReminder: TestRequestPage "Issue Delivery Reminder")
    begin
        IssueDeliveryReminder."Delivery Reminder Header".SetFilter("No.", ReminderNo);
        IssueDeliveryReminder.PrintDoc.SetValue(true);
        IssueDeliveryReminder.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure IssuedDeliveryReminderReportHandler(var IssuedDeliveryReminder: Report "Issued Delivery Reminder")
    begin
    end;
}

