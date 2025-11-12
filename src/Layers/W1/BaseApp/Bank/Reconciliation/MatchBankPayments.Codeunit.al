// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Environment.Configuration;
using System.Telemetry;

#pragma warning disable AA0198
codeunit 1255 "Match Bank Payments"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm;
    TableNo = "Bank Acc. Reconciliation Line";

    trigger OnRun()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.Copy(Rec);

        Code(BankAccReconciliationLine);

        Rec := BankAccReconciliationLine;

        OnAfterCode(BankAccReconciliationLine);
    end;

    procedure MatchNoOverwriteOfManualOrAccepted(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconciliationLineBackup: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLineBackup.Copy(BankAccReconciliationLine);

        Code(BankAccReconciliationLineBackup, false);

        BankAccReconciliationLine := BankAccReconciliationLineBackup;

        OnAfterCode(BankAccReconciliationLine);
    end;

    var
        BankAccount: Record "Bank Account";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
#pragma warning disable AA0470
        TextMapperRulesOverridenTxt: Label '%1 text mapper rules could be applied. They were overridden because a record with the %2 match confidence was found.';
        MultipleEntriesWithSilarConfidenceFoundTxt: Label 'There are %1 ledger entries that this statement line could be applied to with the same confidence.';
        MultipleStatementLinesWithSameConfidenceFoundTxt: Label 'There are %1 alternative statement lines that could be applied to the same ledger entry with the same confidence.';
#pragma warning restore AA0470
        CannotFindRuleLbl: Label 'Unexpected - could not find the payment application rule, score %1', Locked = true, Comment = '%1 is the score';
        AutomatchEventNameTelemetryTxt: Label 'Automatch', Locked = true;
        TempOneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary;
        TempCustomerLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        TempVendorLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        TempBankAccLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        TempEmployeeLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        TempDirectDebitCollectionBuffer: Record "Direct Debit Collection Buffer" temporary;
        BankPmtApplSettingsInitialized: Boolean;
        ApplyEntries: Boolean;
#pragma warning disable AA0470
        CannotApplyDocumentNoOneToManyApplicationTxt: Label 'Document No. %1 was not applied because the transaction amount was insufficient.';
#pragma warning restore AA0470
        UsePaymentDiscounts: Boolean;
        MinimumMatchScore: Integer;
        RelatedPartyMatchedInfoText: Text;
        DocumentMatchedInfoText: Text;
        LogInfoText: Boolean;
        MatchSummaryMsg: Label '%1 payment lines out of %2 are applied.\\', Comment = '%1 number of lines that are applied, %2 total number of lines';
#pragma warning disable AA0470
        MatchingStmtLinesMsg: Label 'The matching of statement lines to open ledger entries is in progress.\\Please wait while the operation is being completed.\\#1####### @2@@@@@@@@@@@@@';
        ProcessedStmtLinesMsg: Label 'Processed %1 out of %2 lines.';
#pragma warning restore AA0470
        CreatingAppliedEntriesMsg: Label 'The application of statement lines to open ledger entries is in progress. Please wait while the operation is being completed.';
        ProgressBarMsg: Label 'Please wait while the operation is being completed.';
        MustChooseAccountErr: Label 'You must choose an account to transfer the difference to.';
        LineSplitTxt: Label 'The value in the Transaction Amount field has been reduced by %1. A new line with %1 in the Transaction Amount field has been created.', Comment = '%1 - Difference';
        BankAccountRecCategoryLbl: Label 'AL Payment Reconciliation', Locked = true;
        BankAccountRecTotalAndMatchedLinesLbl: Label 'Total Bank Statement Lines: %1, of those applied: %2, and text-matched: %3', Locked = true;
        MatchedRelatedPartyOnBankAccountMsg: Label 'The related party was matched based on the bank account in the statement file.';
        MatchedRelatedPartyOnBankStatementInfoMsg: Label 'The related party was matched based on the %1 in the statement file.', Comment = '%1 is the name of the fields used, e.g. Address, Name...';
        TextPartialMatchMsg: Label '%1 was matched with %2% accuracy.', Comment = '%1 is the name of the field, %2 is percent';
        RelatedPartyNameIsUniqueMsg: Label 'The name of the related party is unique in your records.';
        ExternalDocumentNumberMatchedInTransactionTextMsg: Label 'We found a match for the external document number in the transaction text.';
        DocumentNumberMatchedInTransactionTextMsg: Label 'We found a match for the document number in the transaction text.';
        DocumentNumberMatchedByPaymentReferenceMsg: Label 'We matched the document number by using the payment reference.';
        NewLinePlaceholderLbl: Label '%1%2', Locked = true;
        RelatedPartyMatchInfoPlaceholderLbl: Label '%1, %2, %3', Locked = true;
        PaymentRecPreformanceCategoryLbl: Label 'PaymentRecPerformance', Locked = true;
        MatchedLineTelemetryTxt: Label 'Line with SystemId: %1 Matched, Total Time: %2.  Total time Customer Matching %3, Total time Vendor Matching: %4, Total time Employee Matching: %5,Total time Bank Ledger Entries: %6, Total Time TextMappings: %7', Locked = true;
        AppliedEntriesToBankStatementLineTxt: Label 'Line with SystemId: %1 - Applied entries - Account Type: %2, One-To-Many match: %3, Match Quality: %4.', Locked = true;
        SpecificTaskSummaryTxt: Label 'Specific Task Summary: TotalTimeDirectCollection: %1, TotalTimeRelatedPartyMatching: %2, TotalTimeDocumentNoMatching: %3, TotalTimeAmountMatching: %4, TotalTimeStringNearness: %5, TotalTimeDocumentNoMatchingForBankLedgerEntry: %6, TotalTimeSearchingDocumentNoInLedgerEntries: %7, HitCountClosingDocumentMatches: %8 out of %9', Locked = true;
        MissingRelatedPartyTelemetryMsg: Label 'The ledger entries contain the entries that do not exist in master data. This is indication of corrupted ledger entries. Master data type %1.', Locked = true, Comment = '%1 Master Data Type';
        PmtRecNoSeriesNotificationNameLbl: Label 'Payment reconciliation journals need a number series.';
        PmtRecNoSeriesNotificationDescriptionLbl: Label 'Notifies the user that payment reconciliation journals are not assigned to a number series.';
        EntriesMatchedElsewhereMsg: Label 'There are open %1 ledger entries applied in other journals. The entries were not considered in the automatic application. To consider these entries, unapply them first from the other journals.', Comment = '%1 - either "customer", "vendor" or "employee".';
        DontShowAgainTxt: Label 'Don''t show again.';
        TotalTimeMatchingCustomerLedgerEntriesPerLine: Duration;
        TotalTimeMatchingVendorLedgerEntriesPerLine: Duration;
        TotalTimeMatchingEmployeeLedgerEntriesPerLine: Duration;
        TotalTimeMatchingBankLedgerEntriesPerLine: Duration;
        TotalTimeTimeTextMappingsPerLine: Duration;
        TotalTimeDirectCollection: Duration;
        TotalTimeRelatedPartyMatching: Duration;
        TotalTimeDocumentNoMatching: Duration;
        TotalTimeAmountMatching: Duration;
        TotalTimeStringNearness: Duration;
        TotalTimeDocumentNoMatchingForBankLedgerEntry: Duration;
        TotalTimeSearchingDocumentNoInLedgerEntries: Duration;
        BankLedgerEntriesClosingDocumentNumbers: Dictionary of [Integer, List of [Code[35]]];
        MissingDataTypeTelemetrySent: List of [Integer];
        TotalNoClosingDocumentMatches: Integer;
        HitCountClosingDocumentMatches: Integer;

    procedure IsTextToAccountMappig(
        BankAccReconciliaitonLine: Record "Bank Acc. Reconciliation Line";
        var TempTextToAccMapping: Record "Text-to-Account Mapping" temporary
        ): Boolean
    var
        IsMapToTextAccount: Boolean;
    begin
        IsMapToTextAccount := BankAccReconciliaitonLine."Match Confidence" = BankAccReconciliaitonLine."Match Confidence"::"High - Text-to-Account Mapping";
        if IsMapToTextAccount then
            FindApplicableTextMappings(BankAccReconciliaitonLine, TempTextToAccMapping);

        exit(IsMapToTextAccount);
    end;

    procedure IsMatchedAutomatically(
        BankAccReconciliaitonLine: Record "Bank Acc. Reconciliation Line";
        var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"
    ): Boolean
    var
        IsAutoMatch: Boolean;
        MatchingRuleFound: Boolean;
    begin
        IsAutoMatch := BankPmtApplRule.IsMatchedAutomatically(BankAccReconciliaitonLine."Match Confidence".AsInteger(), BankAccReconciliaitonLine."Applied Entries");
        if IsAutoMatch or (BankAccReconciliaitonLine."Match Confidence" = BankAccReconciliaitonLine."Match Confidence"::Accepted) then begin
            BankPmtApplRule.SetRange(Score, BankAccReconciliaitonLine."Match Quality");
            MatchingRuleFound := BankPmtApplRule.FindFirst();
            if not MatchingRuleFound and IsAutoMatch then
                Session.LogMessage('0000BN6', StrSubstNo(CannotFindRuleLbl, BankAccReconciliaitonLine."Match Quality"), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);

            IsAutoMatch := MatchingRuleFound;
            BankPmtApplRule.SetRange(Score);
        end;

        exit(IsAutoMatch);
    end;

    procedure GetMatchPaymentDetailsInfo(
        BankAccReconciliaitonLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        MatchedAutomatically: Boolean;
        var RelatedPartyMatchedText: Text;
        var AmountMatchText: Text;
        var DocumentMatchedText: Text;
        var DirectDebitMatchedText: Text;
        var DirectDebitMatched: Boolean;
        var NoOfLedgerEntriesWithinAmountTolerance: Integer;
        var NoOfLedgerEntriesOutsideAmountTolerance: Integer;
        var RelatedEntryAdditionalMatchInfo: Text;
        var DocumentNoAdditionalMatchInfo: Text
        )
    var
        ActualBankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        MinAmount: Decimal;
        MaxAmount: Decimal;
        RemainingAmount: Decimal;
        TempLedgerEntryFound: Boolean;
        AppliesToEntriesFilter: Text;
    begin
        BankAccReconciliaitonLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        case BankAccReconciliaitonLine."Account Type" of
            BankAccReconciliaitonLine."Account Type"::Customer:
                begin
                    if TempCustomerLedgerEntryMatchingBuffer.IsEmpty() then
                        InitializeCustomerLedgerEntriesMatchingBuffer(BankAccReconciliaitonLine, TempCustomerLedgerEntryMatchingBuffer);

                    NoOfLedgerEntriesWithinAmountTolerance := TempCustomerLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(MinAmount, MaxAmount, BankAccReconciliaitonLine."Transaction Date", UsePaymentDiscounts);
                    NoOfLedgerEntriesOutsideAmountTolerance := TempCustomerLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesOutsideRange(MinAmount, MaxAmount, BankAccReconciliaitonLine."Transaction Date", UsePaymentDiscounts);
                    TempLedgerEntryMatchingBuffer.Copy(TempCustomerLedgerEntryMatchingBuffer, true);
                end;
            BankAccReconciliaitonLine."Account Type"::Vendor:
                begin
                    if TempVendorLedgerEntryMatchingBuffer.IsEmpty() then
                        InitializeVendorLedgerEntriesMatchingBuffer(BankAccReconciliaitonLine, TempVendorLedgerEntryMatchingBuffer);

                    NoOfLedgerEntriesWithinAmountTolerance := TempVendorLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(MinAmount, MaxAmount, BankAccReconciliaitonLine."Transaction Date", UsePaymentDiscounts);
                    NoOfLedgerEntriesOutsideAmountTolerance := TempVendorLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesOutsideRange(MinAmount, MaxAmount, BankAccReconciliaitonLine."Transaction Date", UsePaymentDiscounts);
                    TempLedgerEntryMatchingBuffer.Copy(TempVendorLedgerEntryMatchingBuffer, true);
                end;
            BankAccReconciliaitonLine."Account Type"::"Bank Account":
                begin
                    if TempBankAccLedgerEntryMatchingBuffer.IsEmpty() then
                        InitializeBankAccLedgerEntriesMatchingBuffer(BankAccReconciliaitonLine, TempBankAccLedgerEntryMatchingBuffer);

                    NoOfLedgerEntriesWithinAmountTolerance := TempBankAccLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(MinAmount, MaxAmount, BankAccReconciliaitonLine."Transaction Date", UsePaymentDiscounts);
                    NoOfLedgerEntriesOutsideAmountTolerance := TempBankAccLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesOutsideRange(MinAmount, MaxAmount, BankAccReconciliaitonLine."Transaction Date", UsePaymentDiscounts);
                    TempLedgerEntryMatchingBuffer.Copy(TempBankAccLedgerEntryMatchingBuffer, true);
                end;
        end;

        if not MatchedAutomatically then
            exit;

        TempLedgerEntryFound := false;
        AppliesToEntriesFilter := BankAccReconciliaitonLine.GetAppliedToEntryFilter();
        if AppliesToEntriesFilter <> '' then begin
            TempLedgerEntryMatchingBuffer.SetFilter("Entry No.", StrSubstNo('=%1', AppliesToEntriesFilter));
            TempLedgerEntryFound := TempLedgerEntryMatchingBuffer.FindFirst();
        end;

        LogInfoText := true;
        if TempLedgerEntryFound then
            MatchEntries(TempLedgerEntryMatchingBuffer, BankAccReconciliaitonLine, BankAccReconciliaitonLine."Account Type", ActualBankPmtApplRule, RemainingAmount)
        else begin
            Session.LogMessage('0000BN7', StrSubstNo(
                    'Could not find the Temp Ledger Entry - Filter %1, Account Type %2',
                    BankAccReconciliaitonLine.GetAppliedToEntryFilter(),
                    BankAccReconciliaitonLine."Account Type"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
            ActualBankPmtApplRule := BankPmtApplRule;
        end;

        AmountMatchText := Format(ActualBankPmtApplRule."Amount Incl. Tolerance Matched");
        RelatedPartyMatchedText := Format(ActualBankPmtApplRule."Related Party Matched");
        RelatedEntryAdditionalMatchInfo := RelatedPartyMatchedInfoText;
        DocumentNoAdditionalMatchInfo := DocumentMatchedInfoText;
        DocumentMatchedText := Format(ActualBankPmtApplRule."Doc. No./Ext. Doc. No. Matched");
        DirectDebitMatchedText := Format(ActualBankPmtApplRule."Direct Debit Collect. Matched");
        DirectDebitMatched := ActualBankPmtApplRule."Direct Debit Collect. Matched" = ActualBankPmtApplRule."Direct Debit Collect. Matched"::Yes;
    end;

    procedure "Code"(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Overwrite: Boolean)
    begin
        if BankAccReconciliationLine.IsEmpty() then
            exit;

        MapLedgerEntriesToStatementLines(BankAccReconciliationLine, Overwrite, ApplyEntries);

        if ApplyEntries then begin
            ApplyLedgerEntriesToStatementLines(BankAccReconciliationLine, Overwrite);
            NotifyIfEntriesMatchedElsewhere(BankAccReconciliationLine);
        end;
    end;

    procedure "Code"(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        Code(BankAccReconciliationLine, true);
    end;

    local procedure NotifyIfEntriesMatchedElsewhere(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        Prefix: Code[50];
        MaxEntriesToCheck: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNotifyIfEntriesMatchedElsewhere(BankAccReconciliationLine, IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed() then
            exit;
        MaxEntriesToCheck := 600;
        Prefix := BankAccReconciliationLine.GetAppliesToIDForBankStatement();
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        if CustLedgerEntry.Count() < MaxEntriesToCheck then
            if CustLedgerEntry.FindSet() then
                repeat
                    if CopyStr(CustLedgerEntry."Applies-to ID", 1, StrLen(Prefix)) <> Prefix then begin
                        LaunchEntriesMatchedElsewhereNotification('customer');
                        exit;
                    end;
                until CustLedgerEntry.Next() = 0;
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        if VendorLedgerEntry.Count() < MaxEntriesToCheck then
            if VendorLedgerEntry.FindSet() then
                repeat
                    if CopyStr(VendorLedgerEntry."Applies-to ID", 1, StrLen(Prefix)) <> Prefix then begin
                        LaunchEntriesMatchedElsewhereNotification('vendor');
                        exit;
                    end;
                until VendorLedgerEntry.Next() = 0;
        EmployeeLedgerEntry.SetRange(Open, true);
        EmployeeLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        if EmployeeLedgerEntry.Count() < MaxEntriesToCheck then
            if EmployeeLedgerEntry.FindSet() then
                repeat
                    if CopyStr(EmployeeLedgerEntry."Applies-to ID", 1, StrLen(Prefix)) <> Prefix then begin
                        LaunchEntriesMatchedElsewhereNotification('employee');
                        exit;
                    end;
                until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure LaunchEntriesMatchedElsewhereNotification(Entity: Text)
    var
        MyNotifications: Record "My Notifications";
        Notification: Notification;
    begin
        if not MyNotifications.IsEnabled(EntriesMatchedElsewhereNotificationId()) then
            exit;
        Notification.Id := EntriesMatchedElsewhereNotificationId();
        Notification.Message := StrSubstNo(EntriesMatchedElsewhereMsg, Entity);
        Notification.Scope := NotificationScope::LocalScope;
        Notification.AddAction(DontShowAgainTxt, Codeunit::"Match Bank Payments", 'HideEntriesMatchedElsewhereNotification');
        Notification.Send();
    end;

    internal procedure HideEntriesMatchedElsewhereNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(EntriesMatchedElsewhereNotificationId()) then
            MyNotifications.InsertDefault(EntriesMatchedElsewhereNotificationId(), 'name', 'desc', false);
    end;

    local procedure EntriesMatchedElsewhereNotificationId(): Guid
    begin
        exit('625601f1-689d-456f-9966-6756420215e0');
    end;

    internal procedure DisableNotification(var MyNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotification.Id <> GetNumberSeriesNotificationId() then
            exit;

        MyNotifications.InsertDefault(MyNotification.Id, PmtRecNoSeriesNotificationNameLbl, PmtRecNoSeriesNotificationDescriptionLbl, false);
        MyNotifications.Disable(MyNotification.Id)
    end;

    internal procedure OpenBankAccountCard(var MyNotification: Notification)
    var
        LocalBankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if MyNotification.Id <> GetNumberSeriesNotificationId() then
            exit;

        if not LocalBankAccount.Get(MyNotification.GetData(BankAccReconciliationLine.FieldName("Bank Account No."))) then
            exit;

        Page.Run(Page::"Bank Account Card", LocalBankAccount, LocalBankAccount."Pmt. Rec. No. Series");
    end;

    internal procedure GetNumberSeriesNotificationId(): Guid
    begin
        exit('76d60ad7-20a5-4b64-b160-f059e1c7ab2d');
    end;

    procedure OpenLinesForReviewPage(ReviewNotification: Notification)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        Evaluate(BankAccReconciliationLine."Statement Type", ReviewNotification.GetData(BankAccReconciliationLine.FieldName("Statement Type")));
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", ReviewNotification.GetData(BankAccReconciliationLine.FieldName("Statement No.")));
        BankAccReconciliationLine.SetRange("Bank Account No.", ReviewNotification.GetData(BankAccReconciliationLine.FieldName("Bank Account No.")));
        if not BankAccReconciliationLine.FindFirst() then
            exit;

        GetLinesForReview(BankAccReconciliationLine, ReviewNotification.GetData('ReviewScoreFilter'));
        Page.Run(Page::"Payment Application Review", BankAccReconciliationLine);
    end;

    procedure OpenLinesWithDifferencePage(ReviewNotification: Notification)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        Evaluate(BankAccReconciliationLine."Statement Type", ReviewNotification.GetData(BankAccReconciliationLine.FieldName("Statement Type")));
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", ReviewNotification.GetData(BankAccReconciliationLine.FieldName("Statement No.")));
        BankAccReconciliationLine.SetRange("Bank Account No.", ReviewNotification.GetData(BankAccReconciliationLine.FieldName("Bank Account No.")));
        if not BankAccReconciliationLine.FindFirst() then
            exit;

        GetLinesWithDifference(BankAccReconciliationLine);
        Page.Run(Page::"Payment Application Review", BankAccReconciliationLine);
    end;

    procedure GetLinesForReview(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; ReviewScoreFilter: Text)
    begin
        if BankAccReconciliationLine.IsEmpty() then
            exit;

        BankAccReconciliationLine.SetFilter("Match Quality", ReviewScoreFilter);
        BankAccReconciliationLine.SetFilter("Match Confidence", BankAccReconciliationLine.GetMatchedAutomaticallyFilter());
    end;

    procedure GetLinesWithDifference(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccReconciliationLine.SetFilter(Difference, '<>0');
    end;

    local procedure ApplyLedgerEntriesToStatementLines(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Overwrite: Boolean)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Window: Dialog;
    begin
        FeatureTelemetry.LogUptake('0000KMM', BankAccReconciliation.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::Used);
        Window.Open(CreatingAppliedEntriesMsg);
        BankAccReconciliation.Get(
          BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
          BankAccReconciliationLine."Statement No.");

        DeleteAppliedPaymentEntries(BankAccReconciliation, Overwrite);
        DeletePaymentMatchDetails(BankAccReconciliation);

        CreateAppliedEntries(BankAccReconciliation);
        if not Overwrite then
            BankAccReconciliationLine.SetFilter("Match Confidence", '<>%1&<>%2',
                                                   BankAccReconciliationLine."Match Confidence"::Accepted,
                                                   BankAccReconciliationLine."Match Confidence"::Manual);
        UpdatePaymentMatchDetails(BankAccReconciliationLine);
        OnApplyLedgerEntriesToStatementLinesOnAfterUpdatePaymentMatchDetails(BankAccReconciliation, BankAccReconciliationLine, Overwrite);
        Window.Close();

        ShowMatchSummary(BankAccReconciliation);
        FeatureTelemetry.LogUsage('0000KMN', BankAccReconciliation.GetPaymentRecJournalTelemetryFeatureName(), AutomatchEventNameTelemetryTxt);
    end;

    local procedure MapLedgerEntriesToStatementLines(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Overwrite: Boolean; ApplyEntries: Boolean)
    var
        Window: Dialog;
        TotalNoOfLines: Integer;
        ProcessedLines: Integer;
        LineStartTime: DateTime;
        StartTime: DateTime;
        TimeCustomerLedgerEntries: Duration;
        TimeVendorLedgerEntries: Duration;
        TimeEmployeeLedgerEntries: Duration;
        TimeBankLedgerEntries: Duration;
        TimeTextMappings: Duration;
        DisableBankLedgerEntriesMatch: Boolean;
        DisableCustomerLedgerEntriesMatch: Boolean;
        DisableVendorLedgerEntriesMatch: Boolean;
        DisableEmployeeLedgerEntriesMatch: Boolean;
        SkipOtherEntries: Boolean;
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.DeleteAll();
        TempCustomerLedgerEntryMatchingBuffer.DeleteAll();
        TempVendorLedgerEntryMatchingBuffer.DeleteAll();
        TempBankAccLedgerEntryMatchingBuffer.DeleteAll();
        TempDirectDebitCollectionBuffer.DeleteAll();

        TempBankPmtApplRule.LoadRules();
        MinimumMatchScore := GetLowestMatchScore();

        InitializeBankPmtApplSettings();

        DisableCustomerLedgerEntriesMatch := not BankPmtApplSettings."Cust. Ledger Entries Matching";
        DisableVendorLedgerEntriesMatch := not BankPmtApplSettings."Vendor Ledger Entries Matching";
        DisableBankLedgerEntriesMatch := not BankPmtApplSettings."Bank Ledger Entries Matching";
        DisableEmployeeLedgerEntriesMatch := not BankPmtApplSettings."Empl. Ledger Entries Matching";

        BankAccReconciliationLine.SetFilter("Statement Amount", '<>0');
        if not Overwrite then
            BankAccReconciliationLine.SetFilter("Match Confidence", '<>%1&<>%2',
                                                  BankAccReconciliationLine."Match Confidence"::Accepted,
                                                  BankAccReconciliationLine."Match Confidence"::Manual);
        if BankAccReconciliationLine.FindSet() then begin
            OnDisableCustomerLedgerEntriesMatch(DisableCustomerLedgerEntriesMatch, BankAccReconciliationLine);
            OnDisableVendorLedgerEntriesMatch(DisableVendorLedgerEntriesMatch, BankAccReconciliationLine);
            OnDisableEmployeeLedgerEntriesMatch(DisableEmployeeLedgerEntriesMatch, BankAccReconciliationLine);
            OnDisableBankLedgerEntriesMatch(DisableBankLedgerEntriesMatch, BankAccReconciliationLine);

            if not DisableCustomerLedgerEntriesMatch then
                InitializeCustomerLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempCustomerLedgerEntryMatchingBuffer, ApplyEntries);

            if not DisableVendorLedgerEntriesMatch then
                InitializeVendorLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempVendorLedgerEntryMatchingBuffer, ApplyEntries);

            if not DisableBankLedgerEntriesMatch then
                InitializeBankAccLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempBankAccLedgerEntryMatchingBuffer, ApplyEntries);

            if not DisableEmployeeLedgerEntriesMatch then
                InitializeEmployeeLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempEmployeeLedgerEntryMatchingBuffer, ApplyEntries);

            InitializeDirectDebitCollectionEntriesMatchingBuffer(TempDirectDebitCollectionBuffer);

            if not Overwrite then
                RemoveAppliedEntriesFromBufferTables();

            TotalNoOfLines := BankAccReconciliationLine.Count();
            ProcessedLines := 0;

            if ApplyEntries then
                Window.Open(MatchingStmtLinesMsg)
            else
                Window.Open(ProgressBarMsg);

            repeat
                StartTime := CurrentDateTime();
                LineStartTime := StartTime;

                if not DisableCustomerLedgerEntriesMatch then
                    FindMatchingEntries(
                      BankAccReconciliationLine, TempCustomerLedgerEntryMatchingBuffer, TempBankStatementMatchingBuffer."Account Type"::Customer, SkipOtherEntries);

                TimeCustomerLedgerEntries := CurrentDateTime() - StartTime;
                TotalTimeMatchingCustomerLedgerEntriesPerLine += TimeCustomerLedgerEntries;

                StartTime := CurrentDateTime();
                if (not DisableVendorLedgerEntriesMatch) and (not SkipOtherEntries) then
                    FindMatchingEntries(
                      BankAccReconciliationLine, TempVendorLedgerEntryMatchingBuffer, TempBankStatementMatchingBuffer."Account Type"::Vendor, SkipOtherEntries);
                TimeVendorLedgerEntries := CurrentDateTime() - StartTime;
                TotalTimeMatchingVendorLedgerEntriesPerLine += TimeVendorLedgerEntries;

                StartTime := CurrentDateTime();
                if (not DisableEmployeeLedgerEntriesMatch) and (not SkipOtherEntries) then
                    FindMatchingEntries(
                      BankAccReconciliationLine, TempEmployeeLedgerEntryMatchingBuffer, TempBankStatementMatchingBuffer."Account Type"::Employee, SkipOtherEntries);
                TimeEmployeeLedgerEntries := CurrentDateTime() - StartTime;
                TotalTimeMatchingEmployeeLedgerEntriesPerLine += TimeEmployeeLedgerEntries;

                StartTime := CurrentDateTime();
                if (not DisableBankLedgerEntriesMatch) and (not SkipOtherEntries) then
                    FindMatchingEntries(
                      BankAccReconciliationLine,
                      TempBankAccLedgerEntryMatchingBuffer, TempBankStatementMatchingBuffer."Account Type"::"Bank Account", SkipOtherEntries);
                TimeBankLedgerEntries := CurrentDateTime() - StartTime;
                TotalTimeMatchingBankLedgerEntriesPerLine += TimeBankLedgerEntries;

                StartTime := CurrentDateTime();
                FindTextMappings(BankAccReconciliationLine);
                TimeTextMappings := CurrentDateTime() - StartTime;
                TotalTimeTimeTextMappingsPerLine += TimeTextMappings;
                OnMapLedgerEntriesToStatementLinesOnAfterCalcTotalTimeTimeTextMappingsPerLine(
                    BankAccReconciliationLine, TempBankStatementMatchingBuffer,
                    TotalTimeMatchingCustomerLedgerEntriesPerLine, TotalTimeMatchingVendorLedgerEntriesPerLine,
                    TotalTimeMatchingEmployeeLedgerEntriesPerLine, TotalTimeMatchingBankLedgerEntriesPerLine, RelatedPartyMatchedInfoText,
                    LogInfoText, TotalTimeStringNearness, UsePaymentDiscounts, TempOneToManyTempBankStatementMatchingBuffer,
                    TempCustomerLedgerEntryMatchingBuffer, TempVendorLedgerEntryMatchingBuffer,
                    TempEmployeeLedgerEntryMatchingBuffer, TempBankAccLedgerEntryMatchingBuffer);

                ProcessedLines += 1;
                Session.LogMessage('0000DK9', StrSubstNo(MatchedLineTelemetryTxt, BankAccReconciliationLine.SystemId, CurrentDateTime() - LineStartTime, TimeCustomerLedgerEntries, TimeVendorLedgerEntries, TimeEmployeeLedgerEntries, TimeBankLedgerEntries, TimeTextMappings), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PaymentRecPreformanceCategoryLbl);
                if ApplyEntries then begin
                    Window.Update(1, StrSubstNo(ProcessedStmtLinesMsg, ProcessedLines, TotalNoOfLines));
                    Window.Update(2, Round(ProcessedLines / TotalNoOfLines * 10000, 1));
                end;
            until BankAccReconciliationLine.Next() = 0;

            UpdateOneToManyMatches(BankAccReconciliationLine);

            Session.LogMessage('0000DKD', StrSubstNo(SpecificTaskSummaryTxt, TotalTimeDirectCollection, TotalTimeRelatedPartyMatching, TotalTimeDocumentNoMatching, TotalTimeAmountMatching, TotalTimeStringNearness, TotalTimeDocumentNoMatchingForBankLedgerEntry, TotalTimeSearchingDocumentNoInLedgerEntries, HitCountClosingDocumentMatches, TotalNoClosingDocumentMatches), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PaymentRecPreformanceCategoryLbl);

            Window.Close();
        end;
    end;

    local procedure RemoveAppliedEntriesFromBufferTables()
    begin
        RemoveAppliedEntriesFromTempLEMatchingBuffer(TempCustomerLedgerEntryMatchingBuffer);
        RemoveAppliedEntriesFromTempLEMatchingBuffer(TempVendorLedgerEntryMatchingBuffer);
        RemoveAppliedEntriesFromTempLEMatchingBuffer(TempBankAccLedgerEntryMatchingBuffer);
        RemoveAppliedEntriesFromTempLEMatchingBuffer(TempEmployeeLedgerEntryMatchingBuffer);
        RemoveAppliedEntriesFromDirectDebMatchingBuffer(TempDirectDebitCollectionBuffer);
    end;

    local procedure RemoveAppliedEntriesFromTempLEMatchingBuffer(var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        EntryNo: Integer;
    begin
        AppliedPaymentEntry.SetFilter("Match Confidence", '%1|%2', AppliedPaymentEntry."Match Confidence"::Accepted, AppliedPaymentEntry."Match Confidence"::Manual);
        if AppliedPaymentEntry.FindSet() then
            repeat
                EntryNo := AppliedPaymentEntry."Applies-to Entry No.";
                TempLedgerEntryMatchingBuffer.SetRange("Entry No.", EntryNo);
                TempLedgerEntryMatchingBuffer.DeleteAll();
            until AppliedPaymentEntry.Next() = 0
    end;

    local procedure RemoveAppliedEntriesFromDirectDebMatchingBuffer(var TempDirectDebitCollectionEntryBuffer: Record "Direct Debit Collection Buffer" temporary)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        EntryNo: Integer;
    begin
        AppliedPaymentEntry.SetFilter("Match Confidence", '%1|%2', AppliedPaymentEntry."Match Confidence"::Accepted, AppliedPaymentEntry."Match Confidence"::Manual);
        if AppliedPaymentEntry.FindSet() then
            repeat
                EntryNo := AppliedPaymentEntry."Applies-to Entry No.";
                TempDirectDebitCollectionEntryBuffer.SetRange("Entry No.", EntryNo);
                TempDirectDebitCollectionEntryBuffer.DeleteAll();
            until AppliedPaymentEntry.Next() = 0
    end;

    procedure RerunTextMapper(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        if BankAccReconciliationLine.IsEmpty() then
            exit;

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Payment Application");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        BankAccReconciliationLine.SetFilter("Match Confidence", '<>%1 & <>%2',
          BankAccReconciliationLine."Match Confidence"::Accepted, BankAccReconciliationLine."Match Confidence"::High);

        if BankAccReconciliationLine.FindSet() then begin
            repeat
                SetFilterToBankAccReconciliation(AppliedPaymentEntry, BankAccReconciliationLine);
                if FindTextMappings(BankAccReconciliationLine) then
                    BankAccReconciliationLine.RejectAppliedPayment();
            until BankAccReconciliationLine.Next() = 0;

            BankAccReconciliation.Get(
                BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
                BankAccReconciliationLine."Statement No.");
            CreateAppliedEntries(BankAccReconciliation);

            // Update match details for lines matched by text mapper
            BankAccReconciliationLine.SetRange(
              "Match Confidence", BankAccReconciliationLine."Match Confidence"::"High - Text-to-Account Mapping");
            UpdatePaymentMatchDetails(BankAccReconciliationLine);
        end;
    end;

    procedure TransferDiffToAccount(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        Score: Integer;
        Difference: Decimal;
        TransactionDate: Date;
        LineSplitMsg: Text;
        ParentLineNo: Integer;
        TransactionID: Text[50];
        DifferenceTransferred: Boolean;
        SuppressMessage: Boolean;
    begin
        if BankAccReconciliationLine.IsEmpty() or (BankAccReconciliationLine.Difference = 0) then
            exit;

        TempGenJournalLine.Amount := BankAccReconciliationLine.Difference;
        TempGenJournalLine.Description := BankAccReconciliationLine.Description;
        if not TempGenJournalLine.Insert() then
            TempGenJournalLine.Modify();

        RunTransferDifferencetoAccount(BankAccReconciliationLine, TempGenJournalLine, DifferenceTransferred);
        if DifferenceTransferred then begin
            if TempGenJournalLine."Account No." = '' then
                Error(MustChooseAccountErr);

            if BankAccReconciliationLine."Statement Amount" <> BankAccReconciliationLine.Difference then begin
                ParentLineNo := GetParentLineNo(BankAccReconciliationLine);
                Difference := BankAccReconciliationLine.Difference;
                LineSplitMsg := StrSubstNo(LineSplitTxt, Difference);
                TransactionDate := BankAccReconciliationLine."Transaction Date";
                TransactionID := BankAccReconciliationLine."Transaction ID";
                RevertAcceptedPmtToleranceFromAppliedEntries(BankAccReconciliationLine, Abs(Difference));
                BankAccReconciliationLine."Statement Amount" := BankAccReconciliationLine."Applied Amount";
                BankAccReconciliationLine.Difference := 0;
                BankAccReconciliationLine.Modify();

                BankAccReconciliationLine.Init();
                BankAccReconciliationLine."Statement Line No." := GetAvailableSplitLineNo(BankAccReconciliationLine, ParentLineNo);
                BankAccReconciliationLine."Parent Line No." := ParentLineNo;
                BankAccReconciliationLine.Description := TempGenJournalLine.Description;
                BankAccReconciliationLine."Transaction Text" := TempGenJournalLine.Description;
                BankAccReconciliationLine."Transaction Date" := TransactionDate;
                BankAccReconciliationLine."Statement Amount" := Difference;
                BankAccReconciliationLine."Transaction ID" := TransactionID;

                OnTransferDiffToAccountOnBeforeInsertBankAccReconciliationLine(BankAccReconciliationLine, TempGenJournalLine);

                BankAccReconciliationLine.Insert();
            end;

            BankAccReconciliation.Get(
              BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
              BankAccReconciliationLine."Statement No.");

            Score := TempBankPmtApplRule.GetTextMapperScore();
            TempBankStatementMatchingBuffer.AddMatchCandidate(
              BankAccReconciliationLine."Statement Line No.", -1,
              Score, TempGenJournalLine."Account Type", TempGenJournalLine."Account No.");
            CreateAppliedEntries(BankAccReconciliation);

            BankAccReconciliationLine.SetManualApplication();
            BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Payment Application");
            BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
            BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
            BankAccReconciliationLine.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
            UpdatePaymentMatchDetails(BankAccReconciliationLine);
            if LineSplitMsg <> '' then begin
                OnBeforeShowLineSplitMessage(BankAccReconciliationLine, SuppressMessage);
                if not SuppressMessage then
                    Message(LineSplitMsg);
            end;
        end;
    end;

    local procedure RunTransferDifferencetoAccount(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var DifferenceTransferred: Boolean)
    begin
        DifferenceTransferred := false;
        OnTransferDifference(BankAccReconciliationLine, TempGenJnlLine, DifferenceTransferred);
        if DifferenceTransferred then
            exit;

        if not GuiAllowed() then
            exit;

        DifferenceTransferred := Page.RunModal(Page::"Transfer Difference to Account", TempGenJnlLine) = Action::LookupOK;
    end;

    procedure MatchSingleLineCustomer(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliesToEntryNo: Integer; var NoOfLedgerEntriesWithinTolerance: Integer; var NoOfLedgerEntriesOutsideTolerance: Integer)
    var
        MinAmount: Decimal;
        MaxAmount: Decimal;
        AccountNo: Code[20];
    begin
        InitializeBankPmtApplSettings();

        ApplyEntries := false;
        InitializeCustomerLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempCustomerLedgerEntryMatchingBuffer);
        InitializeDirectDebitCollectionEntriesMatchingBuffer(TempDirectDebitCollectionBuffer);
        if TempCustomerLedgerEntryMatchingBuffer.Get(AppliesToEntryNo, TempCustomerLedgerEntryMatchingBuffer."Account Type"::Customer) then;

        FindMatchingEntry(
          TempCustomerLedgerEntryMatchingBuffer, BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::Customer,
          BankPmtApplRule);

        AccountNo := TempCustomerLedgerEntryMatchingBuffer."Account No.";
        BankAccReconciliationLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);
        TempCustomerLedgerEntryMatchingBuffer.Reset();
        TempCustomerLedgerEntryMatchingBuffer.SetRange("Account No.", AccountNo);
        NoOfLedgerEntriesWithinTolerance :=
          TempCustomerLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(
            MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
        NoOfLedgerEntriesOutsideTolerance :=
          TempCustomerLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesOutsideRange(
            MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
    end;

    procedure MatchSingleLineVendor(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliesToEntryNo: Integer; var NoOfLedgerEntriesWithinTolerance: Integer; var NoOfLedgerEntriesOutsideTolerance: Integer)
    var
        MinAmount: Decimal;
        MaxAmount: Decimal;
        AccountNo: Code[20];
    begin
        InitializeBankPmtApplSettings();

        ApplyEntries := false;
        InitializeVendorLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempVendorLedgerEntryMatchingBuffer);
        if not TempVendorLedgerEntryMatchingBuffer.Get(AppliesToEntryNo, TempVendorLedgerEntryMatchingBuffer."Account Type"::Vendor) then;

        FindMatchingEntry(
          TempVendorLedgerEntryMatchingBuffer, BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::Vendor,
          BankPmtApplRule);

        AccountNo := TempVendorLedgerEntryMatchingBuffer."Account No.";
        BankAccReconciliationLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);
        TempVendorLedgerEntryMatchingBuffer.Reset();
        TempVendorLedgerEntryMatchingBuffer.SetRange("Account No.", AccountNo);

        NoOfLedgerEntriesWithinTolerance :=
          TempVendorLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(
            MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
        NoOfLedgerEntriesOutsideTolerance :=
          TempVendorLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesOutsideRange(
            MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
    end;

    procedure MatchSingleLineEmployee(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliesToEntryNo: Integer; var NoOfLedgerEntriesWithinTolerance: Integer; var NoOfLedgerEntriesOutsideTolerance: Integer)
    var
        MinAmount: Decimal;
        MaxAmount: Decimal;
        AccountNo: Code[20];
    begin
        InitializeBankPmtApplSettings();

        ApplyEntries := false;
        InitializeEmployeeLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempEmployeeLedgerEntryMatchingBuffer);
        if not TempEmployeeLedgerEntryMatchingBuffer.Get(AppliesToEntryNo, TempEmployeeLedgerEntryMatchingBuffer."Account Type"::Employee) then;

        FindMatchingEntry(
          TempEmployeeLedgerEntryMatchingBuffer, BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::Employee,
          BankPmtApplRule);

        AccountNo := TempEmployeeLedgerEntryMatchingBuffer."Account No.";
        BankAccReconciliationLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);
        TempEmployeeLedgerEntryMatchingBuffer.Reset();
        TempEmployeeLedgerEntryMatchingBuffer.SetRange("Account No.", AccountNo);

        NoOfLedgerEntriesWithinTolerance :=
          TempEmployeeLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(
            MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
        NoOfLedgerEntriesOutsideTolerance :=
          TempEmployeeLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesOutsideRange(
            MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
    end;

    procedure MatchSingleLineBankAccountLedgerEntry(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliesToEntryNo: Integer; var NoOfLedgerEntriesWithinTolerance: Integer; var NoOfLedgerEntriesOutsideTolerance: Integer)
    var
        MinAmount: Decimal;
        MaxAmount: Decimal;
        AccountNo: Code[20];
    begin
        InitializeBankPmtApplSettings();

        ApplyEntries := false;
        InitializeBankAccLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempBankAccLedgerEntryMatchingBuffer);
        if not TempBankAccLedgerEntryMatchingBuffer.Get(AppliesToEntryNo, TempBankAccLedgerEntryMatchingBuffer."Account Type"::"Bank Account") then;

        FindMatchingEntry(
          TempBankAccLedgerEntryMatchingBuffer, BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type"::"Bank Account",
          BankPmtApplRule);

        AccountNo := TempBankAccLedgerEntryMatchingBuffer."Account No.";
        BankAccReconciliationLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);
        TempBankAccLedgerEntryMatchingBuffer.Reset();
        TempBankAccLedgerEntryMatchingBuffer.SetRange("Account No.", AccountNo);

        NoOfLedgerEntriesWithinTolerance :=
          TempBankAccLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(
            MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", false);
        NoOfLedgerEntriesOutsideTolerance :=
          TempBankAccLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesOutsideRange(
            MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", false);
    end;

    local procedure FindMatchingEntries(var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; AccountType: Enum "Gen. Journal Account Type"; var SkipOtherEntries: Boolean)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        InitializeBankPmtApplSettings();
        TempLedgerEntryMatchingBuffer.Reset();
        OnFindMatchingEntriesOnBeforeFindFirst(TempBankAccReconciliationLine, TempLedgerEntryMatchingBuffer, AccountType, SkipOtherEntries, ApplyEntries);
        if TempLedgerEntryMatchingBuffer.FindFirst() then
            repeat
                FindMatchingEntry(TempLedgerEntryMatchingBuffer, TempBankAccReconciliationLine, AccountType, BankPmtApplRule);

                if BankPmtApplSettings."Enable Apply Immediatelly" then
                    if BankPmtApplRule."Apply Immediatelly" then begin
                        SkipOtherEntries := true;
                        exit;
                    end;
            until TempLedgerEntryMatchingBuffer.Next() = 0;
    end;

    local procedure FindMatchingEntry(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type"; var BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    var
        Score: Integer;
        RemainingAmount: Decimal;
    begin
        if CanEntriesMatch(
             BankAccReconciliationLine, TempLedgerEntryMatchingBuffer."Remaining Amount", TempLedgerEntryMatchingBuffer."Posting Date")
        then begin
            MatchEntries(TempLedgerEntryMatchingBuffer, BankAccReconciliationLine, AccountType, BankPmtApplRule, RemainingAmount);
            Score := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);

            if Score >= MinimumMatchScore then
                TempBankStatementMatchingBuffer.AddMatchCandidate(
                  BankAccReconciliationLine."Statement Line No.", TempLedgerEntryMatchingBuffer."Entry No.",
                  Score, AccountType,
                  TempLedgerEntryMatchingBuffer."Account No.");

            if BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" = BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes then begin
                TempBankStatementMatchingBuffer.InsertOrUpdateOneToManyRule(
                  TempLedgerEntryMatchingBuffer,
                  BankAccReconciliationLine."Statement Line No.",
                  BankPmtApplRule."Related Party Matched", AccountType,
                  RemainingAmount);

                TempBankStmtMultipleMatchLine.InsertLine(
                  TempLedgerEntryMatchingBuffer,
                  BankAccReconciliationLine."Statement Line No.", AccountType);
            end;
        end;
    end;

    local procedure MatchEntries(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type"; var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; var RemainingAmount: Decimal)
    var
        IsHandled: Boolean;
        StartTime: DateTime;
    begin
        InitializeBankPmtApplSettings();

        if AccountType = TempBankStatementMatchingBuffer."Account Type"::Customer then
            DirectDebitCollectionMatching(BankPmtApplRule, BankAccReconciliationLine, TempLedgerEntryMatchingBuffer);

        StartTime := CurrentDateTime();
        RelatedPartyMatching(BankPmtApplRule, TempLedgerEntryMatchingBuffer, BankAccReconciliationLine, AccountType);
        TotalTimeRelatedPartyMatching += CurrentDateTime() - StartTime;

        IsHandled := false;
        OnFindMatchingEntryOnBeforeDocumentMatching(BankPmtApplRule, BankAccReconciliationLine, TempLedgerEntryMatchingBuffer, IsHandled, TempBankStatementMatchingBuffer, AccountType, TotalTimeDocumentNoMatching, TotalTimeDocumentNoMatchingForBankLedgerEntry, DocumentMatchedInfoText, LogInfoText);
        if not IsHandled then
            if AccountType <> TempBankStatementMatchingBuffer."Account Type"::"Bank Account" then begin
                StartTime := CurrentDateTime();
                DocumentMatching(
                    BankPmtApplRule, BankAccReconciliationLine,
                    TempLedgerEntryMatchingBuffer."Document No.",
                    TempLedgerEntryMatchingBuffer."External Document No.", '');
                TotalTimeDocumentNoMatching += CurrentDateTime() - StartTime;
            end else begin
                StartTime := CurrentDateTime();
                DocumentMatchingForBankLedgerEntry(BankPmtApplRule, BankAccReconciliationLine, TempLedgerEntryMatchingBuffer);
                TotalTimeDocumentNoMatchingForBankLedgerEntry += CurrentDateTime() - StartTime;
            end;

        IsHandled := false;
        OnMatchEntriesOnAfterCalcTotalTimeDocumentNoMatching(
            BankPmtApplRule, BankAccReconciliationLine, TempLedgerEntryMatchingBuffer,
            AccountType, TempBankStatementMatchingBuffer, TotalTimeRelatedPartyMatching,
            TotalTimeAmountMatching, RemainingAmount, RelatedPartyMatchedInfoText,
            LogInfoText, TotalTimeStringNearness, UsePaymentDiscounts, TempOneToManyTempBankStatementMatchingBuffer,
            TempCustomerLedgerEntryMatchingBuffer, TempVendorLedgerEntryMatchingBuffer,
            TempEmployeeLedgerEntryMatchingBuffer, TempBankAccLedgerEntryMatchingBuffer, IsHandled, DocumentMatchedInfoText);
        if not IsHandled then begin
            StartTime := CurrentDateTime();
            RemainingAmount := CalcRemainingAmount(TempLedgerEntryMatchingBuffer, BankAccReconciliationLine);

            AmountInclToleranceMatching(
              BankPmtApplRule, BankAccReconciliationLine, AccountType, RemainingAmount);
            TotalTimeAmountMatching += CurrentDateTime() - StartTime;
        end;
    end;

    local procedure CalcRemainingAmount(var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line") RemainingAmount: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRemainingAmount(TempLedgerEntryMatchingBuffer, BankAccReconciliationLine, UsePaymentDiscounts, RemainingAmount, IsHandled);
        if IsHandled then
            exit(RemainingAmount);

        RemainingAmount := TempLedgerEntryMatchingBuffer.GetApplicableRemainingAmount(BankAccReconciliationLine, UsePaymentDiscounts);
    end;

    procedure InitializeCustomerLedgerEntriesMatchingBuffer(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    begin
        InitializeCustomerLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempLedgerEntryMatchingBuffer, false);
    end;

    procedure InitializeCustomerLedgerEntriesMatchingBuffer(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; ApplyEntries: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        BankAccount.Get(BankAccReconciliationLine."Bank Account No.");
        SalesReceivablesSetup.Get();

        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetFilter("Document Type", '%1|%2|%3|%4|%5',
          CustLedgerEntry."Document Type"::" ",
          CustLedgerEntry."Document Type"::Invoice,
          CustLedgerEntry."Document Type"::"Credit Memo",
          CustLedgerEntry."Document Type"::"Finance Charge Memo",
          CustLedgerEntry."Document Type"::Reminder);

        if ApplyEntries then
            CustLedgerEntry.SetRange("Applies-to ID", '');

        OnInitCustomerLedgerEntriesMatchingBufferSetFilter(CustLedgerEntry, BankAccReconciliationLine);

        if BankAccount.IsInLocalCurrency() then begin
            CustLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)");
            if SalesReceivablesSetup."Appln. between Currencies" = SalesReceivablesSetup."Appln. between Currencies"::None then begin
                GeneralLedgerSetup.Get();
                CustLedgerEntry.SetFilter("Currency Code", '=%1|=%2', '', GeneralLedgerSetup.GetCurrencyCode(''));
            end;
        end else begin
            CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
            CustLedgerEntry.SetRange("Currency Code", BankAccount."Currency Code");
        end;

        OnInitCustomerLedgerEntriesMatchingBufferOnBeforeCustLedgerEntryFindSet(CustLedgerEntry);
        if CustLedgerEntry.FindSet() then
            repeat
                TempLedgerEntryMatchingBuffer.InsertFromCustomerLedgerEntry(
                  CustLedgerEntry, BankAccount.IsInLocalCurrency(), UsePaymentDiscounts);
            until CustLedgerEntry.Next() = 0;
    end;

    procedure InitializeVendorLedgerEntriesMatchingBuffer(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    begin
        InitializeVendorLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempLedgerEntryMatchingBuffer, false);
    end;

    procedure InitializeVendorLedgerEntriesMatchingBuffer(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; ApplyEntries: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        BankAccount.Get(BankAccReconciliationLine."Bank Account No.");
        PurchasesPayablesSetup.Get();

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetFilter("Document Type", '%1|%2|%3|%4|%5',
          VendorLedgerEntry."Document Type"::" ",
          VendorLedgerEntry."Document Type"::Invoice,
          VendorLedgerEntry."Document Type"::"Credit Memo",
          VendorLedgerEntry."Document Type"::"Finance Charge Memo",
          VendorLedgerEntry."Document Type"::Reminder);

        if ApplyEntries then
            VendorLedgerEntry.SetRange("Applies-to ID", '');

        OnInitVendorLedgerEntriesMatchingBufferSetFilter(VendorLedgerEntry, BankAccReconciliationLine);

        if BankAccount.IsInLocalCurrency() then begin
            VendorLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)");
            if PurchasesPayablesSetup."Appln. between Currencies" = PurchasesPayablesSetup."Appln. between Currencies"::None then begin
                GeneralLedgerSetup.Get();
                VendorLedgerEntry.SetFilter("Currency Code", '=%1|=%2', '', GeneralLedgerSetup.GetCurrencyCode(''));
            end;
        end else begin
            VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
            VendorLedgerEntry.SetRange("Currency Code", BankAccount."Currency Code");
        end;

        OnInitVendorLedgerEntriesMatchingBufferOnAfterVendorLedgerEntryFindSet(VendorLedgerEntry);
        if VendorLedgerEntry.FindSet() then
            repeat
                TempLedgerEntryMatchingBuffer.InsertFromVendorLedgerEntry(
                  VendorLedgerEntry, BankAccount.IsInLocalCurrency(), UsePaymentDiscounts);

            until VendorLedgerEntry.Next() = 0;
    end;

    procedure InitializeEmployeeLedgerEntriesMatchingBuffer(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    begin
        InitializeEmployeeLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempLedgerEntryMatchingBuffer, false);
    end;

    procedure InitializeEmployeeLedgerEntriesMatchingBuffer(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; ApplyEntries: Boolean)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        BankAccount.Get(BankAccReconciliationLine."Bank Account No.");

        EmployeeLedgerEntry.SetRange(Open, true);
        EmployeeLedgerEntry.SetRange("Document Type", EmployeeLedgerEntry."Document Type"::" ");

        if ApplyEntries then
            EmployeeLedgerEntry.SetRange("Applies-to ID", '');

        OnInitEmployeeLedgerEntriesMatchingBufferSetFilter(EmployeeLedgerEntry, BankAccReconciliationLine);

        if not BankAccount.IsInLocalCurrency() then begin
            EmployeeLedgerEntry.SetAutoCalcFields("Remaining Amount");
            EmployeeLedgerEntry.SetRange("Currency Code", BankAccount."Currency Code");
        end else
            EmployeeLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)");

        OnInitEmployeeLedgerEntriesMatchingBufferOnAfterEmployeeLedgerEntryFindSet(EmployeeLedgerEntry);
        if EmployeeLedgerEntry.FindSet() then
            repeat
                TempLedgerEntryMatchingBuffer.InsertFromEmployeeLedgerEntry(EmployeeLedgerEntry, BankAccount.IsInLocalCurrency());
            until EmployeeLedgerEntry.Next() = 0;
    end;

    procedure InitializeBankAccLedgerEntriesMatchingBuffer(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    begin
        InitializeBankAccLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempLedgerEntryMatchingBuffer, false);
    end;

    procedure InitializeBankAccLedgerEntriesMatchingBuffer(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; SkipReversed: Boolean)
    var
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        BankAccount.Get(BankAccReconciliationLine."Bank Account No.");
        PurchasesPayablesSetup.Get();

        BankAccLedgerEntry.SetRange(Open, true);
        BankAccLedgerEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        if SkipReversed then
            BankAccLedgerEntry.SetRange(Reversed, false);

        OnInitBankAccLedgerEntriesMatchingBufferSetFilter(BankAccLedgerEntry, BankAccReconciliationLine);

        if BankAccount.IsInLocalCurrency() then
            if PurchasesPayablesSetup."Appln. between Currencies" = PurchasesPayablesSetup."Appln. between Currencies"::None then begin
                GeneralLedgerSetup.Get();
                BankAccLedgerEntry.SetFilter("Currency Code", '=%1|=%2', '', GeneralLedgerSetup.GetCurrencyCode(''));
            end else
                BankAccLedgerEntry.SetRange("Currency Code", BankAccount."Currency Code");

        if BankAccLedgerEntry.FindSet() then
            repeat
                TempLedgerEntryMatchingBuffer.InsertFromBankAccLedgerEntry(BankAccLedgerEntry);
            until BankAccLedgerEntry.Next() = 0;
    end;

    procedure InitializeDirectDebitCollectionEntriesMatchingBuffer(var TempDirectDebitCollectionEntryBuffer: Record "Direct Debit Collection Buffer" temporary)
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        if DirectDebitCollectionEntry.FindSet() then
            repeat
                TempDirectDebitCollectionEntryBuffer.TransferFields(DirectDebitCollectionEntry);
                TempDirectDebitCollectionEntryBuffer.Insert();
            until DirectDebitCollectionEntry.Next() = 0;
    end;

    procedure FindApplicableTextMappings(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempTextToAccMapping: Record "Text-to-Account Mapping" temporary): Boolean
    begin
        exit(FindTextMappings(BankAccReconciliationLine, TempTextToAccMapping, true));
    end;

    local procedure FindTextMappings(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Boolean
    var
        TempTextToAccMapping: Record "Text-to-Account Mapping" temporary;
    begin
        exit(FindTextMappings(BankAccReconciliationLine, TempTextToAccMapping, false));
    end;

    local procedure SubstringMatchPercentage(ToMatchString: Text; OtherString: Text; var LongestCommonSubstringLength: Integer): Integer;
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        CommonSubstring: Text;
        MinLength: Integer;
    begin
        CommonSubstring := RecordMatchMgt.GetLongestCommonSubstring(ToMatchString, OtherString);
        LongestCommonSubstringLength := StrLen(CommonSubstring);
        MinLength := (StrLen(ToMatchString) + StrLen(OtherString) - Abs(StrLen(ToMatchString) - StrLen(OtherString))) / 2;
        if (MinLength = 0) or (LongestCommonSubstringLength < StrLen(ToMatchString)) then
            exit(0);
        exit(GetNormalizingFactor() * LongestCommonSubstringLength div MinLength);
    end;

    local procedure FindTextMappings(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempTextToAccMapping: Record "Text-to-Account Mapping" temporary; TrackApplicableRules: Boolean): Boolean
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        Nearness, LongestCommonSubstringLength : Integer;
        Score: Integer;
        AccountType: Enum "Gen. Journal Account Type";
        AccountNo: Code[20];
        EntryNo: Integer;
        TextMapperMatched: Boolean;
    begin
        TextMapperMatched := false;
        if TextToAccMapping.FindSet() then
            repeat
                Nearness := 0;
                OnFindTextMappingsOnBeforeCalculateStringNearness(BankAccReconciliationLine, TextToAccMapping, Nearness);
                if Nearness = 0 then
                    Nearness := SubstringMatchPercentage(RecordMatchMgt.Trim(TextToAccMapping."Mapping Text"), BankAccReconciliationLine."Transaction Text", LongestCommonSubstringLength);

                case TextToAccMapping."Bal. Source Type" of
                    TextToAccMapping."Bal. Source Type"::"G/L Account":
                        if BankAccReconciliationLine."Statement Amount" >= 0 then
                            AccountNo := TextToAccMapping."Debit Acc. No."
                        else
                            AccountNo := TextToAccMapping."Credit Acc. No.";
                    else // Customer or Vendor
                        AccountNo := TextToAccMapping."Bal. Source No.";
                end;

                if Nearness >= GetExactMatchTreshold() then begin
                    Score := TempBankPmtApplRule.GetTextMapperScore(LongestCommonSubstringLength, LowerCase(BankAccReconciliationLine."Transaction Text").Contains(LowerCase(RecordMatchMgt.Trim(TextToAccMapping."Mapping Text"))));
                    // Customers could post the expense via Journal. In this case there is a risk that we will create double entries.
                    // We will seach for existing bank ledger entries with similar text in the similar range and mapp to that
                    if FindBankAccLedgerEntry(BankAccLedgerEntry, BankAccReconciliationLine, TextToAccMapping, AccountNo) then begin
                        EntryNo := BankAccLedgerEntry."Entry No.";
                        AccountType := TempBankStatementMatchingBuffer."Account Type"::"Bank Account";
                        AccountNo := BankAccLedgerEntry."Bank Account No.";
                    end else begin
                        EntryNo := -TextToAccMapping."Line No."; // mark negative to identify text-mapper
                        AccountType := Enum::"Gen. Journal Account Type".FromInteger(TextToAccMapping."Bal. Source Type");
                    end;

                    TextMapperMatched := true;

                    TempBankStatementMatchingBuffer.AddMatchCandidate(
                        BankAccReconciliationLine."Statement Line No.", EntryNo,
                        Score, AccountType, AccountNo);

                    OnFindTextMappingsOnAfterTextMapperMatched(BankAccReconciliationLine, TextToAccMapping, TempBankStatementMatchingBuffer);

                    if (TrackApplicableRules) then begin
                        TempTextToAccMapping.TransferFields(TextToAccMapping, true);
                        TempTextToAccMapping.Insert();
                    end;
                end;
            until TextToAccMapping.Next() = 0;
        exit(TextMapperMatched)
    end;

    local procedure FindBankAccLedgerEntry(var BankAccLedgerEntry: Record "Bank Account Ledger Entry"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TextToAccountMapping: Record "Text-to-Account Mapping"; BalAccountNo: Code[20]): Boolean
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        Nearness: Integer;
        Found: Boolean;
        Handled: Boolean;
    begin
        OnFindBankAccLedgerEntryForTextToAccountMapping(Handled, Found, BankAccLedgerEntry, BankAccReconciliationLine, TextToAccountMapping, BalAccountNo);

        if Handled then
            exit(Found);

        BankAccLedgerEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        BankAccLedgerEntry.SetRange(Open, true);
        BankAccLedgerEntry.SetRange("Bal. Account Type", TextToAccountMapping."Bal. Source Type");
        BankAccLedgerEntry.SetRange("Bal. Account No.", BalAccountNo);
        BankAccLedgerEntry.SetRange("Remaining Amount", BankAccReconciliationLine."Statement Amount");

        if BankAccReconciliationLine."Transaction Date" = 0D then
            exit(false);

        BankAccLedgerEntry.SetFilter("Posting Date", '>=%1&<=%2', CalcDate('<-2D>', BankAccReconciliationLine."Transaction Date"), CalcDate('<+2D>', BankAccReconciliationLine."Transaction Date"));

        if not BankAccLedgerEntry.FindSet() then
            exit(false);

        repeat
            Nearness := RecordMatchMgt.CalculateStringNearness(RecordMatchMgt.Trim(TextToAccountMapping."Mapping Text"), BankAccLedgerEntry.Description, StrLen(BankAccLedgerEntry.Description), GetNormalizingFactor());
            if Nearness >= GetExactMatchTreshold() then
                exit(true);
        until BankAccLedgerEntry.Next() = 0;
        exit(false);
    end;

    local procedure CreateAppliedEntries(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetCurrentKey(Quality, "No. of Entries");
        TempBankStatementMatchingBuffer.Ascending(false);

        TempBankStmtMultipleMatchLine.SetCurrentKey("Due Date");

        OnCreateAppliedEntriesOnBeforeTempBankStatementMatchingBufferFindset(BankAccReconciliation, TempBankStatementMatchingBuffer, TempBankStmtMultipleMatchLine);
        if TempBankStatementMatchingBuffer.FindSet() then
            repeat
                BankAccReconciliationLine.Get(
                  BankAccReconciliation."Statement Type", BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.",
                  TempBankStatementMatchingBuffer."Line No.");

                if not StatementLineAlreadyApplied(TempBankStatementMatchingBuffer, BankAccReconciliationLine) then begin
                    PrepareLedgerEntryForApplication(BankAccReconciliationLine);
                    ApplyRecords(BankAccReconciliationLine, TempBankStatementMatchingBuffer);
                end;
            until TempBankStatementMatchingBuffer.Next() = 0;
    end;

    local procedure ApplyRecords(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Boolean
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        if TempBankStatementMatchingBuffer.Quality = 0 then
            exit(false);

        if TempBankStatementMatchingBuffer."One to Many Match" then
            ApplyOneToMany(BankAccReconciliationLine, TempBankStatementMatchingBuffer)
        else begin
            if EntryAlreadyApplied(TempBankStatementMatchingBuffer, BankAccReconciliationLine, TempBankStatementMatchingBuffer."Entry No.")
            then
                if not CanApplyManyToOne(TempBankStatementMatchingBuffer, BankAccReconciliationLine) then
                    exit(false);

            AppliedPaymentEntry.ApplyFromBankStmtMatchingBuf(BankAccReconciliationLine, TempBankStatementMatchingBuffer,
              BankAccReconciliationLine."Statement Amount", TempBankStatementMatchingBuffer."Entry No.");
        end;

        Session.LogMessage('0000DKA', StrSubstNo(AppliedEntriesToBankStatementLineTxt, BankAccReconciliationLine.SystemId, TempBankStatementMatchingBuffer."Account Type", TempBankStatementMatchingBuffer."One to Many Match", TempBankStatementMatchingBuffer.Quality), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PaymentRecPreformanceCategoryLbl);

        OnApplyRecordsOnAfterSendTraceTag(BankAccReconciliationLine, TempBankStatementMatchingBuffer);

        exit(true);
    end;

    local procedure ApplyOneToMany(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        TempBankStmtMultipleMatchLine.SetRange("Line No.", TempBankStatementMatchingBuffer."Line No.");
        TempBankStmtMultipleMatchLine.SetRange("Account Type", TempBankStatementMatchingBuffer."Account Type");
        TempBankStmtMultipleMatchLine.SetRange("Account No.", TempBankStatementMatchingBuffer."Account No.");
        TempBankStmtMultipleMatchLine.FindSet();

        repeat
            AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconciliationLine);
            if AppliedPaymentEntry.GetStmtLineRemAmtToApply() = 0 then
                PaymentMatchingDetails.CreatePaymentMatchingDetail(BankAccReconciliationLine,
                  StrSubstNo(CannotApplyDocumentNoOneToManyApplicationTxt, TempBankStmtMultipleMatchLine."Document No."))
            else begin
                Clear(AppliedPaymentEntry);
                if not EntryAlreadyApplied(
                     TempBankStatementMatchingBuffer, BankAccReconciliationLine, TempBankStmtMultipleMatchLine."Entry No.")
                then
                    AppliedPaymentEntry.ApplyFromBankStmtMatchingBuf(BankAccReconciliationLine, TempBankStatementMatchingBuffer,
                      BankAccReconciliationLine."Statement Amount", TempBankStmtMultipleMatchLine."Entry No.")
            end;
        until TempBankStmtMultipleMatchLine.Next() = 0;
    end;

    local procedure CanEntriesMatch(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Amount: Decimal; EntryPostingDate: Date) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanEntriesMatch(BankAccReconciliationLine, Amount, EntryPostingDate, ApplyEntries, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not ApplyEntries then
            exit(true);

        if BankAccReconciliationLine."Statement Amount" * Amount < 0 then
            exit(false);

        if ApplyEntries then
            if BankAccReconciliationLine."Transaction Date" < EntryPostingDate then
                exit(false);

        exit(true);
    end;

    local procedure CanApplyManyToOne(TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary): Boolean
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        HasPositiveApplications: Boolean;
        HasNegativeApplications: Boolean;
    begin
        // Many to one application is possbile if previous applied are for same Account
        SetFilterToRelatedApplications(AppliedPaymentEntry, TempBankStatementMatchingBuffer,
          TempBankAccReconciliationLine);
        if AppliedPaymentEntry.IsEmpty() then
            exit(false);

        // Not possible if positive and negative applications already exists
        AppliedPaymentEntry.SetFilter("Applied Amount", '>0');
        HasPositiveApplications := not AppliedPaymentEntry.IsEmpty();
        AppliedPaymentEntry.SetFilter("Applied Amount", '<0');
        HasNegativeApplications := not AppliedPaymentEntry.IsEmpty();
        if HasPositiveApplications and HasNegativeApplications then
            exit(false);

        // Remaining amount should not be 0
        exit(GetRemainingAmount(TempBankStatementMatchingBuffer, TempBankAccReconciliationLine) <> 0);
    end;

    local procedure RelatedPartyMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type")
    begin
        case AccountType of
            TempBankStatementMatchingBuffer."Account Type"::Customer:
                CustomerMatching(BankPmtApplRule, TempLedgerEntryMatchingBuffer."Account No.", BankAccReconciliationLine, AccountType);
            TempBankStatementMatchingBuffer."Account Type"::Vendor:
                VendorMatching(BankPmtApplRule, TempLedgerEntryMatchingBuffer."Account No.", BankAccReconciliationLine, AccountType);
            TempBankStatementMatchingBuffer."Account Type"::Employee:
                EmployeeMatching(BankPmtApplRule, TempLedgerEntryMatchingBuffer."Account No.", BankAccReconciliationLine, AccountType);
            TempBankStatementMatchingBuffer."Account Type"::"Bank Account":
                RelatedPartyMatchingForBankAccLedgEntry(BankPmtApplRule, TempLedgerEntryMatchingBuffer, BankAccReconciliationLine, AccountType);
        end;
    end;

    local procedure CustomerMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; AccountNo: Code[20]; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type")
    var
        Customer: Record Customer;
    begin
        if IsCustomerBankAccountMatching(
             BankAccReconciliationLine."Related-Party Bank Acc. No.", AccountNo, BankAccReconciliationLine."Bank Account No.")
        then begin
            BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Fully;
            AppendText(RelatedPartyMatchedInfoText, MatchedRelatedPartyOnBankAccountMsg);
            exit;
        end;

        if not Customer.Get(AccountNo) then begin
            BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::No;
            SendMissingRelatedPartyTelemetry(TempBankStatementMatchingBuffer."Account Type"::Customer);
            exit;
        end;

        RelatedPartyInfoMatching(
          BankPmtApplRule, BankAccReconciliationLine, Customer.Name, Customer.Address, Customer.City, AccountType);
    end;

    local procedure VendorMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; AccountNo: Code[20]; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type")
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(AccountNo) then begin
            BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::No;
            SendMissingRelatedPartyTelemetry(TempBankStatementMatchingBuffer."Account Type"::Vendor);
            exit;
        end;

        if IsVendorBankAccountMatching(BankAccReconciliationLine."Related-Party Bank Acc. No.", Vendor."No.", BankAccReconciliationLine."Bank Account No.") then begin
            BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Fully;
            AppendText(RelatedPartyMatchedInfoText, MatchedRelatedPartyOnBankAccountMsg);
            exit;
        end;

        RelatedPartyInfoMatching(
          BankPmtApplRule, BankAccReconciliationLine, Vendor.Name, Vendor.Address, Vendor.City, AccountType);
    end;

    local procedure EmployeeMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; AccountNo: Code[20]; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type")
    var
        Employee: Record Employee;
    begin
        if not Employee.Get(AccountNo) then begin
            BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::No;
            SendMissingRelatedPartyTelemetry(TempBankStatementMatchingBuffer."Account Type"::Employee);
            exit;
        end;

        if IsEmployeeBankAccountMatching(BankAccReconciliationLine."Related-Party Bank Acc. No.", Employee) then begin
            BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Fully;
            AppendText(RelatedPartyMatchedInfoText, MatchedRelatedPartyOnBankAccountMsg);
            exit;
        end;

        RelatedPartyInfoMatching(
          BankPmtApplRule, BankAccReconciliationLine, Employee.FullName(), Employee.Address, Employee.City, AccountType);
    end;

    local procedure RelatedPartyMatchingForBankAccLedgEntry(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type")
    begin
        case TempLedgerEntryMatchingBuffer."Bal. Account Type" of
            TempLedgerEntryMatchingBuffer."Bal. Account Type"::Customer:
                CustomerMatching(BankPmtApplRule, TempLedgerEntryMatchingBuffer."Bal. Account No.", BankAccReconciliationLine, AccountType);
            TempLedgerEntryMatchingBuffer."Bal. Account Type"::Vendor:
                VendorMatching(BankPmtApplRule, TempLedgerEntryMatchingBuffer."Bal. Account No.", BankAccReconciliationLine, AccountType);
            TempLedgerEntryMatchingBuffer."Bal. Account Type"::"Bank Account",
          TempLedgerEntryMatchingBuffer."Bal. Account Type"::"G/L Account":
                BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::No;
        end;
    end;

    local procedure RelatedPartyInfoMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Name: Text[100]; Address: Text[100]; City: Text[30]; AccountType: Enum "Gen. Journal Account Type")
    var
        Handled: Boolean;
    begin
        OnRelatedPartyInfoMatching(BankPmtApplRule, BankAccReconciliationLine, Name, Address, City, AccountType, RelatedPartyMatchedInfoText, Handled);
        if Handled then
            exit;

        InitializeBankPmtApplSettings();
        BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::No;

        // If Strutured text present don't look at unstructured text
        if BankAccReconciliationLine."Related-Party Name" <> '' then begin
            // Use string nearness as names can be reversed, wrongly capitalized, etc
            IsNameMatching(BankAccReconciliationLine."Related-Party Name", Name, BankPmtApplRule, BankAccReconciliationLine);
            if BankPmtApplRule."Related Party Matched" = BankPmtApplRule."Related Party Matched"::Partially then begin

                // City and address should fully match
                if (BankAccReconciliationLine."Related-Party City" = City) and
                   (BankAccReconciliationLine."Related-Party Address" = Address) and (City <> '') and (Address <> '')
                then begin
                    BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Fully;
                    AppendText(RelatedPartyMatchedInfoText, StrSubstNo(MatchedRelatedPartyOnBankStatementInfoMsg, StrSubstNo(RelatedPartyMatchInfoPlaceholderLbl, BankAccReconciliationLine.FieldName(BankAccReconciliationLine."Related-Party Name"), BankAccReconciliationLine.FieldName(BankAccReconciliationLine."Related-Party City"), BankAccReconciliationLine.FieldName(BankAccReconciliationLine."Related-Party Address"))));
                    exit;
                end;

                if IsNameUnique(Name, AccountType) then begin
                    BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Fully;
                    AppendText(RelatedPartyMatchedInfoText, RelatedPartyNameIsUniqueMsg);
                    exit;
                end;
            end;

            exit;
        end;

        // Unstructured text is using string nearness since user may shorten the name or mistype
        IsNameMatching(BankAccReconciliationLine."Transaction Text", Name, BankPmtApplRule, BankAccReconciliationLine);

        if BankPmtApplRule."Related Party Matched" = BankPmtApplRule."Related Party Matched"::Partially then
            if IsNameUnique(Name, AccountType) then begin
                BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Fully;
                AppendText(RelatedPartyMatchedInfoText, RelatedPartyNameIsUniqueMsg);
                exit;
            end;
    end;

    local procedure SendMissingRelatedPartyTelemetry(GenJournalAccountType: Enum "Gen. Journal Account Type")
    begin
        if MissingDataTypeTelemetrySent.Contains(GenJournalAccountType.AsInteger()) then
            exit;

        Session.LogMessage('0000FT3', StrSubstNo(MissingRelatedPartyTelemetryMsg, GenJournalAccountType), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
        MissingDataTypeTelemetrySent.Add(GenJournalAccountType.AsInteger());
    end;

    local procedure DocumentMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DocNo: Code[20]; ExtDocNo: Code[35]; PaymentReference: Code[50])
    var
        SearchText: Text;
    begin
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No;

        if (PaymentReference <> '') and (BankAccReconciliationLine."Payment Reference No." = PaymentReference) then begin
            BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes;
            AppendText(DocumentMatchedInfoText, DocumentNumberMatchedByPaymentReferenceMsg);
            exit;
        end;

        SearchText := UpperCase(BankAccReconciliationLine."Transaction Text" + ' ' +
            BankAccReconciliationLine."Additional Transaction Info");

        if DocNoMatching(SearchText, DocNo) then begin
            BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes;
            AppendText(DocumentMatchedInfoText, DocumentNumberMatchedInTransactionTextMsg);
            exit;
        end;

        if DocNoMatching(SearchText, ExtDocNo) then begin
            BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes;
            AppendText(DocumentMatchedInfoText, ExternalDocumentNumberMatchedInTransactionTextMsg);
        end;
    end;

    procedure DocumentMatchingForBankLedgerEntry(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    var
        SearchText: Text;
        ClosingEntriesDocumentNumbers: List of [Code[35]];
        DisableMatch: Boolean;
    begin
        InitializeBankPmtApplSettings();
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No;

        SearchText := UpperCase(BankAccReconciliationLine."Transaction Text" + ' ' +
            BankAccReconciliationLine."Additional Transaction Info");

        if DocNoMatching(SearchText, TempLedgerEntryMatchingBuffer."Document No.") then begin
            BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes;
            exit;
        end;

        if DocNoMatching(SearchText, TempLedgerEntryMatchingBuffer."External Document No.") then begin
            BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes;
            exit;
        end;

        OnDocumentMatchingForBankLedgerEntryOnBeforeMatch(SearchText, TempLedgerEntryMatchingBuffer, BankPmtApplRule);
        if BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" = BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes then
            exit;

        if not BankPmtApplSettings."Bank Ledg Closing Doc No Match" then
            exit;

        OnDisableMatchBankLedgerEntriesFromClosingLedgerEntries(DisableMatch);
        if DisableMatch then
            exit;

        if not BankLedgerEntriesClosingDocumentNumbers.Get(TempLedgerEntryMatchingBuffer."Entry No.", ClosingEntriesDocumentNumbers) then
            PopulateClosingNumberDictionary(ClosingEntriesDocumentNumbers, TempLedgerEntryMatchingBuffer);

        if ClosingEntriesDocumentNumbers.Count() = 0 then
            exit;

        if ClosingDocumentMatching(SearchText, ClosingEntriesDocumentNumbers) then
            BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes;
    end;

    local procedure PopulateClosingNumberDictionary(var ClosingEntriesDocumentNumbers: List of [Code[35]]; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        StartTime: DateTime;
    begin
        StartTime := CurrentDateTime();
        BankLedgerEntriesClosingDocumentNumbers.Add(TempLedgerEntryMatchingBuffer."Entry No.", ClosingEntriesDocumentNumbers);

        CustLedgerEntry.SetCurrentKey("Document No.");
        CustLedgerEntry.SetRange("Document No.", TempLedgerEntryMatchingBuffer."Document No.");
        CustLedgerEntry.SetRange("Document Type", TempLedgerEntryMatchingBuffer."Document Type");
        CustLedgerEntry.SetRange("Posting Date", TempLedgerEntryMatchingBuffer."Posting Date");
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry2.SetRange(Open, false);
                CustLedgerEntry2.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
                if CustLedgerEntry2.FindFirst() then
                    ClosingEntriesDocumentNumbers.Add(CustLedgerEntry2."Document No.");
            until CustLedgerEntry.Next() = 0;

        VendLedgerEntry.SetCurrentKey("Document No.");
        VendLedgerEntry.SetRange("Document No.", TempLedgerEntryMatchingBuffer."Document No.");
        VendLedgerEntry.SetRange("Document Type", TempLedgerEntryMatchingBuffer."Document Type");
        VendLedgerEntry.SetRange("Posting Date", TempLedgerEntryMatchingBuffer."Posting Date");
        if VendLedgerEntry.FindSet() then
            repeat
                VendLedgerEntry2.SetRange(Open, false);
                VendLedgerEntry2.SetRange("Closed by Entry No.", VendLedgerEntry."Entry No.");
                if VendLedgerEntry2.FindFirst() then
                    ClosingEntriesDocumentNumbers.Add(VendLedgerEntry2."Document No.");
            until VendLedgerEntry.Next() = 0;

        TotalTimeSearchingDocumentNoInLedgerEntries += CurrentDateTime() - StartTime;
    end;

    local procedure ClosingDocumentMatching(SearchText: Text; var ClosingDocumentNumbers: List of [Code[35]]): Boolean
    var
        I: Integer;
    begin
        TotalNoClosingDocumentMatches += 1;
        for I := 1 to ClosingDocumentNumbers.Count() do
            if (DocNoMatching(SearchText, ClosingDocumentNumbers.Get(I))) then begin
                HitCountClosingDocumentMatches += 1;
                exit(true);
            end;

        exit(false);
    end;

    procedure DocNoMatching(SearchText: Text; DocNo: Code[35]): Boolean
    var
        Position: Integer;
    begin
        if StrLen(DocNo) < GetMatchLengthTreshold() then
            exit(false);

        Position := StrPos(SearchText, DocNo);

        case Position of
            0:
                exit(false);
            1:
                begin
                    if StrLen(SearchText) = StrLen(DocNo) then
                        exit(true);

                    exit(not IsAlphanumeric(SearchText[Position + StrLen(DocNo)]));
                end;
            else begin
                if StrLen(SearchText) < Position + StrLen(DocNo) then
                    exit(not IsAlphanumeric(SearchText[Position - 1]));

                exit((not IsAlphanumeric(SearchText[Position - 1])) and
                  (not IsAlphanumeric(SearchText[Position + StrLen(DocNo)])));
            end;
        end;

        exit(true);
    end;

    local procedure AmountInclToleranceMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type"; RemainingAmount: Decimal)
    var
        NoOfEntries: Integer;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        BankAccReconciliationLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);
        BankPmtApplRule."Amount Incl. Tolerance Matched" := BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches";

        if (RemainingAmount < MinAmount) or
           (RemainingAmount > MaxAmount)
        then
            exit;

        NoOfEntries := 0;
        BankPmtApplRule."Amount Incl. Tolerance Matched" := BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches";

        // Check for Multiple Hits for One To Many  matches
        if BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" =
           BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple"
        then begin
            TempOneToManyTempBankStatementMatchingBuffer.SetFilter("Total Remaining Amount", '>=%1&<=%2', MinAmount, MaxAmount);
            NoOfEntries += TempOneToManyTempBankStatementMatchingBuffer.Count();

            if NoOfEntries > 1 then
                exit;
        end;

        // Check is a single match for One to One Matches
        case AccountType of
            TempBankStatementMatchingBuffer."Account Type"::Customer:
                NoOfEntries +=
                  TempCustomerLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(
                    MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
            TempBankStatementMatchingBuffer."Account Type"::Vendor:
                NoOfEntries +=
                  TempVendorLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(
                    MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
            TempBankStatementMatchingBuffer."Account Type"::Employee:
                NoOfEntries +=
                  TempEmployeeLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(
                    MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", UsePaymentDiscounts);
            TempBankStatementMatchingBuffer."Account Type"::"Bank Account":
                NoOfEntries +=
                  TempBankAccLedgerEntryMatchingBuffer.GetNoOfLedgerEntriesWithinRange(
                    MinAmount, MaxAmount, BankAccReconciliationLine."Transaction Date", false);
        end;

        if NoOfEntries = 1 then
            BankPmtApplRule."Amount Incl. Tolerance Matched" := BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match"
    end;

    local procedure DirectDebitCollectionMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        StartTime: DateTime;
    begin
        StartTime := CurrentDateTime;
        BankPmtApplRule."Direct Debit Collect. Matched" := BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered";

        if (BankAccReconciliationLine."Transaction ID" = '') or
           (StrLen(BankAccReconciliationLine."Transaction ID") > MaxStrLen(TempDirectDebitCollectionBuffer."Transaction ID"))
        then
            exit;

        TempDirectDebitCollectionBuffer.Reset();
        TempDirectDebitCollectionBuffer.SetRange("Transaction ID", BankAccReconciliationLine."Transaction ID");
        TempDirectDebitCollectionBuffer.SetFilter(Status, '%1|%2',
          TempDirectDebitCollectionBuffer.Status::"File Created", TempDirectDebitCollectionBuffer.Status::Posted);

        if TempDirectDebitCollectionBuffer.IsEmpty() then
            exit;

        BankPmtApplRule."Direct Debit Collect. Matched" := BankPmtApplRule."Direct Debit Collect. Matched"::No;

        TempDirectDebitCollectionBuffer.SetRange("Applies-to Entry No.", TempLedgerEntryMatchingBuffer."Entry No.");
        if TempDirectDebitCollectionBuffer.FindFirst() then
            if DirectDebitCollection.Get(TempDirectDebitCollectionBuffer."Direct Debit Collection No.") then
                if (DirectDebitCollection.Status in
                    [DirectDebitCollection.Status::"File Created",
                     DirectDebitCollection.Status::Posted,
                     DirectDebitCollection.Status::Closed])
                then
                    BankPmtApplRule."Direct Debit Collect. Matched" := BankPmtApplRule."Direct Debit Collect. Matched"::Yes;
        TotalTimeDirectCollection += CurrentDateTime() - StartTime;
    end;

    local procedure IsNameMatching(Description: Text; CustVendValue: Text; var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Integer
    var
        STRNameNearness: Integer;
    begin
        InitializeBankPmtApplSettings();
        case BankPmtApplSettings."RelatedParty Name Matching" of
            BankPmtApplSettings."RelatedParty Name Matching"::Disabled:
                begin
                    BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::No;
                    exit;
                end;
            BankPmtApplSettings."RelatedParty Name Matching"::"String Nearness":
                begin
                    STRNameNearness := GetStringNearness(Description, CustVendValue);
                    if STRNameNearness >= GetExactMatchTreshold() then begin
                        BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Partially;
                        if STRNameNearness < 100 then
                            AppendText(RelatedPartyMatchedInfoText, StrSubstNo(TextPartialMatchMsg, BankAccReconciliationLine.FieldName("Related-Party Name"), STRNameNearness));
                    end;
                    exit;
                end;
            BankPmtApplSettings."RelatedParty Name Matching"::"Exact Match with Permutations":
                begin
                    IsNameMatchingWithPermutations(Description, CustVendValue, BankPmtApplRule);
                    exit;
                end;
        end;
    end;

    local procedure IsNameMatchingWithPermutations(Description: Text; CustVendValue: Text; var BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    var
        SwappedFirstAndLastName: Text;
        FirstName: text;
        PositionOfFirstSpace: Integer;
    begin
        if StrLen(Description) < StrLen(CustVendValue) then
            exit;

        BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::No;
        if Description.Contains(CustVendValue) then begin
            BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Partially;
            exit;
        end;

        // To simplify the algorith for matching we will just put the first name to the end
        // This works optimal for First Name / Last Name and few other cultures
        PositionOfFirstSpace := CustVendValue.IndexOf(' ');
        if PositionOfFirstSpace <= 0 then
            exit;

        FirstName := CustVendValue.Substring(1, PositionOfFirstSpace - 1);
        SwappedFirstAndLastName += CustVendValue.Substring(PositionOfFirstSpace + 1, StrLen(CustVendValue) - PositionOfFirstSpace) + ' ' + FirstName;

        if Description.Contains(SwappedFirstAndLastName) then begin
            BankPmtApplRule."Related Party Matched" := BankPmtApplRule."Related Party Matched"::Partially;
            exit;
        end;
    end;

    local procedure GetStringNearness(Description: Text; CustVendValue: Text): Integer
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        StartTime: DateTime;
        Nearness: Integer;
        Disable: Boolean;
    begin
        if StrLen(Description) < (StrLen(CustVendValue) * GetCloseMatchTreshold() / GetNormalizingFactor()) then
            exit(0);

        Description := RecordMatchMgt.Trim(Description);

        OnDisableStringNearnessMatch(Disable);
        if Disable then
            exit(0);

        StartTime := CurrentDateTime();
        Nearness := RecordMatchMgt.CalculateStringNearness(CustVendValue, Description, GetMatchLengthTreshold(), GetNormalizingFactor());
        TotalTimeStringNearness += CurrentDateTime() - StartTime;
        exit(Nearness);
    end;

    local procedure IsCustomerBankAccountMatching(ValueFromBankStatement: Text; CustomerNo: Code[20]; BankAccountNo: Code[20]) Result: Boolean
    var
        CustomerBankAccount: Record "Customer Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsCustomerBankAccountMatching(ValueFromBankStatement, CustomerNo, BankAccountNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ValueFromBankStatement := BankAccountNoWithoutSpecialChars(ValueFromBankStatement);
        if ValueFromBankStatement = '' then
            exit(false);

        CustomerBankAccount.SetRange("Customer No.", CustomerNo);
        if CustomerBankAccount.FindSet() then
            repeat
                if BankAccountNoWithoutSpecialChars(CustomerBankAccount.GetBankAccountNo()) = ValueFromBankStatement then
                    exit(true);
            until CustomerBankAccount.Next() = 0;

        exit(false);
    end;

    local procedure IsVendorBankAccountMatching(ValueFromBankStatement: Text; VendorNo: Code[20]; BankAccountNo: Code[20]) Result: Boolean
    var
        VendorBankAccount: Record "Vendor Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsVendorBankAccountMatching(ValueFromBankStatement, VendorNo, BankAccountNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ValueFromBankStatement := BankAccountNoWithoutSpecialChars(ValueFromBankStatement);
        if ValueFromBankStatement = '' then
            exit(false);

        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        if VendorBankAccount.FindSet() then
            repeat
                if BankAccountNoWithoutSpecialChars(VendorBankAccount.GetBankAccountNo()) = ValueFromBankStatement then
                    exit(true);
            until VendorBankAccount.Next() = 0;

        exit(false);
    end;

    local procedure IsEmployeeBankAccountMatching(ValueFromBankStatement: Text; Employee: Record Employee): Boolean
    begin
        ValueFromBankStatement := BankAccountNoWithoutSpecialChars(ValueFromBankStatement);
        if ValueFromBankStatement = '' then
            exit(false);

        if Employee."Bank Account No." <> '' then
            if BankAccountNoWithoutSpecialChars(Employee."Bank Account No.") = ValueFromBankStatement then
                exit(true);

        exit(false);
    end;

    local procedure BankAccountNoWithoutSpecialChars(Input: Text): Text
    begin
        exit(UpperCase(DelChr(Input, '=', DelChr(UpperCase(Input), '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'))));
    end;

    local procedure StatementLineAlreadyApplied(TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary): Boolean
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        SetFilterToBankAccReconciliation(AppliedPaymentEntry, TempBankAccReconciliationLine);
        AppliedPaymentEntry.SetRange("Statement Line No.", TempBankStatementMatchingBuffer."Line No.");

        exit(not AppliedPaymentEntry.IsEmpty);
    end;

    local procedure EntryAlreadyApplied(TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; EntryNo: Integer): Boolean
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        SetFilterToBankAccReconciliation(AppliedPaymentEntry, TempBankAccReconciliationLine);
        AppliedPaymentEntry.SetRange("Account Type", TempBankStatementMatchingBuffer."Account Type");
        AppliedPaymentEntry.SetRange("Applies-to Entry No.", EntryNo);

        exit(not AppliedPaymentEntry.IsEmpty);
    end;

    local procedure SetFilterToBankAccReconciliation(var AppliedPaymentEntry: Record "Applied Payment Entry"; TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary)
    begin
        AppliedPaymentEntry.FilterAppliedPmtEntry(TempBankAccReconciliationLine);
        AppliedPaymentEntry.SetRange("Statement Line No.");
    end;

    local procedure SetFilterToRelatedApplications(var AppliedPaymentEntry: Record "Applied Payment Entry"; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary)
    begin
        SetFilterToBankAccReconciliation(AppliedPaymentEntry, TempBankAccReconciliationLine);
        AppliedPaymentEntry.SetRange("Account Type", TempBankStatementMatchingBuffer."Account Type");
        AppliedPaymentEntry.SetRange("Account No.", TempBankStatementMatchingBuffer."Account No.");
        AppliedPaymentEntry.SetRange("Applies-to Entry No.", TempBankStatementMatchingBuffer."Entry No.");
    end;

    local procedure GetRemainingAmount(TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary): Decimal
    var
        TempAppliedPaymentEntry: Record "Applied Payment Entry" temporary;
    begin
        TempAppliedPaymentEntry.TransferFromBankAccReconLine(TempBankAccReconciliationLine);
        TempAppliedPaymentEntry."Account Type" := TempBankStatementMatchingBuffer."Account Type";
        TempAppliedPaymentEntry."Account No." := TempBankStatementMatchingBuffer."Account No.";
        TempAppliedPaymentEntry."Applies-to Entry No." := TempBankStatementMatchingBuffer."Entry No.";

        exit(TempAppliedPaymentEntry.GetRemAmt() - TempAppliedPaymentEntry.GetAmtAppliedToOtherStmtLines());
    end;

    local procedure ShowMatchSummary(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        MatchedCount: Integer;
        TotalCount: Integer;
        TextMatchCount: Integer;
        FinalText: Text;
        IsHandled: Boolean;
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Payment Application");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        TotalCount := BankAccReconciliationLine.Count();

        BankAccReconciliationLine.SetFilter("Applied Entries", '>0');
        MatchedCount := BankAccReconciliationLine.Count();

        FinalText := StrSubstNo(MatchSummaryMsg, MatchedCount, TotalCount);
        IsHandled := false;
        OnShowMatchSummaryOnAfterSetFinalText(BankAccReconciliation, FinalText, IsHandled);
        if not IsHandled then
            Message(FinalText);

        BankAccReconciliationLine.SetRange("Match Confidence", BankAccReconciliationLine."Match Confidence"::"High - Text-to-Account Mapping");
        TextMatchCount := BankAccReconciliationLine.Count();

        Session.LogMessage('0000AIA', StrSubstNo(BankAccountRecTotalAndMatchedLinesLbl, TotalCount, MatchedCount, TextMatchCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
    end;

    local procedure UpdateOneToManyMatches(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        RemoveInvalidOneToManyMatches();
        GetOneToManyMatches();
        ScoreOneToManyMatches(BankAccReconciliationLine);
    end;

    local procedure ScoreOneToManyMatches(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Score: Integer;
    begin
        if TempBankStatementMatchingBuffer.FindSet() then
            repeat
                BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple";
                BankPmtApplRule."Related Party Matched" := TempBankStatementMatchingBuffer."Related Party Matched";
                BankAccReconciliationLine.Get(
                  BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
                  BankAccReconciliationLine."Statement No.", TempBankStatementMatchingBuffer."Line No.");
                AmountInclToleranceMatching(
                  BankPmtApplRule, BankAccReconciliationLine, TempBankStatementMatchingBuffer."Account Type",
                  TempBankStatementMatchingBuffer."Total Remaining Amount");

                Score := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
                TempBankStatementMatchingBuffer.Quality := Score;
                TempBankStatementMatchingBuffer.Modify();
            until TempBankStatementMatchingBuffer.Next() = 0;

        TempBankStatementMatchingBuffer.Reset();
    end;

    local procedure RemoveInvalidOneToManyMatches()
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("One to Many Match", true);
        TempBankStatementMatchingBuffer.SetFilter("No. of Entries", '=1');
        TempBankStatementMatchingBuffer.DeleteAll(true);
        TempBankStatementMatchingBuffer.Reset();
    end;

    local procedure GetOneToManyMatches()
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("One to Many Match", true);
        TempBankStatementMatchingBuffer.SetFilter("No. of Entries", '>1');

        if TempBankStatementMatchingBuffer.FindSet() then
            repeat
                TempOneToManyTempBankStatementMatchingBuffer := TempBankStatementMatchingBuffer;
                TempOneToManyTempBankStatementMatchingBuffer.Insert(true);
            until TempBankStatementMatchingBuffer.Next() = 0;
    end;

    procedure GetExactMatchTreshold(): Decimal
    begin
        exit(0.95 * GetNormalizingFactor());
    end;

    procedure GetCloseMatchTreshold(): Decimal
    begin
        exit(0.65 * GetNormalizingFactor());
    end;

    local procedure GetMatchLengthTreshold(): Decimal
    begin
        exit(4);
    end;

    procedure GetNormalizingFactor(): Decimal
    begin
        exit(100);
    end;

    local procedure GetLowestMatchScore(): Integer
    var
        Score: Integer;
    begin
        if not ApplyEntries then
            exit(0);

        TempBankPmtApplRule.SetFilter("Match Confidence", '<>%1', TempBankPmtApplRule."Match Confidence"::None);
        TempBankPmtApplRule.SetCurrentKey(Score);
        TempBankPmtApplRule.Ascending(false);
        Score := 0;
        if TempBankPmtApplRule.FindLast() then
            Score := TempBankPmtApplRule.Score;

        TempBankPmtApplRule.Reset();
        exit(Score);
    end;

    local procedure IsNameUnique(Name: Text[100]; AccountType: Enum "Gen. Journal Account Type"): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case AccountType of
            TempBankStatementMatchingBuffer."Account Type"::Customer:
                begin
                    Customer.SetFilter(Name, '%1', '@*' + Name + '*');
                    exit(Customer.Count = 1);
                end;
            TempBankStatementMatchingBuffer."Account Type"::Vendor:
                begin
                    Vendor.SetFilter(Name, '%1', '@*' + Name + '*');
                    exit(Vendor.Count = 1);
                end;
        end;
    end;

    local procedure IsAlphanumeric(Character: Char): Boolean
    begin
        exit((Character in ['0' .. '9']) or (Character in ['A' .. 'Z']) or (Character in ['a' .. 'z']));
    end;

    procedure GetBankStatementMatchingBuffer(var TempBankStatementMatchingBuffer2: Record "Bank Statement Matching Buffer" temporary)
    begin
        TempBankStatementMatchingBuffer2.Copy(TempBankStatementMatchingBuffer, true);
        TempBankStatementMatchingBuffer2.Reset();
    end;

    procedure GetLedgerEntriesAsMatchingBuffer(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
    begin
        BankPmtApplSettings.GetOrInsert();
        if not BankPmtApplSettings."Cust Ledg Hidden In Apply Man" then
            GetCustomerLedgerEntriesAsMatchingBuffer(TempBankStatementMatchingBuffer, BankAccReconciliationLine);
        if not BankPmtApplSettings."Vend Ledg Hidden In Apply Man" then
            GetVendorLedgerEntriesAsMatchingBuffer(TempBankStatementMatchingBuffer, BankAccReconciliationLine);
        if not BankPmtApplSettings."Empl Ledg Hidden In Apply Man" then
            GetEmployeeLedgerEntriesAsMatchingBuffer(TempBankStatementMatchingBuffer, BankAccReconciliationLine);
        if not BankPmtApplSettings."Bank Ledg Hidden In Apply Man" then
            GetBankLedgerEntriesAsMatchingBuffer(TempBankStatementMatchingBuffer, BankAccReconciliationLine);
    end;

    procedure GetCustomerLedgerEntriesAsMatchingBuffer(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        InitializeCustomerLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempCustomerLedgerEntryMatchingBuffer);
        TempCustomerLedgerEntryMatchingBuffer.Reset();
        if TempCustomerLedgerEntryMatchingBuffer.FindSet() then
            repeat
                TempBankStatementMatchingBuffer.AddMatchCandidate(
                    BankAccReconciliationLine."Statement Line No.", TempCustomerLedgerEntryMatchingBuffer."Entry No.",
                    0, GenJournalAccountType::Customer, TempCustomerLedgerEntryMatchingBuffer."Account No.");
            until TempCustomerLedgerEntryMatchingBuffer.Next() = 0;
    end;

    procedure GetVendorLedgerEntriesAsMatchingBuffer(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        InitializeVendorLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempVendorLedgerEntryMatchingBuffer);
        TempVendorLedgerEntryMatchingBuffer.Reset();
        if TempVendorLedgerEntryMatchingBuffer.FindSet() then
            repeat
                TempBankStatementMatchingBuffer.AddMatchCandidate(
                    BankAccReconciliationLine."Statement Line No.", TempVendorLedgerEntryMatchingBuffer."Entry No.",
                    0, GenJournalAccountType::Vendor, TempVendorLedgerEntryMatchingBuffer."Account No.");
            until TempVendorLedgerEntryMatchingBuffer.Next() = 0;
    end;

    procedure GetEmployeeLedgerEntriesAsMatchingBuffer(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        InitializeEmployeeLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempEmployeeLedgerEntryMatchingBuffer);
        TempEmployeeLedgerEntryMatchingBuffer.Reset();
        if TempEmployeeLedgerEntryMatchingBuffer.FindSet() then
            repeat
                TempBankStatementMatchingBuffer.AddMatchCandidate(
                    BankAccReconciliationLine."Statement Line No.", TempEmployeeLedgerEntryMatchingBuffer."Entry No.",
                    0, GenJournalAccountType::Employee, TempEmployeeLedgerEntryMatchingBuffer."Account No.");
            until TempEmployeeLedgerEntryMatchingBuffer.Next() = 0;
    end;

    procedure GetBankLedgerEntriesAsMatchingBuffer(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        InitializeBankAccLedgerEntriesMatchingBuffer(BankAccReconciliationLine, TempBankAccLedgerEntryMatchingBuffer);
        TempBankAccLedgerEntryMatchingBuffer.Reset();
        if TempBankAccLedgerEntryMatchingBuffer.FindSet() then
            repeat
                TempBankStatementMatchingBuffer.AddMatchCandidate(
                    BankAccReconciliationLine."Statement Line No.", TempBankAccLedgerEntryMatchingBuffer."Entry No.",
                    0, GenJournalAccountType::"Bank Account", TempBankAccLedgerEntryMatchingBuffer."Account No.");
            until TempBankAccLedgerEntryMatchingBuffer.Next() = 0;
    end;

    local procedure UpdatePaymentMatchDetails(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine2.CopyFilters(BankAccReconciliationLine);
        OnUpdatePaymentMatchDetailsOnAfterBankAccReconciliationLine2SetFilters(BankAccReconciliationLine2, BankAccReconciliationLine);

        if BankAccReconciliationLine2.FindSet() then
            repeat
                BankAccReconciliationLine2.CalcFields("Match Confidence", "Match Quality");
                AddWarningsForTextMapperOverriden(BankAccReconciliationLine2);
                AddWarningsForStatementCanBeAppliedToMultipleEntries(BankAccReconciliationLine2);
                AddWarningsForMultipleStatementLinesCouldBeAppliedToEntry(BankAccReconciliationLine2);
            until BankAccReconciliationLine2.Next() = 0;
    end;

    local procedure DeletePaymentMatchDetails(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        OnDeletePaymentMatchDetailsOnAfterPaymentMatchingDetailsSetFilters(PaymentMatchingDetails, BankAccReconciliation);
        PaymentMatchingDetails.DeleteAll(true);
    end;

    local procedure DeleteAppliedPaymentEntries(BankAccReconciliation: Record "Bank Acc. Reconciliation"; Overwrite: Boolean)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if not Overwrite then
            AppliedPaymentEntry.SetFilter("Match Confidence", '<>%1&<>%2', AppliedPaymentEntry."Match Confidence"::Accepted, AppliedPaymentEntry."Match Confidence"::Manual);
        OnDeleteAppliedPaymentEntriesOnAfterAppliedPaymentEntrySetFilters(AppliedPaymentEntry, BankAccReconciliation);
        AppliedPaymentEntry.DeleteAll(true);
    end;

    local procedure AddWarningsForTextMapperOverriden(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        if BankAccReconciliationLine."Match Quality" <= BankPmtApplRule.GetTextMapperScore() then
            exit;

        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Line No.", BankAccReconciliationLine."Statement Line No.");
        TempBankStatementMatchingBuffer.SetRange(Quality, BankPmtApplRule.GetTextMapperScore());

        if TempBankStatementMatchingBuffer.Count > 0 then
            PaymentMatchingDetails.CreatePaymentMatchingDetail(BankAccReconciliationLine,
              StrSubstNo(TextMapperRulesOverridenTxt, TempBankStatementMatchingBuffer.Count,
                BankAccReconciliationLine."Match Confidence"));
    end;

    local procedure AddWarningsForStatementCanBeAppliedToMultipleEntries(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        MinRangeValue: Integer;
        MaxRangeValue: Integer;
    begin
        if BankAccReconciliationLine."Match Confidence" = BankAccReconciliationLine."Match Confidence"::None then
            exit;

        if BankAccReconciliationLine."Match Quality" = BankPmtApplRule.GetTextMapperScore() then
            exit;

        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Line No.", BankAccReconciliationLine."Statement Line No.");

        MinRangeValue := BankPmtApplRule.GetLowestScoreInRange(BankAccReconciliationLine."Match Quality");
        MaxRangeValue := BankPmtApplRule.GetHighestScoreInRange(BankAccReconciliationLine."Match Quality");
        TempBankStatementMatchingBuffer.SetRange(Quality, MinRangeValue, MaxRangeValue);

        if TempBankStatementMatchingBuffer.Count > 1 then
            PaymentMatchingDetails.CreatePaymentMatchingDetail(BankAccReconciliationLine,
              StrSubstNo(MultipleEntriesWithSilarConfidenceFoundTxt, TempBankStatementMatchingBuffer.Count));
    end;

    local procedure AddWarningsForMultipleStatementLinesCouldBeAppliedToEntry(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        EntryNo: Integer;
        MinRangeValue: Integer;
        MaxRangeValue: Integer;
    begin
        if BankAccReconciliationLine."Match Confidence" = BankAccReconciliationLine."Match Confidence"::None then
            exit;

        if BankAccReconciliationLine."Match Quality" = BankPmtApplRule.GetTextMapperScore() then
            exit;

        TempBankStatementMatchingBuffer.Reset();

        // Get Entry No.
        TempBankStatementMatchingBuffer.SetRange("Line No.", BankAccReconciliationLine."Statement Line No.");
        TempBankStatementMatchingBuffer.SetRange(Quality, BankAccReconciliationLine."Match Quality");
        TempBankStatementMatchingBuffer.FindFirst();
        EntryNo := TempBankStatementMatchingBuffer."Entry No.";

        MinRangeValue := BankPmtApplRule.GetLowestScoreInRange(BankAccReconciliationLine."Match Quality");
        MaxRangeValue := BankPmtApplRule.GetHighestScoreInRange(BankAccReconciliationLine."Match Quality");

        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetRange("Entry No.", EntryNo);
        TempBankStatementMatchingBuffer.SetRange(Quality, MinRangeValue, MaxRangeValue);
        TempBankStatementMatchingBuffer.SetFilter("Line No.", '<>%1', BankAccReconciliationLine."Statement Line No.");
        if TempBankStatementMatchingBuffer.Count > 1 then
            PaymentMatchingDetails.CreatePaymentMatchingDetail(BankAccReconciliationLine,
              StrSubstNo(MultipleStatementLinesWithSameConfidenceFoundTxt, TempBankStatementMatchingBuffer.Count));
    end;

    local procedure AppendText(var MainText: Text; TextToAppend: Text)
    begin
        if not LogInfoText then
            exit;

        if (MainText <> '') then
            MainText += GetNewLineText() + GetNewLineText();

        MainText += TextToAppend;
    end;

    procedure SetApplyEntries(NewApplyEntries: Boolean)
    begin
        ApplyEntries := NewApplyEntries;
    end;

    local procedure GetAvailableSplitLineNo(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; ParentLineNo: Integer): Integer
    var
        SplitLineNo: Integer;
    begin
        SplitLineNo := BankAccReconciliationLine."Statement Line No." + 1;
        BankAccReconciliationLine.SetRange("Parent Line No.", ParentLineNo);
        if BankAccReconciliationLine.FindLast() then
            SplitLineNo := BankAccReconciliationLine."Statement Line No." + 1;
        exit(SplitLineNo)
    end;

    local procedure GetParentLineNo(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Integer
    begin
        if BankAccReconciliationLine."Parent Line No." <> 0 then
            exit(BankAccReconciliationLine."Parent Line No.");
        exit(BankAccReconciliationLine."Statement Line No.");
    end;

    local procedure PrepareLedgerEntryForApplication(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        if TempBankStatementMatchingBuffer."Entry No." <= 0 then // text mapping has "Entry No." = -10000
            exit;

        SetApplicationDataInCVLedgEntry(
          TempBankStatementMatchingBuffer."Account Type", TempBankStatementMatchingBuffer."Entry No.",
          BankAccReconciliationLine.GetAppliesToID());
    end;

    procedure SetApplicationDataInCVLedgEntry(AccountType: Enum "Gen. Journal Account Type"; EntryNo: Integer;
                                                               AppliesToID: Code[50])
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        if EntryNo = 0 then
            exit;

        case AccountType of
            BankAccReconLine."Account Type"::Customer:
                SetCustAppicationData(EntryNo, AppliesToID);
            BankAccReconLine."Account Type"::Vendor:
                SetVendAppicationData(EntryNo, AppliesToID);
            BankAccReconLine."Account Type"::Employee:
                SetEmployeeAppicationData(EntryNo, AppliesToID);
        end;
    end;

    local procedure SetCustAppicationData(EntryNo: Integer; AppliesToID: Code[50])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(EntryNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        CustLedgEntry."Applies-to ID" := AppliesToID;
        CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
        OnSetCustAppicationDataOnBeforeCustEntryEdit(CustLedgEntry);
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
    end;

    local procedure SetVendAppicationData(EntryNo: Integer; AppliesToID: Code[50])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get(EntryNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        VendLedgEntry."Applies-to ID" := AppliesToID;
        VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
        OnSetVendAppicationDataOnBeforeVendEntryEdit(VendLedgEntry);
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
    end;

    local procedure SetEmployeeAppicationData(EntryNo: Integer; AppliesToID: Code[50])
    var
        EmployeeLedgEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgEntry.Get(EntryNo);
        EmployeeLedgEntry.CalcFields("Remaining Amount");
        EmployeeLedgEntry."Applies-to ID" := AppliesToID;
        EmployeeLedgEntry."Amount to Apply" := EmployeeLedgEntry."Remaining Amount";
        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmployeeLedgEntry);
    end;

    local procedure GetNewLineText(): Text
    var
        NewLine: array[2] of Char;
    begin
        NewLine[1] := 10;
        NewLine[2] := 13;
        exit(StrSubstNo(NewLinePlaceHolderLbl, NewLine[1], NewLine[2]));
    end;

    local procedure RevertAcceptedPmtToleranceFromAppliedEntries(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Difference: Decimal)
    var
        AppliedPmtEntry: Record "Applied Payment Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if Difference = 0 then
            exit;

        AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconciliationLine);
        AppliedPmtEntry.SetFilter("Applies-to Entry No.", '<>%1', 0);
        if not AppliedPmtEntry.FindSet() then
            exit;

        repeat
            case AppliedPmtEntry."Account Type" of
                AppliedPmtEntry."Account Type"::Customer:
                    begin
                        CustLedgerEntry.Get(AppliedPmtEntry."Applies-to Entry No.");
                        if CustLedgerEntry."Accepted Payment Tolerance" <> 0 then begin
                            if -CustLedgerEntry."Accepted Payment Tolerance" > Difference then begin
                                CustLedgerEntry."Accepted Payment Tolerance" += Difference;
                                Difference := 0;
                            end else begin
                                Difference += CustLedgerEntry."Accepted Payment Tolerance";
                                CustLedgerEntry."Accepted Payment Tolerance" := 0;
                            end;
                            CustLedgerEntry.Modify();
                        end;
                    end;
                AppliedPmtEntry."Account Type"::Vendor:
                    begin
                        VendorLedgerEntry.Get(AppliedPmtEntry."Applies-to Entry No.");
                        if VendorLedgerEntry."Accepted Payment Tolerance" <> 0 then begin
                            if VendorLedgerEntry."Accepted Payment Tolerance" > Difference then begin
                                VendorLedgerEntry."Accepted Payment Tolerance" -= Difference;
                                Difference := 0;
                            end else begin
                                Difference -= VendorLedgerEntry."Accepted Payment Tolerance";
                                VendorLedgerEntry."Accepted Payment Tolerance" := 0;
                            end;
                            VendorLedgerEntry.Modify();
                        end;
                    end;
            end;
        until (AppliedPmtEntry.Next() = 0) or (Difference = 0);
    end;

    local procedure InitializeBankPmtApplSettings()
    begin
        if BankPmtApplSettingsInitialized then
            exit;

        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettingsInitialized := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRemainingAmount(var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; UsePaymentDiscounts: Boolean; var RemainingAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCustomerBankAccountMatching(ValueFromBankStatement: Text; CustomerNo: Code[20]; BankAccountNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeNotifyIfEntriesMatchedElsewhere(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVendorBankAccountMatching(ValueFromBankStatement: Text; VendorNo: Code[20]; BankAccountNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDocumentMatchingForBankLedgerEntryOnBeforeMatch(SearchText: Text; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingEntryOnBeforeDocumentMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var IsHandled: Boolean; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer"; AccountType: Enum "Gen. Journal Account Type"; var TotalTimeDocumentNoMatching: Duration; var TotalTimeDocumentNoMatchingForBankLedgerEntry: Duration; var DocumentMatchedInfoText: Text; LogInfoText: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingEntriesOnBeforeFindFirst(var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; var TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; AccountType: Enum "Gen. Journal Account Type"; var SkipOtherEntries: Boolean; var ApplyEntries: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTextMappingsOnBeforeCalculateStringNearness(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TextToAccountMapping: Record "Text-to-Account Mapping"; var Nearness: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitBankAccLedgerEntriesMatchingBufferSetFilter(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitCustomerLedgerEntriesMatchingBufferSetFilter(var CustLedgerEntry: Record "Cust. Ledger Entry"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitCustomerLedgerEntriesMatchingBufferOnBeforeCustLedgerEntryFindSet(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitEmployeeLedgerEntriesMatchingBufferSetFilter(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVendorLedgerEntriesMatchingBufferSetFilter(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitEmployeeLedgerEntriesMatchingBufferOnAfterEmployeeLedgerEntryFindSet(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVendorLedgerEntriesMatchingBufferOnAfterVendorLedgerEntryFindSet(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowMatchSummaryOnAfterSetFinalText(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; FinalText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletePaymentMatchDetailsOnAfterPaymentMatchingDetailsSetFilters(var PaymentMatchingDetails: Record "Payment Matching Details"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAppliedPaymentEntriesOnAfterAppliedPaymentEntrySetFilters(var AppliedPaymentEntry: Record "Applied Payment Entry"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableMatchBankLedgerEntriesFromClosingLedgerEntries(var Disable: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableStringNearnessMatch(var Disable: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableCustomerLedgerEntriesMatch(var Disable: boolean; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableVendorLedgerEntriesMatch(var Disable: boolean; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableEmployeeLedgerEntriesMatch(var Disable: boolean; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableBankLedgerEntriesMatch(var Disable: boolean; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchEntriesOnAfterCalcTotalTimeDocumentNoMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; AccountType: Enum "Gen. Journal Account Type"; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TotalTimeRelatedPartyMatching: Duration; var TotalTimeAmountMatching: Duration; var RemainingAmount: Decimal; var RelatedPartyMatchedInfoText: Text; LogInfoText: Boolean; var TotalTimeStringNearness: Duration; UsePaymentDiscounts: Boolean; OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempCustomerLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var TempVendorLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var TempEmployeeLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var TempBankAccLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var IsHandled: Boolean; var DocumentMatchedInfoText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRelatedPartyInfoMatching(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Name: Text[100]; Address: Text[100]; City: Text[30]; AccountType: Enum "Gen. Journal Account Type"; var RelatedPartyMatchedInfoText: Text; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBankAccLedgerEntryForTextToAccountMapping(var Handled: Boolean; var Found: Boolean; var BankAccLedgerEntry: Record "Bank Account Ledger Entry"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TextToAccountMapping: Record "Text-to-Account Mapping"; BalAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePaymentMatchDetailsOnAfterBankAccReconciliationLine2SetFilters(var BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAppliedEntriesOnBeforeTempBankStatementMatchingBufferFindset(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempBankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanEntriesMatch(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Amount: Decimal; EntryPostingDate: Date; ApplyEntries: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyLedgerEntriesToStatementLinesOnAfterUpdatePaymentMatchDetails(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Overwrite: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMapLedgerEntriesToStatementLinesOnAfterCalcTotalTimeTimeTextMappingsPerLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TotalTimeMatchingCustomerLedgerEntriesPerLine: Duration; var TotalTimeMatchingVendorLedgerEntriesPerLine: Duration; var TotalTimeMatchingEmployeeLedgerEntriesPerLine: Duration; var TotalTimeMatchingBankLedgerEntriesPerLine: Duration; var RelatedPartyMatchedInfoText: Text; LogInfoText: Boolean; var TotalTimeStringNearness: Duration; UsePaymentDiscounts: Boolean; OneToManyTempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempCustomerLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var TempVendorLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var TempEmployeeLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var TempBankAccLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferDiffToAccountOnBeforeInsertBankAccReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyRecordsOnAfterSendTraceTag(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTextMappingsOnAfterTextMapperMatched(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TextToAccountMapping: Record "Text-to-Account Mapping"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetCustAppicationDataOnBeforeCustEntryEdit(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferDifference(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var DifferenceTransferred: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetVendAppicationDataOnBeforeVendEntryEdit(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowLineSplitMessage(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var SuppressMessage: Boolean)
    begin
    end;
}
#pragma warning restore AA0198
