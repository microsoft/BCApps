// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Defines named VAT statement configurations within templates for organizing different VAT calculation scenarios.
/// Groups VAT statement lines under named categories for various reporting and calculation purposes.
/// </summary>
table 257 "VAT Statement Name"
{
    Caption = 'VAT Statement Name';
    LookupPageID = "VAT Statement Names";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Template name that this statement name belongs to for organizational structure.
        /// </summary>
        field(1; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            NotBlank = true;
            TableRelation = "VAT Statement Template";
        }
        /// <summary>
        /// Unique name identifier for the VAT statement within the template.
        /// </summary>
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the VAT statement name.';
            NotBlank = true;
        }
        /// <summary>
        /// Description of the VAT statement purpose and usage scenario.
        /// </summary>
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the VAT statement name.';
        }
        /// <summary>
        /// Date filter applied to VAT calculations for this statement.
        /// </summary>
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Statement Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        VATStmtLine.SetRange("Statement Template Name", "Statement Template Name");
        VATStmtLine.SetRange("Statement Name", Name);
        VATStmtLine.DeleteAll();
    end;

    trigger OnRename()
    begin
        VATStmtLine.SetRange("Statement Template Name", xRec."Statement Template Name");
        VATStmtLine.SetRange("Statement Name", xRec.Name);
        while VATStmtLine.FindFirst() do
            VATStmtLine.Rename("Statement Template Name", Name, VATStmtLine."Line No.");
    end;

    var
        VATStmtLine: Record "VAT Statement Line";
}

