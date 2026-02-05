// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Globalization;

/// <summary>
/// Stores translated reminder note text for different languages linked to reminder terms.
/// </summary>
table 1052 "Reminder Terms Translation"
{
    Caption = 'Reminder Terms Translation';
    DrillDownPageID = "Reminder Terms Translation";
    LookupPageID = "Reminder Terms Translation";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the reminder terms to which this translation belongs.
        /// </summary>
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            TableRelation = "Reminder Terms";
        }
        /// <summary>
        /// Specifies the language code for this translation.
        /// </summary>
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            NotBlank = true;
            TableRelation = Language;
        }
        /// <summary>
        /// Contains the translated note about line fees that appears on reminder reports in this language.
        /// </summary>
        field(3; "Note About Line Fee on Report"; Text[150])
        {
            Caption = 'Note About Line Fee on Report';
        }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

