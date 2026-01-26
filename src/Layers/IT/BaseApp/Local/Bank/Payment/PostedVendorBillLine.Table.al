// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;

table 12184 "Posted Vendor Bill Line"
{
    Caption = 'Posted Vendor Bill Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor Bill No."; Code[20])
        {
            Caption = 'Vendor Bill No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Description; Text[45])
        {
            Caption = 'Description';
        }
        field(6; "Description 2"; Text[45])
        {
            Caption = 'Description 2';
        }
        field(10; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(11; "Vendor Name"; Text[100])
        {
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Caption = 'Vendor Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Vendor Bank Acc. No."; Code[20])
        {
            Caption = 'Vendor Bank Acc. No.';
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Vendor No."));
        }
        field(14; "Vendor Bill List No."; Code[20])
        {
            Caption = 'Vendor Bill List No.';
        }
        field(20; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(21; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if ("Document Type" = const(Invoice)) "Purch. Inv. Header"
            else
            if ("Document Type" = const("Credit Memo")) "Purch. Cr. Memo Hdr."
            else
            if ("Document Type" = const("Finance Charge Memo")) "Finance Charge Memo Header"
            else
            if ("Document Type" = const(Reminder)) "Reminder Header";
        }
        field(22; "Document Occurrence"; Integer)
        {
            Caption = 'Document Occurrence';
        }
        field(23; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(24; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(25; "Instalment Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
            Caption = 'Instalment Amount';
            Editable = false;
        }
        field(26; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
            Editable = false;
        }
        field(27; "Amount to Pay"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
            Caption = 'Amount to Pay';
        }
        field(30; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(31; "Beneficiary Value Date"; Date)
        {
            Caption = 'Beneficiary Value Date';
        }
        field(34; "Cumulative Transfers"; Boolean)
        {
            Caption = 'Cumulative Transfers';
        }
        field(45; "Vendor Entry No."; Integer)
        {
            Caption = 'Vendor Entry No.';
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
        }
        field(61; "Withholding Tax Amount"; Decimal)
        {
            Caption = 'Withholding Tax Amount';
            Editable = false;
        }
        field(62; "Social Security Amount"; Decimal)
        {
            Caption = 'Social Security Amount';
            Editable = false;
        }
        field(63; "Gross Amount to Pay"; Decimal)
        {
            Caption = 'Gross Amount to Pay';
            Editable = false;
        }
        field(64; "Manual Line"; Boolean)
        {
            Caption = 'Manual Line';
            Editable = false;
        }
        field(65; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "Vendor Bill No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Amount to Pay";
        }
        key(Key2; "Vendor No.", "External Document No.", "Document Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        VendorBillHeader: Record "Vendor Bill Header";
        Text12100: Label 'Invoice %1 does not exist.';

    [Scope('OnPrem')]
    procedure GetCurrCode(): Code[10]
    begin
        if VendorBillHeader.Get("Vendor Bill No.") then
            exit(VendorBillHeader."Currency Code");
        exit('');
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    [Scope('OnPrem')]
    procedure ShowInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchInv: Page "Posted Purchase Invoice";
    begin
        if not "Manual Line" then begin
            PurchInvHeader.Get("Document No.");
            PostedPurchInv.SetRecord(PurchInvHeader);
            PostedPurchInv.RunModal();
        end else
            Error(Text12100, "Document No.");
    end;
}

