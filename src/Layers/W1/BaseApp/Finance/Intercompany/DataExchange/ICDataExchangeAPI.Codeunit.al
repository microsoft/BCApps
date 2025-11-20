// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Globalization;
using Microsoft.Foundation.Company;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Intercompany;
using System.Threading;
using Microsoft.Intercompany.Outbox;
using System.Telemetry;
using Microsoft.Intercompany.Journal;

codeunit 561 "IC Data Exchange API" implements "IC Data Exchange"
{
    Permissions = tabledata "IC Inbox Transaction" = i,
                  tabledata "IC Inbox Jnl. Line" = i,
                  tabledata "IC Inbox Purchase Header" = i,
                  tabledata "IC Inbox Purchase Line" = i,
                  tabledata "IC Inbox Sales Header" = i,
                  tabledata "IC Inbox Sales Line" = i,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = i,
                  tabledata "IC Document Dimension" = i,
                  tabledata "IC Comment Line" = i;

    var
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
        CurrentGlobalLanguage: Integer;
        JsonResponse: JsonArray;
        SelectedToken: JsonToken;
        AttributeToken: JsonToken;

        ICDataExchangeAPIFeatureTelemetryNameTok: Label 'Intercompany Data Exchange API', Locked = true;
        JobQueueCategoryCodeSendNotificationTok: Label 'ICSENDNOT', Locked = true;
        JobQueueCategoryCodeReadTransactionTok: Label 'ICREADTRAN', Locked = true;
        JobQueueCategoryCodeCleanUpTok: Label 'ICCLEANUP', Locked = true;
        JobQueueCategoryCodeAutoAcceptTok: Label 'ICAUTOACC', Locked = true;
        SecurityLogDecriptionTok: Label 'Suspicious IC transaction', Locked = true;
        ICPartnerMissingCurrentCompanyErr: Label 'The current company is not registered as a partner in the list of partners of company %1', Comment = '%1 = Partner company name';
        PartnerMissingTableSetupErr: Label 'Partner %1 has not completed the information required at table %2 for using intercompany.', Comment = '%1 = Partner code, %2 = Table caption';
        WrongICPartnerInboxTypeErr: Label 'Partner %1 inbox type is not valid for this interaction. Only partners with database as Inbox Type can be used.', Comment = '%1 = IC Partner Code';
        WrongICDataExchangeTypeErr: Label 'Partner %1 does not support intercompany communication using APIs. Only partners setup to use API as their data exchange type can use this type of communication.', Comment = '%1 = IC Partner Code';
        SendNotificationJobQueueTxt: Label 'API - Send notification to intercompany partner %1 for operation %2', Comment = '%1 = Partner Code, %2 = Operation Id';
        ReadOutgoingNotificationJobQueueTxt: Label 'API - Read outgoing notification from intercompany partner %1 for operation %2', Comment = '%1 = Partner Code, %2 = Operation Id';
        CleanUpOutgoingNotificationJobQueueTxt: Label 'API - Clean up notification to intercompany partner %1 for operation %2', Comment = '%1 = Partner Code, %2 = Operation Id';
        AutoAcceptTransactionJobQueueTxt: Label 'API - Automatically accept transaction %1 of partner %2 for document %3', Comment = '%1 = Transaction ID, %2 = Partner Code, %3 = Document No.';
        ICPartnerNotFoundErr: Label 'IC Partner %1 not found.', Comment = '%1 = IC Partner Code';
        SentTransactionTelemetryTxt: Label 'Transaction sent to IC Partner %1 from source %2.', Comment = '%1 = Target IC Partner Code, %2 = Source IC Partner Code';
        SecurityLogResultDescriptionTxt: Label 'Mismatch between transaction source intercompany code %1 and current company intercompany code %2.', Comment = '%1 = Source IC Partner Code, %2 = Current company IC Partner Code';

    procedure GetICPartnerICGLAccount(ICPartner: Record "IC Partner"; var TempICPartnerICGLAccount: Record "IC G/L Account" temporary)
    begin
        TempICPartnerICGLAccount.Reset();
        TempICPartnerICGLAccount.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerRecordsFromEntityName(ICPartner, 'intercompanyGeneralLedgerAccounts');

        foreach SelectedToken in JsonResponse do
            PopulateICGLAccountFromJson(SelectedToken, TempICPartnerICGLAccount);
    end;

    procedure GetICPartnerICDimension(ICPartner: Record "IC Partner"; var TempICPartnerICDimension: Record "IC Dimension" temporary)
    begin
        TempICPartnerICDimension.Reset();
        TempICPartnerICDimension.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerRecordsFromEntityName(ICPartner, 'intercompanyDimensions');

        foreach SelectedToken in JsonResponse do
            PopulateICDimensionFromJson(SelectedToken, TempICPartnerICDimension);
    end;

    procedure GetICPartnerICDimensionValue(ICPartner: Record "IC Partner"; var TempICPartnerICDimensionValue: Record "IC Dimension Value" temporary)
    begin
        TempICPartnerICDimensionValue.Reset();
        TempICPartnerICDimensionValue.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerRecordsFromEntityName(ICPartner, 'intercompanyDimensionValues');

        foreach SelectedToken in JsonResponse do
            PopulateICDimensionValueFromJson(SelectedToken, TempICPartnerICDimensionValue);
    end;

    procedure GetICPartnerFromICPartner(ICPartner: Record "IC Partner"; var TempRegisteredICPartner: Record "IC Partner" temporary)
    var
        ICSetup: Record "IC Setup";
    begin
        ICSetup.Get();
        GetICPartnerFromICPartner(ICPartner, ICSetup."IC Partner Code", TempRegisteredICPartner);
    end;

    procedure GetICPartnerFromICPartner(ICPartner: Record "IC Partner"; ICPartnerCode: Code[20]; var TempRegisteredICPartner: Record "IC Partner" temporary)
    var
        TempICPartners: Record "IC Partner" temporary;
    begin
        TempRegisteredICPartner.Reset();
        TempRegisteredICPartner.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerRecordsFromEntityName(ICPartner, 'intercompanyPartners');

        foreach SelectedToken in JsonResponse do
            PopulateICPartnerFromJson(SelectedToken, TempICPartners);


        if not TempICPartners.Get(ICPartnerCode) then
            Error(ICPartnerMissingCurrentCompanyErr, ICPartner."Inbox Details");

        TempRegisteredICPartner.TransferFields(TempICPartners);
        TempRegisteredICPartner.Insert();
    end;

    procedure GetICPartnerICSetup(ICPartnerName: Text; var TempICPartnerICSetup: Record "IC Setup" temporary)
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.SetRange("Inbox Details", ICPartnerName);
        if not ICPartner.FindFirst() then
            Error(ICPartnerNotFoundErr, ICPartnerName);

        GetICPartnerICSetup(ICPartner, TempICPartnerICSetup);
    end;

    procedure GetICPartnerICSetup(ICPartner: Record "IC Partner"; var TempICPartnerICSetup: Record "IC Setup" temporary)
    begin
        TempICPartnerICSetup.Reset();
        TempICPartnerICSetup.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerRecordsFromEntityName(ICPartner, 'intercompanySetup');

        foreach SelectedToken in JsonResponse do
            PopulateICSetupFromJson(SelectedToken, TempICPartnerICSetup);

        if not TempICPartnerICSetup.FindFirst() then begin
            if System.GuiAllowed() then
                Message(PartnerMissingTableSetupErr, ICPartner."Inbox Details", TempICPartnerICSetup.TableCaption);
            exit;
        end;
    end;

    procedure GetICPartnerGeneralLedgerSetup(ICPartnerName: Text; var TempICPartnerGeneralLedgerSetup: Record "General Ledger Setup" temporary)
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.SetRange("Inbox Details", ICPartnerName);
        if not ICPartner.FindFirst() then
            Error(ICPartnerNotFoundErr, ICPartnerName);

        GetICPartnerGeneralLedgerSetup(ICPartner, TempICPartnerGeneralLedgerSetup);
    end;

    procedure GetICPartnerGeneralLedgerSetup(ICPartner: Record "IC Partner"; var TempICPartnerGeneralLedgerSetup: Record "General Ledger Setup" temporary)
    begin
        TempICPartnerGeneralLedgerSetup.Reset();
        TempICPartnerGeneralLedgerSetup.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerGeneralLedgerSetup(ICPartner);

        foreach SelectedToken in JsonResponse do
            PopulateGeneralLedgerSetupFromJson(SelectedToken, TempICPartnerGeneralLedgerSetup);

        if not TempICPartnerGeneralLedgerSetup.FindFirst() then begin
            if System.GuiAllowed() then
                Message(PartnerMissingTableSetupErr, ICPartner."Inbox Details", TempICPartnerGeneralLedgerSetup.TableCaption);
            exit;
        end;
    end;

    procedure GetICPartnerCompanyInformation(ICPartnerName: Text; var TempICPartnerCompanyInformation: Record "Company Information" temporary)
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.SetRange("Inbox Details", ICPartnerName);
        if not ICPartner.FindFirst() then
            Error(ICPartnerNotFoundErr, ICPartnerName);

        GetICPartnerCompanyInformation(ICPartner, TempICPartnerCompanyInformation);
    end;

    procedure GetICPartnerCompanyInformation(ICPartner: Record "IC Partner"; var TempICPartnerCompanyInformation: Record "Company Information" temporary)
    begin
        TempICPartnerCompanyInformation.Reset();
        TempICPartnerCompanyInformation.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerCompanyInformation(ICPartner);

        foreach SelectedToken in JsonResponse do
            PopulateCompanyInformationFromJson(SelectedToken, TempICPartnerCompanyInformation);

        if not TempICPartnerCompanyInformation.FindFirst() then begin
            if System.GuiAllowed() then
                Message(PartnerMissingTableSetupErr, ICPartner."Inbox Details", TempICPartnerCompanyInformation.TableCaption);
            exit;
        end;
    end;

    procedure GetICPartnerBankAccount(ICPartner: Record "IC Partner"; var TempICPartnerBankAccount: Record "Bank Account" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempBankAccount: Record "Bank Account" temporary;
        LCYCurrencyCode: Code[10];
    begin
        TempICPartnerBankAccount.Reset();
        TempICPartnerBankAccount.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerBankAccount(ICPartner);

        GeneralLedgerSetup.Get();
        LCYCurrencyCode := GeneralLedgerSetup."LCY Code";
        foreach SelectedToken in JsonResponse do
            PopulateBankAccountFromJson(SelectedToken, TempBankAccount, LCYCurrencyCode);

        TempBankAccount.SetRange(IntercompanyEnable, true);
        if not TempBankAccount.IsEmpty() then begin
            TempBankAccount.FindSet();
            repeat
                TempICPartnerBankAccount.TransferFields(TempBankAccount);
                TempICPartnerBankAccount.Insert();
            until TempBankAccount.Next() = 0;
        end;
    end;

    procedure GetICPartnerICInboxTransaction(ICPartner: Record "IC Partner"; var TempICPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary)
    begin
        TempICPartnerICInboxTransaction.Reset();
        TempICPartnerICInboxTransaction.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerRecordsFromEntityName(ICPartner, 'intercompanyInboxTransactions');

        foreach SelectedToken in JsonResponse do
            PopulateICInboxTransactionFromJson(SelectedToken, TempICPartnerICInboxTransaction);
    end;

    procedure GetICPartnerHandledICInboxTransaction(ICPartner: Record "IC Partner"; var TempICPartnerHandledICInboxTransaction: Record "Handled IC Inbox Trans." temporary)
    begin
        TempICPartnerHandledICInboxTransaction.Reset();
        TempICPartnerHandledICInboxTransaction.DeleteAll();
        CheckICPartnerSetup(ICPartner);

        JsonResponse := CrossIntercompanyConnector.RequestICPartnerRecordsFromEntityName(ICPartner, 'handledIntercompanyInboxTransactions');

        foreach SelectedToken in JsonResponse do
            PopulateHandledICInboxTransactionFromJson(SelectedToken, TempICPartnerHandledICInboxTransaction);
    end;

    procedure PostICTransactionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary)
    var
        ICSetup: Record "IC Setup";
        BufferICInboxTransaction: Record "Buffer IC Inbox Transaction";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not TempICPartnerICInboxTransaction.IsEmpty() then begin
            ICSetup.FindFirst();
            // Move temporary records to buffer table so it can be used with the APIs
            TempICPartnerICInboxTransaction.FindSet();
            repeat
                CustomDimensions.Add('Transaction Details', StrSubstNo(SentTransactionTelemetryTxt, ICPartner.Code, TempICPartnerICInboxTransaction."IC Partner Code"));
                FeatureTelemetry.LogUsage('0000LKR', ICMapping.GetFeatureTelemetryName(), ICDataExchangeAPIFeatureTelemetryNameTok, CustomDimensions);
                if TempICPartnerICInboxTransaction."IC Partner Code" <> ICSetup."IC Partner Code" then
                    Session.LogSecurityAudit(SecurityLogDecriptionTok, SecurityOperationResult::Success, StrSubstNo(SecurityLogResultDescriptionTxt, TempICPartnerICInboxTransaction."IC Partner Code", ICSetup."IC Partner Code"), AuditCategory::UserManagement);
                BufferICInboxTransaction.TransferFields(TempICPartnerICInboxTransaction);
                BufferICInboxTransaction.Insert();
            until TempICPartnerICInboxTransaction.Next() = 0;
        end;
    end;

    procedure PostICJournalLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxJnlLine: Record "IC Inbox Jnl. Line" temporary)
    var
        BufferICInboxJnlLine: Record "Buffer IC Inbox Jnl. Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if not TempICPartnerICInboxJnlLine.IsEmpty() then begin
            TempICPartnerICInboxJnlLine.FindSet();
            repeat
                BufferICInboxJnlLine.TransferFields(TempICPartnerICInboxJnlLine);
                if BufferICInboxJnlLine."Currency Code" = '' then
                    BufferICInboxJnlLine."Currency Code" := GeneralLedgerSetup."LCY Code";
                if BufferICInboxJnlLine."Currency Code" = ICPartner."Currency Code" then
                    BufferICInboxJnlLine."Currency Code" := '';
                BufferICInboxJnlLine.Insert();
            until TempICPartnerICInboxJnlLine.Next() = 0;
        end;
    end;

    procedure PostICPurchaseHeaderToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxPurchaseHeader: Record "IC Inbox Purchase Header" temporary; var RegisteredPartner: Record "IC Partner" temporary)
    var
        BufferICInboxPurchaseHeader: Record "Buffer IC Inbox Purch Header";
    begin
        if not TempICPartnerICInboxPurchaseHeader.IsEmpty() then begin
            TempICPartnerICInboxPurchaseHeader.FindSet();
            repeat
                BufferICInboxPurchaseHeader.TransferFields(TempICPartnerICInboxPurchaseHeader);
                BufferICInboxPurchaseHeader."Buy-from Vendor No." := RegisteredPartner."Vendor No.";
                BufferICInboxPurchaseHeader."Pay-to Vendor No." := RegisteredPartner."Vendor No.";
                OnPostICPurchaseHeaderToICPartnerInboxOnBeforeBufferICInboxPurchaseHeaderInsert(BufferICInboxPurchaseHeader, TempICPartnerICInboxPurchaseHeader, ICPartner, RegisteredPartner);
                BufferICInboxPurchaseHeader.Insert();
            until TempICPartnerICInboxPurchaseHeader.Next() = 0;
        end;
    end;

    procedure PostICPurchaseLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxPurchaseLine: Record "IC Inbox Purchase Line" temporary)
    var
        BufferICInboxPurchaseLine: Record "Buffer IC Inbox Purchase Line";
    begin
        if not TempICPartnerICInboxPurchaseLine.IsEmpty() then begin
            TempICPartnerICInboxPurchaseLine.FindSet();
            repeat
                BufferICInboxPurchaseLine.TransferFields(TempICPartnerICInboxPurchaseLine);
                BufferICInboxPurchaseLine.Insert();
            until TempICPartnerICInboxPurchaseLine.Next() = 0;
        end;
    end;

    procedure PostICSalesHeaderToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxSalesHeader: Record "IC Inbox Sales Header" temporary; var RegisteredPartner: Record "IC Partner" temporary)
    var
        BufferICInboxSalesHeader: Record "Buffer IC Inbox Sales Header";
    begin
        if not TempICPartnerICInboxSalesHeader.IsEmpty() then begin
            TempICPartnerICInboxSalesHeader.FindSet();
            repeat
                BufferICInboxSalesHeader.TransferFields(TempICPartnerICInboxSalesHeader);
                BufferICInboxSalesHeader."Sell-to Customer No." := RegisteredPartner."Customer No.";
                BufferICInboxSalesHeader."Bill-to Customer No." := RegisteredPartner."Customer No.";
                OnPostICSalesHeaderToICPartnerInboxOnBeforeBufferICInboxSalesHeaderInsert(BufferICInboxSalesHeader, TempICPartnerICInboxSalesHeader, ICPartner, RegisteredPartner);
                BufferICInboxSalesHeader.Insert();
            until TempICPartnerICInboxSalesHeader.Next() = 0;
        end;
    end;

    procedure PostICSalesLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxSalesLine: Record "IC Inbox Sales Line" temporary)
    var
        BufferICInboxSalesLine: Record "Buffer IC Inbox Sales Line";
    begin
        if not TempICPartnerICInboxSalesLine.IsEmpty() then begin
            TempICPartnerICInboxSalesLine.FindSet();
            repeat
                BufferICInboxSalesLine.TransferFields(TempICPartnerICInboxSalesLine);
                BufferICInboxSalesLine.Insert();
            until TempICPartnerICInboxSalesLine.Next() = 0;
        end;
    end;

    procedure PostICJournalLineDimensionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary)
    var
        BufferICInOutJnlLineDim: Record "Buffer IC InOut Jnl. Line Dim.";
    begin
        if not TempICPartnerICInboxOutboxJnlLineDim.IsEmpty() then begin
            TempICPartnerICInboxOutboxJnlLineDim.FindSet();
            repeat
                BufferICInOutJnlLineDim.TransferFields(TempICPartnerICInboxOutboxJnlLineDim);
                BufferICInOutJnlLineDim.Insert();
            until TempICPartnerICInboxOutboxJnlLineDim.Next() = 0;
        end;
    end;

    procedure PostICDocumentDimensionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICDocDim: Record "IC Document Dimension" temporary)
    var
        BufferICDocumentDimension: Record "Buffer IC Document Dimension";
    begin
        if not TempICPartnerICDocDim.IsEmpty() then begin
            TempICPartnerICDocDim.FindSet();
            repeat
                BufferICDocumentDimension.TransferFields(TempICPartnerICDocDim);
                BufferICDocumentDimension.Insert();
            until TempICPartnerICDocDim.Next() = 0;
        end;
    end;

    procedure PostICCommentLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxCommentLine: Record "IC Comment Line" temporary)
    var
        BufferICCommentLine: Record "Buffer IC Comment Line";
    begin
        if not TempICPartnerICInboxCommentLine.IsEmpty() then begin
            TempICPartnerICInboxCommentLine.FindSet();
            repeat
                BufferICCommentLine.TransferFields(TempICPartnerICInboxCommentLine);
                BufferICCommentLine.Insert();
            until TempICPartnerICInboxCommentLine.Next() = 0;
        end;
    end;

    procedure EnqueueAutoAcceptedICInboxTransaction(ICPartner: Record "IC Partner"; ICInboxTransaction: Record "IC Inbox Transaction")
    var
        ICSetup: Record "IC Setup";
        DescriptionText: Text[250];
    begin
        ICSetup.Get();
        if ICSetup."IC Partner Code" = ICInboxTransaction."IC Partner Code" then
            // This means that the transaction is being manage by the current company
            exit;

        DescriptionText := StrSubstNo(AutoAcceptTransactionJobQueueTxt, ICInboxTransaction."Transaction No.", ICInboxTransaction."IC Partner Code", ICInboxTransaction."Document No.");
        ScheduleCrossEnvironmentJobQueue(Codeunit::"IC Auto Accept JR", JobQueueCategoryCodeAutoAcceptTok, DescriptionText, ICPartner.RecordId());
    end;

    local procedure CheckICPartnerSetup(var ICPartner: Record "IC Partner")
    begin
        if ICPartner."Inbox Type" <> Enum::"IC Partner Inbox Type"::Database then
            Error(WrongICPartnerInboxTypeErr, ICPartner.Code);

        if ICPartner."Data Exchange Type" <> Enum::"IC Data Exchange Type"::API then
            Error(WrongICDataExchangeTypeErr, ICPartner.Code);
    end;

    #region Procedures to populate records from Json
#pragma warning disable AA0139 // Ignore warning about possible overflow from JSON Text
    local procedure PopulateICGLAccountFromJson(IndividualToken: JsonToken; var TempICPartnerICGLAccount: Record "IC G/L Account" temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerICGLAccount.Init();

        TempICPartnerICGLAccount."No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'accountNumber');
        TempICPartnerICGLAccount.Name := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'name');
        TempICPartnerICGLAccount."Account Type" := Enum::"G/L Account Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'accountTypeOrdinal'));
        TempICPartnerICGLAccount."Income/Balance" := "G/L Account Report Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'incomeBalanceIndex'));
        TempICPartnerICGLAccount.Blocked := GetValueFromJsonTokenOrFalse(IndividualToken, 'blocked');

        TempICPartnerICGLAccount.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure PopulateICDimensionFromJson(IndividualToken: JsonToken; var TempICPartnerICDimension: Record "IC Dimension" temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerICDimension.Init();

        TempICPartnerICDimension.Code := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'code');
        TempICPartnerICDimension.Name := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'name');
        TempICPartnerICDimension.Blocked := GetValueFromJsonTokenOrFalse(IndividualToken, 'blocked');

        TempICPartnerICDimension.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure PopulateICDimensionValueFromJson(IndividualToken: JsonToken; var TempICPartnerICDimensionValue: Record "IC Dimension Value" temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerICDimensionValue.Init();

        TempICPartnerICDimensionValue."Dimension Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'dimensionCode');
        TempICPartnerICDimensionValue.Code := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'code');
        TempICPartnerICDimensionValue.Name := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'name');
        TempICPartnerICDimensionValue."Dimension Value Type" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'dimensionValueTypeIndex');
        TempICPartnerICDimensionValue.Blocked := GetValueFromJsonTokenOrFalse(IndividualToken, 'blocked');

        TempICPartnerICDimensionValue.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure PopulateICPartnerFromJson(IndividualToken: JsonToken; var TempRegisteredICPartner: Record "IC Partner" temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempRegisteredICPartner.Init();

        TempRegisteredICPartner.Code := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'partnerCode');
        TempRegisteredICPartner.Name := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'name');
        TempRegisteredICPartner."Currency Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'currencyCode');
        TempRegisteredICPartner."Inbox Type" := Enum::"IC Partner Inbox Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'inboxTypeOrdinal'));
        TempRegisteredICPartner."Inbox Details" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'inboxDetails');
        TempRegisteredICPartner."Receivables Account" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'receivablesAccount');
        TempRegisteredICPartner."Payables Account" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'payablesAccount');
        TempRegisteredICPartner."Country/Region Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'countryRegionCode');
        TempRegisteredICPartner.Blocked := GetValueFromJsonTokenOrFalse(IndividualToken, 'blocked');
        TempRegisteredICPartner."Customer No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'customerNumber');
        TempRegisteredICPartner."Vendor No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'vendorNumber');
        TempRegisteredICPartner."Outbound Sales Item No. Type" := Enum::"IC Outb. Sales Item No. Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'outboundSalesItemNumberTypeOrdinal'));
        TempRegisteredICPartner."Outbound Purch. Item No. Type" := Enum::"IC Outb. Purch. Item No. Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'outboundPurchaseItemNumberTypeOrdinal'));
        TempRegisteredICPartner."Cost Distribution in LCY" := GetValueFromJsonTokenOrFalse(IndividualToken, 'costDistributionInLCY');
        TempRegisteredICPartner."Auto. Accept Transactions" := GetValueFromJsonTokenOrFalse(IndividualToken, 'autoAcceptTransactions');
        TempRegisteredICPartner."Data Exchange Type" := Enum::"IC Data Exchange Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'dataExchangeTypeOrdinal'));

        TempRegisteredICPartner.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure PopulateICSetupFromJson(IndividualToken: JsonToken; var TempICPartnerICSetup: Record "IC Setup" temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerICSetup.Init();

        TempICPartnerICSetup."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        TempICPartnerICSetup."IC Inbox Type" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'icInboxTypeIndex');
        TempICPartnerICSetup."IC Inbox Details" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icInboxDetails');
        TempICPartnerICSetup."Default IC Gen. Jnl. Template" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'defaultICGeneralJournalTemplate');
        TempICPartnerICSetup."Default IC Gen. Jnl. Batch" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'defaultICGeneralJournalBatch');

        TempICPartnerICSetup.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure PopulateGeneralLedgerSetupFromJson(IndividualToken: JsonToken; var TempICPartnerGeneralLedgerSetup: Record "General Ledger Setup" temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerGeneralLedgerSetup.Init();

        TempICPartnerGeneralLedgerSetup."Allow Posting From" := GetValueFromJsonTokenOrToday(IndividualToken, 'allowPostingFrom');
        TempICPartnerGeneralLedgerSetup."Allow Posting To" := GetValueFromJsonTokenOrToday(IndividualToken, 'allowPostingTo');
        TempICPartnerGeneralLedgerSetup."Additional Reporting Currency" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'additionalReportingCurrency');
        TempICPartnerGeneralLedgerSetup."LCY Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'localCurrencyCode');
        TempICPartnerGeneralLedgerSetup."Local Currency Symbol" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'localCurrencySymbol');

        TempICPartnerGeneralLedgerSetup.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure PopulateCompanyInformationFromJson(IndividualToken: JsonToken; var TempICPartnerCompanyInformation: Record "Company Information" temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerCompanyInformation.Init();

        TempICPartnerCompanyInformation.Name := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'displayName');
        TempICPartnerCompanyInformation.Address := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'addressLine1');
        TempICPartnerCompanyInformation."Address 2" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'addressLine2');
        TempICPartnerCompanyInformation.City := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'city');
        TempICPartnerCompanyInformation.County := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'state');
        TempICPartnerCompanyInformation."Country/Region Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'country');
        TempICPartnerCompanyInformation."Post Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'postalCode');
        TempICPartnerCompanyInformation."Phone No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'phoneNumber');

        TempICPartnerCompanyInformation.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    internal procedure PopulateICInboxTransactionFromJson(IndividualToken: JsonToken; var TempICPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerICInboxTransaction.Init();

        TempICPartnerICInboxTransaction."Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionNumber');
        TempICPartnerICInboxTransaction."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        TempICPartnerICInboxTransaction."IC Source Type" := Enum::"IC Transaction Source Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'sourceTypeIndex'));
        TempICPartnerICInboxTransaction."Document Type" := Enum::"IC Transaction Document Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'documentTypeOrdinal'));
        TempICPartnerICInboxTransaction."Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'documentNumber');
        TempICPartnerICInboxTransaction."Posting Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'postingDate');
        TempICPartnerICInboxTransaction."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        TempICPartnerICInboxTransaction."Document Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'documentDate');
        TempICPartnerICInboxTransaction."Line Action" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'lineActionIndex');
        TempICPartnerICInboxTransaction."Original Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'originalDocumentNumber');
        TempICPartnerICInboxTransaction."Source Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'sourceLineNumber');
        TempICPartnerICInboxTransaction."IC Account Type" := Enum::"IC Journal Account Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'icAccountTypeOrdinal'));
        TempICPartnerICInboxTransaction."IC Account No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icAccountNumber');

        TempICPartnerICInboxTransaction.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure PopulateHandledICInboxTransactionFromJson(IndividualToken: JsonToken; var TempICPartnerHandledICInboxTransaction: Record "Handled IC Inbox Trans." temporary)
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerHandledICInboxTransaction.Init();

        TempICPartnerHandledICInboxTransaction."Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionNumber');
        TempICPartnerHandledICInboxTransaction."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        TempICPartnerHandledICInboxTransaction."IC Source Type" := Enum::"IC Transaction Source Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'sourceTypeIndex'));
        TempICPartnerHandledICInboxTransaction."Document Type" := Enum::"IC Transaction Document Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'documentTypeOrdinal'));
        TempICPartnerHandledICInboxTransaction."Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'documentNumber');
        TempICPartnerHandledICInboxTransaction."Posting Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'postingDate');
        TempICPartnerHandledICInboxTransaction."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        TempICPartnerHandledICInboxTransaction."Document Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'documentDate');
        TempICPartnerHandledICInboxTransaction.Status := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'statusIndex');
        TempICPartnerHandledICInboxTransaction."Source Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'sourceLineNumber');
        TempICPartnerHandledICInboxTransaction."IC Account Type" := Enum::"IC Journal Account Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'icAccountTypeOrdinal'));
        TempICPartnerHandledICInboxTransaction."IC Account No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icAccountNumber');

        TempICPartnerHandledICInboxTransaction.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure PopulateBankAccountFromJson(IndividualToken: JsonToken; var TempICPartnerBankAccount: Record "Bank Account" temporary; LCYCurrencyCode: Code[10])
    var
        CurrencyCode: Code[10];
    begin
        ExtractCurrentUserAndChangeToEnglish();
        TempICPartnerBankAccount.Init();

        TempICPartnerBankAccount."No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'number');
        TempICPartnerBankAccount.Name := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'displayName');
        TempICPartnerBankAccount."Bank Account No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'bankAccountNumber');
        TempICPartnerBankAccount.Blocked := GetValueFromJsonTokenOrFalse(IndividualToken, 'blocked');

        IndividualToken.AsObject().Get('currencyCode', AttributeToken);
        CurrencyCode := AttributeToken.AsValue().AsText();
        if CurrencyCode = LCYCurrencyCode then
            TempICPartnerBankAccount."Currency Code" := ''
        else
            TempICPartnerBankAccount."Currency Code" := CurrencyCode;

        TempICPartnerBankAccount.IBAN := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'iban');
        TempICPartnerBankAccount.IntercompanyEnable := GetValueFromJsonTokenOrFalse(IndividualToken, 'intercompanyEnabled');

        TempICPartnerBankAccount.Insert();
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    internal procedure PopulateTransactionDataFromICOutgoingNotification(IndividualObject: JsonObject)
    begin
        IndividualObject.Get('bufferIntercompanyInboxTransactions', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICInboxTransactionFromJson(SelectedToken);

        IndividualObject.Get('bufferIntercompanyInboxJournalLines', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICInboxJournalLineFromJson(SelectedToken);

        IndividualObject.Get('bufferIntercompanyInboxPurchaseHeaders', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICInboxPurchaseHeaderFromJson(SelectedToken);

        IndividualObject.Get('bufferIntercompanyInboxPurchaseLines', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICInboxPurchaseLineFromJson(SelectedToken);

        IndividualObject.Get('bufferIntercompanyInboxSalesHeaders', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICInboxSalesHeaderFromJson(SelectedToken);

        IndividualObject.Get('bufferIntercompanyInboxSalesLines', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICInboxSalesLineFromJson(SelectedToken);

        IndividualObject.Get('bufferIntercompanyInOutJournalLineDimensions', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICInboxOutboxJnlLineDimFromJson(SelectedToken);

        IndividualObject.Get('bufferIntercompanyDocumentDimensions', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICDocumentDimensionFromJson(SelectedToken);

        IndividualObject.Get('bufferIntercompanyCommentLines', AttributeToken);
        foreach SelectedToken in AttributeToken.AsArray() do
            PopulateICCommentLineFromJson(SelectedToken);
    end;

    internal procedure PopulateICInboxTransactionFromJson(IndividualToken: JsonToken)
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        ICInboxTransaction.Init();

        ICInboxTransaction."Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionNumber');
        ICInboxTransaction."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        ICInboxTransaction."IC Source Type" := Enum::"IC Transaction Source Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'sourceTypeIndex'));
        ICInboxTransaction."Document Type" := Enum::"IC Transaction Document Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'documentTypeOrdinal'));
        ICInboxTransaction."Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'documentNumber');
        ICInboxTransaction."Posting Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'postingDate');
        ICInboxTransaction."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        ICInboxTransaction."Document Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'documentDate');
        ICInboxTransaction."Line Action" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'lineActionIndex');
        ICInboxTransaction."Original Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'originalDocumentNumber');
        ICInboxTransaction."Source Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'sourceLineNumber');
        ICInboxTransaction."IC Account Type" := Enum::"IC Journal Account Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'icAccountTypeOrdinal'));
        ICInboxTransaction."IC Account No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icAccountNumber');

        ICInboxTransaction.Insert();
    end;

    local procedure PopulateICInboxJournalLineFromJson(IndividualToken: JsonToken)
    var
        ICInboxJnlLine: Record "IC Inbox Jnl. Line";
    begin
        ICInboxJnlLine.Init();

        ICInboxJnlLine."Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionNumber');
        ICInboxJnlLine."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        ICInboxJnlLine."Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'lineNumber');
        ICInboxJnlLine."Account Type" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'accountTypeIndex');
        ICInboxJnlLine."Account No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'accountNumber');
        ICInboxJnlLine.Amount := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'amount');
        ICInboxJnlLine.Description := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'description');
        ICInboxJnlLine."VAT Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'vatAmount');
        ICInboxJnlLine."Currency Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'currencyCode');
        ICInboxJnlLine."Due Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'dueDate');
        ICInboxJnlLine."Payment Discount %" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'paymentDiscount');
        ICInboxJnlLine."Payment Discount Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'paymentDiscountDate');
        ICInboxJnlLine.Quantity := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'quantity');
        ICInboxJnlLine."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        ICInboxJnlLine."Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'documentNumber');

        ICInboxJnlLine.Insert();
    end;

    local procedure PopulateICInboxPurchaseHeaderFromJson(IndividualToken: JsonToken)
    var
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
    begin
        ICInboxPurchaseHeader.Init();

        ICInboxPurchaseHeader."Document Type" := Enum::"IC Purchase Document Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'documentTypeOrdinal'));
        ICInboxPurchaseHeader."Buy-from Vendor No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'buyFromVendorNumber');
        ICInboxPurchaseHeader."No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'number');
        ICInboxPurchaseHeader."Pay-to Vendor No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'payToVendorNumber');
        ICInboxPurchaseHeader."Ship-to Name" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToName');
        ICInboxPurchaseHeader."Ship-to Address" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToAddress');
        ICInboxPurchaseHeader."Ship-to Address 2" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToAddress2');
        ICInboxPurchaseHeader."Ship-to City" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToCity');
        ICInboxPurchaseHeader."Posting Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'postingDate');
        ICInboxPurchaseHeader."Expected Receipt Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'expectedReceiptDate');
        ICInboxPurchaseHeader."Due Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'dueDate');
        ICInboxPurchaseHeader."Payment Discount %" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'paymentDiscount');
        ICInboxPurchaseHeader."Pmt. Discount Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'paymentDiscountDate');
        ICInboxPurchaseHeader."Currency Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'currencyCode');
        ICInboxPurchaseHeader."Prices Including VAT" := GetValueFromJsonTokenOrFalse(IndividualToken, 'pricesIncludingVat');
        ICInboxPurchaseHeader."Vendor Order No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'vendorOrderNumber');
        ICInboxPurchaseHeader."Vendor Invoice No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'vendorInvoiceNumber');
        ICInboxPurchaseHeader."Vendor Cr. Memo No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'vendorCreditMemoNumber');
        ICInboxPurchaseHeader."Sell-to Customer No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'sellToCustomerNumber');
        ICInboxPurchaseHeader."Ship-to Post Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToPostCode');
        ICInboxPurchaseHeader."Ship-to County" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToCounty');
        ICInboxPurchaseHeader."Ship-to Country/Region Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToCountryRegionCode');
        ICInboxPurchaseHeader."Ship-to Phone No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToPhoneNo');
        ICInboxPurchaseHeader."Document Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'documentDate');
        ICInboxPurchaseHeader."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'intercompanyPartnerCode');
        ICInboxPurchaseHeader."IC Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'intercompanyTransactionNumber');
        ICInboxPurchaseHeader."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        ICInboxPurchaseHeader."Requested Receipt Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'requestedReceiptDate');
        ICInboxPurchaseHeader."Promised Receipt Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'promisedReceiptDate');

        ICInboxPurchaseHeader.Insert();
    end;

    local procedure PopulateICInboxPurchaseLineFromJson(IndividualToken: JsonToken)
    var
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
    begin
        ICInboxPurchaseLine.Init();

        ICInboxPurchaseLine."Document Type" := Enum::"IC Inbox Purchase Document Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'documentTypeOrdinal'));
        ICInboxPurchaseLine."Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'documentNumber');
        ICInboxPurchaseLine."Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'lineNumber');
        ICInboxPurchaseLine.Description := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'description');
        ICInboxPurchaseLine."Description 2" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'description2');
        ICInboxPurchaseLine.Quantity := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'quantity');
        ICInboxPurchaseLine."Direct Unit Cost" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'directUnitCost');
        ICInboxPurchaseLine."Line Discount %" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'lineDiscount');
        ICInboxPurchaseLine."Line Discount Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'lineDiscountAmount');
        ICInboxPurchaseLine."Amount Including VAT" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'amountIncludingVat');
        ICInboxPurchaseLine.Amount := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'amount');
        ICInboxPurchaseLine."Inv. Discount Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'invoiceDiscountAmount');
        ICInboxPurchaseLine."Job No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'jobNumber');
        ICInboxPurchaseLine."Indirect Cost %" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'indirectCost');
        ICInboxPurchaseLine."Receipt No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'receiptNumber');
        ICInboxPurchaseLine."Receipt Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'receiptLineNumber');
        ICInboxPurchaseLine."Drop Shipment" := GetValueFromJsonTokenOrFalse(IndividualToken, 'dropShipment');
        ICInboxPurchaseLine."Currency Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'currencyCode');
        ICInboxPurchaseLine."VAT Base Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'vatBaseAmount');
        ICInboxPurchaseLine."Unit Cost" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'unitCost');
        ICInboxPurchaseLine."Line Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'lineAmount');
        ICInboxPurchaseLine."IC Partner Ref. Type" := Enum::"IC Partner Reference Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'icPartnerReferenceTypeOrdinal'));
        ICInboxPurchaseLine."IC Partner Reference" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerReference');
        ICInboxPurchaseLine."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        ICInboxPurchaseLine."IC Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'icTransactionNumber');
        ICInboxPurchaseLine."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        ICInboxPurchaseLine."Item Ref." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'itemReferenceIndex');
        ICInboxPurchaseLine."IC Item Reference No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icItemReferenceNumber');
        ICInboxPurchaseLine."Unit of Measure Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'unitOfMeasureCode');
        ICInboxPurchaseLine."Requested Receipt Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'requestedReceiptDate');
        ICInboxPurchaseLine."Promised Receipt Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'promisedReceiptDate');
        ICInboxPurchaseLine."Return Shipment No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'returnShipmentNumber');
        ICInboxPurchaseLine."Return Shipment Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'returnShipmentLineNumber');

        ICInboxPurchaseLine.Insert();
    end;

    local procedure PopulateICInboxSalesHeaderFromJson(IndividualToken: JsonToken)
    var
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
    begin
        ICInboxSalesHeader.Init();

        ICInboxSalesHeader."Sell-to Customer No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'sellToCustomerNumber');
        ICInboxSalesHeader."No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'number');
        ICInboxSalesHeader."Bill-to Customer No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'billToCustomerNumber');
        ICInboxSalesHeader."Document Type" := Enum::"IC Sales Document Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'documentTypeOrdinal'));
        ICInboxSalesHeader."Ship-to Name" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToName');
        ICInboxSalesHeader."Ship-to Address" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToAddress');
        ICInboxSalesHeader."Ship-to Address 2" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToAddress2');
        ICInboxSalesHeader."Ship-to City" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToCity');
        ICInboxSalesHeader."Posting Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'postingDate');
        ICInboxSalesHeader."Due Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'dueDate');
        ICInboxSalesHeader."Payment Discount %" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'paymentDiscount');
        ICInboxSalesHeader."Pmt. Discount Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'paymentDiscountDate');
        ICInboxSalesHeader."Currency Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'currencyCode');
        ICInboxSalesHeader."Prices Including VAT" := GetValueFromJsonTokenOrFalse(IndividualToken, 'pricesIncludingVat');
        ICInboxSalesHeader."Ship-to Post Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToPostCode');
        ICInboxSalesHeader."Ship-to County" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToCounty');
        ICInboxSalesHeader."Ship-to Country/Region Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToCountryRegionCode');
        ICInboxSalesHeader."Ship-to Phone No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'shipToPhoneNo');
        ICInboxSalesHeader."Document Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'documentDate');
        ICInboxSalesHeader."External Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'externalDocumentNumber');
        ICInboxSalesHeader."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'intercompanyPartnerCode');
        ICInboxSalesHeader."IC Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'intercompanyTransactionNumber');
        ICInboxSalesHeader."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        ICInboxSalesHeader."Requested Delivery Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'requestedDeliveryDate');
        ICInboxSalesHeader."Promised Delivery Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'promisedDeliveryDate');

        ICInboxSalesHeader.Insert();
    end;

    local procedure PopulateICInboxSalesLineFromJson(IndividualToken: JsonToken)
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
    begin
        ICInboxSalesLine.Init();

        ICInboxSalesLine."Document Type" := Enum::"IC Inbox Sales Document Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'documentTypeOrdinal'));
        ICInboxSalesLine."Document No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'documentNumber');
        ICInboxSalesLine."Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'lineNumber');
        ICInboxSalesLine.Description := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'description');
        ICInboxSalesLine."Description 2" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'description2');
        ICInboxSalesLine.Quantity := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'quantity');
        ICInboxSalesLine."Unit Price" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'unitPrice');
        ICInboxSalesLine."Line Discount %" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'lineDiscount');
        ICInboxSalesLine."Line Discount Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'lineDiscountAmount');
        ICInboxSalesLine."Amount Including VAT" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'amountIncludingVat');
        ICInboxSalesLine.Amount := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'amount');
        ICInboxSalesLine."Inv. Discount Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'invoiceDiscountAmount');
        ICInboxSalesLine."Job No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'jobNumber');
        ICInboxSalesLine."Drop Shipment" := GetValueFromJsonTokenOrFalse(IndividualToken, 'dropShipment');
        ICInboxSalesLine."Currency Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'currencyCode');
        ICInboxSalesLine."VAT Base Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'vatBaseAmount');
        ICInboxSalesLine."Line Amount" := GetValueFromJsonTokenOrDecimalZero(IndividualToken, 'lineAmount');
        ICInboxSalesLine."IC Partner Ref. Type" := Enum::"IC Partner Reference Type".FromInteger(GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'icPartnerReferenceTypeOrdinal'));
        ICInboxSalesLine."IC Partner Reference" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerReference');
        ICInboxSalesLine."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        ICInboxSalesLine."IC Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'icTransactionNumber');
        ICInboxSalesLine."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        ICInboxSalesLine."Item Ref." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'itemReferenceIndex');
        ICInboxSalesLine."IC Item Reference No." := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icItemReferenceNumber');
        ICInboxSalesLine."Unit of Measure Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'unitOfMeasureCode');
        ICInboxSalesLine."Requested Delivery Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'requestedDeliveryDate');
        ICInboxSalesLine."Promised Delivery Date" := GetValueFromJsonTokenOrToday(IndividualToken, 'promisedDeliveryDate');

        ICInboxSalesLine.Insert();
    end;

    local procedure PopulateICInboxOutboxJnlLineDimFromJson(IndividualToken: JsonToken)
    var
        ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
    begin
        ICInboxOutboxJnlLineDim.Init();

        ICInboxOutboxJnlLineDim."Table ID" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'tableId');
        ICInboxOutboxJnlLineDim."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        ICInboxOutboxJnlLineDim."Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionNumber');
        ICInboxOutboxJnlLineDim."Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'lineNumber');
        ICInboxOutboxJnlLineDim."Dimension Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'dimensionCode');
        ICInboxOutboxJnlLineDim."Dimension Value Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'dimensionValueCode');
        ICInboxOutboxJnlLineDim."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');

        ICInboxOutboxJnlLineDim.Insert();
    end;

    local procedure PopulateICDocumentDimensionFromJson(IndividualToken: JsonToken)
    var
        ICDocumentDimension: Record "IC Document Dimension";
    begin
        ICDocumentDimension.Init();

        ICDocumentDimension."Table ID" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'tableId');
        ICDocumentDimension."Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionNumber');
        ICDocumentDimension."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        ICDocumentDimension."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        ICDocumentDimension."Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'lineNumber');
        ICDocumentDimension."Dimension Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'dimensionCode');
        ICDocumentDimension."Dimension Value Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'dimensionValueCode');

        ICDocumentDimension.Insert();
    end;

    local procedure PopulateICCommentLineFromJson(IndividualToken: JsonToken)
    var
        ICCommentLine: Record "IC Comment Line";
    begin
        ICCommentLine.Init();

        ICCommentLine."Table Name" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'tableNameIndex');
        ICCommentLine."Transaction No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionNumber');
        ICCommentLine."IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'icPartnerCode');
        ICCommentLine."Line No." := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'lineNumber');
        ICCommentLine.Date := GetValueFromJsonTokenOrToday(IndividualToken, 'date');
        ICCommentLine.Comment := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'comment');
        ICCommentLine."Transaction Source" := GetValueFromJsonTokenOrIntegerZero(IndividualToken, 'transactionSourceIndex');
        ICCommentLine."Created By IC Partner Code" := GetValueFromJsonTokenOrEmptyText(IndividualToken, 'createdByIcPartnerCode');

        ICCommentLine.Insert();
    end;

    local procedure GetValueFromJsonTokenOrEmptyText(IndividualToken: JsonToken; AttributeName: Text): Text
    begin
        if IndividualToken.AsObject().Get(AttributeName, AttributeToken) then
            exit(AttributeToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetValueFromJsonTokenOrFalse(IndividualToken: JsonToken; AttributeName: Text): Boolean
    begin
        if IndividualToken.AsObject().Get(AttributeName, AttributeToken) then
            exit(AttributeToken.AsValue().AsBoolean());
        exit(false);
    end;

    local procedure GetValueFromJsonTokenOrIntegerZero(IndividualToken: JsonToken; AttributeName: Text): Integer
    begin
        if IndividualToken.AsObject().Get(AttributeName, AttributeToken) then
            exit(AttributeToken.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetValueFromJsonTokenOrDecimalZero(IndividualToken: JsonToken; AttributeName: Text): Decimal
    begin
        if IndividualToken.AsObject().Get(AttributeName, AttributeToken) then
            exit(AttributeToken.AsValue().AsDecimal());
        exit(0);
    end;

    local procedure GetValueFromJsonTokenOrToday(IndividualToken: JsonToken; AttributeName: Text): Date
    begin
        if IndividualToken.AsObject().Get(AttributeName, AttributeToken) then
            exit(AttributeToken.AsValue().AsDate());
        exit(Today);
    end;

    local procedure ExtractCurrentUserAndChangeToEnglish()
    var
        Language: Codeunit Language;
    begin
        CurrentGlobalLanguage := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
    end;
#pragma warning restore AA0139
    #endregion

    internal procedure CreateJsonContentFromICIncomingNotification(var TempICIncomingNotification: Record "IC Incoming Notification" temporary; var ContentJsonText: Text)
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('id', CrossIntercompanyConnector.RemoveCurlyBracketsAndUpperCases(TempICIncomingNotification."Operation ID"));
        LineJson.Add('sourceICPartnerCode', TempICIncomingNotification."Source IC Partner Code");
        LineJson.Add('targetICPartnerCode', TempICIncomingNotification."Target IC Partner Code");
        LineJson.Add('notifiedDateTime', TempICIncomingNotification."Notified DateTime");
        LineJson.WriteTo(ContentJsonText);
    end;

    internal procedure CreateJsonContentFromICOutgoingNotification(var TempICOutgoingNotification: Record "IC Outgoing Notification" temporary; var ContentJsonText: Text)
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('id', CrossIntercompanyConnector.RemoveCurlyBracketsAndUpperCases(TempICOutgoingNotification."Operation ID"));
        LineJson.Add('sourceICPartnerCode', TempICOutgoingNotification."Source IC Partner Code");
        LineJson.Add('targetICPartnerCode', TempICOutgoingNotification."Target IC Partner Code");
        LineJson.WriteTo(ContentJsonText);
    end;

    procedure InsertICIncomingNotification(var ICIncomingNotification: Record "IC Incoming Notification")
    var
        DescriptionText: Text[250];
    begin
        ICIncomingNotification.Status := ICIncomingNotification.Status::Created;
        ICIncomingNotification.SetErrorMessage('');

        DescriptionText := StrSubstNo(ReadOutgoingNotificationJobQueueTxt, ICIncomingNotification."Source IC Partner Code", ICIncomingNotification."Operation ID");
        ScheduleCrossEnvironmentJobQueue(Codeunit::"IC Read Notification JR", JobQueueCategoryCodeReadTransactionTok, DescriptionText);
    end;

    procedure CleanupICOutgoingNotification(var ICOutgoingNotification: Record "IC Outgoing Notification")
    var
        DescriptionText: Text[250];
    begin
        DescriptionText := StrSubstNo(CleanUpOutgoingNotificationJobQueueTxt, ICOutgoingNotification."Target IC Partner Code", ICOutgoingNotification."Operation ID");
        ScheduleCrossEnvironmentJobQueue(Codeunit::"IC Sync. Completed JR", JobQueueCategoryCodeCleanUpTok, DescriptionText);
    end;

    local procedure ScheduleCrossEnvironmentJobQueue(CodeunitID: Integer; CategoryCode: Code[10]; DescriptionText: Text[250])
    var
        BlankRecordId: RecordId;
    begin
        ScheduleCrossEnvironmentJobQueue(CodeunitID, CategoryCode, DescriptionText, BlankRecordId);
    end;

    local procedure CheckJobQueueEntryGeneration(var JobQueueEntry: Record "Job Queue Entry"; RecordIdentification: RecordId): Boolean
    var
        BlankRecordId: RecordId;
        CreateJobQueueEntry: Boolean;
    begin
        CreateJobQueueEntry := true;

        // Check if RecordIdentification is not BlankRecordId, implying it's for an ICPartner
        if RecordIdentification <> BlankRecordId then
            JobQueueEntry.SetRange("Record ID to Process", RecordIdentification);

        // Cancel errored or waiting Job Queue Entries exceeding the limit
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Error, JobQueueEntry.Status::Waiting);
        if JobQueueEntry.Count() >= 2 then begin
            JobQueueEntry.FindSet();
            repeat
                JobQueueEntry.Cancel();
            until JobQueueEntry.Next() = 0;
        end;
        // Limit the number of JQEs per codeunit or per ICPartner
        // If there are at least two JQEs, prevent creating a new one
        JobQueueEntry.SetRange(Status);
        if JobQueueEntry.Count() >= 2 then
            CreateJobQueueEntry := false;

        exit(CreateJobQueueEntry);
    end;

    local procedure ScheduleCrossEnvironmentJobQueue(CodeunitID: Integer; CategoryCode: Code[10]; DescriptionText: Text[250]; RecordIdentification: RecordId)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitID);
        if not CheckJobQueueEntryGeneration(JobQueueEntry, RecordIdentification) then
            exit;
        JobQueueEntry.Reset();
        JobQueueEntry.ReadIsolation := IsolationLevel::ReadCommitted;

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitID;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry."Job Queue Category Code" := CategoryCode;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        Clear(JobQueueEntry."Error Message");
        Clear(JobQueueEntry."Error Message Register Id");
        JobQueueEntry.Description := DescriptionText;
        JobQueueEntry."Record ID to Process" := RecordIdentification;
        JobQueueEntry.Insert(true);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure AssignOperationIDToBufferObjects(var ICInboxTransaction: Record "IC Inbox Transaction"; OperationID: Guid)
    var
        BufferICInboxTransaction: Record "Buffer IC Inbox Transaction";
        BufferICInboxJnlLine: Record "Buffer IC Inbox Jnl. Line";
        BufferICInboxPurchHeader: Record "Buffer IC Inbox Purch Header";
        BufferICInboxPurchaseLine: Record "Buffer IC Inbox Purchase Line";
        BufferICInboxSalesHeader: Record "Buffer IC Inbox Sales Header";
        BufferICInboxSalesLine: Record "Buffer IC Inbox Sales Line";
        BufferICInOutJnlLineDim: Record "Buffer IC InOut Jnl. Line Dim.";
        BufferICDocumentDimension: Record "Buffer IC Document Dimension";
        BufferICCommentLine: Record "Buffer IC Comment Line";
    begin
        if not BufferICInboxTransaction.Get(ICInboxTransaction."Transaction No.", ICInboxTransaction."IC Partner Code", ICInboxTransaction."Transaction Source", ICInboxTransaction."Document Type") then
            exit;
        BufferICInboxTransaction."Operation ID" := OperationID;
        BufferICInboxTransaction.Modify();

        BufferICInboxJnlLine.SetRange("Transaction No.", ICInboxTransaction."Transaction No.");
        BufferICInboxJnlLine.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        BufferICInboxJnlLine.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        if not BufferICInboxJnlLine.IsEmpty() then begin
            BufferICInboxJnlLine.FindSet();
            repeat
                BufferICInboxJnlLine."Operation ID" := OperationID;
                BufferICInboxJnlLine.Modify();
            until BufferICInboxJnlLine.Next() = 0;
        end;

        BufferICInboxPurchHeader.SetRange("IC Transaction No.", ICInboxTransaction."Transaction No.");
        BufferICInboxPurchHeader.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        BufferICInboxPurchHeader.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        if not BufferICInboxPurchHeader.IsEmpty() then begin
            BufferICInboxPurchHeader.FindSet();
            repeat
                BufferICInboxPurchHeader."Operation ID" := OperationID;
                BufferICInboxPurchHeader.Modify();
            until BufferICInboxPurchHeader.Next() = 0;
        end;

        BufferICInboxPurchaseLine.SetRange("IC Transaction No.", ICInboxTransaction."Transaction No.");
        BufferICInboxPurchaseLine.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        BufferICInboxPurchaseLine.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        if not BufferICInboxPurchaseLine.IsEmpty() then begin
            BufferICInboxPurchaseLine.FindSet();
            repeat
                BufferICInboxPurchaseLine."Operation ID" := OperationID;
                BufferICInboxPurchaseLine.Modify();
            until BufferICInboxPurchaseLine.Next() = 0;
        end;

        BufferICInboxSalesHeader.SetRange("IC Transaction No.", ICInboxTransaction."Transaction No.");
        BufferICInboxSalesHeader.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        BufferICInboxSalesHeader.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        if not BufferICInboxSalesHeader.IsEmpty() then begin
            BufferICInboxSalesHeader.FindSet();
            repeat
                BufferICInboxSalesHeader."Operation ID" := OperationID;
                BufferICInboxSalesHeader.Modify();
            until BufferICInboxSalesHeader.Next() = 0;
        end;

        BufferICInboxSalesLine.SetRange("IC Transaction No.", ICInboxTransaction."Transaction No.");
        BufferICInboxSalesLine.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        BufferICInboxSalesLine.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        if not BufferICInboxSalesLine.IsEmpty() then begin
            BufferICInboxSalesLine.FindSet();
            repeat
                BufferICInboxSalesLine."Operation ID" := OperationID;
                BufferICInboxSalesLine.Modify();
            until BufferICInboxSalesLine.Next() = 0;
        end;

        BufferICInOutJnlLineDim.SetRange("Transaction No.", ICInboxTransaction."Transaction No.");
        BufferICInOutJnlLineDim.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        BufferICInOutJnlLineDim.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        if not BufferICInOutJnlLineDim.IsEmpty() then begin
            BufferICInOutJnlLineDim.FindSet();
            repeat
                BufferICInOutJnlLineDim."Operation ID" := OperationID;
                BufferICInOutJnlLineDim.Modify();
            until BufferICInOutJnlLineDim.Next() = 0;
        end;

        BufferICDocumentDimension.SetRange("Transaction No.", ICInboxTransaction."Transaction No.");
        BufferICDocumentDimension.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        BufferICDocumentDimension.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        if not BufferICDocumentDimension.IsEmpty() then begin
            BufferICDocumentDimension.FindSet();
            repeat
                BufferICDocumentDimension."Operation ID" := OperationID;
                BufferICDocumentDimension.Modify();
            until BufferICDocumentDimension.Next() = 0;
        end;

        BufferICCommentLine.SetRange("Transaction No.", ICInboxTransaction."Transaction No.");
        BufferICCommentLine.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        BufferICCommentLine.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        if not BufferICCommentLine.IsEmpty() then begin
            BufferICCommentLine.FindSet();
            repeat
                BufferICCommentLine."Operation ID" := OperationID;
                BufferICCommentLine.Modify();
            until BufferICCommentLine.Next() = 0;
        end;
    end;

    local procedure IsCrossEnvironmentPartner(PartnerCompanyName: Text): Boolean
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.LoadFields("Data Exchange Type");
        ICPartner.ReadIsolation := IsolationLevel::ReadCommitted;
        ICPartner.SetRange(Name, PartnerCompanyName);
        if ICPartner.FindFirst() then
            exit(ICPartner."Data Exchange Type" = Enum::"IC Data Exchange Type"::API);
        exit(false);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Move IC Trans. to Partner Comp", 'OnICInboxTransactionCreated', '', false, false)]
    local procedure OnAfterICInboxTransactionMovedToBuffer(var Sender: Report "Move IC Trans. to Partner Comp"; var ICInboxTransaction: Record "IC Inbox Transaction"; PartnerCompanyName: Text)
    var
        ICOutgoingNotification: Record "IC Outgoing Notification";
        ICSetup: Record "IC Setup";
        DescriptionText: Text[250];
        OperationID: Guid;
    begin
        if not IsCrossEnvironmentPartner(PartnerCompanyName) then
            exit;

        if ICInboxTransaction.IsEmpty() then
            exit;

        OperationID := CreateGuid();
        AssignOperationIDToBufferObjects(ICInboxTransaction, OperationID);

        ICSetup.LoadFields("IC Partner Code");
        ICSetup.ReadIsolation := IsolationLevel::ReadCommitted;
        ICSetup.Get();
        ICOutgoingNotification."Operation ID" := OperationID;
        ICOutgoingNotification."Source IC Partner Code" := ICSetup."IC Partner Code";
        ICOutgoingNotification."Target IC Partner Code" := Sender.GetCurrentPartnerCode();
        ICOutgoingNotification.Status := ICOutgoingNotification.Status::Created;
        ICOutgoingNotification."Notified DateTime" := CurrentDateTime();
        ICOutgoingNotification.SetErrorMessage('');
        ICOutgoingNotification.Insert();

        DescriptionText := StrSubstNo(SendNotificationJobQueueTxt, ICOutgoingNotification."Target IC Partner Code", ICOutgoingNotification."Operation ID");
        ScheduleCrossEnvironmentJobQueue(Codeunit::"IC New Notification JR", JobQueueCategoryCodeSendNotificationTok, DescriptionText);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IC Data Exchange API", 'OnPopulateTransactionDataFromICOutgoingNotification', '', false, false)]
    local procedure HandledOnPopulate(IndividualObject: JsonObject; var Success: Boolean)
    begin
        PopulateTransactionDataFromICOutgoingNotification(IndividualObject);
        Success := true;
    end;

    [InternalEvent(false, true)]
    internal procedure OnPopulateTransactionDataFromICOutgoingNotification(IndividualObject: JsonObject; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostICPurchaseHeaderToICPartnerInboxOnBeforeBufferICInboxPurchaseHeaderInsert(var BufferICInboxPurchaseHeader: Record "Buffer IC Inbox Purch Header"; TempICPartnerICInboxPurchaseHeader: Record "IC Inbox Purchase Header" temporary; ICPartner: Record "IC Partner"; RegisteredPartner: Record "IC Partner" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostICSalesHeaderToICPartnerInboxOnBeforeBufferICInboxSalesHeaderInsert(var BufferICInboxSalesHeader: Record "Buffer IC Inbox Sales Header"; TempICPartnerICInboxSalesHeader: Record "IC Inbox Sales Header" temporary; ICPartner: Record "IC Partner"; RegisteredPartner: Record "IC Partner" temporary)
    begin
    end;
}