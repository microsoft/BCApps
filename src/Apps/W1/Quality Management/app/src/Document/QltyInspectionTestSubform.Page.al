// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Subform Page for Quality Inspections.
/// </summary>
page 20407 "Qlty. Inspection Subform"
{
    Caption = 'Quality Inspection Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Qlty. Inspection Line";
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(GroupLinesRepeater)
            {
                ShowCaption = false;

                field("Line No."; Rec."Line No.")
                {
                    StyleExpr = RowStyleText;
                    Editable = false;
                    Visible = false;
                }
                field("Field Code"; Rec."Field Code")
                {
                    Editable = false;
                    StyleExpr = RowStyleText;
                }
                field(Description; Rec.Description)
                {
                    Editable = false;
                    StyleExpr = RowStyleText;
                }
                field("Field Type"; Rec."Field Type")
                {
                    Visible = false;
                }
                field("Test Value"; Rec."Test Value")
                {
                    StyleExpr = RowStyleText;
                    Editable = CanEditTestValue;

                    trigger OnAssistEdit()
                    begin
                        UpdateRowData();

                        CurrPage.Update(true);
                        Rec.AssistEditTestValue();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateRowData();
                        if not CanEditTestValue then
                            exit;

                        Rec.Validate("Test Value", Rec."Test Value");
                        CurrPage.Update(false);
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    Visible = ShowUnitOfMeasure;
                    Editable = false;
                }
                field("NCR Test No."; Rec."NCR Test No.")
                {
                    Visible = false;
                }
                field(Field1; MatrixArrayConditionCellData[1])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[1];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                    Visible = false;
                }
                field(Field1_Desc; MatrixArrayConditionDescriptionCellData[1])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[1] + ' Description';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                    Visible = Visible1;
                }

                field(Field2; MatrixArrayConditionCellData[2])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[2];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 2';
                    Visible = false;
                }
                field(Field2_Desc; MatrixArrayConditionDescriptionCellData[2])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[2] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 2';
                    Visible = Visible2;
                }
                field(Field3; MatrixArrayConditionCellData[3])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[3];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                    Visible = false;
                }
                field(Field3_Desc; MatrixArrayConditionDescriptionCellData[3])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[3] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                    Visible = Visible3;
                }
                field(Field4; MatrixArrayConditionCellData[4])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[4];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 4';
                    Visible = false;
                }
                field(Field4_Desc; MatrixArrayConditionDescriptionCellData[4])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[4] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 4';
                    Visible = Visible4;
                }
                field(Field5; MatrixArrayConditionCellData[5])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[5];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 5';
                    Visible = false;
                }
                field(Field5_Desc; MatrixArrayConditionDescriptionCellData[5])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[5] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 5';
                    Visible = Visible5;
                }
                field(Field6; MatrixArrayConditionCellData[6])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[6];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 6';
                    Visible = false;
                }
                field(Field6_Desc; MatrixArrayConditionDescriptionCellData[6])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[6] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 6';
                    Visible = Visible6;
                }
                field(Field7; MatrixArrayConditionCellData[7])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[7];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 7';
                    Visible = false;
                }
                field(Field7_Desc; MatrixArrayConditionDescriptionCellData[7])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[7] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 7';
                    Visible = Visible7;
                }
                field(Field8; MatrixArrayConditionCellData[8])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[8];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 8';
                    Visible = false;
                }
                field(Field8_Desc; MatrixArrayConditionDescriptionCellData[8])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[8] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 8';
                    Visible = Visible8;
                }
                field(Field9; MatrixArrayConditionCellData[9])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[9];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 9';
                    Visible = false;
                }
                field(Field9_Desc; MatrixArrayConditionDescriptionCellData[9])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[9] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 9';
                    Visible = Visible9;
                }
                field(Field10; MatrixArrayConditionCellData[10])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[10];
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 10';
                    Visible = false;
                }
                field(Field10_Desc; MatrixArrayConditionDescriptionCellData[10])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[10] + ' Desc.';
                    Editable = false;
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 10';
                    Visible = Visible10;
                }
                field("Grade Code"; Rec."Grade Code")
                {
                    Visible = false;
                    StyleExpr = GradeStyleExpr;
                }
                field("Grade Description"; Rec."Grade Description")
                {
                    StyleExpr = GradeStyleExpr;
                }
                field("Grade Priority"; Rec."Grade Priority")
                {
                    Visible = false;
                }
                field("Allowable Values"; Rec."Allowable Values")
                {
                    Visible = false;
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
            }
        }
    }

    protected var
        CachedReadOnlyQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixArrayConditionCellData: array[10] of Text;
        MatrixArrayConditionDescriptionCellData: array[10] of Text;
        MatrixArrayCaptionSet: array[10] of Text;
        MatrixVisibleState: array[10] of Boolean;
        CanEditTestValue: Boolean;
        Visible1: Boolean;
        Visible2: Boolean;
        Visible3: Boolean;
        Visible4: Boolean;
        Visible5: Boolean;
        Visible6: Boolean;
        Visible7: Boolean;
        Visible8: Boolean;
        Visible9: Boolean;
        Visible10: Boolean;
        CanEditLineNotes: Boolean;
        CanSeeLineNotes: Boolean;
        ShowUnitOfMeasure: Boolean;
        GradeStyleExpr: Text;
        MeasurementNote: Text;
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        RowStyleText: Text;
        CurrentSelectedTestLineTok: Label 'CurrentSelectedTestLine', Locked = true;

    trigger OnOpenPage()
    begin
        CanEditLineNotes := QltyPermissionMgmt.CanEditLineComments() and CurrPage.Editable();
        CanSeeLineNotes := QltyPermissionMgmt.CanReadLineComments();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        QltyInspectionLine: Record "Qlty. Inspection Line";
    begin
        QltyInspectionLine.CopyFilters(Rec);
        QltyInspectionLine.SetFilter("Unit of Measure Code", '<>''''');
        ShowUnitOfMeasure := not QltyInspectionLine.IsEmpty();
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        RowStyle := RowStyle::None;

        Rec.CalcFields("Field Type");
        if Rec."Field Type" = Rec."Field Type"::"Field Type Label" then
            RowStyle := RowStyle::Strong;

        GradeStyleExpr := Rec.GetGradeStyle();

        RowStyleText := Format(RowStyle);

        UpdateRowData();
    end;

    trigger OnAfterGetCurrRecord()
    var
        QltySessionHelper: Codeunit "Qlty. Session Helper";
    begin
        QltySessionHelper.SetSessionValue(CurrentSelectedTestLineTok, Format(Rec.RecordId()));
        UpdateRowData();
    end;

    local procedure UpdateRowData()
    begin
        MeasurementNote := Rec.GetMeasurementNote();

        if (CachedReadOnlyQltyInspectionHeader."No." <> Rec."Test No.") or (CachedReadOnlyQltyInspectionHeader."Retest No." <> CachedReadOnlyQltyInspectionHeader."Retest No.") then begin
            CachedReadOnlyQltyInspectionHeader.ReadIsolation(IsolationLevel::ReadUncommitted);
            if CachedReadOnlyQltyInspectionHeader.Get(Rec."Test No.", Rec."Retest No.") then;
        end;

        Rec.CalcFields("Field Type");
        CanEditTestValue := GetCanEditTestValue();

        QltyGradeConditionMgmt.GetPromotedGradesForTestLine(Rec, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);

        Visible1 := MatrixVisibleState[1];
        Visible2 := MatrixVisibleState[2];
        Visible3 := MatrixVisibleState[3];
        Visible4 := MatrixVisibleState[4];
        Visible5 := MatrixVisibleState[5];
        Visible6 := MatrixVisibleState[6];
        Visible7 := MatrixVisibleState[7];
        Visible8 := MatrixVisibleState[8];
        Visible9 := MatrixVisibleState[9];
        Visible10 := MatrixVisibleState[10];
    end;

    local procedure GetCanEditTestValue() Result: Boolean
    var
        Handled: Boolean;
    begin
        OnBeforeCanEditTestValue(Rec, Result, Handled);
        if Handled then
            exit;

        Rec.CalcFields("Field Type");
        exit(not (Rec."Field Type" in [Rec."Field Type"::"Field Type Label"]));
    end;

    /// <summary>
    /// Use this event to manipulate the decision if this inspection line can have it's test value edited or not.
    /// </summary>
    /// <param name="QltyInspectionLine"></param>
    /// <param name="CanEditTestValue"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanEditTestValue(var QltyInspectionLine: Record "Qlty. Inspection Line"; var CanEditTestValue: Boolean; var Handled: Boolean)
    begin
    end;
}
