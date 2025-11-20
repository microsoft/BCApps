// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Document;
using Microsoft.Intercompany;
using Microsoft.Purchases.History;
using System.Utilities;

table 418 "IC Inbox Transaction"
{
    Caption = 'IC Inbox Transaction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
#if not CLEANSCHEMA29
        field(3; "Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
            ObsoleteReason = 'Replaced by IC Source Type for Enum typing';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(10; "Line Action"; Option)
        {
            Caption = 'Line Action';
            OptionCaption = 'No Action,Accept,Return to IC Partner,Cancel';
            OptionMembers = "No Action",Accept,"Return to IC Partner",Cancel;

            trigger OnValidate()
            begin
                if (("Line Action" = "Line Action"::"Return to IC Partner") or ("Line Action" = "Line Action"::Accept)) and
                   ("Transaction Source" = "Transaction Source"::"Returned by Partner")
                then
                    Error(InvalidActionForReturnedTransactionErr, "Transaction No.", "IC Partner Code");

                if "Line Action" = "Line Action"::Accept then
                    InboxCheckAccept();
            end;
        }
        field(11; "Original Document No."; Code[20])
        {
            Caption = 'Original Document No.';
        }
#if not CLEANSCHEMA25
        field(12; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            ObsoleteReason = 'Replaced by IC Account No.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        field(15; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source", "Document Type")
        {
            Clustered = true;
        }
        key(Key2; "IC Partner Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ICInboxJnlLine: Record "IC Inbox Jnl. Line";
        ICInboxPurchHdr: Record "IC Inbox Purchase Header";
        ICInboxSalesHdr: Record "IC Inbox Sales Header";
    begin
        case "IC Source Type" of
            "IC Source Type"::Journal:
                begin
                    ICInboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    ICInboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    ICInboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    if ICInboxJnlLine.FindFirst() then
                        ICInboxJnlLine.DeleteAll(true);
                end;
            "IC Source Type"::"Sales Document":
                begin
                    ICInboxSalesHdr.SetRange("IC Transaction No.", "Transaction No.");
                    ICInboxSalesHdr.SetRange("IC Partner Code", "IC Partner Code");
                    ICInboxSalesHdr.SetRange("Transaction Source", "Transaction Source");
                    if ICInboxSalesHdr.FindFirst() then
                        ICInboxSalesHdr.Delete(true);
                end;
            "IC Source Type"::"Purchase Document":
                begin
                    ICInboxPurchHdr.SetRange("IC Transaction No.", "Transaction No.");
                    ICInboxPurchHdr.SetRange("IC Partner Code", "IC Partner Code");
                    ICInboxPurchHdr.SetRange("Transaction Source", "Transaction Source");
                    if ICInboxPurchHdr.FindFirst() then
                        ICInboxPurchHdr.Delete(true);
                end;
            else
                OnDeleteOnSourceTypeCase(Rec);
        end;
    end;

    var
        InvalidActionForReturnedTransactionErr: Label 'Transaction No. %1 has been returned by IC Partner %2.\You can only cancel returned transactions.', Comment = '%1 - Transaction No, %2 - IC parthner code';
        TransactionAlreadyExistsInInboxHandledQst: Label '%1 %2 has already been received from intercompany partner %3. Accepting it again will create a duplicate %1. Do you want to accept the %1?', Comment = '%1 - Document Type, %2 - Document No, %3 - IC parthner code';
        DuplicateTransactionNoMsg: Label 'Transaction No. %2 is a copy of Transaction No. %1, which has already been set to Accept.\Do you also want to accept Transaction No. %2?', Comment = '%1 - New Transaction No, %2 - Old Transaction No';
        DuplicatePurchaseOrderMsg: Label 'A purchase order already exists for transaction %1. If you accept and post this document, you should delete the original purchase order %2 to avoid duplicate postings.', Comment = '%1 - New Transaction No, %2 - Old Transaction No';
        DuplicatePurchaseInvoiceMsg: Label 'Purchase invoice %1 has already been posted for transaction %2. If you accept and post this document, you will have duplicate postings.\Are you sure you want to accept the transaction?', Comment = '%1 - Purchase Invoice No, %2 - Transaction No';

    procedure ShowDetails()
    var
        ICInBoxJnlLine: Record "IC Inbox Jnl. Line";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxPurchHeader: Record "IC Inbox Purchase Header";
        ICInboxJnlLines: Page "IC Inbox Jnl. Lines";
        ICInboxSalesDoc: Page "IC Inbox Sales Doc.";
        ICInboxPurchDoc: Page "IC Inbox Purchase Doc.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDetails(Rec, IsHandled);
        if not IsHandled then
            case "IC Source Type" of
                "IC Source Type"::Journal:
                    begin
                        ICInBoxJnlLine.SetRange("Transaction No.", "Transaction No.");
                        ICInBoxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                        ICInBoxJnlLine.SetRange("Transaction Source", "Transaction Source");
                        Clear(ICInboxJnlLines);
                        ICInboxJnlLines.SetTableView(ICInBoxJnlLine);
                        ICInboxJnlLines.RunModal();
                    end;
                "IC Source Type"::"Sales Document":
                    begin
                        ICInboxSalesHeader.SetRange("IC Transaction No.", "Transaction No.");
                        ICInboxSalesHeader.SetRange("IC Partner Code", "IC Partner Code");
                        ICInboxSalesHeader.SetRange("Transaction Source", "Transaction Source");
                        Clear(ICInboxSalesDoc);
                        ICInboxSalesDoc.SetTableView(ICInboxSalesHeader);
                        ICInboxSalesDoc.RunModal();
                    end;
                "IC Source Type"::"Purchase Document":
                    begin
                        ICInboxPurchHeader.SetRange("IC Partner Code", "IC Partner Code");
                        ICInboxPurchHeader.SetRange("IC Transaction No.", "Transaction No.");
                        ICInboxPurchHeader.SetRange("Transaction Source", "Transaction Source");
                        Clear(ICInboxPurchDoc);
                        ICInboxPurchDoc.SetTableView(ICInboxPurchHeader);
                        ICInboxPurchDoc.RunModal();
                    end;
            end;

        OnAfterShowDetails(Rec);
    end;

    local procedure InboxCheckAccept()
    var
        ICInboxTransaction2: Record "IC Inbox Transaction";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICInboxPurchHeader: Record "IC Inbox Purchase Header";
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInboxCheckAccept(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        HandledICInboxTrans.SetRange("IC Partner Code", "IC Partner Code");
        HandledICInboxTrans.SetRange("Document Type", "Document Type");
        HandledICInboxTrans.SetRange("IC Source Type", "IC Source Type");
        HandledICInboxTrans.SetRange("Document No.", "Document No.");
        if HandledICInboxTrans.FindFirst() then
            if not ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(
                    TransactionAlreadyExistsInInboxHandledQst, HandledICInboxTrans."Document Type",
                    HandledICInboxTrans."Document No.", HandledICInboxTrans."IC Partner Code"),
                true)
            then
                Error('');

        ICInboxTransaction2.SetRange("IC Partner Code", "IC Partner Code");
        ICInboxTransaction2.SetRange("Document Type", "Document Type");
        ICInboxTransaction2.SetRange("IC Source Type", "IC Source Type");
        ICInboxTransaction2.SetRange("Document No.", "Document No.");
        ICInboxTransaction2.SetFilter("Transaction No.", '<>%1', "Transaction No.");
        ICInboxTransaction2.SetRange("IC Account Type", "IC Account Type");
        ICInboxTransaction2.SetRange("IC Account No.", "IC Account No.");
        ICInboxTransaction2.SetRange("Source Line No.", "Source Line No.");
        ICInboxTransaction2.SetRange("Line Action", "Line Action"::Accept);
        if ICInboxTransaction2.FindFirst() then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(DuplicateTransactionNoMsg, ICInboxTransaction2."Transaction No.", "Transaction No."), true)
            then
                Error('');
        if ("IC Source Type" = "IC Source Type"::"Purchase Document") and
           ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"])
        then begin
            ICInboxPurchHeader.Get("Transaction No.", "IC Partner Code", "Transaction Source");
            if ICInboxPurchHeader."Your Reference" <> '' then begin
                PurchHeader.SetRange("Your Reference", ICInboxPurchHeader."Your Reference");
                if not PurchHeader.IsEmpty() then
                    Message(DuplicatePurchaseOrderMsg, ICInboxPurchHeader."IC Transaction No.", ICInboxPurchHeader."Your Reference")
                else begin
                    PurchInvHeader.SetRange("Your Reference", ICInboxPurchHeader."Your Reference");
                    if PurchInvHeader.FindFirst() then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               DuplicatePurchaseInvoiceMsg, ICInboxPurchHeader."Your Reference",
                               ICInboxPurchHeader."IC Transaction No."), true)
                        then
                            "Line Action" := xRec."Line Action";
                end;
            end;
        end;

        OnAfterInboxCheckAccept(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInboxCheckAccept(var ICInboxTransaction: Record "IC Inbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDetails(var ICInboxTransaction: Record "IC Inbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInboxCheckAccept(var ICInboxTransaction: Record "IC Inbox Transaction"; var IsHandled: Boolean; xICInboxTransaction: Record "IC Inbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnSourceTypeCase(var ICInboxTransaction: Record "IC Inbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDetails(var ICInboxTransaction: Record "IC Inbox Transaction"; var IsHandled: Boolean)
    begin
    end;
}

