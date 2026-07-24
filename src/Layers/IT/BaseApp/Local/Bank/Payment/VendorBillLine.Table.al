// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;

table 12182 "Vendor Bill Line"
{
    Caption = 'Vendor Bill Line';
    Permissions = TableData "Vendor Ledger Entry" = m;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor Bill List No."; Code[20])
        {
            Caption = 'Vendor Bill List No.';
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
        field(14; "Vendor Bill No."; Code[20])
        {
            Caption = 'Vendor Bill No.';
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

            trigger OnValidate()
            begin
                if ("Amount to Pay" > "Remaining Amount") or
                   ("Amount to Pay" <= 0)
                then
                    Error(MustNotBeLessOrGreaterErr, FieldCaption("Amount to Pay"), "Remaining Amount");
            end;
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
        field(60; "Transfer Type"; Option)
        {
            Caption = 'Transfer Type';
            OptionCaption = 'Transfer,Salary';
            OptionMembers = Transfer,Salary;
        }
        field(63; "Gross Amount to Pay"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
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
        field(66; "Has Payment Export Error"; Boolean)
        {
            CalcFormula = exist("Payment Jnl. Export Error Text" where("Journal Line No." = field("Line No."),
                                                                        "Document No." = field("Vendor Bill List No.")));
            Caption = 'Has Payment Export Error';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Vendor Bill List No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Amount to Pay";
        }
        key(Key2; "Vendor No.", "External Document No.", "Document Date")
        {
        }
        key(Key3; "Vendor Bill List No.", "Vendor No.", "Due Date", "Vendor Bank Acc. No.", "Cumulative Transfers")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if not "Manual Line" then begin
            VendLedgEntry.Get("Vendor Entry No.");
            if VendLedgEntry.Open then begin
                VendLedgEntry."Vendor Bill List" := '';
                VendLedgEntry."Vendor Bill No." := '';
            end;
            VendLedgEntry.Modify();
        end;
        DeletePaymentFileErrors();
    end;

    var
        VendorBillHeader: Record "Vendor Bill Header";
        DimMgt: Codeunit DimensionManagement;
        MustNotBeLessOrGreaterErr: Label '%1 must not be less than zero or greater than %2.', Comment = '%1 - field caption, %2 - remaining amount';
        InvoiceDoesNotExistErr: Label 'Invoice %1 does not exist.', Comment = '%1 - document number';

    [Scope('OnPrem')]
    procedure GetCurrCode(): Code[10]
    begin
        if VendorBillHeader.Get("Vendor Bill List No.") then
            exit(VendorBillHeader."Currency Code");
        exit('');
    end;

    [Scope('OnPrem')]
    procedure EditDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        if "Manual Line" then
            EditDimensions()
        else
            ShowPurchInvDimensions();
    end;

    [Scope('OnPrem')]
    procedure ShowPurchInvDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."), 1, 250));
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
            Error(InvoiceDoesNotExistErr, "Document No.");
    end;

    [Scope('OnPrem')]
    procedure DeletePaymentFileErrors()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := '';
        GenJnlLine."Document No." := "Vendor Bill List No.";
        GenJnlLine."Line No." := "Line No.";
        GenJnlLine.DeletePaymentFileErrors();
    end;

}
