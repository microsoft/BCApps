// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

table 10012 "Sales Tax Amount Difference"
{
    Caption = 'Sales Tax Amount Difference';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(2; "Document Product Area"; Enum "Sales Tax Document Area")
        {
            Caption = 'Document Product Area';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
#pragma warning disable AL0603
            TableRelation = if ("Document Product Area" = const(Sales)) "Sales Header"."No." where("Document Type" = field("Document Type"))
            else
            if ("Document Product Area" = const(Purchase)) "Purchase Header"."No." where("Document Type" = field("Document Type"))
#pragma warning restore AL0603
            else
            if ("Document Type" = const(Invoice), "Document Product Area" = const("Posted Sale")) "Sales Invoice Header"
            else
            if ("Document Type" = const("Credit Memo"), "Document Product Area" = const("Posted Sale")) "Sales Cr.Memo Header"
            else
            if ("Document Type" = const(Invoice), "Document Product Area" = const("Posted Purchase")) "Purch. Inv. Header"
            else
            if ("Document Type" = const("Credit Memo"), "Document Product Area" = const("Posted Purchase")) "Purch. Cr. Memo Hdr.";
        }
        field(5; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(6; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            TableRelation = "Tax Jurisdiction";
        }
        field(7; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(8; "Tax %"; Decimal)
        {
            Caption = 'Tax %';
        }
        field(9; "Expense/Capitalize"; Boolean)
        {
            Caption = 'Expense/Capitalize';
        }
        field(10; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            OptionCaption = 'Sales and Use Tax,Excise Tax,Sales Tax Only,Use Tax Only';
            OptionMembers = "Sales and Use Tax","Excise Tax","Sales Tax Only","Use Tax Only";
        }
        field(11; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(15; "Tax Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Difference';
            Editable = false;
        }
        field(16; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Product Area", "Document Type", "Document No.", "Tax Area Code", "Tax Jurisdiction Code", "Tax %", "Tax Group Code", "Expense/Capitalize", "Tax Type", "Use Tax")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ClearDocDifference(ProductArea: Option Sales,Purchase; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20])
    var
        TaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        TaxAmountDifference.Reset();
        TaxAmountDifference.SetRange("Document Product Area", ProductArea);
        TaxAmountDifference.SetRange("Document Type", DocType);
        TaxAmountDifference.SetRange("Document No.", DocNo);
        if TaxAmountDifference.FindFirst() then
            TaxAmountDifference.DeleteAll();
    end;

    procedure AnyTaxDifferenceRecords(ProductArea: Option Sales,Purchase; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]): Boolean
    var
        TaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        TaxAmountDifference.Reset();
        TaxAmountDifference.SetRange("Document Product Area", ProductArea);
        TaxAmountDifference.SetRange("Document Type", DocType);
        TaxAmountDifference.SetRange("Document No.", DocNo);
        exit(TaxAmountDifference.FindFirst())
    end;

    procedure CopyTaxDifferenceRecords(FromProductArea: Enum "Sales Tax Document Area"; FromDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; FromDocNo: Code[20]; ToProductArea: Enum "Sales Tax Document Area"; ToDocType: Option ,,Invoice,"Credit Memo"; ToDocNo: Code[20])
    var
        FromTaxAmountDifference: Record "Sales Tax Amount Difference";
        ToTaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        FromTaxAmountDifference.Reset();
        FromTaxAmountDifference.SetRange("Document Product Area", FromProductArea);
        FromTaxAmountDifference.SetRange("Document Type", FromDocType);
        FromTaxAmountDifference.SetRange("Document No.", FromDocNo);
        if FromTaxAmountDifference.Find('-') then begin
            ToTaxAmountDifference.Init();
            ToTaxAmountDifference."Document Product Area" := ToProductArea;
            ToTaxAmountDifference."Document Type" := ToDocType;
            ToTaxAmountDifference."Document No." := ToDocNo;
            repeat
                ToTaxAmountDifference."Tax Area Code" := FromTaxAmountDifference."Tax Area Code";
                ToTaxAmountDifference."Tax Jurisdiction Code" := FromTaxAmountDifference."Tax Jurisdiction Code";
                ToTaxAmountDifference."Tax %" := FromTaxAmountDifference."Tax %";
                ToTaxAmountDifference."Tax Group Code" := FromTaxAmountDifference."Tax Group Code";
                ToTaxAmountDifference."Expense/Capitalize" := FromTaxAmountDifference."Expense/Capitalize";
                ToTaxAmountDifference."Tax Type" := FromTaxAmountDifference."Tax Type";
                ToTaxAmountDifference."Use Tax" := FromTaxAmountDifference."Use Tax";
                ToTaxAmountDifference."Tax Difference" := FromTaxAmountDifference."Tax Difference";
                ToTaxAmountDifference.Positive := FromTaxAmountDifference.Positive;
                OnCopyTaxDifferenceRecordsOnBeforeToTaxAmountDifferenceInsert(ToTaxAmountDifference, FromTaxAmountDifference);
                ToTaxAmountDifference.Insert();
            until FromTaxAmountDifference.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyTaxDifferenceRecordsOnBeforeToTaxAmountDifferenceInsert(var ToTaxAmountDifference: Record "Sales Tax Amount Difference"; var FromTaxAmountDifference: Record "Sales Tax Amount Difference")
    begin
    end;
}

