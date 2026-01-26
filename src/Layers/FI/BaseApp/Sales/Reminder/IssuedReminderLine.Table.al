// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

table 298 "Issued Reminder Line"
{
    Caption = 'Issued Reminder Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reminder No."; Code[20])
        {
            Caption = 'Reminder No.';
            TableRelation = "Issued Reminder Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Issued Reminder Line"."Line No." where("Reminder No." = field("Reminder No."));
        }
        field(4; Type; Enum "Reminder Source Type")
        {
            Caption = 'Type';
        }
        field(5; "Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry";

            trigger OnLookup()
            begin
                LookupCustomerLedgerEntry(FieldNo("Entry No."));
            end;
        }
        field(6; "No. of Reminders"; Integer)
        {
            Caption = 'No. of Reminders';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            begin
                LookupDocNo();
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Original Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Original Amount';
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Remaining Amount';
        }
        field(15; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const("Line Fee")) "G/L Account";
        }
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';
        }
        field(17; "Interest Rate"; Decimal)
        {
            BlankZero = true;
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(19; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
        }
        field(20; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        field(21; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader();
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(22; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(24; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(25; "Line Type"; Enum "Reminder Line Type")
        {
            Caption = 'Line Type';
        }
        field(26; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(27; "Applies-To Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-To Document Type';
        }
        field(28; "Applies-To Document No."; Code[20])
        {
            Caption = 'Applies-To Document No.';

            trigger OnLookup()
            begin
                if Type <> Type::"Line Fee" then
                    exit;
                IssuedReminderHeader.Get("Reminder No.");
                CustLedgEntry.SetCurrentKey("Customer No.");
                CustLedgEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
                CustLedgEntry.SetRange("Document Type", "Applies-To Document Type");
                CustLedgEntry.SetRange("Document No.", "Applies-To Document No.");
                if CustLedgEntry.FindLast() then;
                PAGE.RunModal(0, CustLedgEntry);
            end;
        }
        field(30; "Detailed Interest Rates Entry"; Boolean)
        {
            Caption = 'Detailed Interest Rates Entry';
        }
        field(50; Canceled; Boolean)
        {
            Caption = 'Canceled';
            DataClassification = SystemMetadata;
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(32000000; "Reference No."; Code[20])
        {
            Caption = 'Reference No.';
        }
    }

    keys
    {
        key(Key1; "Reminder No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Reminder No.", Type, "Line Type", "Detailed Interest Rates Entry")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key3; "Reminder No.", "Detailed Interest Rates Entry")
        {
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key4; "Reminder No.", Type)
        {
            SumIndexFields = "VAT Amount";
        }
    }

    fieldgroups
    {
    }

    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustLedgEntry: Record "Cust. Ledger Entry";

    procedure GetCurrencyCodeFromHeader(): Code[10]
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        if "Reminder No." = IssuedReminderHeader."No." then
            exit(IssuedReminderHeader."Currency Code");

        if IssuedReminderHeader.Get("Reminder No.") then
            exit(IssuedReminderHeader."Currency Code");

        exit('');
    end;

    procedure LookupDocNo()
    var
        IsHandled: Boolean;
    begin
        OnBeforeLookupDocNo(Rec, IsHandled);
        if IsHandled then
            exit;

        LookupCustomerLedgerEntry(FieldNo("Document No."));
    end;

    local procedure LookupCustomerLedgerEntry(CalledByFieldNo: Integer)
    begin
        if Type <> Type::"Customer Ledger Entry" then
            exit;
        IssuedReminderHeader.Get("Reminder No.");
        SetCustLedgEntryFilter(CustLedgEntry, IssuedReminderHeader, CalledByFieldNo);
        if CustLedgEntry.Get("Entry No.") then;
        PAGE.RunModal(0, CustLedgEntry);
    end;

    local procedure SetCustLedgEntryFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; IssuedReminderHeader: Record "Issued Reminder Header"; CalledByFieldNo: Integer)
    begin
        CustLedgEntry.SetCurrentKey("Customer No.");
        CustLedgEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");

        OnAfterSetCustLedgEntryFilter(CustLedgEntry, Rec, CalledByFieldNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocNo(var IssuedReminderLine: Record "Issued Reminder Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustLedgEntryFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; var IssuedReminderLine: Record "Issued Reminder Line"; CalledByFieldNo: Integer)
    begin
    end;
}
