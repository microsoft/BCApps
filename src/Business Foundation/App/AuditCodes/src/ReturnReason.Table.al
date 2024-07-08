// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

/// <summary>
/// Return reason codes indicate why a product was returned.
/// </summary>
table 6635 "Return Reason"
{
    Caption = 'Return Reason';
    DataClassification = CustomerContent;
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
    DrillDownPageID = "Return Reasons";
    LookupPageID = "Return Reasons";

    fields
    {
        /// <summary>
        /// The return reason code. Use codes that are easy to remember and descriptive.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// The description field. Enter an explanatory text for the code.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }
}
