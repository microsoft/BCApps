// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Reflection;

/// <summary>
/// Defines VAT statement templates that serve as containers for organizing VAT statement names and lines.
/// Provides framework for different VAT calculation and reporting scenarios with customizable page and report assignments.
/// </summary>
table 255 "VAT Statement Template"
{
    Caption = 'VAT Statement Template';
    LookupPageID = "VAT Statement Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique name identifier for the VAT statement template.
        /// </summary>
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the VAT statement template you are about to create.';
            NotBlank = true;
        }
        /// <summary>
        /// Description of the VAT statement template purpose and usage.
        /// </summary>
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the VAT statement template.';
        }
        /// <summary>
        /// Page ID for the VAT statement interface associated with this template.
        /// </summary>
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    "Page ID" := PAGE::"VAT Statement";
                "VAT Statement Report ID" := REPORT::"VAT Statement";
            end;
        }
        /// <summary>
        /// Report ID for generating VAT statement reports from this template.
        /// </summary>
        field(7; "VAT Statement Report ID"; Integer)
        {
            Caption = 'VAT Statement Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        /// <summary>
        /// Display caption of the associated VAT statement page.
        /// </summary>
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Display caption of the associated VAT statement report.
        /// </summary>
        field(17; "VAT Statement Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("VAT Statement Report ID")));
            Caption = 'VAT Statement Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        VATStmtLine.SetRange("Statement Template Name", Name);
        VATStmtLine.DeleteAll();
        VATStmtName.SetRange("Statement Template Name", Name);
        VATStmtName.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        VATStmtName: Record "VAT Statement Name";
        VATStmtLine: Record "VAT Statement Line";
}

