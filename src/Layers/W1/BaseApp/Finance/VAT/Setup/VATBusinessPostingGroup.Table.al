// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

/// <summary>
/// Defines VAT business posting groups that categorize customers and vendors by their VAT characteristics.
/// Used in combination with VAT product posting groups to determine VAT calculation rules and G/L account assignments.
/// </summary>
/// <remarks>
/// Key relationships: Combined with VAT Product Posting Groups in VAT Posting Setup for VAT calculations.
/// Integration points: Customer/Vendor cards, sales/purchase documents, VAT ledger entry creation.
/// Extensibility: VAT business posting group extensions support additional VAT categorization requirements.
/// </remarks>
table 323 "VAT Business Posting Group"
{
    Caption = 'VAT Business Posting Group';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "VAT Business Posting Groups";
    LookupPageID = "VAT Business Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier code for the VAT business posting group.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the posting group that determines how to calculate and post VAT for customers and vendors. The number of VAT posting groups that you set up can depend on local legislation and whether you trade both domestically and internationally.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name explaining the VAT business posting group's purpose and scope.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the posting group that determines how to calculate and post VAT for customers and vendors. The number of VAT posting groups that you set up can depend on local legislation and whether you trade both domestically and internationally.';
        }
        /// <summary>
        /// Timestamp indicating when this VAT business posting group was last modified.
        /// </summary>
        field(10; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
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
        "Last Modified Date Time" := CurrentDateTime;
    end;
}
