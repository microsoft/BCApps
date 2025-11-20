// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Analysis;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using System.Utilities;

page 9211 "Resource Alloc. per Job Matrix"
{
    Caption = 'Resource Allocated per Project Matrix';
    DataCaptionExpression = '';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                }
                field(Col1; MatrixCellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[1];
                    DrillDown = true;
                    DrillDownPageID = "Job Planning Lines";
                    Editable = false;
                    Visible = Col1Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(1);
                    end;
                }
                field(Col2; MatrixCellData[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[2];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col2Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(2);
                    end;
                }
                field(Col3; MatrixCellData[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[3];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col3Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(3);
                    end;
                }
                field(Col4; MatrixCellData[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[4];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col4Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(4);
                    end;
                }
                field(Col5; MatrixCellData[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[5];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col5Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(5);
                    end;
                }
                field(Col6; MatrixCellData[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[6];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col6Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(6);
                    end;
                }
                field(Col7; MatrixCellData[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[7];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col7Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(7);
                    end;
                }
                field(Col8; MatrixCellData[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[8];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col8Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(8);
                    end;
                }
                field(Col9; MatrixCellData[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[9];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col9Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(9);
                    end;
                }
                field(Col10; MatrixCellData[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[10];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col10Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(10);
                    end;
                }
                field(Col11; MatrixCellData[11])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[11];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col11Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(11);
                    end;
                }
                field(Col12; MatrixCellData[12])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[12];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col12Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(12);
                    end;
                }
                field(Col13; MatrixCellData[13])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[13];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col13Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(13);
                    end;
                }
                field(Col14; MatrixCellData[14])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[14];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col14Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(14);
                    end;
                }
                field(Col15; MatrixCellData[15])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[15];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col15Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(15);
                    end;
                }
                field(Col16; MatrixCellData[16])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[16];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col16Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(16);
                    end;
                }
                field(Col17; MatrixCellData[17])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[17];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col17Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(17);
                    end;
                }
                field(Col18; MatrixCellData[18])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[18];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col18Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(18);
                    end;
                }
                field(Col19; MatrixCellData[19])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[19];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col19Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(19);
                    end;
                }
                field(Col20; MatrixCellData[20])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[20];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col20Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(20);
                    end;
                }
                field(Col21; MatrixCellData[21])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[21];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col21Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(21);
                    end;
                }
                field(Col22; MatrixCellData[22])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[22];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col22Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(22);
                    end;
                }
                field(Col23; MatrixCellData[23])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[23];
                    DrillDown = true;
                    Editable = false;
                    Visible = Col23Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(23);
                    end;
                }
                field(Col24; MatrixCellData[24])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[24];
                    Visible = Col24Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(24);
                    end;
                }
                field(Col25; MatrixCellData[25])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[25];
                    Visible = Col25Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(25);
                    end;
                }
                field(Col26; MatrixCellData[26])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[26];
                    Visible = Col26Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(26);
                    end;
                }
                field(Col27; MatrixCellData[27])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[27];
                    Visible = Col27Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(27);
                    end;
                }
                field(Col28; MatrixCellData[28])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[28];
                    Visible = Col28Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(28);
                    end;
                }
                field(Col29; MatrixCellData[29])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[29];
                    Visible = Col29Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(29);
                    end;
                }
                field(Col30; MatrixCellData[30])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[30];
                    Visible = Col30Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(30);
                    end;
                }
                field(Col31; MatrixCellData[31])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[31];
                    Visible = Col31Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(31);
                    end;
                }
                field(Col32; MatrixCellData[32])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[32];
                    Visible = Col32Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        MatrixOnAfterGetRecord();
    end;

    trigger OnInit()
    begin
        Col32Visible := true;
        Col31Visible := true;
        Col30Visible := true;
        Col29Visible := true;
        Col28Visible := true;
        Col27Visible := true;
        Col26Visible := true;
        Col25Visible := true;
        Col24Visible := true;
        Col23Visible := true;
        Col22Visible := true;
        Col21Visible := true;
        Col20Visible := true;
        Col19Visible := true;
        Col18Visible := true;
        Col17Visible := true;
        Col16Visible := true;
        Col15Visible := true;
        Col14Visible := true;
        Col13Visible := true;
        Col12Visible := true;
        Col11Visible := true;
        Col10Visible := true;
        Col9Visible := true;
        Col8Visible := true;
        Col7Visible := true;
        Col6Visible := true;
        Col5Visible := true;
        Col4Visible := true;
        Col3Visible := true;
        Col2Visible := true;
        Col1Visible := true;
    end;

    var
        MatrixColumnDateFilters: array[32] of Record Date;
        MatrixRec: Record "Job Planning Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        MatrixColumnCaptions: array[32] of Text[100];
        MatrixCellData: array[32] of Text[100];
        MatrixCellQuantity: Decimal;
        AmountType: Enum "Analysis Amount Type";
        Col1Visible: Boolean;
        Col2Visible: Boolean;
        Col3Visible: Boolean;
        Col4Visible: Boolean;
        Col5Visible: Boolean;
        Col6Visible: Boolean;
        Col7Visible: Boolean;
        Col8Visible: Boolean;
        Col9Visible: Boolean;
        Col10Visible: Boolean;
        Col11Visible: Boolean;
        Col12Visible: Boolean;
        Col13Visible: Boolean;
        Col14Visible: Boolean;
        Col15Visible: Boolean;
        Col16Visible: Boolean;
        Col17Visible: Boolean;
        Col18Visible: Boolean;
        Col19Visible: Boolean;
        Col20Visible: Boolean;
        Col21Visible: Boolean;
        Col22Visible: Boolean;
        Col23Visible: Boolean;
        Col24Visible: Boolean;
        Col25Visible: Boolean;
        Col26Visible: Boolean;
        Col27Visible: Boolean;
        Col28Visible: Boolean;
        Col29Visible: Boolean;
        Col30Visible: Boolean;
        Col31Visible: Boolean;
        Col32Visible: Boolean;

    procedure LoadMatrix(var NewVerticalRec: Record Job; var NewHorizontalRec: Record "Job Planning Line"; NewMatrixColumnCaptions: array[32] of Text[100]; var NewMatrixDateFilters: array[32] of Record Date; AmountType2: Enum "Analysis Amount Type")
    begin
        Rec.Copy(NewVerticalRec);
        MatrixRec.Copy(NewHorizontalRec);
        CopyArray(MatrixColumnCaptions, NewMatrixColumnCaptions, 1);
        CopyArray(MatrixColumnDateFilters, NewMatrixDateFilters, 1);
        AmountType := AmountType2;
    end;

    local procedure MatrixOnAfterGetRecord()
    var
        I: Integer;
    begin
        MatrixRec.Reset();
        MatrixRec.SetRange("Job No.", Rec."No.");
        MatrixRec.SetRange(Type, MatrixRec.Type::Resource);
        MatrixRec.SetRange("Schedule Line", true);
        if Rec.GetFilter("Resource Filter") <> '' then
            MatrixRec.SetFilter("No.", Rec.GetRangeMin("Resource Filter"), Rec.GetRangeMax("Resource Filter"));
        for I := 1 to ArrayLen(MatrixColumnDateFilters) do begin
            MatrixCellQuantity := 0;
            MatrixRec.SetRange(
              "Planning Date", GetStartDate(MatrixColumnDateFilters[I]."Period Start"), MatrixColumnDateFilters[I]."Period End");
            OnMatrixOnAfterGetRecordOnBeforeMatrixRecLoop(MatrixRec, MatrixCellQuantity);
            if MatrixRec.Find('-') then
                repeat
                    MatrixCellQuantity += Round(MatrixRec.Quantity * MatrixRec."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision())
                until MatrixRec.Next() = 0;

            if MatrixCellQuantity <> 0 then
                MatrixCellData[I] := Format(MatrixCellQuantity)
            else
                MatrixCellData[I] := '';
        end;

        SetVisible();
    end;

    local procedure MatrixOnDrillDown(Column: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        JobPlanningLine.SetFilter("No.", Rec.GetRangeMin("Resource Filter"), Rec.GetRangeMax("Resource Filter"));
        JobPlanningLine.SetRange(
          "Planning Date", GetStartDate(MatrixColumnDateFilters[Column]."Period Start"),
          MatrixColumnDateFilters[Column]."Period End");
        JobPlanningLine.SetRange("Job No.", Rec."No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.SetRange("Schedule Line", true);
        IsHandled := false;
        OnAfterMatrixOnDrillDown(JobPlanningLine, IsHandled);
        if IsHandled then
            exit;

        PAGE.RunModal(PAGE::"Job Planning Lines", JobPlanningLine);
    end;

    procedure SetVisible()
    begin
        Col1Visible := MatrixColumnCaptions[1] <> '';
        Col2Visible := MatrixColumnCaptions[2] <> '';
        Col3Visible := MatrixColumnCaptions[3] <> '';
        Col4Visible := MatrixColumnCaptions[4] <> '';
        Col5Visible := MatrixColumnCaptions[5] <> '';
        Col6Visible := MatrixColumnCaptions[6] <> '';
        Col7Visible := MatrixColumnCaptions[7] <> '';
        Col8Visible := MatrixColumnCaptions[8] <> '';
        Col9Visible := MatrixColumnCaptions[9] <> '';
        Col10Visible := MatrixColumnCaptions[10] <> '';
        Col11Visible := MatrixColumnCaptions[11] <> '';
        Col12Visible := MatrixColumnCaptions[12] <> '';
        Col13Visible := MatrixColumnCaptions[13] <> '';
        Col14Visible := MatrixColumnCaptions[14] <> '';
        Col15Visible := MatrixColumnCaptions[15] <> '';
        Col16Visible := MatrixColumnCaptions[16] <> '';
        Col17Visible := MatrixColumnCaptions[17] <> '';
        Col18Visible := MatrixColumnCaptions[18] <> '';
        Col19Visible := MatrixColumnCaptions[19] <> '';
        Col20Visible := MatrixColumnCaptions[20] <> '';
        Col21Visible := MatrixColumnCaptions[21] <> '';
        Col22Visible := MatrixColumnCaptions[22] <> '';
        Col23Visible := MatrixColumnCaptions[23] <> '';
        Col24Visible := MatrixColumnCaptions[24] <> '';
        Col25Visible := MatrixColumnCaptions[25] <> '';
        Col26Visible := MatrixColumnCaptions[26] <> '';
        Col27Visible := MatrixColumnCaptions[27] <> '';
        Col28Visible := MatrixColumnCaptions[28] <> '';
        Col29Visible := MatrixColumnCaptions[29] <> '';
        Col30Visible := MatrixColumnCaptions[30] <> '';
        Col31Visible := MatrixColumnCaptions[31] <> '';
        Col32Visible := MatrixColumnCaptions[32] <> '';
    end;

    local procedure GetStartDate(PeriodStartDate: Date): Date
    begin
        case AmountType of
            AmountType::"Net Change":
                exit(PeriodStartDate);
            AmountType::"Balance at Date":
                exit(0D);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMatrixOnDrillDown(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatrixOnAfterGetRecordOnBeforeMatrixRecLoop(var JobPlanningLine: Record "Job Planning Line"; var MatrixCellQuantity: Decimal)
    begin
    end;
}

