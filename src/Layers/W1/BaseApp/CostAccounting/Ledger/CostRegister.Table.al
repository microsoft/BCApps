// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Ledger;

using Microsoft.CostAccounting.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Security.AccessControl;

table 1105 "Cost Register"
{
    Caption = 'Cost Register';
    DataClassification = CustomerContent;
    LookupPageID = "Cost Registers";

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            Editable = false;
        }
        field(2; Source; Enum "Cost Register Source")
        {
            Caption = 'Source';
            Editable = false;
        }
        field(3; Text; Text[30])
        {
            Caption = 'Text';
            Editable = false;
        }
        field(4; "From G/L Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'From G/L Entry No.';
            Editable = false;
            TableRelation = "G/L Entry";
        }
        field(5; "To G/L Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'To G/L Entry No.';
            Editable = false;
            TableRelation = "G/L Entry";
        }
        field(6; "From Cost Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'From Cost Entry No.';
            Editable = false;
            TableRelation = "Cost Entry";
        }
        field(7; "To Cost Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'To Cost Entry No.';
            Editable = false;
            TableRelation = "Cost Entry";
        }
        field(8; "No. of Entries"; Integer)
        {
            Caption = 'No. of Entries';
            Editable = false;
        }
        field(15; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            Editable = false;
        }
        field(16; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            Editable = false;
        }
        field(20; "Processed Date"; Date)
        {
            Caption = 'Processed Date';
            Editable = false;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(23; Closed; Boolean)
        {
            Caption = 'Closed';

            trigger OnValidate()
            begin
                if xRec.Closed and not Closed then
                    Error(Text000);

                if Closed and not xRec.Closed then begin
                    if not Confirm(Text001, false, "No.") then begin
                        Closed := not Closed;
                        exit;
                    end;

                    CostRegister.SetRange("No.", 1, "No.");
                    CostRegister := Rec;
                    CostRegister.SetRange(Closed, false);
                    CostRegister.ModifyAll(Closed, true);
                    Get("No.");
                end;
            end;
        }
        field(25; Level; Integer)
        {
            BlankZero = true;
            Caption = 'Level';
            Editable = false;
        }
        field(26; "Posting Time"; Time)
        {
            Caption = 'Posting Time';
        }
        field(31; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(32; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            Editable = false;
            TableRelation = "Cost Journal Template";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Source)
        {
        }
        key(Key3; Closed)
        {
        }
    }

    fieldgroups
    {
    }

    var
        CostRegister: Record "Cost Register";
#pragma warning disable AA0074
        Text000: Label 'A closed register cannot be reactivated.';
#pragma warning disable AA0470
        Text001: Label 'All registers up to the current register %1 will be closed and can no longer be deleted.\\Do you want to close the registers?';
#pragma warning restore AA0470
#pragma warning restore AA0074
}
