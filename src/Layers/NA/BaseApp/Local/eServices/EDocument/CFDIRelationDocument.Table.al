// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

table 27006 "CFDI Relation Document"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Table ID"; Integer)
        {
        }
        field(2; "Document Type"; Integer)
        {
        }
        field(3; "Document No."; Code[20])
        {
        }
        field(4; "Customer No."; Code[20])
        {
            Editable = false;
        }
        field(6; "Related Doc. Type"; Option)
        {
            InitValue = Invoice;
            OptionMembers = ,,Invoice,"Credit Memo";
        }
        field(7; "Related Doc. No."; Code[20])
        {
            NotBlank = true;
            TableRelation = if ("Related Doc. Type" = const(Invoice)) "Cust. Ledger Entry"."Document No." where("Document Type" = filter(Invoice),
                                                                                                               "Customer No." = field("Customer No."))
            else
            if ("Related Doc. Type" = const("Credit Memo")) "Cust. Ledger Entry"."Document No." where("Document Type" = filter("Credit Memo"),
                                                                                                                                                                                                             "Customer No." = field("Customer No."));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Related Doc. No." = '' then
                    exit;

                CheckRelatedDocumentNo();
                UpdateFiscalInvoiceNumber();
            end;
        }
        field(11; "SAT Relation Type"; Code[10])
        {
            TableRelation = "SAT Relationship Type";
        }
        field(21; "Fiscal Invoice Number PAC"; Text[50])
        {
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Table ID", "Document Type", "Document No.", "Customer No.", "Related Doc. Type", "Related Doc. No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure InsertRelatedCreditMemos()
    begin
        if "Related Doc. No." = '' then
            exit;

        case "Document Table ID" of
            DATABASE::"Sales Header", DATABASE::"Sales Invoice Header":
                InsertRelatedSalesCreditMemos();
        end;

        OnAfterInsertRelatedCreditMemos(Rec);
    end;

    local procedure InsertRelatedSalesCreditMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CFDIRelationDocument: Record "CFDI Relation Document";
    begin
        if "Related Doc. Type" <> "Related Doc. Type"::Invoice then
            exit;

        SalesCrMemoHeader.SetRange("Bill-to Customer No.", "Customer No.");
        SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", "Related Doc. No.");
        if not SalesCrMemoHeader.FindSet() then
            exit;

        repeat
            CFDIRelationDocument := Rec;
            CFDIRelationDocument."Related Doc. Type" := CFDIRelationDocument."Related Doc. Type"::"Credit Memo";
            CFDIRelationDocument."Related Doc. No." := SalesCrMemoHeader."No.";
            CFDIRelationDocument."Fiscal Invoice Number PAC" := SalesCrMemoHeader."Fiscal Invoice Number PAC";
            if CFDIRelationDocument.Insert() then;
        until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure CheckRelatedDocumentNo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", "Related Doc. Type");
        CustLedgerEntry.SetRange("Document No.", "Related Doc. No.");
        CustLedgerEntry.SetRange("Customer No.", "Customer No.");
        CustLedgerEntry.FindFirst();
    end;

    local procedure UpdateFiscalInvoiceNumber()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if "Related Doc. No." = '' then
            exit;

        case "Document Table ID" of
            DATABASE::"Sales Header", DATABASE::"Sales Invoice Header", DATABASE::"Sales Cr.Memo Header":
                if "Related Doc. Type" = "Related Doc. Type"::Invoice then begin
                    SalesInvoiceHeader.Get("Related Doc. No.");
                    "Fiscal Invoice Number PAC" := SalesInvoiceHeader."Fiscal Invoice Number PAC";
                end else begin
                    SalesCrMemoHeader.Get("Related Doc. No.");
                    "Fiscal Invoice Number PAC" := SalesCrMemoHeader."Fiscal Invoice Number PAC";
                end;
        end;

        OnAfterUpdateFiscalInvoiceNumber(Rec);
    end;

    [InternalEvent(false)]
    local procedure OnAfterInsertRelatedCreditMemos(var Rec: Record "CFDI Relation Document")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnAfterUpdateFiscalInvoiceNumber(var Rec: Record "CFDI Relation Document")
    begin
    end;
}

