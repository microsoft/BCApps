// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.UOM;

using System.Globalization;

table 5402 "Unit of Measure Translation"
{
    Caption = 'Unit of Measure Translation';
    LookupPageID = "Unit of Measure Translation";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the unit of measure code for which you want to enter a translation.';
            NotBlank = true;
            TableRelation = "Unit of Measure";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
            NotBlank = true;
            TableRelation = Language;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the unit of measure code that corresponds to Code in the selected foreign language.';
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

