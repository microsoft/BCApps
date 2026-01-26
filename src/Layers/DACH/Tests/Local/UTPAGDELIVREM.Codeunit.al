codeunit 142041 "UT PAG DELIVREM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowRecordsIssuedDelivReminderHeaderNavigate()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        Navigate: TestPage Navigate;
        IssuedDeliveryRemindersList: TestPage "Issued Delivery Reminders List";
    begin
        // Purpose of the test is to validate Function ShowRecords for Page 344 - Navigate.
        // Setup: Create Issued Delivery Reminder Header, Open Navigate and Find.
        CreateIssuedDelivReminderHeader(IssuedDelivReminderHeader);
        OpenNavigatePageAndFindEntry(Navigate, IssuedDelivReminderHeader."No.");
        IssuedDeliveryRemindersList.Trap();

        // Exercise.
        Navigate.Show.Invoke();

        // Verify: Verify Reminder No on Page IssuedDeliveryRemindersList.
        IssuedDeliveryRemindersList."No.".AssertEquals(IssuedDelivReminderHeader."No.");
        IssuedDeliveryRemindersList.Close();
        Navigate.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowRecordsDeliveryReminderLedgerEntryNavigate()
    var
        DeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry";
        DelivReminderLedgerEntries: TestPage "Deliv. Reminder Ledger Entries";
        Navigate: TestPage Navigate;
    begin
        // Purpose of the test is to validate Function ShowRecords for Page 344 - Navigate.
        // Setup: Create Delivery Reminder Ledger Entry, Open Navigate and Find.
        CreateDeliveryReminderLedgerEntry(DeliveryReminderLedgerEntry);
        OpenNavigatePageAndFindEntry(Navigate, DeliveryReminderLedgerEntry."Reminder No.");
        DelivReminderLedgerEntries.Trap();

        // Exercise.
        Navigate.Show.Invoke();

        // Verify: Verify Reminder No on Page DelivReminderLedgerEntries.
        DelivReminderLedgerEntries."Reminder No.".AssertEquals(DeliveryReminderLedgerEntry."Reminder No.");
        DelivReminderLedgerEntries.Close();
        Navigate.Close();
    end;

    [Test]
    [HandlerFunctions('IssuedDeliveryReminderReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintActionOnIssuedDeliveryReminder()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        IssuedDeliveryReminder: TestPage "Issued Delivery Reminder";
    begin
        // Purpose of the test is to validate Print Action for Page 5005273 - Issued Delivery Reminder.
        // Setup: Create Issued Delivery Reminder Header and Open Page Issued Delivery Reminder.
        CreateReportSelections("Report Selection Usage"::"Issued Delivery Reminder", Report::"Issued Delivery Reminder");
        CreateIssuedDelivReminderHeader(IssuedDelivReminderHeader);
        OpenIssuedDeliveryReminderPage(IssuedDeliveryReminder, IssuedDelivReminderHeader."No.");

        // Exercise and Verify: Print from Page Issued Delivery Reminder and add Report handler -IssuedDeliveryReminderReportHandler.
        IssuedDeliveryReminder.PrintReport.Invoke();
        IssuedDeliveryReminder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigateActionOnIssuedDeliveryReminder()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        DocumentEntry: Record "Document Entry";
        Navigate: TestPage Navigate;
        IssuedDeliveryReminder: TestPage "Issued Delivery Reminder";
    begin
        // Purpose of the test is to validate Navigate Action for Page 5005273 - Issued Delivery Reminder.
        // Setup: Create Issued Delivery Reminder Header and Open Page Issued Delivery Reminder.
        CreateIssuedDelivReminderHeader(IssuedDelivReminderHeader);
        OpenIssuedDeliveryReminderPage(IssuedDeliveryReminder, IssuedDelivReminderHeader."No.");
        Navigate.Trap();

        // Exercise: Navigate from Page Issued Delivery Reminder.
        IssuedDeliveryReminder.Navigate.Invoke();

        // Verify: Verify Table Name on Navigate Page.
        Navigate."Table Name".AssertEquals(CopyStr(IssuedDelivReminderHeader.TableCaption(), 1, MaxStrLen(DocumentEntry."Table Name")));
        IssuedDeliveryReminder.Close();
        Navigate.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnFindRecordDelivReminderLedgerEntries()
    var
        DeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry";
        DelivReminderLedgerEntries: TestPage "Deliv. Reminder Ledger Entries";
    begin
        // Purpose of the test is to validate Function OnFindRecord for Page 5005276 - Deliv. Reminder Ledger Entries.
        // Setup.
        CreateDeliveryReminderLedgerEntry(DeliveryReminderLedgerEntry);

        // Exercise: Open Delivery Reminder Ledger Entries Page.
        DelivReminderLedgerEntries.OpenEdit();
        DelivReminderLedgerEntries.FILTER.SetFilter("Entry No.", Format(DeliveryReminderLedgerEntry."Entry No."));

        // Verify: Verify Reminder No on Page Delivery Reminder Ledger Entries.
        DelivReminderLedgerEntries."Reminder No.".AssertEquals(DeliveryReminderLedgerEntry."Reminder No.");
        DelivReminderLedgerEntries.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageOnDeliveryReminderLevels()
    var
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        DeliveryReminderLevels: TestPage "Delivery Reminder Levels";
    begin
        // Purpose of the test is to validate Function OnOpenPage for Page 5005281 - Delivery Reminder Levels.
        // Setup: Create Delivery Reminder Level.
        DeliveryReminderLevel."Reminder Terms Code" := '1';
        DeliveryReminderLevel."No." := 1;
        DeliveryReminderLevel.Insert();

        // Exercise: Open Page Delivery Reminder Level.
        DeliveryReminderLevels.OpenEdit();
        DeliveryReminderLevels.FILTER.SetFilter("Reminder Terms Code", DeliveryReminderLevel."Reminder Terms Code");

        // Verify: Verify No on Page Delivery Reminder Level.
        DeliveryReminderLevels."No.".AssertEquals(DeliveryReminderLevel."No.");
        DeliveryReminderLevels.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertExtTextsDeliveryReminderSubform()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        DeliveryReminder: TestPage "Delivery Reminder";
    begin
        // Purpose of the test is to validate Action - InsertExtTexts of Page ID - 5005271 Delivery Reminder Subform.

        // Setup: Create Delivery Reminder Header and Line, Create Extended Text Header and Line.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.");
        CreateExtendedTextHeader(ExtendedTextHeader, DeliveryReminderLine."No.");
        CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader."No.");
        OpenDeliveryReminderPage(DeliveryReminder, DeliveryReminderHeader."No.");

        // Exercise: Invoke Action - InsertExtTexts on Page Delivery Reminder Subform.
        DeliveryReminder.DeliveryReminderLines.InsertExtTexts.Invoke();
        DeliveryReminder.Close();

        // Verify: Verify Text of Extended Text Line is updated as Description of Delivery Reminder Line.
        DeliveryReminderLine.SetRange("Document No.", DeliveryReminderHeader."No.");
        DeliveryReminderLine.SetRange("Attached to Line No.", DeliveryReminderLine."Line No.");
        DeliveryReminderLine.FindFirst();
        DeliveryReminderLine.TestField(Description, ExtendedTextLine.Text);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateNoDeliveryReminderSubform()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        StandardText: Record "Standard Text";
        DeliveryReminder: TestPage "Delivery Reminder";
    begin
        // Purpose of the test is to validate No. - OnValidate of Page ID - 5005271 Delivery Reminder Subform.

        // Setup: Create Delivery Reminder Header and Line.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.");
        CreateStandardText(StandardText);
        OpenDeliveryReminderPage(DeliveryReminder, DeliveryReminderHeader."No.");

        // Exercise: Validate No. of Delivery Reminder Lines Subform.
        DeliveryReminder.DeliveryReminderLines."No.".SetValue(StandardText.Code);

        // Verify: Verify Description of Standard Text is updated as Description of Delivery Reminder Line.
        DeliveryReminder.DeliveryReminderLines.Description.AssertEquals(StandardText.Description);
        DeliveryReminder.Close();
    end;

    [Test]
    [HandlerFunctions('IssuedDeliveryReminderReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintActionOnIssuedDeliveryReminderList()
    var
        IssuedDeliveryRemindersList: TestPage "Issued Delivery Reminders List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 284485] Page 5005275 "Issued Delivery Reminders List" has a valid Print Action
        // [GIVEN] Page "Issued Delivery Reminders List" open
        LibraryApplicationArea.EnableFoundationSetup();
        CreateReportSelections("Report Selection Usage"::"Issued Delivery Reminder", Report::"Issued Delivery Reminder");
        IssuedDeliveryRemindersList.OpenView();
        // [WHEN] Invoke Print Action
        // [THEN] Report "Issued Delivery Reminder" is called
        IssuedDeliveryRemindersList.PrintReport.Invoke();
        IssuedDeliveryRemindersList.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentNoAndPostingDateFiltersFilledWhenInvokeNavigateFromIssuedDeliveryReminder()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        IssuedDeliveryRemindersList: TestPage "Issued Delivery Reminders List";
        Navigate: TestPage Navigate;
    begin
        // [FEATURE] [Reminder] [UT]
        // [SCENARIO 307362] Document No and Posting Date filters are filled when call Navigate page from Issued Delivery Reminders page.

        // [GIVEN] Issued Deliv. Reminder Header record "R1".
        // [GIVEN] Issued Delivery Reminders List page "P1".
        // [GIVEN] Navigate page "P2".
        CreateIssuedDelivReminderHeaderWithPostingDate(IssuedDelivReminderHeader);

        // [WHEN] Invoke Navigate action on "P1".
        Navigate.Trap();
        IssuedDeliveryRemindersList.OpenView();
        IssuedDeliveryRemindersList.FILTER.SetFilter("No.", IssuedDelivReminderHeader."No.");
        IssuedDeliveryRemindersList.Navigate.Invoke();

        // [THEN] "P2".DocNoFilter = "R1"."No.".
        Navigate.DocNoFilter.AssertEquals(IssuedDelivReminderHeader."No.");

        // [THEN] "P2".PostingDateFilter = "R1"."Posting Date".
        Navigate.PostingDateFilter.AssertEquals(IssuedDelivReminderHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDelRemDateFieldIsPresentOnPurchasePayablesSetupPage()
    var
        PurchasesPayablesSetup: TestPage "Purchases & Payables Setup";
    begin
        // [FEATURE] [UI] [Purchases] [Reminder]
        // [SCENARIO 330466] Default Del. Rem. Date Field is accessible and editable on Purchases & Payables Setup page
        LibraryPermissions.SetTestabilitySoftwareAsAService(true);
        PurchasesPayablesSetup.OpenEdit();
        Assert.IsTrue(PurchasesPayablesSetup."Default Del. Rem. Date Field".Enabled(), '');
        Assert.IsTrue(PurchasesPayablesSetup."Default Del. Rem. Date Field".Editable(), '');
        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure CreateIssuedDelivReminderHeader(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header")
    begin
        IssuedDelivReminderHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedDelivReminderHeader.Insert();
    end;

    local procedure CreateIssuedDelivReminderHeaderWithPostingDate(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header")
    begin
        IssuedDelivReminderHeader."No." := LibraryUtility.GenerateGUID();
        IssuedDelivReminderHeader."Posting Date" := LibraryRandom.RandDate(100);
        IssuedDelivReminderHeader.Insert();
    end;

    local procedure CreateDeliveryReminderLedgerEntry(var DeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry")
    begin
        DeliveryReminderLedgerEntry."Entry No." := SelectDeliveryReminderLedgerEntryNo();
        DeliveryReminderLedgerEntry."Reminder No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderLedgerEntry.Insert();
    end;

    local procedure SelectDeliveryReminderLedgerEntryNo(): Integer
    var
        DeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry";
    begin
        if DeliveryReminderLedgerEntry.FindLast() then
            exit(DeliveryReminderLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure CreateDeliveryReminderHeader(var DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
        DeliveryReminderHeader."No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderHeader.Name := LibraryUTUtility.GetNewCode();
        DeliveryReminderHeader."Document Date" := WorkDate();
        DeliveryReminderHeader.Insert();
    end;

    local procedure CreateDeliveryReminderLine(var DeliveryReminderLine: Record "Delivery Reminder Line"; DocumentNo: Code[20])
    begin
        DeliveryReminderLine."Document No." := DocumentNo;
        DeliveryReminderLine."Line No." := LibraryRandom.RandInt(10);
        DeliveryReminderLine.Insert();
    end;

    local procedure CreateExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; No: Code[20])
    begin
        ExtendedTextHeader."No." := No;
        ExtendedTextHeader."Delivery Reminder" := true;
        ExtendedTextHeader.Insert();
    end;

    local procedure CreateExtendedTextLine(var ExtendedTextLine: Record "Extended Text Line"; No: Code[20])
    begin
        ExtendedTextLine."No." := No;
        ExtendedTextLine.Text := LibraryUTUtility.GetNewCode();
        ExtendedTextLine.Insert();
    end;

    local procedure CreateStandardText(var StandardText: Record "Standard Text")
    begin
        StandardText.Code := LibraryUTUtility.GetNewCode();
        StandardText.Description := LibraryUTUtility.GetNewCode();
        StandardText.Insert();
    end;

    local procedure OpenNavigatePageAndFindEntry(var Navigate: TestPage Navigate; DocNoFilter: Code[250])
    begin
        Navigate.OpenEdit();
        Navigate.DocNoFilter.SetValue(DocNoFilter);
        Navigate.Find.Invoke();
    end;

    local procedure OpenIssuedDeliveryReminderPage(var IssuedDeliveryReminder: TestPage "Issued Delivery Reminder"; No: Code[20])
    begin
        IssuedDeliveryReminder.OpenEdit();
        IssuedDeliveryReminder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenDeliveryReminderPage(var DeliveryReminder: TestPage "Delivery Reminder"; No: Code[20])
    begin
        DeliveryReminder.OpenEdit();
        DeliveryReminder.FILTER.SetFilter("No.", No);
    end;

    local procedure CreateReportSelections(Usage: Enum "Report Selection Usage"; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := LibraryUTUtility.GetNewCode10();
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure IssuedDeliveryReminderReportHandler(var IssuedDeliveryReminder: Report "Issued Delivery Reminder")
    begin
    end;
}

