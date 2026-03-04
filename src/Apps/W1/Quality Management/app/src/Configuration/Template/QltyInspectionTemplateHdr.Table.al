// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;

/// 
/// <summary>
/// A Quality Inspection Template is an inspection plan containing a set of questions and data points that you want to collect.
/// A place where the contents of what goes in an inspection are defined.
/// </summary>
table 20402 "Qlty. Inspection Template Hdr."
{
    Caption = 'Quality Inspection Template Header';
    DrillDownPageId = "Qlty. Inspection Template List";
    LookupPageId = "Qlty. Inspection Template List";
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
            ToolTip = 'Specifies an explanation of the Quality Inspection Template. You can enter a maximum of 100 characters, both numbers and letters.';
        }
        field(7; "Copied From Template Code"; Code[20])
        {
            Caption = 'Copied From Template Code';
            ToolTip = 'Specifies where a template was copied from.';
        }
        field(17; "Sample Source"; Enum "Qlty. Sample Size Source")
        {
            Caption = 'Sample Source';
            ToolTip = 'Specifies how the Sample Size initially gets set. Values are rounded up to the nearest whole number.';
        }
        field(18; "Sample Fixed Amount"; Integer)
        {
            Caption = 'Sample Amount';
            ToolTip = 'Specifies the discrete fixed sample amount when Sample Source is set to a fixed quantity. Samples can only be discrete units. If the quantity here exceeds the Source Quantity then the Source Quantity will be used instead.';
        }
        field(19; "Sample Percentage"; Decimal)
        {
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
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        QltyInspectionTemplateLine.SetRange("Template Code", Code);
        QltyInspectionTemplateLine.DeleteAll(true);

        QltyInspectionGenRule.SetRange("Template Code", Code);
        QltyInspectionGenRule.DeleteAll();
    end;

    trigger OnRename()
    var
        RenameQltyInspectionLine: Record "Qlty. Inspection Line";
    begin
        if (xRec."Code" <> '') and (Rec."Code" <> '') and (xRec."Code" <> Rec."Code") then begin
            RenameQltyInspectionLine.SetRange("Template Code", xRec."Code");
            RenameQltyInspectionLine.ModifyAll("Template Code", Rec."Code");
        end;
    end;

    /// <summary>
    /// Adds the supplied test to the template if it does not already exist.
    /// If it already exists then it will not add the test.
    /// </summary>
    /// <param name="TestCode"></param>
    procedure AddTestToTemplate(TestCode: Code[20]): Boolean
    var
        DummyQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        exit(AddTestToTemplate(TestCode, DummyQltyInspectionTemplateLine));
    end;

    /// <summary>
    /// Adds the supplied test to the template if it does not already exist.
    /// If it already exists then it will not add the test and it will simply find it.
    /// </summary>
    /// <param name="TestCode"></param>
    /// <param name="QltyInspectionTemplateLine">the template line</param>
    procedure AddTestToTemplate(TestCode: Code[20]; var QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"): Boolean
    begin
        QltyInspectionTemplateLine.Reset();
        QltyInspectionTemplateLine.SetRange("Template Code", Rec.Code);
        QltyInspectionTemplateLine.SetRange("Test Code", TestCode);
        if not QltyInspectionTemplateLine.FindFirst() then begin
            Clear(QltyInspectionTemplateLine);
            QltyInspectionTemplateLine.Init();
            QltyInspectionTemplateLine."Template Code" := Rec.Code;
            QltyInspectionTemplateLine.InitLineNoIfNeeded();
            QltyInspectionTemplateLine.Validate("Test Code", TestCode);
            QltyInspectionTemplateLine.Insert(true);
            QltyInspectionTemplateLine.EnsureResultsExist(true);
            QltyInspectionTemplateLine.Modify();
            exit(true);
        end;

        exit(false);
    end;
}
