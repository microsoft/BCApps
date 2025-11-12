// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using System.Threading;
using System.Telemetry;

codeunit 532 "IC Data Exchange Database" implements "IC Data Exchange"
{
    Access = Internal;

    var
        FailedToChangeCompanyErr: Label 'It was not possible to find the %1 of partner %2.', Comment = '%1 = Table caption, %2 = Partner Code';
        MissingPermissionToReadTableErr: Label 'You do not have the necessary permissions to access the %1 of partner %2.', Comment = '%1 = Table caption, %2 = Partner Code';
        ICPartnerMissingCurrentCompanyErr: Label 'The current company is not registered as a partner in the list of partners of company %1', Comment = '%1 = Partner company name';
        PartnerMissingTableSetupErr: Label 'Partner %1 has not completed the information required at table %2 for using intercompany.', Comment = '%1 = Partner code, %2 = Table caption';
        ICTransactionAlreadyExistMsg: Label '%1 %2 to IC Partner %3 already exists in the IC inbox of IC Partner %3. IC Partner %3 must complete the line action for transaction %2 in their IC inbox.', Comment = '%1 = Field caption, %2 = field value, %3 = IC Partner code';
        JobQueueCategoryCodeTxt: Label 'ICAUTOACC', Locked = true;
        AutoAcceptTransactionTxt: Label 'Auto. accept transaction %1 of partner %2 for document %3', Comment = '%1 = Transaction ID, %2 = Partner Code, %3 = Document No.';
        ICDataExchangeDatabaseFeatureTelemetryNameTok: Label 'Intercompany Data Exchange Database', Locked = true;
        SentTransactionTelemetryTxt: Label 'Transaction sent to IC Partner %1 from source %2.', Comment = '%1 = Target IC Partner Code, %2 = Source IC Partner Code';

    procedure GetICPartnerICGLAccount(ICPartner: Record "IC Partner"; var TempICPartnerICGLAccount: Record "IC G/L Account" temporary)
    var
        ICPartnerICGLAccount: Record "IC G/L Account";
    begin
        TempICPartnerICGLAccount.Reset();
        TempICPartnerICGLAccount.DeleteAll();

        if not ICPartnerICGLAccount.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, ICPartnerICGLAccount.TableCaption, ICPartner.Name);

        if not ICPartnerICGLAccount.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerICGLAccount.TableCaption, ICPartner.Name);

        ICPartnerICGLAccount.ReadIsolation := IsolationLevel::ReadCommitted;
        if ICPartnerICGLAccount.IsEmpty() then
            exit;

        ICPartnerICGLAccount.FindSet();
        repeat
            TempICPartnerICGLAccount.TransferFields(ICPartnerICGLAccount, true);
            TempICPartnerICGLAccount.Insert();
        until ICPartnerICGLAccount.Next() = 0;
    end;

    procedure GetICPartnerICDimension(ICPartner: Record "IC Partner"; var TempICPartnerICDimension: Record "IC Dimension" temporary)
    var
        ICPartnerICDimension: Record "IC Dimension";
    begin
        TempICPartnerICDimension.Reset();
        TempICPartnerICDimension.DeleteAll();

        if not ICPartnerICDimension.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, ICPartnerICDimension.TableCaption, ICPartner.Name);

        if not ICPartnerICDimension.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerICDimension.TableCaption, ICPartner.Name);

        ICPartnerICDimension.ReadIsolation := IsolationLevel::ReadCommitted;
        if ICPartnerICDimension.IsEmpty() then
            exit;

        ICPartnerICDimension.FindSet();
        repeat
            TempICPartnerICDimension.TransferFields(ICPartnerICDimension, true);
            TempICPartnerICDimension.Insert();
        until ICPartnerICDimension.Next() = 0;
    end;

    procedure GetICPartnerICDimensionValue(ICPartner: Record "IC Partner"; var TempICPartnerICDimensionValue: Record "IC Dimension Value" temporary)
    var
        ICPartnerICDimensionValue: Record "IC Dimension Value";
    begin
        TempICPartnerICDimensionValue.Reset();
        TempICPartnerICDimensionValue.DeleteAll();

        if not ICPartnerICDimensionValue.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, ICPartnerICDimensionValue.TableCaption, ICPartner.Name);

        if not ICPartnerICDimensionValue.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerICDimensionValue.TableCaption, ICPartner.Name);

        ICPartnerICDimensionValue.ReadIsolation := IsolationLevel::ReadCommitted;
        if ICPartnerICDimensionValue.IsEmpty() then
            exit;

        ICPartnerICDimensionValue.FindSet();
        repeat
            TempICPartnerICDimensionValue.TransferFields(ICPartnerICDimensionValue, true);
            TempICPartnerICDimensionValue.Insert();
        until ICPartnerICDimensionValue.Next() = 0;
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
        RegisteredICPartner: Record "IC Partner";
    begin
        TempRegisteredICPartner.Reset();
        TempRegisteredICPartner.DeleteAll();

        if not RegisteredICPartner.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, RegisteredICPartner.TableCaption, ICPartner.Name);

        if not RegisteredICPartner.ReadPermission() then
            Error(MissingPermissionToReadTableErr, RegisteredICPartner.TableCaption, ICPartner.Name);

        RegisteredICPartner.ReadIsolation := IsolationLevel::ReadCommitted;
        if not RegisteredICPartner.Get(ICPartnerCode) then
            Error(ICPartnerMissingCurrentCompanyErr, ICPartner."Inbox Details");

        TempRegisteredICPartner.TransferFields(RegisteredICPartner, true);
        TempRegisteredICPartner.Insert();
    end;

    procedure GetICPartnerICSetup(ICPartner: Record "IC Partner"; var TempICPartnerICSetup: Record "IC Setup" temporary)
    begin
        GetICPartnerICSetup(ICPartner."Inbox Details", TempICPartnerICSetup);
    end;

    procedure GetICPartnerICSetup(ICPartnerName: Text; var TempICPartnerICSetup: Record "IC Setup" temporary)
    var
        ICPartnerICSetup: Record "IC Setup";
    begin
        TempICPartnerICSetup.Reset();
        TempICPartnerICSetup.DeleteAll();

        if not ICPartnerICSetup.ChangeCompany(ICPartnerName) then
            Error(FailedToChangeCompanyErr, ICPartnerICSetup.TableCaption, ICPartnerName);

        if not ICPartnerICSetup.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerICSetup.TableCaption, ICPartnerName);

        ICPartnerICSetup.ReadIsolation := IsolationLevel::ReadCommitted;
        if not ICPartnerICSetup.Get() then begin
            if System.GuiAllowed() then
                Message(PartnerMissingTableSetupErr, ICPartnerName, ICPartnerICSetup.TableCaption);
            exit;
        end;

        TempICPartnerICSetup.TransferFields(ICPartnerICSetup, true);
        TempICPartnerICSetup.Insert();
    end;

    procedure GetICPartnerGeneralLedgerSetup(ICPartner: Record "IC Partner"; var TempICPartnerGeneralLedgerSetup: Record "General Ledger Setup" temporary)
    begin
        GetICPartnerGeneralLedgerSetup(ICPartner."Inbox Details", TempICPartnerGeneralLedgerSetup);
    end;

    procedure GetICPartnerGeneralLedgerSetup(ICPartnerName: Text; var TempICPartnerGeneralLedgerSetup: Record "General Ledger Setup" temporary)
    var
        ICPartnerGeneralLedgerSetup: Record "General Ledger Setup";
    begin
        TempICPartnerGeneralLedgerSetup.Reset();
        TempICPartnerGeneralLedgerSetup.DeleteAll();

        if not ICPartnerGeneralLedgerSetup.ChangeCompany(ICPartnerName) then
            Error(FailedToChangeCompanyErr, ICPartnerGeneralLedgerSetup.TableCaption, ICPartnerName);

        if not ICPartnerGeneralLedgerSetup.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerGeneralLedgerSetup.TableCaption, ICPartnerName);

        ICPartnerGeneralLedgerSetup.ReadIsolation := IsolationLevel::ReadCommitted;
        if not ICPartnerGeneralLedgerSetup.Get() then begin
            if System.GuiAllowed() then
                Message(PartnerMissingTableSetupErr, ICPartnerName, ICPartnerGeneralLedgerSetup.TableCaption);
            exit;
        end;

        TempICPartnerGeneralLedgerSetup.TransferFields(ICPartnerGeneralLedgerSetup, true);
        TempICPartnerGeneralLedgerSetup.Insert();
    end;

    procedure GetICPartnerCompanyInformation(ICPartner: Record "IC Partner"; var TempICPartnerCompanyInformation: Record "Company Information" temporary)
    begin
        GetICPartnerCompanyInformation(ICPartner."Inbox Details", TempICPartnerCompanyInformation);
    end;

    procedure GetICPartnerCompanyInformation(ICPartnerName: Text; var TempICPartnerCompanyInformation: Record "Company Information" temporary)
    var
        ICPartnerCompanyInformation: Record "Company Information";
    begin
        TempICPartnerCompanyInformation.Reset();
        TempICPartnerCompanyInformation.DeleteAll();

        if not ICPartnerCompanyInformation.ChangeCompany(ICPartnerName) then
            Error(FailedToChangeCompanyErr, ICPartnerCompanyInformation.TableCaption, ICPartnerName);

        if not ICPartnerCompanyInformation.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerCompanyInformation.TableCaption, ICPartnerName);

        ICPartnerCompanyInformation.ReadIsolation := IsolationLevel::ReadCommitted;
        if not ICPartnerCompanyInformation.Get() then begin
            if System.GuiAllowed() then
                Message(PartnerMissingTableSetupErr, ICPartnerName, ICPartnerCompanyInformation.TableCaption);
            exit;
        end;

        TempICPartnerCompanyInformation.TransferFields(ICPartnerCompanyInformation, true);
        TempICPartnerCompanyInformation.Insert();
    end;

    procedure GetICPartnerBankAccount(ICPartner: Record "IC Partner"; var TempICPartnerBankAccount: Record "Bank Account" temporary)
    var
        ICPartnerBankAccount: Record "Bank Account";
    begin
        TempICPartnerBankAccount.Reset();
        TempICPartnerBankAccount.DeleteAll();

        if not ICPartnerBankAccount.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, ICPartnerBankAccount.TableCaption, ICPartner.Name);

        if not ICPartnerBankAccount.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerBankAccount.TableCaption, ICPartner.Name);

        ICPartnerBankAccount.ReadIsolation := IsolationLevel::ReadCommitted;
        if ICPartnerBankAccount.IsEmpty() then
            exit;

        ICPartnerBankAccount.FindSet();
        repeat
            TempICPartnerBankAccount.TransferFields(ICPartnerBankAccount, true);
            TempICPartnerBankAccount.Insert();
        until ICPartnerBankAccount.Next() = 0;
    end;

    procedure GetICPartnerICInboxTransaction(ICPartner: Record "IC Partner"; var TempICPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary)
    var
        ICPartnerICInboxTransaction: Record "IC Inbox Transaction";
    begin
        TempICPartnerICInboxTransaction.Reset();
        TempICPartnerICInboxTransaction.DeleteAll();

        if not ICPartnerICInboxTransaction.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, ICPartnerICInboxTransaction.TableCaption, ICPartner.Name);

        if not ICPartnerICInboxTransaction.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerICInboxTransaction.TableCaption, ICPartner.Name);

        ICPartnerICInboxTransaction.ReadIsolation := IsolationLevel::ReadCommitted;
        if ICPartnerICInboxTransaction.IsEmpty() then
            exit;

        ICPartnerICInboxTransaction.FindSet();
        repeat
            TempICPartnerICInboxTransaction.TransferFields(ICPartnerICInboxTransaction, true);
            TempICPartnerICInboxTransaction.Insert();
        until ICPartnerICInboxTransaction.Next() = 0;
    end;

    procedure GetICPartnerHandledICInboxTransaction(ICPartner: Record "IC Partner"; var TempICPartnerHandledICInboxTransaction: Record "Handled IC Inbox Trans." temporary)
    var
        ICPartnerHandledICInboxTransaction: Record "Handled IC Inbox Trans.";
    begin
        TempICPartnerHandledICInboxTransaction.Reset();
        TempICPartnerHandledICInboxTransaction.DeleteAll();

        if not ICPartnerHandledICInboxTransaction.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, ICPartnerHandledICInboxTransaction.TableCaption, ICPartner.Name);

        if not ICPartnerHandledICInboxTransaction.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartnerHandledICInboxTransaction.TableCaption, ICPartner.Name);

        ICPartnerHandledICInboxTransaction.ReadIsolation := IsolationLevel::ReadCommitted;
        if ICPartnerHandledICInboxTransaction.IsEmpty() then
            exit;

        ICPartnerHandledICInboxTransaction.FindSet();
        repeat
            TempICPartnerHandledICInboxTransaction.TransferFields(ICPartnerHandledICInboxTransaction, true);
            TempICPartnerHandledICInboxTransaction.Insert();
        until ICPartnerHandledICInboxTransaction.Next() = 0;
    end;

    procedure PostICTransactionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary)
    var
        PartnerInboxTransaction: Record "IC Inbox Transaction";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not PartnerInboxTransaction.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerInboxTransaction.TableCaption, ICPartner.Name);

        if not PartnerInboxTransaction.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerInboxTransaction.TableCaption, ICPartner.Name);

        if not TempICPartnerICInboxTransaction.IsEmpty() then begin
            TempICPartnerICInboxTransaction.FindSet();
            repeat
                CustomDimensions.Add('Transaction Details', StrSubstNo(SentTransactionTelemetryTxt, ICPartner.Code, TempICPartnerICInboxTransaction."IC Partner Code"));
                FeatureTelemetry.LogUsage('0000LKS', ICMapping.GetFeatureTelemetryName(), ICDataExchangeDatabaseFeatureTelemetryNameTok, CustomDimensions);
                PartnerInboxTransaction.TransferFields(TempICPartnerICInboxTransaction, true);
                if not PartnerInboxTransaction.Insert() then
                    Error(
                      ICTransactionAlreadyExistMsg, PartnerInboxTransaction.FieldCaption("Transaction No."),
                      PartnerInboxTransaction."Transaction No.",
                      PartnerInboxTransaction."IC Partner Code");
            until TempICPartnerICInboxTransaction.Next() = 0;
        end;
    end;

    procedure PostICJournalLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxJnlLine: Record "IC Inbox Jnl. Line" temporary)
    var
        PartnerInboxJnlLine: Record "IC Inbox Jnl. Line";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if not PartnerInboxJnlLine.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerInboxJnlLine.TableCaption, ICPartner.Name);

        if not PartnerInboxJnlLine.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerInboxJnlLine.TableCaption, ICPartner.Name);

        if not TempICPartnerICInboxJnlLine.IsEmpty() then begin
            TempICPartnerICInboxJnlLine.FindSet();
            repeat
                PartnerInboxJnlLine.TransferFields(TempICPartnerICInboxJnlLine, true);
                if PartnerInboxJnlLine."Currency Code" = '' then
                    PartnerInboxJnlLine."Currency Code" := GLSetup."LCY Code";
                if PartnerInboxJnlLine."Currency Code" = ICPartner."Currency Code" then
                    PartnerInboxJnlLine."Currency Code" := '';
                PartnerInboxJnlLine.Insert();
            until TempICPartnerICInboxJnlLine.Next() = 0;
        end;
    end;

    procedure PostICPurchaseHeaderToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxPurchaseHeader: Record "IC Inbox Purchase Header" temporary; var RegisteredPartner: Record "IC Partner" temporary)
    var
        PartnerInboxPurchHeader: Record "IC Inbox Purchase Header";
    begin
        if not PartnerInboxPurchHeader.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerInboxPurchHeader.TableCaption, ICPartner.Name);

        if not PartnerInboxPurchHeader.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerInboxPurchHeader.TableCaption, ICPartner.Name);

        if not TempICPartnerICInboxPurchaseHeader.IsEmpty() then begin
            TempICPartnerICInboxPurchaseHeader.FindSet();
            repeat
                PartnerInboxPurchHeader.TransferFields(TempICPartnerICInboxPurchaseHeader, true);
                PartnerInboxPurchHeader."Buy-from Vendor No." := RegisteredPartner."Vendor No.";
                PartnerInboxPurchHeader."Pay-to Vendor No." := RegisteredPartner."Vendor No.";
                PartnerInboxPurchHeader.Insert();
            until TempICPartnerICInboxPurchaseHeader.Next() = 0;
        end;
    end;

    procedure PostICPurchaseLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxPurchaseLine: Record "IC Inbox Purchase Line" temporary)
    var
        PartnerInboxPurchLine: Record "IC Inbox Purchase Line";
    begin
        if not PartnerInboxPurchLine.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerInboxPurchLine.TableCaption, ICPartner.Name);

        if not PartnerInboxPurchLine.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerInboxPurchLine.TableCaption, ICPartner.Name);

        if not TempICPartnerICInboxPurchaseLine.IsEmpty() then begin
            TempICPartnerICInboxPurchaseLine.FindSet();
            repeat
                PartnerInboxPurchLine.TransferFields(TempICPartnerICInboxPurchaseLine, true);
                PartnerInboxPurchLine.Insert();
            until TempICPartnerICInboxPurchaseLine.Next() = 0;
        end;
    end;

    procedure PostICSalesHeaderToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxSalesHeader: Record "IC Inbox Sales Header" temporary; var RegisteredPartner: Record "IC Partner" temporary)
    var
        PartnerInboxSalesHeader: Record "IC Inbox Sales Header";
    begin
        if not PartnerInboxSalesHeader.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerInboxSalesHeader.TableCaption, ICPartner.Name);

        if not PartnerInboxSalesHeader.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerInboxSalesHeader.TableCaption, ICPartner.Name);

        if not TempICPartnerICInboxSalesHeader.IsEmpty() then begin
            TempICPartnerICInboxSalesHeader.FindSet();
            repeat
                PartnerInboxSalesHeader.TransferFields(TempICPartnerICInboxSalesHeader, true);
                PartnerInboxSalesHeader."Sell-to Customer No." := RegisteredPartner."Customer No.";
                PartnerInboxSalesHeader."Bill-to Customer No." := RegisteredPartner."Customer No.";
                PartnerInboxSalesHeader.Insert();
            until TempICPartnerICInboxSalesHeader.Next() = 0;
        end;
    end;

    procedure PostICSalesLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxSalesLine: Record "IC Inbox Sales Line" temporary)
    var
        PartnerInboxSalesLine: Record "IC Inbox Sales Line";
    begin
        if not PartnerInboxSalesLine.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerInboxSalesLine.TableCaption, ICPartner.Name);

        if not PartnerInboxSalesLine.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerInboxSalesLine.TableCaption, ICPartner.Name);

        if not TempICPartnerICInboxSalesLine.IsEmpty() then begin
            TempICPartnerICInboxSalesLine.FindSet();
            repeat
                PartnerInboxSalesLine.TransferFields(TempICPartnerICInboxSalesLine, true);
                PartnerInboxSalesLine.Insert();
            until TempICPartnerICInboxSalesLine.Next() = 0;
        end;
    end;

    procedure PostICJournalLineDimensionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary)
    var
        PartnerInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
    begin
        if not PartnerInboxOutboxJnlLineDim.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerInboxOutboxJnlLineDim.TableCaption, ICPartner.Name);

        if not PartnerInboxOutboxJnlLineDim.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerInboxOutboxJnlLineDim.TableCaption, ICPartner.Name);

        if not TempICPartnerICInboxOutboxJnlLineDim.IsEmpty() then begin
            TempICPartnerICInboxOutboxJnlLineDim.FindSet();
            repeat
                PartnerInboxOutboxJnlLineDim.TransferFields(TempICPartnerICInboxOutboxJnlLineDim, true);
                PartnerInboxOutboxJnlLineDim.Insert();
            until TempICPartnerICInboxOutboxJnlLineDim.Next() = 0;
        end;
    end;

    procedure PostICDocumentDimensionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICDocDim: Record "IC Document Dimension" temporary)
    var
        PartnerICDocDim: Record "IC Document Dimension";
    begin
        if not PartnerICDocDim.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerICDocDim.TableCaption, ICPartner.Name);

        if not PartnerICDocDim.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerICDocDim.TableCaption, ICPartner.Name);

        if not TempICPartnerICDocDim.IsEmpty() then begin
            TempICPartnerICDocDim.FindSet();
            repeat
                PartnerICDocDim.TransferFields(TempICPartnerICDocDim, true);
                PartnerICDocDim.Insert();
            until TempICPartnerICDocDim.Next() = 0;
        end;
    end;

    procedure PostICCommentLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxCommentLine: Record "IC Comment Line" temporary)
    var
        PartnerICCommentLine: Record "IC Comment Line";
    begin
        if not PartnerICCommentLine.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnerICCommentLine.TableCaption, ICPartner.Name);

        if not PartnerICCommentLine.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnerICCommentLine.TableCaption, ICPartner.Name);

        if not TempICPartnerICInboxCommentLine.IsEmpty() then begin
            TempICPartnerICInboxCommentLine.FindSet();
            repeat
                PartnerICCommentLine.TransferFields(TempICPartnerICInboxCommentLine, true);
                PartnerICCommentLine.Insert();
            until TempICPartnerICInboxCommentLine.Next() = 0;
        end;
    end;

    procedure EnqueueAutoAcceptedICInboxTransaction(ICPartner: Record "IC Partner"; ICInboxTransaction: Record "IC Inbox Transaction")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not JobQueueEntry.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, JobQueueEntry.TableCaption, ICPartner.Name);

        if not JobQueueEntry.ReadPermission() then
            Error(MissingPermissionToReadTableErr, JobQueueEntry.TableCaption, ICPartner.Name);

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"IC Inbox Outbox Subs. Runner";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry."Record ID to Process" := ICInboxTransaction.RecordId;
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryCodeTxt;
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Description := StrSubstNo(AutoAcceptTransactionTxt, ICInboxTransaction."Transaction No.", ICInboxTransaction."IC Partner Code", ICInboxTransaction."Document No.");
        JobQueueEntry.Insert(true);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;
}
