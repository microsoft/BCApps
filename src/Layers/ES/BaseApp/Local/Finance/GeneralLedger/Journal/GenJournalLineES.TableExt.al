// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Purchases.History;
using Microsoft.Sales.History;

#pragma warning disable AS0088
tableextension 7000100 "Gen. Journal Line ES" extends "Gen. Journal Line"
{
    fields
    {
        field(10715; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;

            trigger OnValidate()
            begin
                if "Correction Type" <> 0 then
                    CheckDataForCorrection();
            end;
        }
        field(10716; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
                PurchInvHeader: Record "Purch. Inv. Header";
                TempGenJournalLine: Record "Gen. Journal Line" temporary;
            begin
                InitGenJnlLineBufferWithCustVend(TempGenJournalLine);
                case true of
                    TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Customer:
                        if SalesInvoiceHeader.LookupInvoice("Account No.") then
                            Validate("Corrected Invoice No.", SalesInvoiceHeader."No.");
                    TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Vendor:
                        if PurchInvHeader.LookupInvoice("Account No.") then
                            Validate("Corrected Invoice No.", PurchInvHeader."No.");
                end;
            end;

            trigger OnValidate()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
                PurchInvHeader: Record "Purch. Inv. Header";
                TempGenJournalLine: Record "Gen. Journal Line" temporary;
            begin
                if "Corrected Invoice No." <> '' then begin
                    CheckDataForCorrection();
                    InitGenJnlLineBufferWithCustVend(TempGenJournalLine);
                    case true of
                        TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Customer:
                            SalesInvoiceHeader.CheckCorrectedDocumentExist("Account No.", "Corrected Invoice No.");
                        TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Vendor:
                            PurchInvHeader.CheckCorrectedDocumentExist("Account No.", "Corrected Invoice No.");
                    end;
                end;
            end;
        }
    }

    var
        IncorrectAccTypeErr: Label '%1 or %2 must be a %3.', Comment = '%1=Account Type,%2=Balance Account Type,%3=Customer or Vendor';
        OneOrAnotherTxt: Label '%1 or %2', Comment = '%1 - Customer or Vendor, %2 - Customer or Vendor';

    procedure CheckDataForCorrection()
    begin
        TestField("Document Type", "Document Type"::"Credit Memo");
        if not (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) or
                ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]))
        then
            Error(IncorrectAccTypeErr,
              FieldCaption("Account Type"), FieldCaption("Bal. Account Type"),
              StrSubstNo(OneOrAnotherTxt, Format("Account Type"::Customer), Format("Account Type"::Vendor)));
    end;

    local procedure InitGenJnlLineBufferWithCustVend(var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
        TempGenJournalLine.Init();
        case true of
            "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]:
                begin
                    TempGenJournalLine."Account Type" := "Account Type";
                    TempGenJournalLine."Account No." := "Account No.";
                end;
            "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]:
                begin
                    TempGenJournalLine."Account Type" := "Bal. Account Type";
                    TempGenJournalLine."Account No." := "Bal. Account No.";
                end;
        end;
    end;

    procedure ClearInvCrMemoTypeFields()
    begin
        OnBeforeClearInvCrMemoTypeFields(Rec);
        "Correction Type" := 0;
        "Corrected Invoice No." := '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearInvCrMemoTypeFields(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}
