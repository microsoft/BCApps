// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50192 "Filename Reminder Tests"
{
    // Drives two Base Application workflows that put several report files on one email, end to end,
    // and checks the name each file gets: reminder automation sending a reminder with its overdue
    // invoices attached, and the email download fallback Base Application uses when no email account
    // is set up. Each with no pattern - Business Central's own names, untouched - and with a reminder
    // pattern and an invoice pattern.
    //
    // The reminder is constructed rather than issued: issuing one for real needs overdue customer
    // entries, and posting those would leave ledger entries behind that cannot be removed. Everything
    // after that is Base Application's own: Send Reminder Action Job.SendReminders with a Send
    // Reminders Setup that attaches the invoices, two report selections for the invoice so that two
    // invoice files go on the email, and the email as Document-Mailing builds it. Base Application
    // asks each invoice's name once and gives it to both copies, which is why every invoice appears
    // twice under one name.
    //
    // A test codeunit because the download fallback asks a question first, which only a handler can
    // answer. Every row it creates carries the code ZZMEASURE or the number ZZRM-MEASURE and is
    // removed before and after; scripts/checkleftovers.ps1 checks that nothing is left.

    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>
    /// Reminder automation's email, stopped where Base Application raises OnBeforeSendEmail with every
    /// attachment named. With patterns the reminder carries its own pattern's name and each invoice
    /// its pattern's name - measured on 5 October, before the fix, as Business Central's names for all
    /// five files.
    /// </summary>
    [Test]
    procedure ReminderAutomationNamesTheReminderAndItsInvoices()
    begin
        RunBothWays(true);
    end;

    /// <summary>
    /// The same email with no email account set up: Base Application asks whether to download the
    /// attachments instead, and offers the same names.
    /// </summary>
    [Test]
    [HandlerFunctions('DownloadInsteadHandler')]
    procedure TheEmailDownloadFallbackOffersTheSameNames()
    var
        EmailAccount: Codeunit "Email Account";
    begin
        // With an account Base Application sends rather than falls back, and this must not send.
        if EmailAccount.IsAnyAccountRegistered() then
            Error(AccountRegisteredErr);
        RunBothWays(false);
    end;

    [ConfirmHandler]
    procedure DownloadInsteadHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure RunBothWays(StopBeforeSend: Boolean)
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        GlobalLanguage(ProofSupport.EnglishLanguageId());
        RemoveEverything();
        Commit();
        SetUpReminder();

        FilenameProofGuard.ClearPatterns();
        Commit();
        AssertNames(RunReminderAutomation(StopBeforeSend),
            BusinessCentralReminderTok + ReminderNoTok + PdfTok, BusinessCentralInvoiceTok, NoPatternTok);

        SetPatterns();
        AssertNames(RunReminderAutomation(StopBeforeSend),
            ReminderPrefixTok + ReminderNoTok + PdfTok, InvoicePrefixTok, WithPatternsTok);

        RemoveEverything();
        FilenameProofGuard.ClearPatterns();
        Commit();
    end;

    /// <summary>
    /// The names on the one email, in Base Application's order: the reminder, then each invoice twice.
    /// </summary>
    local procedure AssertNames(Captured: List of [Text]; ReminderName: Text; InvoiceStart: Text; Situation: Text)
    var
        Expected: Text;
        Actual: Text;
    begin
        if Captured.Count() <> 1 then
            Error(NotOneEmailErr, Situation, Captured.Count());
        Captured.Get(1, Actual);
        Expected := StrSubstNo(CountLbl, 5) + ReminderName + SeparatorTok +
            InvoiceStart + FirstInvoice."No." + PdfTok + SeparatorTok + InvoiceStart + FirstInvoice."No." + PdfTok + SeparatorTok +
            InvoiceStart + SecondInvoice."No." + PdfTok + SeparatorTok + InvoiceStart + SecondInvoice."No." + PdfTok + SeparatorTok;
        if Actual <> Expected then
            Error(WrongNamesErr, Situation, Expected, Actual);
    end;

    /// <summary>
    /// Runs reminder automation's send action once, for a freshly built reminder, and returns what the
    /// email carried: stopped at OnBeforeSendEmail, or let through to the download fallback.
    /// </summary>
    local procedure RunReminderAutomation(StopBeforeSend: Boolean): List of [Text]
    var
        ReminderAction: Record "Reminder Action";
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderActionGroupLog: Record "Reminder Action Group Log";
        ReminderAutomationError: Record "Reminder Automation Error";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
        EmailCapture: Codeunit "Filename Email Capture";
        SendReminderActionJob: Codeunit "Send Reminder Action Job";
        ErrorsOccured: Boolean;
    begin
        BuildReminder();
        // A run of the group first, as Reminders Automation Job starts one: the send action logs its
        // progress against the group's latest run and refuses to start without one.
        ReminderActionGroup.Get(GroupCodeTok);
        ReminderActionProgress.CreateGroupEntry(ReminderActionGroup, ReminderActionGroupLog);
        Commit();

        EmailCapture.Start(StopBeforeSend);
        BindSubscription(EmailCapture);
        ReminderAction.Get(GroupCodeTok, ActionCodeTok);
        SendReminderActionJob.SendReminders(ReminderAction, ErrorsOccured);
        UnbindSubscription(EmailCapture);

        ReminderAutomationError.SetRange("Reminder Action Group Code", GroupCodeTok);
        if ReminderAutomationError.FindFirst() then
            Error(AutomationErr, ReminderAutomationError."Error Text Short");
        if StopBeforeSend then
            exit(EmailCapture.CapturedEmails());
        exit(EmailCapture.CapturedDownloads());
    end;

    /// <summary>
    /// Reminder terms and a level of their own, so that reminder automation's terms filter selects
    /// this reminder and nothing in the company; two posted invoices of one customer; a second report
    /// selection for the invoice; and reminder automation's group, send action and setup.
    /// </summary>
    local procedure SetUpReminder()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderAction: Record "Reminder Action";
        SendRemindersSetup: Record "Send Reminders Setup";
        Existing: Record "Report Selections";
        ReportSelections: Record "Report Selections";
    begin
        FirstInvoice.SetFilter("Bill-to Customer No.", '<>%1', '');
        if FirstInvoice.FindSet() then
            repeat
                SecondInvoice.Reset();
                SecondInvoice.SetRange("Bill-to Customer No.", FirstInvoice."Bill-to Customer No.");
                SecondInvoice.SetFilter("No.", '<>%1', FirstInvoice."No.");
            until SecondInvoice.FindFirst() or (FirstInvoice.Next() = 0);
        if SecondInvoice."No." = '' then
            Error(NoTwoInvoicesErr);

        ReminderTerms.Init();
        ReminderTerms.Code := TermsCodeTok;
        ReminderTerms.Description := TermsCodeTok;
        ReminderTerms.Insert(false);
        ReminderLevel.Init();
        ReminderLevel."Reminder Terms Code" := TermsCodeTok;
        ReminderLevel."No." := 1;
        ReminderLevel.Insert(false);

        Existing.SetRange(Usage, Existing.Usage::"S.Invoice");
        Existing.FindFirst();
        ReportSelections := Existing;
        ReportSelections.Sequence := SecondSequenceTok;
        ReportSelections.Insert(false);

        ReminderActionGroup.Init();
        ReminderActionGroup.Code := GroupCodeTok;
        ReminderActionGroup.Insert(false);
        ReminderActionGroup.SetReminderTermsSelectionFilter(TermsCodeTok);

        ReminderAction.Init();
        ReminderAction."Reminder Action Group Code" := GroupCodeTok;
        ReminderAction.Code := ActionCodeTok;
        ReminderAction.Type := ReminderAction.Type::"Send Reminder";
        ReminderAction.Insert(false);

        SendRemindersSetup.Init();
        SendRemindersSetup.Code := ActionCodeTok;
        SendRemindersSetup."Action Group Code" := GroupCodeTok;
        SendRemindersSetup."Send by Email" := true;
        SendRemindersSetup."Attach Invoice Documents" := SendRemindersSetup."Attach Invoice Documents"::All;
        SendRemindersSetup.Insert(false);
        Commit();
    end;

    /// <summary>
    /// An issued reminder at level 1 for the customer, not yet emailed, with one reminder line for each
    /// of the two invoices. Built again for every run, so the run finds it unsent.
    /// </summary>
    local procedure BuildReminder()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        Customer: Record Customer;
    begin
        RemoveReminder();
        Customer.Get(FirstInvoice."Bill-to Customer No.");
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." := ReminderNoTok;
        IssuedReminderHeader."Customer No." := Customer."No.";
        IssuedReminderHeader.Name := Customer.Name;
        IssuedReminderHeader."Reminder Terms Code" := TermsCodeTok;
        IssuedReminderHeader."Reminder Level" := 1;
        IssuedReminderHeader."Posting Date" := WorkDate();
        IssuedReminderHeader."Document Date" := WorkDate();
        IssuedReminderHeader."Due Date" := WorkDate();
        IssuedReminderHeader."Language Code" := Customer."Language Code";
        IssuedReminderHeader."Currency Code" := Customer."Currency Code";
        // What Reminder-Make copies from the customer, and the reminder report reads.
        IssuedReminderHeader."Customer Posting Group" := Customer."Customer Posting Group";
        IssuedReminderHeader."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
        IssuedReminderHeader."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        IssuedReminderHeader.Address := Customer.Address;
        IssuedReminderHeader.City := Customer.City;
        IssuedReminderHeader."Post Code" := Customer."Post Code";
        IssuedReminderHeader."Country/Region Code" := Customer."Country/Region Code";
        IssuedReminderHeader.Insert(false);

        AddReminderLine(IssuedReminderLine, 10000, FirstInvoice."No.");
        AddReminderLine(IssuedReminderLine, 20000, SecondInvoice."No.");
        Commit();
    end;

    local procedure AddReminderLine(var IssuedReminderLine: Record "Issued Reminder Line"; LineNo: Integer; InvoiceNo: Code[20])
    begin
        IssuedReminderLine.Init();
        IssuedReminderLine."Reminder No." := ReminderNoTok;
        IssuedReminderLine."Line No." := LineNo;
        IssuedReminderLine.Type := IssuedReminderLine.Type::"Customer Ledger Entry";
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Document Type" := IssuedReminderLine."Document Type"::Invoice;
        IssuedReminderLine."Document No." := InvoiceNo;
        IssuedReminderLine.Description := InvoiceNo;
        IssuedReminderLine.Insert(false);
    end;

    local procedure SetPatterns()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        FilenameProofGuard.ClearPatterns();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Issued Reminder Header");
        Pattern.Validate("File Name Pattern", ReminderPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        Clear(Pattern);
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", InvoicePatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        Commit();
    end;

    local procedure RemoveReminder()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Reminder No.", ReminderNoTok);
        IssuedReminderLine.DeleteAll(false);
        IssuedReminderHeader.SetRange("No.", ReminderNoTok);
        IssuedReminderHeader.DeleteAll(false);
    end;

    /// <summary>
    /// Removes every row this codeunit creates, and the rows reminder automation writes about its run.
    /// </summary>
    local procedure RemoveEverything()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderAction: Record "Reminder Action";
        SendRemindersSetup: Record "Send Reminders Setup";
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionGroupLog: Record "Reminder Action Group Log";
        ReminderAutomationError: Record "Reminder Automation Error";
        ReportSelections: Record "Report Selections";
    begin
        RemoveReminder();
        ReminderLevel.SetRange("Reminder Terms Code", TermsCodeTok);
        ReminderLevel.DeleteAll(false);
        ReminderTerms.SetRange(Code, TermsCodeTok);
        ReminderTerms.DeleteAll(false);
        SendRemindersSetup.SetRange("Action Group Code", GroupCodeTok);
        SendRemindersSetup.DeleteAll(false);
        ReminderAction.SetRange("Reminder Action Group Code", GroupCodeTok);
        ReminderAction.DeleteAll(false);
        ReminderActionGroup.SetRange(Code, GroupCodeTok);
        ReminderActionGroup.DeleteAll(false);
        ReminderActionLog.SetRange("Reminder Action Group ID", GroupCodeTok);
        ReminderActionLog.DeleteAll(false);
        ReminderActionGroupLog.SetRange("Reminder Action Group ID", GroupCodeTok);
        ReminderActionGroupLog.DeleteAll(false);
        ReminderAutomationError.SetRange("Reminder Action Group Code", GroupCodeTok);
        ReminderAutomationError.DeleteAll(false);
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        ReportSelections.SetRange(Sequence, SecondSequenceTok);
        ReportSelections.DeleteAll(false);
    end;

    var
        FirstInvoice: Record "Sales Invoice Header";
        SecondInvoice: Record "Sales Invoice Header";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        ProofSupport: Codeunit "Filename Proof Support";
        TermsCodeTok: Label 'ZZMEASURE', Locked = true;
        GroupCodeTok: Label 'ZZMEASURE', Locked = true;
        ActionCodeTok: Label 'ZZMEASURE', Locked = true;
        SecondSequenceTok: Label 'ZZMEASURE', Locked = true;
        ReminderNoTok: Label 'ZZRM-MEASURE', Locked = true;
        ReminderPatternTok: Label 'Reminder-[No.]', Locked = true;
        InvoicePatternTok: Label 'Invoice-[No.]', Locked = true;
        ReminderPrefixTok: Label 'Reminder-', Locked = true;
        InvoicePrefixTok: Label 'Invoice-', Locked = true;
        // Business Central's own names for the two documents, as measured on 5 October in English.
        BusinessCentralReminderTok: Label 'Issued Reminder ', Locked = true;
        BusinessCentralInvoiceTok: Label 'Sales Invoice ', Locked = true;
        PdfTok: Label '.pdf', Locked = true;
        CountLbl: Label '%1 attachments: ', Comment = '%1 how many', Locked = true;
        SeparatorTok: Label ' | ', Locked = true;
        NoPatternTok: Label 'no pattern', Locked = true;
        WithPatternsTok: Label 'reminder and invoice patterns', Locked = true;
        WrongNamesErr: Label 'With %1, the email should carry "%2" but carries "%3".', Comment = '%1 the situation, %2 expected, %3 actual';
        NotOneEmailErr: Label 'With %1, reminder automation should produce one email, but produced %2.', Comment = '%1 the situation, %2 how many';
        AutomationErr: Label 'Reminder automation reported an error: %1', Comment = '%1 the error';
        NoTwoInvoicesErr: Label 'No customer with two posted sales invoices, so reminder automation cannot be tested.';
        AccountRegisteredErr: Label 'An email account is registered, so Base Application would send instead of falling back to a download.';
}
