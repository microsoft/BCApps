// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.MachineCenter;

using Microsoft.Manufacturing.Capacity;

report 99003800 "Reg. Abs. (from Machine Ctr.)"
{
    ApplicationArea = Manufacturing;
    Caption = 'Reg. Abs. (from Machine Ctr.)';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Machine Center"; "Machine Center")
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                Date := StartingDate;
                repeat
                    AbsenceChange.Init();
                    AbsenceChange."Capacity Type" := AbsenceChange."Capacity Type"::"Machine Center";
                    AbsenceChange."No." := "No.";
                    AbsenceChange."Starting Time" := StartingTime;
                    AbsenceChange."Ending Time" := EndingTime;
                    AbsenceChange.Date := Date;
                    AbsenceChange.Description := Description;
                    AbsenceChange.Capacity := Capacity2;
                    AbsenceChange.UpdateDatetime();
                    if not AbsenceChange.Insert() then
                        if Overwrite then
                            AbsenceChange.Modify();
                    Date := Date + 1;
                until Date = EndingDate + 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingTime; StartingTime)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Time';
                        ToolTip = 'Specifies the starting time of the absence, that is, the time the employee normally starts work or the time the machine starts to operate.';

                        trigger OnValidate()
                        begin
                            if (EndingTime <> 0T) and (StartingTime > EndingTime) then
                                Error(Text004);
                        end;
                    }
                    field(EndingTime; EndingTime)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Ending Time';
                        ToolTip = 'Specifies the ending time of the absence (the time the employee normally leaves, or the time the machine stops operating).';

                        trigger OnValidate()
                        begin
                            if StartingTime > EndingTime then
                                Error(Text004);
                        end;
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting time of the absence, that is, the time the employee normally starts to work or the time the machine starts to operate.';

                        trigger OnValidate()
                        begin
                            if (EndingDate <> 0D) and (StartingDate > EndingDate) then
                                Error(Text003);
                        end;
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending time of the absence, that is, the time the employee normally leaves, or the time the machine stops operating.';

                        trigger OnValidate()
                        begin
                            if StartingDate > EndingDate then
                                Error(Text003);
                        end;
                    }
                    field(Capacity; Capacity2)
                    {
                        ApplicationArea = Manufacturing;
                        AutoFormatType = 1;
                        Caption = 'Capacity';
                        MinValue = 0;
                        ToolTip = 'Specifies the amount of capacity that cannot be used during the absence period.';
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Description';
                        ToolTip = 'Specifies a short description of the reason for the absence.';
                    }
                    field(Overwrite; Overwrite)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Overwrite';
                        ToolTip = 'Specifies if the program will overwrite entries on this particular date and time for this machine center.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if StartingDate = 0D then
            Error(Text000);
        if EndingDate = 0D then
            Error(Text001);
        if StartingTime = 0T then
            Error(Text002, AbsenceChange.FieldCaption("Starting Time"));
        if EndingTime = 0T then
            Error(Text002, AbsenceChange.FieldCaption("Ending Time"));
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'The Starting Date field must not be blank.';
        Text001: Label 'The Ending Date field must not be blank.';
#pragma warning disable AA0470
        Text002: Label 'The %1 field must not be blank.';
#pragma warning restore AA0470
        Text003: Label 'The ending date must be later than the starting date.';
        Text004: Label 'The ending time must be later than the starting time.';
#pragma warning restore AA0074
        AbsenceChange: Record "Registered Absence";
        StartingDate: Date;
        EndingDate: Date;
        StartingTime: Time;
        EndingTime: Time;
        Capacity2: Decimal;
        Description: Text[30];
        Date: Date;
        Overwrite: Boolean;
}

