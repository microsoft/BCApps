// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

table 579 "Apply Unapply Parameters"
{
    Caption = 'Apply Unapply Parameters';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(48; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Template";
        }
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CopyFromCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        "Entry No." := CustLedgEntry."Entry No.";
        "Account Type" := "Account Type"::Customer;
        "Account No." := CustLedgEntry."Customer No.";
        "Posting Date" := CustLedgEntry."Posting Date";
        "Document Type" := CustLedgEntry."Document Type";
        "Document No." := CustLedgEntry."Document No.";

        OnAfterCopyFromCustLedgerEntry(Rec, CustLedgEntry);
    end;

    procedure CopyFromVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        "Entry No." := VendLedgEntry."Entry No.";
        "Account Type" := "Account Type"::Vendor;
        "Account No." := VendLedgEntry."Vendor No.";
        "Posting Date" := VendLedgEntry."Posting Date";
        "Document Type" := VendLedgEntry."Document Type";
        "Document No." := VendLedgEntry."Document No.";

        OnAfterCopyFromVendLedgerEntry(Rec, VendLedgEntry);
    end;

    procedure CopyFromEmplLedgEntry(EmplLedgEntry: Record "Employee Ledger Entry")
    begin
        "Entry No." := EmplLedgEntry."Entry No.";
        "Account Type" := "Account Type"::Employee;
        "Account No." := EmplLedgEntry."Employee No.";
        "Posting Date" := EmplLedgEntry."Posting Date";
        "Document Type" := EmplLedgEntry."Document Type";
        "Document No." := EmplLedgEntry."Document No.";

        OnAfterCopyFromEmplLedgerEntry(Rec, EmplLedgEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCustLedgerEntry(var PostApplyParameters: Record "Apply Unapply Parameters"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVendLedgerEntry(var PostApplyParameters: Record "Apply Unapply Parameters"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromEmplLedgerEntry(var PostApplyParameters: Record "Apply Unapply Parameters"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;
}

