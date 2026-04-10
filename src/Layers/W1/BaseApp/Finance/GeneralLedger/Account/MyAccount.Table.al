// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.Security.AccessControl;

/// <summary>
/// Stores personalized G/L account favorites for individual users.
/// Allows users to create shortcuts to frequently accessed accounts for quick navigation and monitoring.
/// </summary>
table 9153 "My Account"
{
    Caption = 'My Account';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// User identifier for the account favorite owner.
        /// </summary>
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// The G/L account number that the user has marked as a favorite.
        /// </summary>
        field(2; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            ToolTip = 'Specifies the G/L account number.';
            NotBlank = true;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                SetAccountFields();
            end;
        }
        /// <summary>
        /// The name of the G/L account, populated automatically from the account master data.
        /// </summary>
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the G/L account.';
            Editable = false;
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Legacy account balance field, replaced by "Acc. Balance" to avoid modification issues.
        /// </summary>
        field(5; "Account Balance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Account Balance (to be removed)';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
            ObsoleteReason = 'Replaced by "Acc. Balance" to avoid modification in My Accounts page.';
        }
#endif
        /// <summary>
        /// The totaling filter from the G/L account, used for calculating balances of total-type accounts.
        /// </summary>
        field(7; Totaling; Text[250])
        {
            Caption = 'Totaling';
            Editable = false;
        }
        /// <summary>
        /// Current balance of the G/L account, calculated from posted G/L entries.
        /// </summary>
        field(10; "Acc. Balance"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry".Amount where("G/L Account No." = field("Account No."),
                                                       "G/L Account No." = field(filter(Totaling))));
            Caption = 'Balance';
            ToolTip = 'Specifies the balance of the G/L account.';
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
