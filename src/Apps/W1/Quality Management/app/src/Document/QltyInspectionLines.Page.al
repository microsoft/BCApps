// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.QualityManagement.AccessControl;

/// <summary>
/// Introduced to make it easier to analyze inspection values changes over time.
/// </summary>
page 20413 "Qlty. Inspection Lines"
{
    Caption = 'Quality Inspection Values';
    PageType = List;
    SourceTable = "Qlty. Inspection Line";
    SourceTableView = sorting("Inspection No.", "Reinspection No.", "Line No.") order(descending);
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
                field("Reinspection No."; Rec."Reinspection No.")
                {
                }
                field("Line No."; Rec."Line No.")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Field Code"; Rec."Field Code")
                {
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    Editable = false;
                }
                field("Field Type"; Rec."Field Type")
                {
                }
                field("Allowable Values"; Rec."Allowable Values")
                {
                }
                field("Test Value"; Rec."Test Value")
                {
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
                field("Result Priority"; Rec."Result Priority")
                {
                    Visible = false;
                }
                field("Numeric Value"; Rec."Numeric Value")
                {
                }
                field(ChooseMeasurementNote; MeasurementNote)
                {
                    Caption = 'Note';
                    Visible = CanSeeLineNotes;
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
                Visible = CanSeeLineNotes;
                Enabled = CanEditLineNotes;
            }
        }
    }

    protected var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        CanEditLineNotes: Boolean;
        CanSeeLineNotes: Boolean;
        MeasurementNote: Text;

    trigger OnOpenPage()
    begin
        CanEditLineNotes := QltyPermissionMgmt.CanEditLineComments();
        CanSeeLineNotes := QltyPermissionMgmt.CanReadLineComments();
    end;

    trigger OnAfterGetRecord()
    begin
        MeasurementNote := Rec.GetMeasurementNote();
    end;
}
