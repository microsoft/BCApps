// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Purchases.History;
using Microsoft.Sales.History;

table 11723 "VAT LCY Corr. Document CZL"
{
    Caption = 'VAT LCY Correction Document';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(5; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    internal procedure CopyFrom(SourceDocument: Variant)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
#if not CLEAN29
        VATLCYCorrectionCZL: Page "VAT LCY Correction CZL";
#endif
        SourceDocumentRecRef: RecordRef;
#if not CLEAN29
        NewDocumentNo: Code[20];
        NewPostingDate: Date;
        NewTransactionNo: Integer;
        IsHandled: Boolean;
#endif
    begin
        SourceDocumentRecRef.GetTable(SourceDocument);
        case SourceDocumentRecRef.Number of
            Database::"Purch. Inv. Header":
                begin
                    SourceDocumentRecRef.SetTable(PurchInvHeader);
                    CopyFrom(PurchInvHeader);
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    SourceDocumentRecRef.SetTable(PurchCrMemoHdr);
                    CopyFrom(PurchCrMemoHdr);
                end;
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentRecRef.SetTable(SalesInvoiceHeader);
                    CopyFrom(SalesInvoiceHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentRecRef.SetTable(SalesCrMemoHeader);
                    CopyFrom(SalesCrMemoHeader);
                end;
#if not CLEAN29
            else begin
                VATLCYCorrectionCZL.RaiseOnInitGlobals(SourceDocumentRecRef, NewDocumentNo, NewPostingDate, NewTransactionNo, IsHandled);
                if (NewDocumentNo <> '') or (NewPostingDate <> 0D) or (NewTransactionNo <> 0) then begin
                    "Document No." := NewDocumentNo;
                    "Posting Date" := NewPostingDate;
                    "Transaction No." := NewTransactionNo;
                end;
            end;
#endif
        end;

        OnAfterCopyFrom(SourceDocumentRecRef, Rec);
    end;

    local procedure CopyFrom(PurchInvHeader: Record "Purch. Inv. Header")
    begin
        "Document No." := PurchInvHeader."No.";
        "Posting Date" := PurchInvHeader."Posting Date";
        "Transaction No." := PurchInvHeader.GetTransactionNoCZL();
        "Dimension Set ID" := PurchInvHeader."Dimension Set ID";
    end;

    local procedure CopyFrom(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        "Document No." := PurchCrMemoHdr."No.";
        "Posting Date" := PurchCrMemoHdr."Posting Date";
        "Transaction No." := PurchCrMemoHdr.GetTransactionNoCZL();
        "Dimension Set ID" := PurchCrMemoHdr."Dimension Set ID";
    end;

    local procedure CopyFrom(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        "Document No." := SalesInvoiceHeader."No.";
        "Posting Date" := SalesInvoiceHeader."Posting Date";
        "Transaction No." := SalesInvoiceHeader.GetTransactionNoCZL();
        "Dimension Set ID" := SalesInvoiceHeader."Dimension Set ID";
    end;

    local procedure CopyFrom(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        "Document No." := SalesCrMemoHeader."No.";
        "Posting Date" := SalesCrMemoHeader."Posting Date";
        "Transaction No." := SalesCrMemoHeader.GetTransactionNoCZL();
        "Dimension Set ID" := SalesCrMemoHeader."Dimension Set ID";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFrom(SourceDocumentRecRef: RecordRef; var TempVATLCYCorrDocumentCZL: Record "VAT LCY Corr. Document CZL")
    begin
    end;
}