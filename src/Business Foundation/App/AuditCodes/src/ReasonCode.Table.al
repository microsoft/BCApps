// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

/// <summary>
/// Reason codes supplement the source codes and are used to indicate why an entry was created.
/// </summary>
/// <remarks>
/// https://learn.microsoft.com/en-us/dynamics365/business-central/finance-setup-trail-codes
/// </remarks>
table 231 "Reason Code"
{
    Caption = 'Reason Code';
    LookupPageID = "Reason Codes";
    DataClassification = CustomerContent;
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';

    fields
    {
        /// <summary>
        /// The reason code. Use codes that are easy to remember and descriptive.
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
        fieldgroup(Brick; "Code", Description)
        {
        }
    }
}

