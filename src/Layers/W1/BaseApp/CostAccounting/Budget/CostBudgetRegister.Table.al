// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Journal;
using Microsoft.Finance.GeneralLedger.Budget;
using System.Security.AccessControl;

table 1111 "Cost Budget Register"
{
    Caption = 'Cost Budget Register';
    DataClassification = CustomerContent;
    LookupPageID = "Cost Budget Registers";

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            Editable = false;
        }
        field(2; Source; Option)
        {
            Caption = 'Source';
            Editable = false;
            OptionCaption = 'Transfer from G/L Budget,Cost Journal,Allocation,Manual';
            OptionMembers = "Transfer from G/L Budget","Cost Journal",Allocation,Manual;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(4; "From Budget Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'From Budget Entry No.';
            Editable = false;
            TableRelation = "G/L Budget Entry";
        }
        field(5; "To Budget Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'To Budget Entry No.';
            Editable = false;
            TableRelation = "G/L Budget Entry";
        }
        field(6; "From Cost Budget Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'From Cost Budget Entry No.';
            Editable = false;
            TableRelation = "Cost Budget Entry";
        }
        field(7; "To Cost Budget Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'To Cost Budget Entry No.';
            Editable = false;
            TableRelation = "Cost Budget Entry";
        }
        field(8; "No. of Entries"; Integer)
        {
            Caption = 'No. of Entries';
            Editable = false;
        }
        field(15; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';
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
                    if not Confirm(Text001, false, "No.") then
                        Error('');

                    CostBudgetRegister2.SetRange("No.", 1, "No.");
                    CostBudgetRegister2 := Rec;
                    CostBudgetRegister2.SetRange(Closed, false);
                    CostBudgetRegister2.ModifyAll(Closed, true);
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
        field(33; "Cost Budget Name"; Code[10])
        {
            Caption = 'Cost Budget Name';
            Editable = false;
            TableRelation = "Cost Budget Name";
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
        key(Key3; "Cost Budget Name")
        {
        }
        key(Key4; "From Cost Budget Entry No.", "To Cost Budget Entry No.")
        {
        }
        key(Key5; Closed)
        {
        }
    }

    fieldgroups
    {
    }

    var
        CostBudgetRegister2: Record "Cost Budget Register";
#pragma warning disable AA0074
        Text000: Label 'A closed register cannot be reactivated.';
#pragma warning disable AA0470
        Text001: Label 'All registers up to the current register %1 will be closed and can no longer be deleted.\\Do you want to close the registers?';
#pragma warning restore AA0470
#pragma warning restore AA0074
}
