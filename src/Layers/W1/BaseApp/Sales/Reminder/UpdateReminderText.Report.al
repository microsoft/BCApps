// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

report 187 "Update Reminder Text"
{
    Caption = 'Update Reminder Text';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Reminder Header"; "Reminder Header")
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                ReminderHeader.Get("No.");
                if ReminderLevel.Get(ReminderHeader."Reminder Terms Code", ReminderLevelNo) then begin
                    ReminderHeader.Validate("Reminder Level", ReminderLevelNo);
                    ReminderHeader.Modify();
                    ReminderHeader.UpdateLines(ReminderHeader, UpdateAdditionalFee);
                end
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
                    field(ReminderLevelNo; ReminderLevelNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reminder Level';
                        ToolTip = 'Specifies the reminder level to which the beginning and/or ending text you want to use is linked.';
                    }
                    field(UpdateAdditionalFee; UpdateAdditionalFee)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Additional Fee';
                        ToolTip = 'Specifies whether you want to update the additional fee.';
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
        ReminderHeader: Record "Reminder Header";
        ReminderLevel: Record "Reminder Level";
        ReminderLevelNo: Integer;
        UpdateAdditionalFee: Boolean;
}

