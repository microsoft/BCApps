// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.MachineCenter;

using Microsoft.Manufacturing.Capacity;

report 99001045 "Calc. Machine Center Calendar"
{
    Caption = 'Calc. Machine Center Calendar';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Machine Center"; "Machine Center")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                TestField("Work Center No.");
                TestField(Capacity);
                TestField(Efficiency);

                CalculateMachineCenterSchedule("Machine Center");
            end;

            trigger OnPreDataItem()
            begin
                if StartingDate = 0D then
                    Error(Text004);

                if EndingDate = 0D then
                    Error(Text005);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date that you will start creating new calendar entries.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the final date that you will create new calendar entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            if StartingDate = 0D then
                StartingDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
            if EndingDate = 0D then
                EndingDate := DMY2Date(31, 12, Date2DMY(WorkDate(), 3));
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        Window.Open(
          Text000 +
          Text001);
    end;

    var
        ShopCalendarManagement: Codeunit "Shop Calendar Management";
        Window: Dialog;

#pragma warning disable AA0074
        Text000: Label 'Calculating Machine Center...\\';
#pragma warning disable AA0470
        Text001: Label 'No.            #1##########';
#pragma warning restore AA0470
        Text004: Label 'You must enter the Starting Date.';
        Text005: Label 'You must enter the Ending Date.';
#pragma warning restore AA0074

    protected var
        StartingDate: Date;
        EndingDate: Date;

    procedure InitializeRequest(NewStartingDate: Date; NewEndingDate: Date)
    begin
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
    end;

    local procedure CalculateMachineCenterSchedule(MachineCenter: Record "Machine Center")
    var
        CapacityType: Enum "Capacity Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateMachineCenterSchedule(MachineCenter, StartingDate, EndingDate, IsHandled);
        if IsHandled then
            exit;

        ShopCalendarManagement.CalculateSchedule(
            CapacityType::"Machine Center", MachineCenter."No.", MachineCenter."Work Center No.", StartingDate, EndingDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateMachineCenterSchedule(MachineCenter: Record "Machine Center"; StartingDate: Date; EndingDate: Date; var IsHandled: Boolean);
    begin
    end;
}

