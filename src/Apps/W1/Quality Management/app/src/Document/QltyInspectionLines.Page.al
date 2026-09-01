// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.QualityManagement.AccessControl;
using System.Environment.Configuration;

/// <summary>
/// Introduced to make it easier to analyze inspection line values changes over time.
/// </summary>
page 20413 "Qlty. Inspection Lines"
{
    Caption = 'Quality Inspection Lines';
    PageType = List;
    SourceTable = "Qlty. Inspection Line";
    SourceTableView = sorting("Inspection No.", "Re-inspection No.", "Line No.") order(descending);
    UsageCategory = Lists;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Template Code"; Rec."Template Code")
                {
                }
                field("Inspection No."; Rec."Inspection No.")
                {
                }
                field("Re-inspection No."; Rec."Re-inspection No.")
                {
                }
                field("Line No."; Rec."Line No.")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Test Code"; Rec."Test Code")
                {
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    Editable = false;
                }
                field("Test Value Type"; Rec."Test Value Type")
                {
                }
                field("Allowable Values"; Rec."Allowable Values")
                {
                }
                field("Test Value"; Rec."Test Value")
                {
                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditTestValue();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Test Value", Rec."Test Value");
                        CurrPage.Update(false);
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    Editable = false;
                }
                field("Non-Conformance Inspection No."; Rec."Non-Conformance Inspection No.")
                {
                    Visible = false;
                }
                field("Result Code"; Rec."Result Code")
                {
                    Visible = false;
                }
                field("Result Description"; Rec."Result Description")
                {
                }
                field("Evaluation Sequence"; Rec."Evaluation Sequence")
                {
                    Visible = false;
                }
                field("Derived Numeric Value"; Rec."Derived Numeric Value")
                {
                }
                field(ChooseMeasurementNote; MeasurementNote)
                {
                    AccessByPermission = tabledata "Record Link" = R;
                    Caption = 'Note';
                    Editable = CanEditLineNotes;
                    ToolTip = 'Specifies a free text note associated with the measurement.';

                    trigger OnAssistEdit()
                    begin
                        if not CanEditLineNotes then
                            Rec.RunModalReadOnlyComment()
                        else
                            Rec.RunModalEditMeasurementNote();
                    end;

                    trigger OnValidate()
                    begin
                        if not CanEditLineNotes then
                            exit;
                        Rec.SetMeasurementNote(MeasurementNote);
                    end;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the inspection line was created.';
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified at';
                    ToolTip = 'Specifies the date and time when the inspection line was last modified.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                AccessByPermission = tabledata "Record Link" = R;
                Enabled = CanEditLineNotes;
            }
        }
    }

    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        CanEditLineNotes: Boolean;
        MeasurementNote: Text;

    trigger OnOpenPage()
    begin
        CanEditLineNotes := QltyPermissionMgmt.CanEditLineComments();
    end;

    trigger OnAfterGetRecord()
    begin
        MeasurementNote := Rec.GetMeasurementNote();
    end;
}
