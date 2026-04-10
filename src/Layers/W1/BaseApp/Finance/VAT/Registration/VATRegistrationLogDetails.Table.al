// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

/// <summary>
/// Stores detailed field-level validation results from VAT registration number verification services.
/// Tracks requested values, service responses, and current field values for audit and reconciliation purposes.
/// </summary>
table 227 "VAT Registration Log Details"
{
    Caption = 'VAT Registration Log Details';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference to the parent VAT registration log entry.
        /// </summary>
        field(1; "Log Entry No."; Integer)
        {
            Caption = 'Log Entry No.';
            TableRelation = "VAT Registration Log";
        }
        /// <summary>
        /// Name of the field that was validated by the VAT registration service.
        /// </summary>
        field(2; "Field Name"; Enum "VAT Reg. Log Details Field")
        {
            Caption = 'Field Name';
            ToolTip = 'Specifies the name of the field that has been validated by the VAT registration no. validation service.';
        }
        /// <summary>
        /// Type of account associated with this validation detail record.
        /// </summary>
        field(10; "Account Type"; Enum "VAT Registration Log Account Type")
        {
            Caption = 'Account Type';
        }
        /// <summary>
        /// Account number associated with this validation detail record.
        /// </summary>
        field(11; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        /// <summary>
        /// Value that was requested for validation from the VAT registration service.
        /// </summary>
        field(20; "Requested"; Text[150])
        {
            Caption = 'Requested';
            ToolTip = 'Specifies the requested value.';
        }
        /// <summary>
        /// Value returned by the VAT registration validation service.
        /// </summary>
        field(21; "Response"; Text[150])
        {
            Caption = 'Response';
            ToolTip = 'Specifies the value that was returned by the service.';
        }
        /// <summary>
        /// Current value stored in the Business Central system for comparison.
        /// </summary>
        field(22; "Current Value"; Text[150])
        {
            Caption = 'Current Value';
            ToolTip = 'Specifies the current value.';
        }
        /// <summary>
        /// Validation status indicating whether the field values match the service response.
        /// </summary>
        field(23; Status; Enum "VAT Reg. Log Details Field Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the field validation.';
        }
    }

    keys
    {
        key(PK; "Log Entry No.", "Field Name")
        {
            Clustered = true;
        }
    }
}
