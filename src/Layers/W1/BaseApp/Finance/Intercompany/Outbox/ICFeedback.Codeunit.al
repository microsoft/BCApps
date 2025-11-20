// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Intercompany;

codeunit 404 "IC Feedback"
{
    var
        CreatedTransactionWaitingInOutboxMsg: Label 'An entry for document %1 has been created as an intercompany transaction. The entry awaits a manual check in the Intercompany Outbox before being sent.', Comment = '%1 = Document No.';
        CreatedMultipleTransactionsWaitingInOutboxMsg: Label 'Multiple entries have been created as intercompany transactions. Multiple entries have been created as intercompany transactions. The entries await a manual check in the Intercompany Outbox before being sent.';
        CreatedAndSentTransactionMsg: Label 'An entry for document %1 has been created as an intercompany transaction. The entry was automatically sent to IC partner %2.', Comment = '%1 = Document No., %2 = IC Partner No.';
        CreatedAndSentMultipleTransactionsMsg: Label 'Multiple entries have been created as intercompany transactions. The entries were automatically sent to their corresponding IC partners.';

    procedure ShowIntercompanyMessage(PurchaseHeader: Record "Purchase Header"; ICTransactionDocumentType: Enum "IC Transaction Document Type")
    begin
        ShowIntercompanyMessage(PurchaseHeader, ICTransactionDocumentType, PurchaseHeader."No.");
    end;

    procedure ShowIntercompanyMessage(PurchaseHeader: Record "Purchase Header"; ICTransactionDocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20])
    var
        ICSetup: Record "IC Setup";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICPartnerCode: Code[20];
    begin
        if GuiAllowed() then begin
            if PurchaseHeader."Pay-to IC Partner Code" <> '' then
                ICPartnerCode := PurchaseHeader."Pay-to IC Partner Code"
            else
                ICPartnerCode := PurchaseHeader."Buy-from IC Partner Code";
            if ICPartnerCode = '' then
                exit;
            if (not ICSetup.FindFirst()) or (not ICSetup."Transaction Notifications") then
                exit;


            if ICSetup."Auto. Send Transactions" then begin
                if ExistsInICHandledOutbox(ICPartnerCode, ICOutboxTransaction."IC Source Type"::"Purchase Document", ICTransactionDocumentType, DocumentNo, PurchaseHeader."Posting Date", PurchaseHeader."Document Date") then
                    Message(CreatedAndSentTransactionMsg, DocumentNo, ICPartnerCode);
            end
            else
                if ExistsInICOutbox(ICPartnerCode, ICOutboxTransaction."IC Source Type"::"Purchase Document", ICTransactionDocumentType, DocumentNo, PurchaseHeader."Posting Date", PurchaseHeader."Document Date") then
                    Message(CreatedTransactionWaitingInOutboxMsg, DocumentNo);
        end;
    end;

    procedure ShowIntercompanyMessage(SalesHeader: Record "Sales Header"; ICTransactionDocumentType: Enum "IC Transaction Document Type")
    begin
        ShowIntercompanyMessage(SalesHeader, ICTransactionDocumentType, SalesHeader."No.");
    end;

    procedure ShowIntercompanyMessage(SalesHeader: Record "Sales Header"; ICTransactionDocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20])
    var
        ICSetup: Record "IC Setup";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICPartnerCode: Code[20];
    begin
        if GuiAllowed() then begin
            if SalesHeader."Sell-to IC Partner Code" <> '' then
                ICPartnerCode := SalesHeader."Sell-to IC Partner Code"
            else
                ICPartnerCode := SalesHeader."Bill-to IC Partner Code";
            if ICPartnerCode = '' then
                exit;
            if (not ICSetup.FindFirst()) or (not ICSetup."Transaction Notifications") then
                exit;

            if ICSetup."Auto. Send Transactions" then begin
                if ExistsInICHandledOutbox(ICPartnerCode, ICOutboxTransaction."IC Source Type"::"Sales Document", ICTransactionDocumentType, DocumentNo, SalesHeader."Posting Date", SalesHeader."Document Date") then
                    Message(CreatedAndSentTransactionMsg, DocumentNo, ICPartnerCode);
            end
            else
                if ExistsInICOutbox(ICPartnerCode, ICOutboxTransaction."IC Source Type"::"Sales Document", ICTransactionDocumentType, DocumentNo, SalesHeader."Posting Date", SalesHeader."Document Date") then
                    Message(CreatedTransactionWaitingInOutboxMsg, DocumentNo);
        end;
    end;

    internal procedure ShowIntercompanyMessage(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; ICProccessedLines: Integer)
    var
        ICSetup: Record "IC Setup";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        if (not ICSetup.FindFirst()) or (not ICSetup."Transaction Notifications") then
            exit;

        if ICSetup."Auto. Send Transactions" then begin
            if ExistsInICHandledOutbox(GenJournalLine."IC Partner Code", ICOutboxTransaction."IC Source Type"::Journal, "IC Transaction Document Type"::" ", GenJournalLine."Document No.", GenJournalLine."Posting Date", GenJournalLine."Document Date") then
                if ICProccessedLines = 1 then
                    Message(CreatedAndSentTransactionMsg, DocumentNo, GenJournalLine."IC Partner Code")
                else
                    Message(CreatedAndSentMultipleTransactionsMsg);
        end
        else
            if ExistsInICOutbox(GenJournalLine."IC Partner Code", ICOutboxTransaction."IC Source Type"::Journal, "IC Transaction Document Type"::" ", GenJournalLine."Document No.", GenJournalLine."Posting Date", GenJournalLine."Document Date") then
                if ICProccessedLines = 1 then
                    Message(CreatedTransactionWaitingInOutboxMsg, DocumentNo)
                else
                    Message(CreatedMultipleTransactionsWaitingInOutboxMsg);
    end;

    local procedure ExistsInICOutbox(ICPartnerCode: Code[20]; SourceType: Enum "IC Transaction Source Type"; ICTransactionDocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20]; PostingDate: Date; DocumentDate: Date): Boolean
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        ICOutboxTransaction.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxTransaction.SetRange("IC Source Type", SourceType);
        ICOutboxTransaction.SetRange("Document Type", ICTransactionDocumentType);
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("Posting Date", PostingDate);
        ICOutboxTransaction.SetRange("Document Date", DocumentDate);
        exit(not ICOutboxTransaction.IsEmpty());
    end;

    local procedure ExistsInICHandledOutbox(ICPartnerCode: Code[20]; SourceType: Enum "IC Transaction Source Type"; ICTransactionDocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20]; PostingDate: Date; DocumentDate: Date): Boolean
    var
        HandledICOutboxTransaction: Record "Handled IC Outbox Trans.";
    begin
        HandledICOutboxTransaction.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTransaction.SetRange("IC Source Type", SourceType);
        HandledICOutboxTransaction.SetRange("Document Type", ICTransactionDocumentType);
        HandledICOutboxTransaction.SetRange("Document No.", DocumentNo);
        HandledICOutboxTransaction.SetRange("Posting Date", PostingDate);
        HandledICOutboxTransaction.SetRange("Document Date", DocumentDate);
        exit(not HandledICOutboxTransaction.IsEmpty());
    end;
}
