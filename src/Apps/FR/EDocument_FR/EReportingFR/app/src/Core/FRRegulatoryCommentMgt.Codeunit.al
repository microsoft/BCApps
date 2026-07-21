// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 10971 "FR Regulatory Comment Mgt."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterPostSalesDoc, '', false, false)]
    local procedure CopyCommentsAfterPosting(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean; PreviewMode: Boolean)
    var
        FromDocumentType: Enum "FR Reg. Comment Doc. Type";
    begin
        if PreviewMode then
            exit;

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                FromDocumentType := FromDocumentType::Order;
            SalesHeader."Document Type"::Invoice:
                FromDocumentType := FromDocumentType::Invoice;
            SalesHeader."Document Type"::"Credit Memo":
                FromDocumentType := FromDocumentType::"Credit Memo";
            else
                exit;
        end;

        if SalesInvHdrNo <> '' then
            CopyComments(FromDocumentType, SalesHeader."No.", FromDocumentType::"Posted Invoice", SalesInvHdrNo);
        if SalesCrMemoHdrNo <> '' then
            CopyComments(FromDocumentType, SalesHeader."No.", FromDocumentType::"Posted Credit Memo", SalesCrMemoHdrNo);
    end;

    local procedure CopyComments(FromDocumentType: Enum "FR Reg. Comment Doc. Type"; FromDocumentNo: Code[20]; ToDocumentType: Enum "FR Reg. Comment Doc. Type"; ToDocumentNo: Code[20])
    var
        FromComment: Record "FR Regulatory Comment";
        ToComment: Record "FR Regulatory Comment";
    begin
        FromComment.SetRange("Document Type", FromDocumentType);
        FromComment.SetRange("Document No.", FromDocumentNo);
        if FromComment.FindSet() then
            repeat
                ToComment := FromComment;
                ToComment."Document Type" := ToDocumentType;
                ToComment."Document No." := ToDocumentNo;
                ToComment.Insert();
            until FromComment.Next() = 0;
    end;
}