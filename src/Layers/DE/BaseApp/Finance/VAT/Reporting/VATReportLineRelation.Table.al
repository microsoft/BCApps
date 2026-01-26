// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Links VAT report lines to source table entries for tracking which records contribute to reported amounts.
/// Provides audit trail between VAT report lines and underlying data sources like VAT entries or G/L entries.
/// </summary>
table 744 "VAT Report Line Relation"
{
    Caption = 'VAT Report Line Relation';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// VAT report number containing the related line.
        /// </summary>
        field(1; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
            TableRelation = "VAT Report Header"."No.";
        }
        /// <summary>
        /// Line number within the VAT report that this relation applies to.
        /// </summary>
        field(2; "VAT Report Line No."; Integer)
        {
            Caption = 'VAT Report Line No.';
            TableRelation = "VAT Report Line"."Line No.";
        }
        /// <summary>
        /// Sequential line number for multiple relations to the same VAT report line.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Table number identifying the source table type for the related entry.
        /// </summary>
        field(10; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        /// <summary>
        /// Entry number from the source table that contributes to the VAT report line amount.
        /// </summary>
        field(11; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "VAT Report No.", "VAT Report Line No.", "Table No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        // One VAT Report line can have relations only to one table
        VATReportLineRelation.SetRange("VAT Report No.", "VAT Report No.");
        VATReportLineRelation.SetRange("VAT Report Line No.", "VAT Report Line No.");
        if VATReportLineRelation.FindFirst() then
            TestField("Table No.", VATReportLineRelation."Table No.");
    end;
}

