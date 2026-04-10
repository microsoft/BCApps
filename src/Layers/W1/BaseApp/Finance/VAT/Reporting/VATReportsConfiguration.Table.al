// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Reflection;

/// <summary>
/// Configures VAT report types with associated codeunit handlers for processing and submission workflows.
/// Defines the framework for extensible VAT reporting with customizable processing logic.
/// </summary>
table 746 "VAT Reports Configuration"
{
    Caption = 'VAT Reports Configuration';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of VAT report defining the processing framework and submission requirements.
        /// </summary>
        field(1; "VAT Report Type"; Enum "VAT Report Configuration")
        {
            Caption = 'VAT Report Type';
            ToolTip = 'Specifies if you want to create a new VAT report, or if you want to change a previously submitted report.';
        }
        /// <summary>
        /// Version identifier for VAT report configuration allowing multiple versions per type.
        /// </summary>
        field(2; "VAT Report Version"; Code[10])
        {
            Caption = 'VAT Report Version';
            ToolTip = 'Specifies the version of the VAT report.';
        }
        /// <summary>
        /// Codeunit ID responsible for suggesting VAT statement lines for report generation.
        /// </summary>
        field(3; "Suggest Lines Codeunit ID"; Integer)
        {
            Caption = 'Suggest Lines Codeunit ID';
            ToolTip = 'Specifies whether an ID is suggested automatically.';
            TableRelation = "CodeUnit Metadata".ID;
        }
        /// <summary>
        /// Display caption of the suggest lines codeunit for user identification.
        /// </summary>
        field(4; "Suggest Lines Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Suggest Lines Codeunit ID")));
            Caption = 'Suggest Lines Codeunit Caption';
            ToolTip = 'Specifies whether a caption is suggested automatically.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Codeunit ID responsible for generating report content and formatting.
        /// </summary>
        field(5; "Content Codeunit ID"; Integer)
        {
            Caption = 'Content Codeunit ID';
            ToolTip = 'Specifies the codeunit ID.';
            TableRelation = "CodeUnit Metadata".ID;
        }
        /// <summary>
        /// Display caption of the content codeunit for user identification.
        /// </summary>
        field(6; "Content Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Content Codeunit ID")));
            Caption = 'Content Codeunit Caption';
            ToolTip = 'Specifies the codeunit caption code.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Codeunit ID responsible for submitting VAT reports to tax authorities.
        /// </summary>
        field(7; "Submission Codeunit ID"; Integer)
        {
            Caption = 'Submission Codeunit ID';
            ToolTip = 'Specifies the ID associated with the submission codeunit.';
            TableRelation = "CodeUnit Metadata".ID;
        }
        /// <summary>
        /// Display caption of the submission codeunit for user identification.
        /// </summary>
        field(8; "Submission Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Submission Codeunit ID")));
            Caption = 'Submission Codeunit Caption';
            ToolTip = 'Specifies the caption associated with the submission codeunit.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Codeunit ID responsible for handling responses from tax authority submissions.
        /// </summary>
        field(9; "Response Handler Codeunit ID"; Integer)
        {
            Caption = 'Response Handler Codeunit ID';
            ToolTip = 'Specifies the codeunit ID of the response handler.';
            TableRelation = "CodeUnit Metadata".ID;
        }
        /// <summary>
        /// Display caption of the response handler codeunit for user identification.
        /// </summary>
        field(10; "Resp. Handler Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Response Handler Codeunit ID")));
            Caption = 'Resp. Handler Codeunit Caption';
            ToolTip = 'Specifies the name of the caption that related to the line.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Codeunit ID responsible for validating VAT report data before submission.
        /// </summary>
        field(11; "Validate Codeunit ID"; Integer)
        {
            Caption = 'Validate Codeunit ID';
            ToolTip = 'Specifies the codeunit ID for the VAT Report line.';
            TableRelation = "CodeUnit Metadata".ID;
        }
        /// <summary>
        /// Display caption of the validate codeunit for user identification.
        /// </summary>
        field(12; "Validate Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Validate Codeunit ID")));
            Caption = 'Validate Codeunit Caption';
            ToolTip = 'Specifies the caption for the codeunit VAT Report.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// VAT statement template used as the basis for generating report lines.
        /// </summary>
        field(13; "VAT Statement Template"; Code[10])
        {
            Caption = 'VAT Statement Template';
            TableRelation = "VAT Statement Template".Name;
        }
        /// <summary>
        /// VAT statement name within the template used for report line generation.
        /// </summary>
        field(14; "VAT Statement Name"; Code[10])
        {
            Caption = 'VAT Statement Name';
            TableRelation = "VAT Statement Name".Name;
        }
    }

    keys
    {
        key(Key1; "VAT Report Type", "VAT Report Version")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

