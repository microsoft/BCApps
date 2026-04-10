// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Globalization;

/// <summary>
/// Stores multilingual translations for dimension names and captions to support international business operations.
/// Enables dimension display in multiple languages based on user language preferences.
/// </summary>
/// <remarks>
/// Part of the multilingual framework allowing dimension names to appear in users' preferred languages.
/// Automatically generates code and filter captions based on translated dimension names.
/// Integrates with Windows Language settings to provide localized dimension terminology.
/// </remarks>
table 388 "Dimension Translation"
{
    Caption = 'Dimension Translation';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Dimension code for which this translation applies.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = Dimension;
        }
        /// <summary>
        /// Windows language identifier for this translation.
        /// </summary>
        field(2; "Language ID"; Integer)
        {
            Caption = 'Language ID';
            ToolTip = 'Specifies a language code.';
            NotBlank = true;
            TableRelation = "Windows Language";

            trigger OnValidate()
            begin
                CalcFields("Language Name");
            end;
        }
        /// <summary>
        /// Translated name for the dimension in the specified language.
        /// </summary>
        field(3; Name; Text[30])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the dimension code.';

            trigger OnValidate()
            begin
                if "Code Caption" = '' then
                    "Code Caption" := CopyStr(StrSubstNo(Text001, Name), 1, MaxStrLen("Code Caption"));
                if "Filter Caption" = '' then
                    "Filter Caption" := CopyStr(StrSubstNo(Text002, Name), 1, MaxStrLen("Filter Caption"));
            end;
        }
        /// <summary>
        /// Translated caption text for dimension code fields in the specified language.
        /// </summary>
        field(4; "Code Caption"; Text[80])
        {
            Caption = 'Code Caption';
            ToolTip = 'Specifies the name of the dimension code as you want it to appear as a field name after the Language ID code is selected.';
        }
        /// <summary>
        /// Translated caption text for dimension filter fields in the specified language.
        /// </summary>
        field(5; "Filter Caption"; Text[80])
        {
            Caption = 'Filter Caption';
            ToolTip = 'Specifies the dimension filter caption.';
        }
        /// <summary>
        /// Display name of the Windows language from the language table.
        /// </summary>
        field(6; "Language Name"; Text[80])
        {
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Language ID")));
            Caption = 'Language Name';
            ToolTip = 'Specifies the name of the language.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code", "Language ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 Code';
        Text002: Label '%1 Filter';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

