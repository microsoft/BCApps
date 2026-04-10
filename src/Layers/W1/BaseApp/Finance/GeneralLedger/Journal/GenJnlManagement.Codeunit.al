// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

/// <summary>
/// Provides comprehensive management functionality for general journal templates, batches, and line processing.
/// Handles template selection, batch management, account validation, and journal navigation workflows.
/// </summary>
/// <remarks>
/// Central management codeunit for journal operations including template selection, batch creation, and validation.
/// Key capabilities: Template selection logic, batch management, account name lookup, and journal page navigation.
/// Extensibility: Multiple integration events enable custom template selection logic and journal processing workflows.
/// </remarks>
codeunit 230 GenJnlManagement
{
    Permissions = TableData "Gen. Journal Template" = rimd,
                  TableData "Gen. Journal Batch" = rimd;

    trigger OnRun()
    begin
    end;

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        PrevGenJnlLine: Record "Gen. Journal Line";
        OpenFromBatch: Boolean;
        AccountNames: Dictionary of [Text, Text];

#pragma warning disable AA0074
        Text000: Label 'Fixed Asset G/L Journal';
#pragma warning disable AA0470
        Text001: Label '%1 journal';
#pragma warning restore AA0470
        Text002: Label 'RECURRING';
        Text003: Label 'Recurring General Journal';
        Text004: Label 'DEFAULT';
        Text005: Label 'Default Journal';
#pragma warning restore AA0074

    /// <summary>
    /// Manages template selection for journal pages based on page type and recurring journal requirements.
    /// Filters available templates and launches appropriate journal interface.
    /// </summary>
    /// <param name="PageID">Page identifier for the journal type being opened.</param>
    /// <param name="PageTemplate">Template type enum that determines journal behavior.</param>
    /// <param name="RecurringJnl">Boolean indicating if this is for recurring journal functionality.</param>
    /// <param name="GenJnlLine">Journal line record used for context and filtering.</param>
    /// <param name="JnlSelected">Returns true if a valid template was selected and journal opened.</param>
    procedure TemplateSelection(PageID: Integer; PageTemplate: Enum "Gen. Journal Template Type"; RecurringJnl: Boolean; var GenJnlLine: Record "Gen. Journal Line"; var JnlSelected: Boolean)
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlTemplateType: Option;
    begin
        JnlSelected := true;

        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange("Page ID", PageID);
        GenJnlTemplate.SetRange(Recurring, RecurringJnl);
        if not RecurringJnl then
            GenJnlTemplate.SetRange(Type, PageTemplate);

        GenJnlTemplateType := PageTemplate.AsInteger();
        OnTemplateSelectionSetFilter(GenJnlTemplate, GenJnlTemplateType, RecurringJnl, PageID, GenJnlLine);
        PageTemplate := Enum::"Gen. Journal Template Type".FromInteger(GenJnlTemplateType);

        JnlSelected := FindTemplateFromSelection(GenJnlTemplate, PageTemplate, RecurringJnl);

        if JnlSelected then
            RunTemplateJournalPage(GenJnlTemplate, GenJnlLine);

        OnAfterTemplateSelection(GenJnlTemplate, GenJnlLine, JnlSelected, OpenFromBatch, RecurringJnl);
    end;

    local procedure RunTemplateJournalPage(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunTemplateJournalPage(GenJnlTemplate, GenJnlLine, OpenFromBatch, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.FilterGroup := 2;
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.FilterGroup := 0;
        if OpenFromBatch then begin
            GenJnlLine."Journal Template Name" := '';
            PAGE.Run(GenJnlTemplate."Page ID", GenJnlLine);
        end;
    end;

    /// <summary>
    /// Opens journal interface directly from a batch selection, bypassing template selection.
    /// Validates batch configuration and launches the appropriate journal page.
    /// </summary>
    /// <param name="GenJnlBatch">Journal batch record containing template reference and batch settings.</param>
    procedure TemplateSelectionFromBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        OpenFromBatch := true;
        GenJnlTemplate.Get(GenJnlBatch."Journal Template Name");
        GenJnlTemplate.TestField("Page ID");
        GenJnlBatch.TestField(Name);

        OpenJournalPageFromBatch(GenJnlBatch, GenJnlTemplate);
    end;

    local procedure OpenJournalPageFromBatch(var GenJnlBatch: Record "Gen. Journal Batch"; GenJnlTemplate: Record "Gen. Journal Template")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenJournalPageFromBatch(GenJnlBatch, GenJnlTemplate, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.FilterGroup := 2;
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.FilterGroup := 0;

        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        PAGE.Run(GenJnlTemplate."Page ID", GenJnlLine);
    end;

    /// <summary>
    /// Opens journal batch with current batch name and manages batch selection logic.
    /// Handles batch validation and provides default batch creation when necessary.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Current journal batch name to open or validate.</param>
    /// <param name="GenJnlLine">Journal line record for context and template information.</param>
    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    begin
        OnBeforeOpenJnl(CurrentJnlBatchName, GenJnlLine);

        if (GenJnlLine."Journal Template Name" <> '') and (GenJnlLine.GetFilter("Journal Template Name") = '') then
            CheckTemplateName(GenJnlLine."Journal Template Name", CurrentJnlBatchName)
        else
            CheckTemplateName(GenJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        OnOpenJnlOnAfterCheckTemplateName(GenJnlLine, CurrentJnlBatchName);

        GenJnlLine.FilterGroup := 2;
        GenJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        GenJnlLine.FilterGroup := 0;
    end;

    /// <summary>
    /// Opens and initializes a general journal batch with template selection and validation.
    /// Ensures proper batch setup by creating missing templates and handling batch selection logic.
    /// </summary>
    /// <param name="GenJnlBatch">General journal batch record to open and configure</param>
    procedure OpenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlTemplate: Record "Gen. Journal Template";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlLine: Record "Gen. Journal Line";
        JnlSelected: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenJnlBatch(GenJnlBatch, IsHandled);
        if not IsHandled then begin
            if GenJnlBatch.GetFilter("Journal Template Name") <> '' then
                exit;
            GenJnlBatch.FilterGroup(2);
            if GenJnlBatch.GetFilter("Journal Template Name") <> '' then begin
                GenJnlBatch.FilterGroup(0);
                exit;
            end;
            GenJnlBatch.FilterGroup(0);

            if not GenJnlBatch.Find('-') then
                for GenJnlTemplate.Type := GenJnlTemplate.Type::General to GenJnlTemplate.Type::Jobs do begin
                    GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type);
                    if not GenJnlTemplate.FindFirst() then
                        TemplateSelection(0, GenJnlTemplate.Type, false, GenJnlLine, JnlSelected);
                    if GenJnlTemplate.FindFirst() then
                        CheckTemplateName(GenJnlTemplate.Name, GenJnlBatch.Name);
                    if GenJnlTemplate.Type = GenJnlTemplate.Type::General then begin
                        GenJnlTemplate.SetRange(Recurring, true);
                        if not GenJnlTemplate.FindFirst() then
                            TemplateSelection(0, GenJnlTemplate.Type, true, GenJnlLine, JnlSelected);
                        if GenJnlTemplate.FindFirst() then
                            CheckTemplateName(GenJnlTemplate.Name, GenJnlBatch.Name);
                        GenJnlTemplate.SetRange(Recurring);
                    end;
                end;

            GenJnlBatch.Find('-');
            JnlSelected := true;
            GenJnlBatch.CalcFields("Template Type", Recurring);
            GenJnlTemplate.SetRange(Recurring, GenJnlBatch.Recurring);
            if not GenJnlBatch.Recurring then
                GenJnlTemplate.SetRange(Type, GenJnlBatch."Template Type");
            if GenJnlBatch.GetFilter("Journal Template Name") <> '' then
                GenJnlTemplate.SetRange(Name, GenJnlBatch.GetFilter("Journal Template Name"));
            OnOpenJnlBatchOnBeforeCheckGenJnlTemplateCount(GenJnlBatch, GenJnlTemplate);
            case GenJnlTemplate.Count of
                1:
                    GenJnlTemplate.FindFirst();
                else
                    JnlSelected := PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK;
            end;
            if not JnlSelected then
                Error('');

            GenJnlBatch.FilterGroup(0);
            GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
            GenJnlBatch.FilterGroup(2);
        end;

        OnAfterOpenJournalBatch(GenJnlBatch, GenJnlTemplate);
    end;

    /// <summary>
    /// Checks if the journal batch has an empty number series configuration.
    /// Validates whether the batch requires manual document numbering or has automatic numbering configured.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Journal batch name to check for number series configuration</param>
    /// <param name="GenJnlLine">Journal line record providing template context for batch lookup</param>
    /// <returns>True if the batch number series is empty, false if number series is configured</returns>
    procedure IsBatchNoSeriesEmpty(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if (GenJnlLine."Journal Template Name" <> '') and (GenJnlLine.GetFilter("Journal Template Name") = '') then
            GenJnlBatch.get(GenJnlLine."Journal Template Name", CurrentJnlBatchName)
        else
            if GenJnlBatch.get(GenJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName) then;
        exit(GenJnlBatch."No. Series" = '');
    end;

    [Scope('OnPrem')]
    procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not GenJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not GenJnlBatch.FindFirst() then begin
                GenJnlBatch.Init();
                GenJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                GenJnlBatch.SetupNewBatch();
                GenJnlBatch.Name := Text004;
                GenJnlBatch.Description := Text005;
                GenJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := GenJnlBatch.Name
        end;
    end;

    /// <summary>
    /// Validates journal batch exists and gets batch configuration for the specified batch name.
    /// Ensures batch is properly configured before allowing journal operations.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Journal batch name to validate and check.</param>
    /// <param name="GenJnlLine">Journal line record for template context.</param>
    procedure CheckName(CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlBatch.Get(GenJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        OnAfterCheckName(GenJnlBatch, CurrentJnlBatchName, GenJnlLine);
    end;

    /// <summary>
    /// Validates currency code exists in the currency master data.
    /// Provides currency validation for journal line processing.
    /// </summary>
    /// <param name="CurrencyCode">Currency code to validate against currency table.</param>
    procedure CheckCurrencyCode(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
    end;

    /// <summary>
    /// Sets journal batch filter on journal lines and positions to first record.
    /// Configures journal line record for batch-specific operations.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Journal batch name to filter on.</param>
    /// <param name="GenJnlLine">Journal line record to configure with batch filter.</param>
    procedure SetName(CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.FilterGroup := 2;
        GenJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        GenJnlLine.FilterGroup := 0;
        OnAfterSetName(GenJnlLine, CurrentJnlBatchName);
        if GenJnlLine.Find('-') then;
    end;

    /// <summary>
    /// Configures journal page display mode preference for the current user.
    /// Stores user preference for simple or classic view mode in journal pages.
    /// </summary>
    /// <param name="SetToSimpleMode">True to set simple mode, false for classic mode.</param>
    /// <param name="PageIdToSet">Page identifier to set the preference for.</param>
    procedure SetJournalSimplePageModePreference(SetToSimpleMode: Boolean; PageIdToSet: Integer)
    var
        JournalUserPreferences: Record "Journal User Preferences";
        IsHandled: Boolean;
    begin
        // sets journal page preference for a page
        // preference set to simple page if SetToSimpleMode is true; else set to classic mode

        IsHandled := false;
        OnBeforeSetJournalSimplePageModePreference(SetToSimpleMode, PageIdToSet, IsHandled);
        if IsHandled then
            exit;

        JournalUserPreferences.Reset();
        JournalUserPreferences.SetFilter("User ID", '%1', UserSecurityId());
        JournalUserPreferences.SetFilter("Page ID", '%1', PageIdToSet);
        if JournalUserPreferences.FindFirst() then begin
            JournalUserPreferences."Is Simple View" := SetToSimpleMode;
            JournalUserPreferences.Modify();
        end else begin
            Clear(JournalUserPreferences);
            JournalUserPreferences."Page ID" := PageIdToSet;
            JournalUserPreferences."Is Simple View" := SetToSimpleMode;
            JournalUserPreferences."User ID" := UserSecurityId();
            JournalUserPreferences.Insert();
        end;
    end;

    /// <summary>
    /// Retrieves journal page display mode preference for the current user.
    /// Returns user preference for simple or classic view mode in journal pages.
    /// </summary>
    /// <param name="PageIdToCheck">Page identifier to check preference for.</param>
    /// <returns>True if simple mode is preferred, false for classic mode or if no preference set.</returns>
    procedure GetJournalSimplePageModePreference(PageIdToCheck: Integer): Boolean
    var
        JournalUserPreferences: Record "Journal User Preferences";
    begin
        // Get journal page mode preference for a page; By defaults this returns FALSE unless a preference
        // is set
        OnBeforeGetJournalSimplePageModePreference(PageIdToCheck);
        JournalUserPreferences.Reset();
        JournalUserPreferences.SetFilter("User ID", '%1', UserSecurityId());
        JournalUserPreferences.SetFilter("Page ID", '%1', PageIdToCheck);
        if JournalUserPreferences.FindFirst() then
            exit(JournalUserPreferences."Is Simple View");
        exit(false);
    end;

    /// <summary>
    /// Retrieves the last viewed journal batch name for a specific page from user preferences.
    /// Returns stored user preference for batch selection when reopening journal pages.
    /// </summary>
    /// <param name="PageIdToCheck">Page identifier to retrieve batch preference for.</param>
    /// <returns>Last viewed journal batch name for the page, or empty string if no preference stored.</returns>
    procedure GetLastViewedJournalBatchName(PageIdToCheck: Integer): Code[10]
    var
        JournalUserPreferences: Record "Journal User Preferences";
    begin
        JournalUserPreferences.Reset();
        JournalUserPreferences.SetFilter("User ID", '%1', UserSecurityId());
        JournalUserPreferences.SetFilter("Page ID", '%1', PageIdToCheck);
        if JournalUserPreferences.FindFirst() then
            exit(JournalUserPreferences."Journal Batch Name");
        exit('');
    end;

    /// <summary>
    /// Stores the last viewed journal batch name for a specific page in user preferences.
    /// Updates user preference for batch selection to improve user experience on page reopening.
    /// </summary>
    /// <param name="PageIdToCheck">Page identifier to set batch preference for.</param>
    /// <param name="GenJnlBatch">Journal batch name to store as last viewed preference.</param>
    procedure SetLastViewedJournalBatchName(PageIdToCheck: Integer; GenJnlBatch: Code[10])
    var
        JournalUserPreferences: Record "Journal User Preferences";
    begin
        JournalUserPreferences.Reset();
        JournalUserPreferences.SetFilter("User ID", '%1', UserSecurityId());
        JournalUserPreferences.SetFilter("Page ID", '%1', PageIdToCheck);
        if JournalUserPreferences.FindFirst() then begin
            JournalUserPreferences."Journal Batch Name" := GenJnlBatch;
            JournalUserPreferences.Modify();
        end;
    end;

    /// <summary>
    /// Provides journal batch lookup functionality with filtering and selection capabilities.
    /// Opens batch selection page and updates current batch name based on user selection.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Current journal batch name that will be updated with selection.</param>
    /// <param name="GenJnlLine">Journal line record providing template context for batch filtering.</param>
    procedure LookupName(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        Commit();
        GenJnlBatch."Journal Template Name" := GenJnlLine.GetRangeMax("Journal Template Name");
        GenJnlBatch.Name := GenJnlLine.GetRangeMax("Journal Batch Name");
        GenJnlBatch.FilterGroup(2);
        GenJnlBatch.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlBatch.FilterGroup(0);
        OnBeforeLookupName(GenJnlBatch, GenJnlLine);
        if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := GenJnlBatch.Name;
            SetName(CurrentJnlBatchName, GenJnlLine);
        end;
    end;

    /// <summary>
    /// Opens journal batch name lookup and updates journal line batch assignment.
    /// Provides user interface for selecting and assigning journal batch to current line.
    /// </summary>
    /// <param name="GenJnlLine">Journal line record that will have batch name updated from selection.</param>
    procedure SetJnlBatchName(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlLine.TestField("Journal Template Name");
        GenJnlBatch.FilterGroup(2);
        GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlBatch."Journal Template Name" := GenJnlLine."Journal Template Name";
        GenJnlBatch.FilterGroup(0);
        GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
        if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
            GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    /// <summary>
    /// Retrieves and caches account names for display in journal lines to improve user experience.
    /// Optimizes performance by caching account names to avoid repeated database lookups.
    /// </summary>
    /// <param name="GenJnlLine">Journal line record containing account information.</param>
    /// <param name="AccName">Returns the account name for the primary account.</param>
    /// <param name="BalAccName">Returns the account name for the balancing account.</param>
    procedure GetAccounts(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100]; var BalAccName: Text[100])
    begin
        if (GenJnlLine."Account Type" <> PrevGenJnlLine."Account Type") or
           (GenJnlLine."Account No." <> PrevGenJnlLine."Account No.")
        then begin
            AccName := '';
            if GenJnlLine."Account No." <> '' then
                AccName := GetAccountName(GenJnlLine."Account Type", GenJnlLine."Account No.");
        end;

        if (GenJnlLine."Bal. Account Type" <> PrevGenJnlLine."Bal. Account Type") or
           (GenJnlLine."Bal. Account No." <> PrevGenJnlLine."Bal. Account No.")
        then begin
            BalAccName := '';
            if GenJnlLine."Bal. Account No." <> '' then
                BalAccName := GetAccountName(GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.");
        end;

        OnAfterGetAccounts(GenJnlLine, AccName, BalAccName);

        PrevGenJnlLine := GenJnlLine;
    end;

    local procedure GetAccountName(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]): Text[100]
    var
        KeyName: Text;
        AccName: Text[100];
    begin
        if AccNo = '' then
            exit('');
        KeyName := Format(AccType.AsInteger()) + '$' + AccNo;
        if AccountNames.ContainsKey(KeyName) then
            AccName := CopyStr(AccountNames.Get(KeyName), 1, MaxStrLen(AccName))
        else begin
            AccName := LookupAccountName(AccType, AccNo);
            AccountNames.Add(KeyName, AccName);
        end;
        exit(AccName);
    end;

    local procedure LookupAccountName(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]): Text[100]
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAcc: Record "G/L Account";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Cust: Record Customer;
        [SecurityFiltering(SecurityFilter::Filtered)]
        Vend: Record Vendor;
        [SecurityFiltering(SecurityFilter::Filtered)]
        BankAcc: Record "Bank Account";
        [SecurityFiltering(SecurityFilter::Filtered)]
        FA: Record "Fixed Asset";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ICPartner: Record "IC Partner";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Employee: Record Employee;
        [SecurityFiltering(SecurityFilter::Filtered)]
        AllocationAccount: Record "Allocation Account";
        AccName: Text[100];
    begin
        case AccType of
            AccType::"G/L Account":
                begin
                    GLAcc.SetloadFields(Name);
                    if GLAcc.Get(AccNo) then
                        AccName := GLAcc.Name;
                end;
            AccType::Customer:
                begin
                    Cust.SetloadFields(Name);
                    if Cust.Get(AccNo) then
                        AccName := Cust.Name;
                end;
            AccType::Vendor:
                begin
                    Vend.SetloadFields(Name);
                    if Vend.Get(AccNo) then
                        AccName := Vend.Name;
                end;
            AccType::"Bank Account":
                begin
                    BankAcc.SetloadFields(Name);
                    if BankAcc.Get(AccNo) then
                        AccName := BankAcc.Name;
                end;
            AccType::"Fixed Asset":
                begin
                    FA.SetloadFields(Description);
                    if FA.Get(AccNo) then
                        AccName := FA.Description;
                end;
            AccType::"IC Partner":
                begin
                    ICPartner.SetloadFields(Name);
                    if ICPartner.Get(AccNo) then
                        AccName := ICPartner.Name;
                end;
            AccType::Employee:
                begin
                    Employee.SetloadFields("First Name", "Last Name");
                    if Employee.Get(AccNo) then
                        AccName := Employee."First Name" + ' ' + Employee."Last Name";
                end;
            AccType::"Allocation Account":
                begin
                    AllocationAccount.SetloadFields(Name);
                    if AllocationAccount.Get(AccNo) then
                        AccName := AllocationAccount.Name;
                end;
        end;
        exit(AccName);
    end;

    /// <summary>
    /// Calculates running balance and total balance for journal lines within the current batch context.
    /// Provides balance calculations for journal line display and validation purposes.
    /// </summary>
    /// <param name="GenJnlLine">Current journal line for balance calculation context.</param>
    /// <param name="LastGenJnlLine">Last journal line used for calculation positioning.</param>
    /// <param name="Balance">Returns the running balance up to the current line.</param>
    /// <param name="TotalBalance">Returns the total balance for all lines in the batch.</param>
    /// <param name="ShowBalance">Returns true if running balance should be displayed.</param>
    /// <param name="ShowTotalBalance">Returns true if total balance should be displayed.</param>
    procedure CalcBalance(var GenJnlLine: Record "Gen. Journal Line"; LastGenJnlLine: Record "Gen. Journal Line"; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean)
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        TempGenJnlLine: Record "Gen. Journal Line";
    begin
        TempGenJnlLine.CopyFilters(GenJnlLine);
        OnCalcBalanceOnAfterCopyFilters(TempGenJnlLine);
        if CurrentClientType in [CLIENTTYPE::SOAP, CLIENTTYPE::OData, CLIENTTYPE::ODataV4, CLIENTTYPE::Api] then
            ShowTotalBalance := false
        else
            ShowTotalBalance := TempGenJnlLine.CalcSums("Balance (LCY)");

        if ShowTotalBalance then begin
            TotalBalance := TempGenJnlLine."Balance (LCY)";
            if GenJnlLine."Line No." = 0 then
                TotalBalance := TotalBalance + LastGenJnlLine."Balance (LCY)";
        end;

        if GenJnlLine."Line No." <> 0 then begin
            TempGenJnlLine.SetRange("Line No.", 0, GenJnlLine."Line No.");
            ShowBalance := TempGenJnlLine.CalcSums("Balance (LCY)");
            if ShowBalance then
                Balance := TempGenJnlLine."Balance (LCY)";
        end else begin
            TempGenJnlLine.SetRange("Line No.", 0, LastGenJnlLine."Line No.");
            ShowBalance := TempGenJnlLine.CalcSums("Balance (LCY)");
            if ShowBalance then begin
                Balance := TempGenJnlLine."Balance (LCY)";
                TempGenJnlLine.CopyFilters(GenJnlLine);
                TempGenJnlLine := LastGenJnlLine;
                OnCalcBalanceOnBeforeTempGenJnlLineNext(TempGenJnlLine);
                if TempGenJnlLine.Next() = 0 then
                    Balance := Balance + LastGenJnlLine."Balance (LCY)";
            end;
        end;
        if CurrentClientType in [CLIENTTYPE::SOAP, CLIENTTYPE::OData, CLIENTTYPE::ODataV4, CLIENTTYPE::Api] then
            ShowBalance := false;

        OnAfterCalcBalance(GenJnlLine);
    end;

    /// <summary>
    /// Generates unique journal template names by checking for conflicts and incrementing names when needed.
    /// Ensures new template names are unique while maintaining meaningful naming based on template type.
    /// </summary>
    /// <param name="TemplateName">Proposed template name to check for availability.</param>
    /// <returns>Available template name, either original or incremented to avoid conflicts.</returns>
    procedure GetAvailableGeneralJournalTemplateName(TemplateName: Code[10]): Code[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        PotentialTemplateName: Code[10];
        PotentialTemplateNameIncrement: Integer;
    begin
        // Make sure proposed value + incrementer will fit in Name field
        if StrLen(TemplateName) > 9 then
            TemplateName := Format(TemplateName, 9);

        GenJnlTemplate.Init();
        PotentialTemplateName := TemplateName;
        PotentialTemplateNameIncrement := 0;

        // Expecting few naming conflicts, but limiting to 10 iterations to avoid possible infinite loop.
        while PotentialTemplateNameIncrement < 10 do begin
            GenJnlTemplate.SetFilter(Name, PotentialTemplateName);
            if GenJnlTemplate.Count = 0 then
                exit(PotentialTemplateName);

            PotentialTemplateNameIncrement := PotentialTemplateNameIncrement + 1;
            PotentialTemplateName := TemplateName + Format(PotentialTemplateNameIncrement);
        end;
    end;

    local procedure FindTemplateFromSelection(var GenJnlTemplate: Record "Gen. Journal Template"; TemplateType: Enum "Gen. Journal Template Type"; RecurringJnl: Boolean) TemplateSelected: Boolean
    begin
        TemplateSelected := true;
        case GenJnlTemplate.Count of
            0:
                begin
                    GenJnlTemplate.Init();
                    GenJnlTemplate.Type := TemplateType;
                    GenJnlTemplate.Recurring := RecurringJnl;
                    if not RecurringJnl then begin
                        GenJnlTemplate.Name :=
                          GetAvailableGeneralJournalTemplateName(Format(GenJnlTemplate.Type, MaxStrLen(GenJnlTemplate.Name)));
                        if TemplateType = GenJnlTemplate.Type::Assets then
                            GenJnlTemplate.Description := Text000
                        else
                            GenJnlTemplate.Description := StrSubstNo(Text001, GenJnlTemplate.Type);
                    end else begin
                        GenJnlTemplate.Name := Text002;
                        GenJnlTemplate.Description := Text003;
                    end;
                    GenJnlTemplate.Validate(Type);
                    OnFindTemplateFromSelectionOnBeforeGenJnlTemplateInsert(GenJnlTemplate);
                    GenJnlTemplate.Insert();
                    Commit();
                end;
            1:
                GenJnlTemplate.FindFirst();
            else
                TemplateSelected := PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK;
        end;
    end;

    [Scope('OnPrem')]
    procedure TemplateSelectionSimple(var GenJnlTemplate: Record "Gen. Journal Template"; TemplateType: Enum "Gen. Journal Template Type"; RecurringJnl: Boolean): Boolean
    begin
        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange(Type, TemplateType);
        GenJnlTemplate.SetRange(Recurring, RecurringJnl);
        exit(FindTemplateFromSelection(GenJnlTemplate, TemplateType, RecurringJnl));
    end;

    /// <summary>
    /// Integration event raised after retrieving account names for journal line display.
    /// Enables customization of account name lookup and display logic.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record containing account information.</param>
    /// <param name="AccName">Account name for the primary account that can be modified.</param>
    /// <param name="BalAccName">Balancing account name that can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccounts(var GenJournalLine: Record "Gen. Journal Line"; var AccName: Text[100]; var BalAccName: Text[100])
    begin
    end;

    /// <summary>
    /// Integration event raised after validating journal batch name exists and is properly configured.
    /// Enables custom batch validation logic and post-validation processing.
    /// </summary>
    /// <param name="GenJnlBatch">Journal batch record that was validated.</param>
    /// <param name="CurrentJnlBatchName">Current journal batch name being validated.</param>
    /// <param name="GenJournalLine">Journal line record providing template context.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckName(GenJnlBatch: Record "Gen. Journal Batch"; CurrentJnlBatchName: Code[10]; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting journal batch filter on journal lines.
    /// Enables custom filtering logic and post-filter processing.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record with batch filter applied.</param>
    /// <param name="CurrentJnlBatchName">Journal batch name that was set as filter.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetName(var GenJournalLine: Record "Gen. Journal Line"; CurrentJnlBatchName: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised after opening journal batch operations complete.
    /// Enables custom logic after batch and template have been selected and configured.
    /// </summary>
    /// <param name="GenJnlBatch">Journal batch record that was opened.</param>
    /// <param name="GenJnlTemplate">Journal template record associated with the batch.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenJournalBatch(GenJnlBatch: Record "Gen. Journal Batch"; GenJnlTemplate: Record "Gen. Journal Template")
    begin
    end;

    /// <summary>
    /// Integration event raised after template selection process completes.
    /// Enables custom logic after template selection and journal page launch.
    /// </summary>
    /// <param name="GenJnlTemplate">Selected journal template record.</param>
    /// <param name="GenJnlLine">Journal line record used for context.</param>
    /// <param name="JnlSelected">Boolean indicating if template selection was successful.</param>
    /// <param name="OpenFromBatch">Boolean indicating if opened from batch context.</param>
    /// <param name="RecurringJnl">Boolean indicating if this is for recurring journal.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTemplateSelection(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlLine: Record "Gen. Journal Line"; var JnlSelected: Boolean; var OpenFromBatch: Boolean; RecurringJnl: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before journal batch name lookup operations.
    /// Enables custom filtering or validation logic before batch selection.
    /// </summary>
    /// <param name="GenJnlBatch">Journal batch record that will be used for lookup.</param>
    /// <param name="GenJnlLine">Journal line record providing context for lookup.</param>  
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupName(var GenJnlBatch: Record "Gen. Journal Batch"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving journal simple page mode preference.
    /// Enables custom logic before preference retrieval.
    /// </summary>
    /// <param name="PageIdToCheck">Page identifier to check preference for.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetJournalSimplePageModePreference(PageIdToCheck: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before setting journal simple page mode preference.
    /// Enables custom validation or modification of preference settings.
    /// </summary>
    /// <param name="SetToSimpleMode">Boolean indicating simple mode preference (can be modified).</param>
    /// <param name="PageIdToSet">Page identifier to set preference for.</param>
    /// <param name="IsHandled">Set to true to skip standard preference setting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetJournalSimplePageModePreference(var SetToSimpleMode: Boolean; PageIdToSet: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before opening journal with batch name operations.
    /// Enables custom validation or preprocessing before journal opening.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Current journal batch name being opened.</param>
    /// <param name="GenJnlLine">Journal line record providing context.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before journal batch opening operations.
    /// Enables custom logic to completely override batch opening process.
    /// </summary>
    /// <param name="GenJnlBatch">Journal batch record being opened.</param>
    /// <param name="IsHandled">Set to true to skip standard batch opening logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before opening journal page from batch context.
    /// Enables custom logic to override page opening from batch selection.
    /// </summary>
    /// <param name="GenJnlBatch">Journal batch record being opened.</param>
    /// <param name="GenJnlTemplate">Journal template record associated with batch.</param>
    /// <param name="IsHandled">Set to true to skip standard page opening logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJournalPageFromBatch(var GenJnlBatch: Record "Gen. Journal Batch"; var GenJnlTemplate: Record "Gen. Journal Template"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before running template journal page operations.
    /// Enables custom logic to override journal page launching.
    /// </summary>
    /// <param name="GenJnlTemplate">Journal template record for page launching.</param>
    /// <param name="GenJnlLine">Journal line record providing context.</param>
    /// <param name="OpenFromBatch">Boolean indicating if opened from batch context.</param>
    /// <param name="IsHandled">Set to true to skip standard page launching logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunTemplateJournalPage(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlLine: Record "Gen. Journal Line"; OpenFromBatch: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised during template selection to enable custom filtering logic.
    /// Allows modification of template filters and selection criteria.
    /// </summary>
    /// <param name="GenJnlTemplate">Journal template record with filters that can be modified.</param>
    /// <param name="PageTemplate">Template type option that can be modified.</param>
    /// <param name="RecurringJnl">Boolean indicating recurring journal that can be modified.</param>
    /// <param name="PageId">Page identifier for template selection context.</param>
    /// <param name="GenJnlLine">Journal line record providing context.</param>
    [IntegrationEvent(false, false)]
    local procedure OnTemplateSelectionSetFilter(var GenJnlTemplate: Record "Gen. Journal Template"; var PageTemplate: Option; var RecurringJnl: Boolean; PageId: Integer; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a new journal template during template selection.
    /// Enables custom template configuration before insertion.
    /// </summary>
    /// <param name="GenJnlTemplate">Journal template record being inserted that can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindTemplateFromSelectionOnBeforeGenJnlTemplateInsert(var GenJnlTemplate: Record "Gen. Journal Template")
    begin
    end;

    /// <summary>
    /// Integration event raised after template name checking during journal opening.
    /// Enables custom processing after template validation.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record with template context.</param>
    /// <param name="CurrentJnlBatchName">Current journal batch name being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnOpenJnlOnAfterCheckTemplateName(var GenJournalLine: Record "Gen. Journal Line"; var CurrentJnlBatchName: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised before checking journal template count during batch operations.
    /// Enables custom template filtering or validation logic.
    /// </summary>
    /// <param name="GenJnlBatch">Journal batch record being processed.</param>
    /// <param name="GenJnlTemplate">Journal template record with filters that can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnOpenJnlBatchOnBeforeCheckGenJnlTemplateCount(var GenJnlBatch: Record "Gen. Journal Batch"; var GenJnlTemplate: Record "Gen. Journal Template")
    begin
    end;

    /// <summary>
    /// Integration event raised after balance calculation operations complete.
    /// Enables custom processing or validation after balance calculations.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record used for balance calculation context.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBalance(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying filters during balance calculation setup.
    /// Enables custom filter modification before balance calculation processing.
    /// </summary>
    /// <param name="TempGenJournalLine">Temporary journal line record with copied filters that can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcBalanceOnAfterCopyFilters(var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    /// <summary>
    /// Integration event raised before moving to next record during balance calculation.
    /// Enables custom record positioning logic during balance calculation.
    /// </summary>
    /// <param name="TempGenJournalLine">Temporary journal line record being positioned.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcBalanceOnBeforeTempGenJnlLineNext(var TempGenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

