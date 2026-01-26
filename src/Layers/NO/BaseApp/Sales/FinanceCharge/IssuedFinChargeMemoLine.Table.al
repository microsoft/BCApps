// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

table 305 "Issued Fin. Charge Memo Line"
{
    Caption = 'Issued Fin. Charge Memo Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Finance Charge Memo No."; Code[20])
        {
            Caption = 'Finance Charge Memo No.';
            TableRelation = "Issued Fin. Charge Memo Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Issued Fin. Charge Memo Line"."Line No." where("Finance Charge Memo No." = field("Finance Charge Memo No."));
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Customer Ledger Entry';
            OptionMembers = " ","G/L Account","Customer Ledger Entry";
        }
        field(5; "Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry";

            trigger OnLookup()
            begin
                if Type <> Type::"Customer Ledger Entry" then
                    exit;
                IssuedFinChrgMemoHeader.Get("Finance Charge Memo No.");
                SetCustLedgEntryFilter(CustLedgEntry, IssuedFinChrgMemoHeader, FieldNo("Entry No."));
                if CustLedgEntry.Get("Entry No.") then;
                PAGE.RunModal(0, CustLedgEntry);
            end;
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
                if Type <> Type::"Customer Ledger Entry" then
                    exit;
                IssuedFinChrgMemoHeader.Get("Finance Charge Memo No.");
                SetCustLedgEntryFilter(CustLedgEntry, IssuedFinChrgMemoHeader, FieldNo("Document No."));
                if CustLedgEntry.Get("Entry No.") then;
                PAGE.RunModal(0, CustLedgEntry);
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Original Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Original Amount';
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Remaining Amount';
        }
        field(15; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account";
        }
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
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
            AutoFormatExpression = GetCurrencyCode();
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
        field(25; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Finance Charge Memo Line,Beginning Text,Ending Text,Rounding';
            OptionMembers = "Finance Charge Memo Line","Beginning Text","Ending Text",Rounding;
        }
        field(26; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(30; "Detailed Interest Rates Entry"; Boolean)
        {
            Caption = 'Detailed Interest Rates Entry';
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(10601; "Account Code"; Text[30])
        {
            Caption = 'Account Code';

            trigger OnValidate()
            begin
                if (Type = Type::" ") and ("Account Code" <> '') then
                    Error(Text10600, FieldCaption("Account Code"), FieldCaption(Type), Type);
            end;
        }
    }

    keys
    {
        key(Key1; "Finance Charge Memo No.", "Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
        }
        key(Key2; "Finance Charge Memo No.", Type, "Detailed Interest Rates Entry")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key3; "Finance Charge Memo No.", "Detailed Interest Rates Entry")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
    }

    fieldgroups
    {
    }

    var
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Text10600: Label 'You cannot enter %1 if %2 is "%3".';

    procedure GetCurrencyCode(): Code[10]
    var
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        if "Finance Charge Memo No." = IssuedFinChrgMemoHeader."No." then
            exit(IssuedFinChrgMemoHeader."Currency Code");

        if IssuedFinChrgMemoHeader.Get("Finance Charge Memo No.") then
            exit(IssuedFinChrgMemoHeader."Currency Code");

        exit('');
    end;

    local procedure SetCustLedgEntryFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header"; CalledByFieldNo: Integer)
    begin
        CustLedgEntry.SetCurrentKey("Customer No.");
        CustLedgEntry.SetRange("Customer No.", IssuedFinChrgMemoHeader."Customer No.");

        OnAfterSetCustLedgEntryFilter(CustLedgEntry, Rec, CalledByFieldNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustLedgEntryFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; var IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line"; CalledByFieldNo: Integer)
    begin
    end;
}
