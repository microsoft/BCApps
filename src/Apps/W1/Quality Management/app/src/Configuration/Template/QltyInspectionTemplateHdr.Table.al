// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;

/// 
/// <summary>
/// A Quality Inspection Template is a test plan containing a set of questions and data points that you want to collect.
/// A place where the contents of what goes in an inspection are defined.
/// </summary>
table 20402 "Qlty. Inspection Template Hdr."
{
    Caption = 'Quality Inspection Template Header';
    DrillDownPageID = "Qlty. Inspection Template List";
    LookupPageID = "Qlty. Inspection Template List";
    DataClassification = CustomerContent;
    Permissions = tabledata "Qlty. Inspection Template Line" = d;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the code to identify the Quality Inspection Template set.';

            trigger OnValidate()
            begin
                Rec."Code" := DelChr(Rec."Code", '=', ' ><{}.@!`~''"|\/?&*()');
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            Description = 'Specifies an explanation of the Quality Inspection Template. You can enter a maximum of 100 characters, both numbers and letters.';
            ToolTip = 'Specifies an explanation of the Quality Inspection Template. You can enter a maximum of 100 characters, both numbers and letters.';
        }
        field(7; "Copied From Template Code"; Code[20])
        {
            Description = 'Used to track where a template was copied from.';
            Caption = 'Copied From Template Code';
        }
        field(17; "Sample Source"; Enum "Qlty. Sample Size Source")
        {
            Description = 'Sample Source determines how the Sample Size initially gets set. Values are rounded up to the nearest whole number.';
            Caption = 'Sample Source';
            ToolTip = 'Specifies how the Sample Size initially gets set.';
        }
        field(18; "Sample Fixed Amount"; Integer)
        {
            Description = 'When Sample Source is set to a fixed quantity then this represents a discrete fixed sample size. Samples can only be discrete units.';
            Caption = 'Sample Amount';
            ToolTip = 'Specifies the discrete fixed sample amount when Sample Source is set to a fixed quantity. Samples can only be discrete units. If the quantity here exceeds the Source Quantity then the Source Quantity will be used instead.';
        }
        field(19; "Sample Percentage"; Decimal)
        {
            Description = 'When Sample Source is set to a percentage then this represents the percent of the source quantity to use. Values will be rounded to the highest discrete amount.';
            Caption = 'Sample %';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 2;
            MaxValue = 100;
            MinValue = 0;
            ToolTip = 'Specifies a percentage of the source quantity that will default the sample size. Samples can only be discrete units. Values will be rounded to the highest discrete amount.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        QltyInspectionTemplateLine.SetRange("Template Code", Code);
        QltyInspectionTemplateLine.DeleteAll(true);

        QltyInTestGenerationRule.SetRange("Template Code", Code);
        QltyInTestGenerationRule.DeleteAll();
    end;

    trigger OnRename()
    var
        RenameQltyInspectionTestLine: Record "Qlty. Inspection Test Line";
    begin
        if (xRec."Code" <> '') and (Rec."Code" <> '') and (xRec."Code" <> Rec."Code") then begin
            RenameQltyInspectionTestLine.SetRange("Template Code", xRec."Code");
            RenameQltyInspectionTestLine.ModifyAll("Template Code", Rec."Code");
        end;
    end;

    /// <summary>
    /// Adds the supplied field to the template if it does not already exist.
    /// If it already exists then it will not add the field.
    /// </summary>
    /// <param name="FieldCode"></param>
    procedure AddFieldToTemplate(FieldCode: Code[20]): Boolean
    var
        DummyQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        exit(AddFieldToTemplate(FieldCode, DummyQltyInspectionTemplateLine));
    end;

    /// <summary>
    /// Adds the supplied field to the template if it does not already exist.
    /// If it already exists then it will not add the field and it will simply find it.
    /// </summary>
    /// <param name="FieldCode"></param>
    /// <param name="QltyInspectionTemplateLine">the template line</param>
    procedure AddFieldToTemplate(FieldCode: Code[20]; var QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"): Boolean
    begin
        QltyInspectionTemplateLine.Reset();
        QltyInspectionTemplateLine.SetRange("Template Code", Rec.Code);
        QltyInspectionTemplateLine.SetRange("Field Code", FieldCode);
        if not QltyInspectionTemplateLine.FindFirst() then begin
            Clear(QltyInspectionTemplateLine);
            QltyInspectionTemplateLine.Init();
            QltyInspectionTemplateLine."Template Code" := Rec.Code;
            QltyInspectionTemplateLine.InitLineNoIfNeeded();
            QltyInspectionTemplateLine.Validate("Field Code", FieldCode);
            QltyInspectionTemplateLine.Insert(true);
            QltyInspectionTemplateLine.EnsureGrades(true);
            QltyInspectionTemplateLine.Modify();
            exit(true);
        end;

        exit(false);
    end;
}
