// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using System.Utilities;

page 976 "Time Sheet Archive Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Time Sheet Line Archive";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of time sheet line.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number for the project that is associated with the time sheet line.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project task.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the archived time sheet line.';
                }
                field("Cause of Absence Code"; Rec."Cause of Absence Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the codes that you can use to describe the type of absence from work.';
                }
                field(Chargeable; Rec.Chargeable)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the time associated with an archived time sheet is chargeable.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                }
                field("Assembly Order No."; Rec."Assembly Order No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the assembly order number that is associated with the time sheet line.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies information about the status of an archived time sheet.';
                }
                field(Field1; CellData[1])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[1];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field2; CellData[2])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[2];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field3; CellData[3])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[3];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field4; CellData[4])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[4];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field5; CellData[5])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[5];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field6; CellData[6])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[6];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field7; CellData[7])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[7];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    DrillDown = false;
                    ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
            }
            group(GroupTotal)
            {
                ShowCaption = false;
                field(UnitOfMeasureCode; UnitOfMeasureCode)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Unit of Measure';
                    ToolTip = 'Specifies the unit of measure for the time sheet.';
                    Editable = false;
                }
                field(TimeSheetTotalQuantity; GetTimeSheetTotalQuantity())
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount of time for the time sheet.';
                    Editable = false;
                    DecimalPlaces = 0 : 2;
                }
            }
        }

    }

    actions
    {
        area(Processing)
        {
            group(Line)
            {

                action(LineComments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Time Sheet Arc. Comment Sheet";
                    RunPageLink = "No." = field("Time Sheet No."),
                                  "Time Sheet Line No." = field("Line No.");
                    Scope = Repeater;
                    ToolTip = 'View or create comments.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    var
        TimeSheetDetailArchive: Record "Time Sheet Detail Archive";
        ColumnRecords: array[32] of Record Date;
        TimeSheetMgt: Codeunit "Time Sheet Management";
        NoOfColumns: Integer;
        CellData: array[32] of Decimal;
        ColumnCaption: array[32] of Text[1024];
        UnitOfMeasureCode: Code[10];

    protected var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";

    procedure SetColumns(TimeSheetNo: Code[20])
    var
        Calendar: Record Date;
    begin
        Clear(ColumnCaption);
        Clear(ColumnRecords);
        Clear(Calendar);
        Clear(NoOfColumns);

        TimeSheetHeaderArchive.Get(TimeSheetNo);
        TimeSheetHeaderArchive.CalcFields("Unit of Measure");
        UnitOfMeasureCode := TimeSheetHeaderArchive."Unit of Measure";

        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", TimeSheetHeaderArchive."Starting Date", TimeSheetHeaderArchive."Ending Date");
        if Calendar.FindSet() then
            repeat
                NoOfColumns += 1;
                ColumnRecords[NoOfColumns]."Period Start" := Calendar."Period Start";
                ColumnCaption[NoOfColumns] := TimeSheetMgt.FormatDate(Calendar."Period Start", 1);
            until Calendar.Next() = 0;
    end;

    local procedure UpdateControls()
    var
        i: Integer;
    begin
        i := 0;
        while i < NoOfColumns do begin
            i := i + 1;
            if (Rec."Line No." <> 0) and TimeSheetDetailArchive.Get(
                 Rec."Time Sheet No.",
                 Rec."Line No.",
                 ColumnRecords[i]."Period Start")
            then
                CellData[i] := TimeSheetDetailArchive.Quantity
            else
                CellData[i] := 0;
        end;
    end;

    local procedure GetTimeSheetTotalQuantity(): Decimal
    begin
        TimeSheetHeaderArchive.Get(Rec."Time Sheet No.");
        TimeSheetHeaderArchive.CalcFields(Quantity);
        exit(TimeSheetHeaderArchive.Quantity);
    end;
}
