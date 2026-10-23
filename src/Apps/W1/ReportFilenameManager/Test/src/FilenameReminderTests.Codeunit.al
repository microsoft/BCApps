// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.Email;

codeunit 149542 "Filename Reminder Tests"
{
    // Names on a reminder automation email with its overdue invoices attached, sent and through the
    // download fallback (no email account), with and without patterns. The reminder is constructed
    // rather than issued, so no reminder entries are posted; Base Application asks each invoice's name
    // once for both report selections, so every invoice appears twice under one name. The setup rows
    // carry ZZMEASURE or ZZRM-MEASURE and are removed before and after; the posted invoices stay.

    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>
    /// Reminder automation's email at OnBeforeSendEmail: with patterns the reminder and each invoice
    /// carry their own pattern's name.
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
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        Captured: List of [Text];
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        GlobalLanguage(ProofSupport.EnglishLanguageId());
        RemoveEverything();
        Commit();
        SetUpReminder();

        FilenameProofGuard.ClearPatterns();
        Commit();
        Captured := RunReminderAutomation(StopBeforeSend);
        IssuedReminderHeader.Get(ReminderNoTok);
        AssertNames(Captured,
            ReportDistributionManagement.GetFullDocumentTypeText(IssuedReminderHeader) + ' ' + ReminderNoTok + PdfTok,
            ReportDistributionManagement.GetFullDocumentTypeText(FirstInvoice) + ' ' + FirstInvoice."No." + PdfTok,
            ReportDistributionManagement.GetFullDocumentTypeText(SecondInvoice) + ' ' + SecondInvoice."No." + PdfTok, NoPatternTok);

        SetPatterns();
        AssertNames(RunReminderAutomation(StopBeforeSend),
            ReminderPrefixTok + ReminderNoTok + PdfTok,
            InvoicePrefixTok + FirstInvoice."No." + PdfTok, InvoicePrefixTok + SecondInvoice."No." + PdfTok, WithPatternsTok);

        RemoveEverything();
        FilenameProofGuard.ClearPatterns();
        Commit();
    end;

    // In Base Application's order: the reminder, then each invoice twice.
    local procedure AssertNames(Captured: List of [Text]; ReminderName: Text; FirstInvoiceName: Text; SecondInvoiceName: Text; Situation: Text)
    var
        Expected: Text;
        Actual: Text;
    begin
        if Captured.Count() <> 1 then
            Error(NotOneEmailErr, Situation, Captured.Count());
        Captured.Get(1, Actual);
        Expected := StrSubstNo(CountLbl, 5) + ReminderName + SeparatorTok +
            FirstInvoiceName + SeparatorTok + FirstInvoiceName + SeparatorTok +
            SecondInvoiceName + SeparatorTok + SecondInvoiceName + SeparatorTok;
        if Actual <> Expected then
            Error(WrongNamesErr, Situation, Expected, Actual);
    end;

    // Returns what the email carried, stopped at OnBeforeSendEmail or at the download fallback.
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
        // The send action refuses to start without a run of the group to log against.
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

    // Reminder terms of the test's own, so reminder automation's terms filter selects nothing else.
    local procedure SetUpReminder()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderAction: Record "Reminder Action";
        SendRemindersSetup: Record "Send Reminders Setup";
        Existing: Record "Report Selections";
        ReportSelections: Record "Report Selections";
        TestData: Codeunit "Filename Test Data";
        CustomerNo: Code[20];
    begin
        CustomerNo := TestData.CreateCustomer();
        TestData.SetupDocumentReports();
        TestData.PostNewInvoice(CustomerNo, FirstInvoice);
        TestData.PostNewInvoice(CustomerNo, SecondInvoice);

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

    // Built again for every run, so the run finds it unsent.
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
        // What a reminder copies from its customer (Reminder Header's Customer No. validation), and
        // the reminder report reads.
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

    // Includes the rows reminder automation writes about its run.
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
        // Business Central's own names for the two documents, in English.
        PdfTok: Label '.pdf', Locked = true;
        CountLbl: Label '%1 attachments: ', Comment = '%1 how many', Locked = true;
        SeparatorTok: Label ' | ', Locked = true;
        NoPatternTok: Label 'no pattern', Locked = true;
        WithPatternsTok: Label 'reminder and invoice patterns', Locked = true;
        WrongNamesErr: Label 'With %1, the email should carry "%2" but carries "%3".', Comment = '%1 the situation, %2 expected, %3 actual';
        NotOneEmailErr: Label 'With %1, reminder automation should produce one email, but produced %2.', Comment = '%1 the situation, %2 how many';
        AutomationErr: Label 'Reminder automation reported an error: %1', Comment = '%1 the error';
        AccountRegisteredErr: Label 'An email account is registered, so Base Application would send instead of falling back to a download.';
}
