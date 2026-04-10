// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

page 1319 "Reminder Cues"
{
    PageType = CardPart;
    Caption = 'Reminders';
    SourceTable = "Finance Cue";

    layout
    {
        area(Content)
        {
            cuegroup(Reminders)
            {
                field("Non Issued Reminders"; Rec."Non Issued Reminders")
                {
                    ApplicationArea = All;
                    Caption = 'Draft Reminders';
                }
                field("Active Reminders"; Rec."Active Reminders")
                {
                    ApplicationArea = All;
                    Caption = 'Issued, not paid reminders';
                }
                field(RemindersNotSent; Rec."Reminders not Send")
                {
                    ApplicationArea = All;
                    Caption = 'Reminders not sent';
                }
                field("Active Automations"; Rec."Active Reminder Automation")
                {
                    ApplicationArea = All;
                    Caption = 'Configured automations';
                }
                field("Automation Failures"; Rec."Reminder Automation Failures")
                {
                    ApplicationArea = All;
                    Caption = 'Automation failures';
                    StyleExpr = FailuresStyleExpr;
                }
            }
        }
    }

    var
        FailuresStyleExpr: Text;

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Clear(Rec);
            Rec.Insert();
        end;

        Rec.SetRange("Date Filter", 0D, WorkDate());
        Rec.SetAutoCalcFields("Non issued Reminders", "Active Reminders", "Reminders not Send", "Active Reminder Automation", "Reminder Automation Failures");
        if Rec."Reminder Automation Failures" > 0 then
            FailuresStyleExpr := 'Unfavorable'
        else
            FailuresStyleExpr := 'None';
    end;
}
