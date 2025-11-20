// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.Security.AccessControl;

table 9153 "My Account"
{
    Caption = 'My Account';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            NotBlank = true;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                SetAccountFields();
            end;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            Editable = false;
        }
#if not CLEANSCHEMA29
        field(5; "Account Balance"; Decimal)
        {
            Caption = 'Account Balance (to be removed)';
            Editable = false;
#if CLEAN26
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
            ObsoleteReason = 'Replaced by "Acc. Balance" to avoid modification in My Accounts page.';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
            ObsoleteReason = 'Replaced by "Acc. Balance" to avoid modification in My Accounts page.';
#endif
        }
#endif
        field(7; Totaling; Text[250])
        {
            Caption = 'Totaling';
            Editable = false;
        }
        field(10; "Acc. Balance"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry".Amount where("G/L Account No." = field("Account No."),
                                                       "G/L Account No." = field(filter(Totaling))));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User ID", "Account No.")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
    }

    local procedure SetAccountFields()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetLoadFields("Name", Totaling);
        if GLAccount.Get("Account No.") then begin
            Name := GLAccount.Name;
            Totaling := GLAccount.Totaling;
        end;
    end;
}
