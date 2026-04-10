// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

/// <summary>
/// Stores diagnostic results for intercompany setup validation and configuration verification.
/// Used for displaying setup issues and validation status in diagnostic reports.
/// </summary>
table 33 "Intercompany Setup Diagnostic"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for diagnostic category or validation area.
        /// </summary>
        field(1; Id; Code[20])
        {

        }
        /// <summary>
        /// Description of diagnostic finding or validation result message.
        /// </summary>
        field(2; Description; Text[250])
        {

        }
        /// <summary>
        /// Validation status indicating severity level of diagnostic result.
        /// </summary>
        field(3; Status; Option)
        {
            OptionMembers = Ok,Warning,Error;
        }
    }
    keys
    {
        key(Key1; Id, Description)
        {
        }
    }
}
