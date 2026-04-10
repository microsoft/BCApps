// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Stores error messages generated during VAT report validation and processing.
/// Provides temporary storage for displaying validation errors to users before report release.
/// </summary>
table 745 "VAT Report Error Log"
{
    Caption = 'VAT Report Error Log';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the error log entry within the validation session.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        /// <summary>
        /// Error message text describing the validation issue or processing error.
        /// </summary>
        field(2; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            ToolTip = 'Specifies the error message that is the result of validating a VAT report.';
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
}

