codeunit 142034 "UT COD DELIVREM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        SameValueMsg: Label 'Value must be same';
        TrueValueMsg: Label 'Value must be True';
        FalseValueMsg: Label 'Value must be False';

    [Test]
    [Scope('OnPrem')]
    procedure OnRunIssDeliveryRemindPrinted()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        OldNoPrinted: Integer;
    begin
        // Purpose of the test is to validate Function OnRun for Codeunit 5005273 - Iss. Delivery Remind. Printed.
        // Setup: Create Issued Delivery Reminder Header.
        CreateIssuedDelivReminderHeader(IssuedDelivReminderHeader);
        OldNoPrinted := IssuedDelivReminderHeader."No. Printed";

        // Exercise: Run Codeunit Iss. Delivery Remind. Printed, Transaction Model as AutoCommit becasue commit on OnRun Function, Codeunit - Iss. Delivery Remind. Printed.
        CODEUNIT.Run(CODEUNIT::"Iss. Delivery Remind. printed", IssuedDelivReminderHeader);

        // Verify: Verify No.Printed increased by 1.
        Assert.AreEqual(OldNoPrinted + 1, IssuedDelivReminderHeader."No. Printed", SameValueMsg);
    end;

    [Test]
    [HandlerFunctions('DeliveryReminderTestReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeliveryRemindPrintOnPrintDocumentComfort()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        PrintDocumentComfort: Codeunit "Print Document Comfort";
    begin
        // Purpose of the test is to validate Function DeliveryRemindPrint for Codeunit 5005396 - Print Document Comfort.
        // Setup: Create Delivery Reminder Header.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);

        // Exercise.
        PrintDocumentComfort.PrintDeliveryReminder(DeliveryReminderHeader);

        // Verify: Verify Report Delivery Reminder Test executed, added Report Handler DeliveryReminderTestReportHandler.
    end;

    [Test]
    [HandlerFunctions('IssuedDeliveryReminderReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IssuedDeliveryRemindPrintOnPrintDocumentComfort()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        PrintDocumentComfort: Codeunit "Print Document Comfort";
    begin
        // Purpose of the test is to validate Function IssuedDeliveryRemindPrint for Codeunit 5005396 - Print Document Comfort.
        // Setup: Create Issued Delivery Reminder Header.
        CreateIssuedDelivReminderHeader(IssuedDelivReminderHeader);

        // Exercise.
        PrintDocumentComfort.IssuedDeliveryRemindPrint(IssuedDelivReminderHeader, false);

        // Verify: Verify Report Issued Delivery Reminder executed, added Report Handler IssuedDeliveryReminderReportHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelifRemindVendOnFormatAdressComfort()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        FormatAdressComfort: Codeunit "Format Adress Comfort";
        AddrArray: array[8] of Text[100];
    begin
        // Purpose of the test is to validate Function DelifRemindVend for Codeunit 5005397 - Print Document Comfort.
        // Setup: Create Delivery Reminder Header.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);

        // Exercise.
        FormatAdressComfort.DelifRemindVend(AddrArray, DeliveryReminderHeader);

        // Verify: Verify Name value in Address Array.
        Assert.AreEqual(AddrArray[1], DeliveryReminderHeader.Name, SameValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IssDelivRemindVendOnFormatAdressComfort()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        FormatAdressComfort: Codeunit "Format Adress Comfort";
        AddrArray: array[8] of Text[100];
    begin
        // Purpose of the test is to validate Function IssDelivRemindVend for Codeunit 5005397 - Print Document Comfort.
        // Setup: Create Issued Delivery Reminder Header.
        CreateIssuedDelivReminderHeader(IssuedDelivReminderHeader);

        // Exercise.
        FormatAdressComfort.IssDelivRemindVend(AddrArray, IssuedDelivReminderHeader);

        // Verify: Verify Name value in Address Array.
        Assert.AreEqual(AddrArray[1], IssuedDelivReminderHeader.Name, SameValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MakeUpdateFalseOnDelivRemExtTextTransfer()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        DelivRemExtTextTransfer: Codeunit "Deliv.-Rem. Ext. Text Transfer";
    begin
        // Purpose of the test is to validate Function MakeUpdate for Codeunit 5005272 - Deliv.-Rem. Ext. Text Transfer.
        // Setup: Create Delivery Reminder Header and Line.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.", 1);  // 1 as Line No.

        // Exercise.
        DelivRemExtTextTransfer.ReminderCheckIfAnyExtText(DeliveryReminderLine, false);

        // Verify: Verify Function MakeUpdate return value as False.
        Assert.IsFalse(DelivRemExtTextTransfer.MakeUpdate(), FalseValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MakeUpdateTrueOnDelivRemExtTextTransfer()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        DeliveryReminderLine2: Record "Delivery Reminder Line";
        DelivRemExtTextTransfer: Codeunit "Deliv.-Rem. Ext. Text Transfer";
    begin
        // Purpose of the test is to validate Function MakeUpdate for Codeunit 5005272 - Deliv.-Rem. Ext. Text Transfer.
        // Setup: Create Delivery Reminder Header and Multiple Line.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.", 1);  // Line No as 1.
        CreateDeliveryReminderLine(DeliveryReminderLine2, DeliveryReminderHeader."No.", 2);  // Line No as 2.
        DeliveryReminderLine2."Attached to Line No." := DeliveryReminderLine."Line No.";
        DeliveryReminderLine2.Modify();

        // Exercise.
        DelivRemExtTextTransfer.ReminderCheckIfAnyExtText(DeliveryReminderLine, false);

        // Verify: Verify Function MakeUpdate return value as True.
        Assert.IsTrue(DelivRemExtTextTransfer.MakeUpdate(), TrueValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReminderCheckIfAnyExtTextWithTypeItemDelivRemExtTextTransfer()
    var
        DeliveryReminderLine: Record "Delivery Reminder Line";
    begin
        // Purpose of the test is to validate Function ReminderCheckIfAnyExtText With Type Item for Codeunit 5005272 - Deliv.-Rem. Ext. Text Transfer.
        // Setup.
        ReminderCheckIfAnyExtTextOnDelivRemExtTextTransfer(DeliveryReminderLine.Type::Item, LibraryUTUtility.GetNewCode(), true);  // Forcefully check Extended Text Header  - True.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReminderCheckIfAnyExtTextWithTypeBlankDelivRemExtTextTransfer()
    var
        DeliveryReminderLine: Record "Delivery Reminder Line";
    begin
        // Purpose of the test is to validate Function ReminderCheckIfAnyExtText With Type blank for Codeunit 5005272 - Deliv.-Rem. Ext. Text Transfer.
        // Setup.
        ReminderCheckIfAnyExtTextOnDelivRemExtTextTransfer(DeliveryReminderLine.Type::" ", '', false);  // Forcefully check Extended Text Header  - False.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReminderCheckIfAnyExtTextWithTypeGLAccountDelivRemExtTextTransfer()
    var
        DeliveryReminderLine: Record "Delivery Reminder Line";
    begin
        // Purpose of the test is to validate Function ReminderCheckIfAnyExtText With Type Account (G/L) for Codeunit 5005272 - Deliv.-Rem. Ext. Text Transfer.
        // Setup.
        ReminderCheckIfAnyExtTextOnDelivRemExtTextTransfer(DeliveryReminderLine.Type::"Account (G/L)", CreateGLAccount(), false);  // Forcefully check Extended Text Header  - False.
    end;

    local procedure ReminderCheckIfAnyExtTextOnDelivRemExtTextTransfer(Type: Option; No: Code[20]; AutoCheckExtendedTextHeader: Boolean)
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        DelivRemExtTextTransfer: Codeunit "Deliv.-Rem. Ext. Text Transfer";
    begin
        // Create and Update Delivery Reminder Header, Delivery Reminder Line, Extended Text Header and Extended Text Line.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        UpdateDeliveryReminderHeader(DeliveryReminderHeader, 'ENU');  // Language Code as ENU.
        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.", 1);  // Line No as 1.
        UpdateDeliveryReminderLine(DeliveryReminderLine, Type, No);
        CreateExtendedTextHeader(ExtendedTextHeader, "Extended Text Table Name".FromInteger(DeliveryReminderLine.Type), DeliveryReminderLine."No.", 'ENU');  // Language Code as ENU.
        UpdateExtendedTextHeader(ExtendedTextHeader, true);

        CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader."Table Name", ExtendedTextHeader."No.", ExtendedTextHeader."Language Code", ExtendedTextHeader."Text No.");

        // Exercise and Verify: Verify Function ReminderCheckIfAnyExtText return value as True.
        Assert.IsTrue(DelivRemExtTextTransfer.ReminderCheckIfAnyExtText(DeliveryReminderLine, AutoCheckExtendedTextHeader), TrueValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReadLinesWithoutReminderLanguageCodeOnDelivRemExtTextTransfer()
    begin
        // Purpose of the test is to validate Function ReadLines with Language Code for Codeunit 5005272 - Deliv.-Rem. Ext. Text Transfer.
        // Setup.
        ReadLinesOnDelivRemExtTextTransfer('', 'ENU');  // ReminderLanguageCode as blank and ExtendedTextLanguageCode as ENU.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReadLinesWithReminderLanguageCodeOnDelivRemExtTextTransfer()
    begin
        // Purpose of the test is to validate Function ReadLines without Language Code for Codeunit 5005272 - Deliv.-Rem. Ext. Text Transfer.
        // Setup.
        ReadLinesOnDelivRemExtTextTransfer('ENU', '');  // ReminderLanguageCode as ENU and ExtendedTextLanguageCode as Blank.
    end;

    local procedure ReadLinesOnDelivRemExtTextTransfer(ReminderLanguageCode: Code[10]; ExtendedTextLanguageCode: Code[10])
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        ExtendedTextHeader: Record "Extended Text Header";
        DelivRemExtTextTransfer: Codeunit "Deliv.-Rem. Ext. Text Transfer";
    begin
        // Create and Update Delivery Reminder Header,Delivery Reminder Line,Extended Text Header.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        UpdateDeliveryReminderHeader(DeliveryReminderHeader, ReminderLanguageCode);
        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.", 1);  // Line No as 1.
        UpdateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderLine.Type::" ", LibraryUTUtility.GetNewCode());
        CreateExtendedTextHeader(ExtendedTextHeader, "Extended Text table Name".FromInteger(DeliveryReminderLine.Type), DeliveryReminderLine."No.", ExtendedTextLanguageCode);
        UpdateExtendedTextHeader(ExtendedTextHeader, false);

        // Exercise and Verify : Verify Function ReminderCheckIfAnyExtText return value as False.
        Assert.IsFalse(DelivRemExtTextTransfer.ReminderCheckIfAnyExtText(DeliveryReminderLine, true), FalseValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelivReminInsertExtendedTextOnDelivRemExtTextTransfer()
    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        DelivRemExtTextTransfer: Codeunit "Deliv.-Rem. Ext. Text Transfer";
    begin
        // Purpose of the test is to validate Function DelivReminInsertExtendedText for Codeunit 5005272 - Deliv.-Rem. Ext. Text Transfer.
        // Setup: Create and Update Delivery Reminder Header, Delivery Reminder Line, Extended Text Header and call function ReminderCheckIfAnyExtText.
        CreateDeliveryReminderHeader(DeliveryReminderHeader);
        UpdateDeliveryReminderHeader(DeliveryReminderHeader, 'ENU');  // Language Code as ENU.
        CreateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderHeader."No.", 1);  // Line No as 1.
        UpdateDeliveryReminderLine(DeliveryReminderLine, DeliveryReminderLine.Type::Item, LibraryUTUtility.GetNewCode());
        CreateExtendedTextHeader(ExtendedTextHeader, "Extended Text Table Name".FromInteger(DeliveryReminderLine.Type), DeliveryReminderLine."No.", 'ENU');  // Language Code as ENU.
        UpdateExtendedTextHeader(ExtendedTextHeader, true);
        CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader."Table Name", ExtendedTextHeader."No.", ExtendedTextHeader."Language Code", ExtendedTextHeader."Text No.");
        ExtendedTextLine.Text := 'Extended Text Line Text';
        ExtendedTextLine.Modify();
        DelivRemExtTextTransfer.ReminderCheckIfAnyExtText(DeliveryReminderLine, true);

        // Exercise.
        DelivRemExtTextTransfer.DelivReminInsertExtendedText(DeliveryReminderLine);

        // Verify: Verify New line created in Delivery Reminder with Description.
        DeliveryReminderLine.SetRange("Document No.", DeliveryReminderHeader."No.");
        DeliveryReminderLine.SetRange("Attached to Line No.", DeliveryReminderLine."Line No.");
        DeliveryReminderLine.FindFirst();
        DeliveryReminderLine.TestField(Description, ExtendedTextLine.Text);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RemindPromisedReceiptDate()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        DeliveryReminderTerm: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        CreateDeliveryReminder: Codeunit "Create Delivery Reminder";
    begin
        // Purpose of the test is to validate Codeunit 5005271: Create Delivery Reminder - Function Remind() -  PurchaseSetup CASE Statement.

        // Setup.
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Default Del. Rem. Date Field"::"Promised Receipt Date");

        PurchaseLine."Promised Receipt Date" := CalcDate('<1D>', WorkDate());
        PurchaseLine.Insert();

        // Exercise & Verify : Verify that the reminder line is not created for Promised Receipt Date. Return value from Function Remind must be false.
        Assert.IsFalse(CreateDeliveryReminder.Remind(PurchaseLine, DeliveryReminderTerm, DeliveryReminderLevel, WorkDate()), FalseValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RemindExpectedReceiptDate()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        DeliveryReminderTerm: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        CreateDeliveryReminder: Codeunit "Create Delivery Reminder";
    begin
        // Purpose of the test is to validate Codeunit 5005271: Create Delivery Reminder - Function Remind() -  PurchaseSetup CASE Statement.

        // Setup.
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Default Del. Rem. Date Field"::"Expected Receipt Date");

        PurchaseLine."Expected Receipt Date" := CalcDate('<1D>', WorkDate());
        PurchaseLine.Insert();

        // Exercise & Verify : Verify that the reminder line is not created for Expected Receipt Date. Return value from Function Remind must be false.
        Assert.IsFalse(CreateDeliveryReminder.Remind(PurchaseLine, DeliveryReminderTerm, DeliveryReminderLevel, WorkDate()), FalseValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RemindWithoutDate()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        DeliveryReminderTerm: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        CreateDeliveryReminder: Codeunit "Create Delivery Reminder";
    begin
        // Purpose of the test is to validate Codeunit 5005271: Create Delivery Reminder - Function Remind().

        // Setup.
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Default Del. Rem. Date Field"::"Expected Receipt Date");

        // Exercise & Verify : Verify that the reminder line is not created when RemindingDate = 0D. Return value from Function Remind must be false.
        Assert.IsFalse(CreateDeliveryReminder.Remind(PurchaseLine, DeliveryReminderTerm, DeliveryReminderLevel, WorkDate()), FalseValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RemindWithoutOutstandingQty()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        DeliveryReminderTerm: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        CreateDeliveryReminder: Codeunit "Create Delivery Reminder";
    begin
        // Purpose of the test is to validate Codeunit 5005271: Create Delivery Reminder - Function Remind().

        // Setup.
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Default Del. Rem. Date Field"::"Promised Receipt Date");

        PurchaseLine."Promised Receipt Date" := WorkDate();
        PurchaseLine."Outstanding Quantity" := 0;
        PurchaseLine.Insert();

        // Exercise & Verify : Verify that the reminder line is not created when Purchase Line - Outstanding Quantity <= 0. Return value from Function Remind must be false.
        Assert.IsFalse(CreateDeliveryReminder.Remind(PurchaseLine, DeliveryReminderTerm, DeliveryReminderLevel, CalcDate('<1D>', WorkDate())), FalseValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RemindMaxNoOfDeliveryReminder()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        DeliveryReminderTerm: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        DeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry";
        CreateDeliveryReminder: Codeunit "Create Delivery Reminder";
    begin
        // Purpose of the test is to validate Codeunit 5005271: Create Delivery Reminder - Function Remind().

        // Setup.
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Default Del. Rem. Date Field"::"Expected Receipt Date");

        PurchaseLine."Document No." := LibraryUTUtility.GetNewCode();
        PurchaseLine."Line No." := 1;
        PurchaseLine."Expected Receipt Date" := WorkDate();
        PurchaseLine."Outstanding Quantity" := 1;
        PurchaseLine.Insert();

        DeliveryReminderTerm."Max. No. of Delivery Reminders" := 1;
        DeliveryReminderTerm.Insert();

        DeliveryReminderLedgerEntry."Entry No." := SelectDeliveryReminderLedgerEntryNo();
        DeliveryReminderLedgerEntry."Posting Date" := WorkDate();
        DeliveryReminderLedgerEntry."Document Date" := WorkDate();
        DeliveryReminderLedgerEntry."Order No." := PurchaseLine."Document No.";
        DeliveryReminderLedgerEntry."Order Line No." := PurchaseLine."Line No.";
        DeliveryReminderLedgerEntry."Reminder Level" := 1;
        DeliveryReminderLedgerEntry.Insert();

        // Exercise & Verify : Verify that the reminder line is not created when DeliveryReminderTerms."Max. No. of Delivery Reminders"  <> 0 and does not exceed one more than Reminder levels.
        // Return value from Function Remind must be false.
        Assert.IsFalse(CreateDeliveryReminder.Remind(PurchaseLine, DeliveryReminderTerm, DeliveryReminderLevel, CalcDate('<1D>', WorkDate())), FalseValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidateVendorItemNoLength()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        DeliveryReminderTerm: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        CreateDeliveryReminder: Codeunit "Create Delivery Reminder";
    begin
        // [SCENARIO 442903] To ensure that delivery reminder line is able to capture vendor item no. if the length is more than 20

        // [GIVEN] Create a purchase document 
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Default Del. Rem. Date Field"::"Promised Receipt Date");

        PurchaseLine."Promised Receipt Date" := CalcDate('<1D>', WorkDate());
        // [WHEN] Vendor item no. is updated for 50 characters
        PurchaseLine."Vendor Item No." := LibraryRandom.RandText(50);
        PurchaseLine.Insert();

        // [THEN] Delivery reminder should be created withour any error
        Assert.IsFalse(CreateDeliveryReminder.Remind(PurchaseLine, DeliveryReminderTerm, DeliveryReminderLevel, WorkDate()), FalseValueMsg);
    end;

    local procedure CreateIssuedDelivReminderHeader(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header")
    begin
        IssuedDelivReminderHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedDelivReminderHeader.Name := LibraryUTUtility.GetNewCode();
        IssuedDelivReminderHeader.Insert();
    end;

    local procedure CreateDeliveryReminderHeader(var DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
        DeliveryReminderHeader."No." := LibraryUTUtility.GetNewCode();
        DeliveryReminderHeader.Name := LibraryUTUtility.GetNewCode();
        DeliveryReminderHeader.Insert();
    end;

    local procedure CreateDeliveryReminderLine(var DeliveryReminderLine: Record "Delivery Reminder Line"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        DeliveryReminderLine."Document No." := DocumentNo;
        DeliveryReminderLine."Line No." := LineNo;
        DeliveryReminderLine.Insert();
    end;

    local procedure CreateExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; TableName: Enum "Extended Text Table Name"; No: Code[20]; LanguageCode: Code[10])
    begin
        ExtendedTextHeader."Table Name" := TableName;
        ExtendedTextHeader."No." := No;
        ExtendedTextHeader."Language Code" := LanguageCode;
        ExtendedTextHeader."Text No." := 1;
        ExtendedTextHeader.Insert();
    end;

    local procedure CreateExtendedTextLine(var ExtendedTextLine: Record "Extended Text Line"; TableName: Enum "Extended Text Table Name"; No: Code[20]; LanguageCode: Code[10]; TextNo: Integer)
    begin
        ExtendedTextLine."Table Name" := TableName;
        ExtendedTextLine."No." := No;
        ExtendedTextLine."Language Code" := LanguageCode;
        ExtendedTextLine."Text No." := TextNo;
        ExtendedTextLine.Insert();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        GLAccount."Automatic Ext. Texts" := true;
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure UpdateExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; AllLanguageCodes: Boolean)
    begin
        ExtendedTextHeader."Delivery Reminder" := true;
        ExtendedTextHeader."All Language Codes" := AllLanguageCodes;
        ExtendedTextHeader.Modify();
    end;

    local procedure UpdateDeliveryReminderHeader(var DeliveryReminderHeader: Record "Delivery Reminder Header"; LanguageCode: Code[10])
    begin
        DeliveryReminderHeader."Document Date" := WorkDate();
        DeliveryReminderHeader."Language Code" := LanguageCode;
        DeliveryReminderHeader.Modify();
    end;

    local procedure UpdateDeliveryReminderLine(var DeliveryReminderLine: Record "Delivery Reminder Line"; Type: Option; No: Code[20])
    begin
        DeliveryReminderLine.Type := Type;
        DeliveryReminderLine."No." := No;
        DeliveryReminderLine.Modify();
    end;

    local procedure UpdatePurchasesPayablesSetup(DefaultDelRemDateField: Enum "Delivery Reminder Date Type")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Default Del. Rem. Date Field" := DefaultDelRemDateField;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SelectDeliveryReminderLedgerEntryNo(): Integer
    var
        DeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry";
    begin
        if DeliveryReminderLedgerEntry.FindLast() then
            exit(DeliveryReminderLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure IssuedDeliveryReminderReportHandler(var IssuedDeliveryReminder: Report "Issued Delivery Reminder")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure DeliveryReminderTestReportHandler(var DeliveryReminderTest: Report "Delivery Reminder - Test")
    begin
    end;
}

