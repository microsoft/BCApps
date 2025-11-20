// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.MachineCenter;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;
using System.Utilities;

page 9293 "Machine Center Calendar Matrix"
{
    Caption = 'Machine Center Calendar Matrix';
    DataCaptionExpression = '';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Machine Center";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a name for the machine center.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Mach. Ctr.")
            {
                Caption = '&Mach. Ctr.';
                Image = MachineCenter;
                action("Capacity Ledger E&ntries")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Ledger E&ntries';
                    Image = CapacityLedger;
                    RunObject = Page "Capacity Ledger Entries";
                    RunPageLink = Type = const("Machine Center"),
                                  "No." = field("No."),
                                  "Posting Date" = field("Date Filter");
                    RunPageView = sorting(Type, "No.", "Item No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "No." = field("No.");
                    RunPageView = where("Table Name" = const("Machine Center"));
                    ToolTip = 'View or add comments for the record.';
                }
                action("Lo&ad")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Lo&ad';
                    Image = WorkCenterLoad;
                    RunObject = Page "Machine Center Load";
                    RunPageLink = "No." = field("No.");
                    RunPageView = sorting("No.");
                    ToolTip = 'View the availability of the machine or work center, including its capacity, the allocated quantity, availability after orders, and the load in percent of its total capacity.';
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Machine Center Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Work Shift Filter" = field("Work Shift Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
            group("Pla&nning")
            {
                Caption = 'Pla&nning';
                Image = Planning;
                action("A&bsence")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'A&bsence';
                    Image = WorkCenterAbsence;
                    RunObject = Page "Capacity Absence";
                    RunPageLink = "Capacity Type" = const("Machine Center"),
                                  "No." = field("No."),
                                  Date = field("Date Filter");
                    ToolTip = 'View which working days are not available. ';
                }
                action("Ta&sk List")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ta&sk List';
                    Image = TaskList;
                    RunObject = Page "Machine Center Task List";
                    RunPageLink = Type = const("Machine Center"),
                                  "No." = field("No."),
                                  "Routing Status" = filter(<> Finished);
                    RunPageView = sorting(Type, "No.", "Starting Date");
                    ToolTip = 'View the list of operations that are scheduled for the machine center.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Calculate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calculate';
                    Ellipsis = true;
                    Image = Calculate;
                    RunObject = Report "Calc. Machine Center Calendar";
                    ToolTip = 'Update the window with any new capacity ledger entries.';
                }
                action(Recalculate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Recalculate';
                    Ellipsis = true;
                    Image = Refresh;
                    ToolTip = 'Update the calendar entries after you make modifications in the shop calendar or with the calendar absences. The program checks the existing calendar entries to see whether they correspond to the shop calendar and the calendar absences. If they don''t correspond, the appropriate calendar is corrected.';

                    trigger OnAction()
                    var
                        CalEntry: Record "Calendar Entry";
                    begin
                        CalEntry.SetRange("Capacity Type", CalEntry."Capacity Type"::"Machine Center");

                        REPORT.RunModal(REPORT::"Recalculate Calendar", true, true, CalEntry);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Recalculate_Promoted; Recalculate)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    trigger OnOpenPage()
    begin
        MATRIX_CurrentNoOfMatrixColumn := ArrayLen(MATRIX_CaptionSet);
    end;

    var
        MatrixRecords: array[32] of Record Date;
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[80];

    local procedure SetDateFilter(MATRIX_ColumnOrdinal: Integer)
    begin
        if MatrixRecords[MATRIX_ColumnOrdinal]."Period Start" = MatrixRecords[MATRIX_ColumnOrdinal]."Period End" then
            Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start")
        else
            Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start", MatrixRecords[MATRIX_ColumnOrdinal]."Period End")
    end;

    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record Date; CurrentNoOfMatrixColumns: Integer)
    begin
        CopyArray(MATRIX_CaptionSet, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    var
        CalendarEntry: Record "Calendar Entry";
    begin
        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Machine Center");
        CalendarEntry.SetRange("No.", Rec."No.");

        if MatrixRecords[MATRIX_ColumnOrdinal]."Period Start" = MatrixRecords[MATRIX_ColumnOrdinal]."Period End" then
            CalendarEntry.SetRange(Date, MatrixRecords[MATRIX_ColumnOrdinal]."Period Start")
        else
            CalendarEntry.SetRange(Date,
              MatrixRecords[MATRIX_ColumnOrdinal]."Period Start", MatrixRecords[MATRIX_ColumnOrdinal]."Period End");

        PAGE.RunModal(PAGE::"Calendar Entries", CalendarEntry);
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        SetDateFilter(MATRIX_ColumnOrdinal);
        Rec.CalcFields("Capacity (Effective)");
        MATRIX_CellData[MATRIX_ColumnOrdinal] := Rec."Capacity (Effective)";
    end;
}

