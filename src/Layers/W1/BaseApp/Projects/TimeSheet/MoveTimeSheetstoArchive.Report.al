// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

report 953 "Move Time Sheets to Archive"
{
    Caption = 'Move Time Sheets to Archive';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Time Sheet Header"; "Time Sheet Header")
        {
            RequestFilterFields = "No.", "Starting Date";

            trigger OnAfterGetRecord()
            begin
                Counter := Counter + 1;
                if GuiAllowed then begin
                    Window.Update(1, "No.");
                    Window.Update(2, Round(Counter / CounterTotal * 10000, 1));
                end;
                TimeSheetMgt.MoveTimeSheetToArchive("Time Sheet Header");
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed then begin
                    Window.Close();
                    Message(Text002, Counter);
                end;
            end;

            trigger OnPreDataItem()
            begin
                OnBeforePreDataItemTimesheetHeader("Time Sheet Header");

                CounterTotal := Count;
                if GuiAllowed then
                    Window.Open(Text001);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        Window: Dialog;
        Counter: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Moving time sheets to archive  #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 time sheets have been moved to the archive.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CounterTotal: Integer;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreDataItemTimesheetHeader(var TimeSheetHeader: Record "Time Sheet Header")
    begin
    end;
}

