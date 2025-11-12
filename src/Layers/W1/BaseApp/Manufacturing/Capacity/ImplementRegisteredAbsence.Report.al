// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

report 99003801 "Implement Registered Absence"
{
    ApplicationArea = Manufacturing;
    Caption = 'Implement Registered Absence';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Registered Absence"; "Registered Absence")
        {
            DataItemTableView = sorting("Capacity Type", "No.", Date, "Starting Time", "Ending Time");

            trigger OnAfterGetRecord()
            begin
                CalendarAbsEntry.Init();
                CalendarAbsEntry.Validate("Capacity Type", "Capacity Type");
                CalendarAbsEntry.Validate("No.", "No.");
                CalendarAbsEntry.Validate(Date, Date);
                CalendarAbsEntry.Validate("Starting Time", "Starting Time");
                CalendarAbsEntry.Validate("Ending Time", "Ending Time");
                CalendarAbsEntry.Validate(Capacity, Capacity);
                CalendarAbsEntry.Validate(Description, Description);
                if not CalendarAbsEntry.Insert() then
                    if Overwrite then
                        CalendarAbsEntry.Modify();
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
                    field(Overwrite; Overwrite)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Overwrite';
                        ToolTip = 'Specifies if you want to overwrite any existing absence entries on this particular date and time, for the machine center or work center in question.';
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

    var
        CalendarAbsEntry: Record "Calendar Absence Entry";
        Overwrite: Boolean;
}

