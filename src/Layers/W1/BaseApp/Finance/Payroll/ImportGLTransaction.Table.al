// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Payroll;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Stores mapping between external payroll accounts and G/L accounts for import processing.
/// Used during payroll import to determine correct G/L account assignments.
/// </summary>
/// <remarks>
/// Supports account mapping persistence across imports. Auto-suggests G/L accounts based on previous mappings.
/// Key relationships: Links to G/L Account with validation for posting accounts only.
/// </remarks>
table 1661 "Import G/L Transaction"
{
    Caption = 'Import G/L Transaction';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Identifies the payroll service application that owns this mapping.
        /// </summary>
        field(1; "App ID"; Guid)
        {
            Caption = 'App ID';
            Editable = false;
        }
        /// <summary>
        /// External account code from the payroll system that needs mapping to G/L accounts.
        /// Auto-suggests G/L account based on previous mappings when validated.
        /// </summary>
        field(2; "External Account"; Code[50])
        {
            Caption = 'External Account';

            trigger OnValidate()
            var
                ImportGLTransaction: Record "Import G/L Transaction";
            begin
                if "External Account" = '' then
                    exit;
                ImportGLTransaction.SetRange("App ID", "App ID");
                ImportGLTransaction.SetRange("External Account", "External Account");
                if ImportGLTransaction.FindFirst() then
                    Validate("G/L Account", ImportGLTransaction."G/L Account");
            end;
        }
        /// <summary>
        /// Target G/L account for posting payroll transactions from the external account.
        /// Restricted to unblocked posting accounts with direct posting enabled.
        /// </summary>
        field(3; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            TableRelation = "G/L Account" where(Blocked = const(false),
                                                 "Direct Posting" = const(true),
                                                 "Account Type" = const(Posting));
        }
        /// <summary>
        /// Display name of the selected G/L account for user reference.
        /// </summary>
        field(4; "G/L Account Name"; Text[100])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("G/L Account")));
            Caption = 'G/L Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Unique sequential identifier for import transaction entries.
        /// </summary>
        field(5; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Date when the payroll transaction occurred.
        /// </summary>
        field(10; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        /// <summary>
        /// Monetary amount of the payroll transaction.
        /// </summary>
        field(12; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Descriptive text explaining the nature of the payroll transaction.
        /// </summary>
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "App ID", "Entry No.")
        {
        }
        key(Key2; "App ID", "External Account", "Transaction Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
