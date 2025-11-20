// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 764 "Acc. Sched. Chart Matrix"
{
    Caption = 'Acc. Sched. Chart Matrix';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Acc. Sched. Chart Setup Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("<Row No.>"; AccSchedLineRowNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Row No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the row.';
                }
                field("<Description>"; AccSchedLineDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies a description of the account schedule.';
                }
                field("ChartType[1]"; ChartType[1])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[1];

                    trigger OnValidate()
                    begin
                        SetChartType(1);
                    end;
                }
                field("ChartType[2]"; ChartType[2])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[2];

                    trigger OnValidate()
                    begin
                        SetChartType(2);
                    end;
                }
                field("ChartType[3]"; ChartType[3])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[3];

                    trigger OnValidate()
                    begin
                        SetChartType(3);
                    end;
                }
                field("ChartType[4]"; ChartType[4])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[4];

                    trigger OnValidate()
                    begin
                        SetChartType(4);
                    end;
                }
                field("ChartType[5]"; ChartType[5])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[5];

                    trigger OnValidate()
                    begin
                        SetChartType(5);
                    end;
                }
                field("ChartType[6]"; ChartType[6])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[6];

                    trigger OnValidate()
                    begin
                        SetChartType(6);
                    end;
                }
                field("ChartType[7]"; ChartType[7])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[7];

                    trigger OnValidate()
                    begin
                        SetChartType(7);
                    end;
                }
                field("ChartType[8]"; ChartType[8])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[8];

                    trigger OnValidate()
                    begin
                        SetChartType(8);
                    end;
                }
                field("ChartType[9]"; ChartType[9])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[9];

                    trigger OnValidate()
                    begin
                        SetChartType(9);
                    end;
                }
                field("ChartType[10]"; ChartType[10])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[10];

                    trigger OnValidate()
                    begin
                        SetChartType(10);
                    end;
                }
                field("ChartType[11]"; ChartType[11])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[11];

                    trigger OnValidate()
                    begin
                        SetChartType(11);
                    end;
                }
                field("ChartType[12]"; ChartType[12])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[12];

                    trigger OnValidate()
                    begin
                        SetChartType(12);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowAll)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select All';
                Image = AllLines;
                ToolTip = 'Select all lines.';

                trigger OnAction()
                var
                    AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                    AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
                begin
                    AccSchedChartSetupLine.Copy(Rec);
                    AccSchedChartSetupLine.SetRange("Column Layout Line No.");
                    AccSchedChartManagement.SelectAll(AccSchedChartSetupLine, true);
                end;
            }
            action(ShowNone)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deselect All';
                Image = CancelAllLines;
                ToolTip = 'Unselect all lines.';

                trigger OnAction()
                var
                    AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                    AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
                begin
                    AccSchedChartSetupLine.Copy(Rec);
                    AccSchedChartSetupLine.SetRange("Column Layout Line No.");
                    AccSchedChartManagement.DeselectAll(AccSchedChartSetupLine, true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowAll_Promoted; ShowAll)
                {
                }
                actionref(ShowNone_Promoted; ShowNone)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AccSchedLine: Record "Acc. Schedule Line";
    begin
        if AccSchedLine.Get(Rec."Account Schedule Name", Rec."Account Schedule Line No.") then begin
            AccSchedLineRowNo := AccSchedLine."Row No.";
            AccSchedLineDescription := AccSchedLine.Description;
            GetChartTypes();
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Rec.FindSet());
    end;

    var
        AccSchedLineRowNo: Code[10];
        AccSchedLineDescription: Text[100];
        ChartType: array[12] of Option " ",Line,StepLine,Column,StackedColumn;
        ColumnCaptions: array[12] of Text[100];
        ColumnLineNos: array[12] of Integer;
        MaxColumns: Integer;
#pragma warning disable AA0074
        Text001: Label 'Invalid Column Layout.';
#pragma warning restore AA0074

    procedure SetFilters(AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    begin
        Rec.Reset();

        AccountSchedulesChartSetup.SetLinkToLines(Rec);
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                if Rec.FindFirst() then
                    Rec.SetRange("Column Layout Line No.", Rec."Column Layout Line No.");
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line",
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                Rec.SetRange("Column Layout Line No.", 0);
        end;
        UpdateColumnCaptions(AccountSchedulesChartSetup);
    end;

    local procedure UpdateColumnCaptions(AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    var
        ColumnLayout: Record "Column Layout";
        ColumnNo: Integer;
        i: Integer;
    begin
        Clear(ColumnCaptions);
        AccountSchedulesChartSetup.FilterColumnLayout(ColumnLayout);
        if ColumnLayout.FindSet() then
            repeat
                ColumnNo := ColumnNo + 1;
                if ColumnNo <= ArrayLen(ColumnCaptions) then begin
                    ColumnCaptions[ColumnNo] := ColumnLayout."Column Header";
                    ColumnLineNos[ColumnNo] := ColumnLayout."Line No.";
                end;
            until ColumnLayout.Next() = 0;
        MaxColumns := ColumnNo;
        // Set unused columns to blank to prevent RTC to display control ID as caption
        for i := MaxColumns + 1 to ArrayLen(ColumnCaptions) do
            ColumnCaptions[i] := ' ';
    end;

    local procedure GetChartTypes()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
        AccSchedChartSetupLine2: Record "Acc. Sched. Chart Setup Line";
        i: Integer;
    begin
        AccountSchedulesChartSetup.Get(Rec."User ID", Rec.Name);
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                for i := 1 to MaxColumns do
                    if AccSchedChartSetupLine.Get(Rec."User ID", Rec.Name, Rec."Account Schedule Line No.", ColumnLineNos[i]) then
                        ChartType[i] := AccSchedChartSetupLine."Chart Type".AsInteger();
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                begin
                    AccSchedChartSetupLine.Get(Rec."User ID", Rec.Name, Rec."Account Schedule Line No.", 0);
                    if AccSchedChartSetupLine."Chart Type" <> AccSchedChartSetupLine."Chart Type"::" " then
                        for i := 1 to MaxColumns do
                            if AccSchedChartSetupLine2.Get(Rec."User ID", Rec.Name, 0, ColumnLineNos[i]) then
                                ChartType[i] := AccSchedChartSetupLine2."Chart Type".AsInteger()
                            else
                                for i := 1 to MaxColumns do
                                    ChartType[i] := AccSchedChartSetupLine2."Chart Type"::" ".AsInteger();
                end;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                begin
                    AccSchedChartSetupLine.Get(Rec."User ID", Rec.Name, Rec."Account Schedule Line No.", 0);
                    for i := 1 to MaxColumns do begin
                        AccSchedChartSetupLine2.Get(Rec."User ID", Rec.Name, 0, ColumnLineNos[i]);
                        if AccSchedChartSetupLine2."Chart Type" <> AccSchedChartSetupLine2."Chart Type"::" " then
                            ChartType[i] := AccSchedChartSetupLine."Chart Type".AsInteger()
                        else
                            ChartType[i] := AccSchedChartSetupLine."Chart Type"::" ".AsInteger();
                    end;
                end;
        end;
        for i := MaxColumns + 1 to ArrayLen(ColumnCaptions) do
            ChartType[i] := AccSchedChartSetupLine."Chart Type"::" ".AsInteger();
    end;

    local procedure SetChartType(ColumnNo: Integer)
    var
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        if ColumnNo > MaxColumns then
            Error(Text001);

        AccountSchedulesChartSetup.Get(Rec."User ID", Rec.Name);
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                AccSchedChartSetupLine.Get(Rec."User ID", Rec.Name, Rec."Account Schedule Line No.", ColumnLineNos[ColumnNo]);
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                AccSchedChartSetupLine.Get(Rec."User ID", Rec.Name, 0, ColumnLineNos[ColumnNo]);
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                AccSchedChartSetupLine.Get(Rec."User ID", Rec.Name, Rec."Account Schedule Line No.", 0);
        end;
        AccSchedChartSetupLine.Validate("Chart Type", ChartType[ColumnNo]);
        AccSchedChartSetupLine.Modify();
        CurrPage.Update();
    end;
}

