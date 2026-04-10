// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Purchases.History;
using Microsoft.Sales.History;

table 1900 "Cancelled Document"
{
    Caption = 'Cancelled Document';
    Permissions = TableData "Cancelled Document" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source ID"; Integer)
        {
            Caption = 'Source ID';
        }
        field(2; "Cancelled Doc. No."; Code[20])
        {
            Caption = 'Cancelled Doc. No.';
            TableRelation = if ("Source ID" = const(112)) "Sales Invoice Header"."No."
            else
            if ("Source ID" = const(122)) "Purch. Inv. Header"."No."
            else
            if ("Source ID" = const(114)) "Sales Cr.Memo Header"."No."
            else
            if ("Source ID" = const(124)) "Purch. Cr. Memo Hdr."."No.";
        }
        field(3; "Cancelled By Doc. No."; Code[20])
        {
            Caption = 'Cancelled By Doc. No.';
            TableRelation = if ("Source ID" = const(114)) "Sales Invoice Header"."No."
            else
            if ("Source ID" = const(124)) "Purch. Inv. Header"."No."
            else
            if ("Source ID" = const(112)) "Sales Cr.Memo Header"."No."
            else
            if ("Source ID" = const(122)) "Purch. Cr. Memo Hdr."."No.";
        }
    }

    keys
    {
        key(Key1; "Source ID", "Cancelled Doc. No.")
        {
            Clustered = true;
        }
        key(Key2; "Cancelled By Doc. No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure InsertSalesInvToCrMemoCancelledDocument(InvNo: Code[20]; CrMemoNo: Code[20])
    begin
        InsertEntry(DATABASE::"Sales Invoice Header", InvNo, CrMemoNo);
    end;

    procedure InsertSalesCrMemoToInvCancelledDocument(CrMemoNo: Code[20]; InvNo: Code[20])
    begin
        InsertEntry(DATABASE::"Sales Cr.Memo Header", CrMemoNo, InvNo);
        RemoveSalesInvCancelledDocument();
    end;

    procedure InsertPurchInvToCrMemoCancelledDocument(InvNo: Code[20]; CrMemoNo: Code[20])
    begin
        InsertEntry(DATABASE::"Purch. Inv. Header", InvNo, CrMemoNo);
    end;

    procedure InsertPurchCrMemoToInvCancelledDocument(CrMemoNo: Code[20]; InvNo: Code[20])
    begin
        InsertEntry(DATABASE::"Purch. Cr. Memo Hdr.", CrMemoNo, InvNo);
        RemovePurchInvCancelledDocument();
    end;

    local procedure InsertEntry(SourceID: Integer; CanceledDocNo: Code[20]; CanceledByDocNo: Code[20])
    begin
        Init();
        Validate("Source ID", SourceID);
        Validate("Cancelled Doc. No.", CanceledDocNo);
        Validate("Cancelled By Doc. No.", CanceledByDocNo);
        Insert(true);
    end;

    local procedure RemoveSalesInvCancelledDocument()
    begin
        FindSalesCorrectiveCrMemo("Cancelled Doc. No.");
        DeleteAll(true);
    end;

    local procedure RemovePurchInvCancelledDocument()
    begin
        FindPurchCorrectiveCrMemo("Cancelled Doc. No.");
        DeleteAll(true);
    end;

    procedure FindSalesCancelledInvoice(CanceledDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledDocNo(DATABASE::"Sales Invoice Header", CanceledDocNo));
    end;

    procedure FindSalesCorrectiveInvoice(CanceledByDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledByDocNo(DATABASE::"Sales Cr.Memo Header", CanceledByDocNo));
    end;

    procedure FindPurchCancelledInvoice(CanceledDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledDocNo(DATABASE::"Purch. Inv. Header", CanceledDocNo));
    end;

    procedure FindPurchCorrectiveInvoice(CanceledByDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledByDocNo(DATABASE::"Purch. Cr. Memo Hdr.", CanceledByDocNo));
    end;

    procedure FindSalesCorrectiveCrMemo(CanceledByDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledByDocNo(DATABASE::"Sales Invoice Header", CanceledByDocNo));
    end;

    procedure FindSalesCancelledCrMemo(CanceledDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledDocNo(DATABASE::"Sales Cr.Memo Header", CanceledDocNo));
    end;

    procedure FindPurchCorrectiveCrMemo(CanceledByDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledByDocNo(DATABASE::"Purch. Inv. Header", CanceledByDocNo));
    end;

    procedure FindPurchCancelledCrMemo(CanceledDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledDocNo(DATABASE::"Purch. Cr. Memo Hdr.", CanceledDocNo));
    end;

    local procedure FindWithCancelledDocNo(SourceID: Integer; CanceledDocNo: Code[20]): Boolean
    begin
        exit(Get(SourceID, CanceledDocNo));
    end;

    local procedure FindWithCancelledByDocNo(SourceID: Integer; CanceledByDocNo: Code[20]): Boolean
    begin
        Reset();
        SetRange("Source ID", SourceID);
        SetRange("Cancelled By Doc. No.", CanceledByDocNo);
        exit(FindFirst());
    end;
}

