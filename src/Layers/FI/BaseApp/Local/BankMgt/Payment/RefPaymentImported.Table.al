// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 32000001 "Ref. Payment - Imported"
{
    Caption = 'Ref. Payment - Imported';
    DrillDownPageID = "Ref. Payment - Import";
    LookupPageID = "Ref. Payment - Import";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Record ID"; Integer)
        {
            Caption = 'Record ID';
        }
        field(5; "Bank Code"; Text[2])
        {
            Caption = 'Bank Code';
        }
        field(6; "Agent Code"; Text[9])
        {
            Caption = 'Agent Code';
        }
        field(7; "Currency Code"; Text[1])
        {
            Caption = 'Currency Code';
        }
        field(8; "Account Owner Code"; Text[9])
        {
            Caption = 'Account Owner Code';
        }
        field(9; "Account No."; Text[15])
        {
            Caption = 'Account No.';
        }
        field(10; "Banks Posting Date"; Date)
        {
            Caption = 'Banks Posting Date';
        }
        field(11; "Banks Payment Date"; Date)
        {
            Caption = 'Banks Payment Date';
        }
        field(12; "Filing Code"; Text[16])
        {
            Caption = 'Filing Code';
        }
        field(13; "Reference No."; Code[20])
        {
            Caption = 'Reference No.';
        }
        field(14; "Payers Name"; Text[12])
        {
            Caption = 'Payers Name';
        }
        field(15; "Currency Code 2"; Text[1])
        {
            Caption = 'Currency Code 2';
        }
        field(16; "Name Source"; Text[1])
        {
            Caption = 'Name Source';
        }
        field(17; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(18; "Correction Code"; Text[1])
        {
            Caption = 'Correction Code';
        }
        field(19; "Delivery Method"; Text[1])
        {
            Caption = 'Delivery Method';
        }
        field(20; "Feedback Code"; Text[1])
        {
            Caption = 'Feedback Code';
        }
        field(21; "Transaction Qty."; Text[6])
        {
            Caption = 'Transaction Qty.';
        }
        field(22; "Payments Qty."; Decimal)
        {
            Caption = 'Payments Qty.';
        }
        field(23; "Corrections Qty."; Text[6])
        {
            Caption = 'Corrections Qty.';
        }
        field(24; "Corrections Amount"; Decimal)
        {
            Caption = 'Corrections Amount';
        }
        field(25; "Failed Direct Debiting Qty."; Text[6])
        {
            Caption = 'Failed Direct Debiting Qty.';
        }
        field(26; "Failed Direct Debiting Amount"; Decimal)
        {
            Caption = 'Failed Direct Debiting Amount';
        }
        field(28; Matched; Boolean)
        {
            Caption = 'Matched';
        }
        field(29; "Matched Date"; Date)
        {
            Caption = 'Matched Date';
        }
        field(30; "Matched Time"; Time)
        {
            Caption = 'Matched Time';
        }
        field(31; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry"."Entry No." where(Open = const(true),
                                                                    "Customer No." = field("Customer No."));

            trigger OnValidate()
            begin
                if ("Entry No." <> xRec."Entry No.") and ("Entry No." <> 0) then begin
                    CustEntry.Get("Entry No.");
                    "Document No." := CustEntry."Document No.";
                end else
                    "Document No." := '';
            end;
        }
        field(35; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            TableRelation = "Bank Account";
        }
        field(36; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(37; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";

            trigger OnValidate()
            begin
                if ("Customer No." <> xRec."Customer No.") and ("Customer No." <> '') then begin
                    Cust.Get("Customer No.");
                    Description := CopyStr(Cust.Name, 1, MaxStrLen(Description));
                end else
                    if "Customer No." = '' then
                        Description := '';
            end;
        }
        field(38; Description; Text[35])
        {
            Caption = 'Description';
        }
        field(40; "Posted to G/L"; Boolean)
        {
            Caption = 'Posted to G/L';
            Editable = false;
        }
        field(41; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(42; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Filing Code", "Record ID")
        {
        }
        key(Key3; "Banks Payment Date", "Filing Code", "Customer No.")
        {
        }
        key(Key4; "Banks Posting Date", "Bank Code", "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Cust: Record Customer;
        CustEntry: Record "Cust. Ledger Entry";
}

