// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

/// <summary>
/// Defines VAT product posting groups that categorize items and services by their VAT characteristics.
/// Used in combination with VAT business posting groups to determine VAT calculation rules and G/L account assignments.
/// </summary>
/// <remarks>
/// Key relationships: Combined with VAT Business Posting Groups in VAT Posting Setup for VAT calculations.
/// Integration points: Item cards, resource cards, sales/purchase lines, VAT ledger entry creation.
/// Extensibility: VAT product posting group extensions support additional VAT categorization requirements.
/// </remarks>
table 324 "VAT Product Posting Group"
{
    Caption = 'VAT Product Posting Group';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "VAT Product Posting Groups";
    LookupPageID = "VAT Product Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier code for the VAT product posting group.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the posting group the determines how to calculate VAT for items or resources that you purchase or sell.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name explaining the VAT product posting group's purpose and scope.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the posting group the determines how to calculate VAT for items or resources that you purchase or sell.';
        }
        /// <summary>
        /// Timestamp indicating when this VAT product posting group was last modified.
        /// </summary>
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
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
        fieldgroup(Brick; Description)
        {
        }
    }

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime();
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;
}
