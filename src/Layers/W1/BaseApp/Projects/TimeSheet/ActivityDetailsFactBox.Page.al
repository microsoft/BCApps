// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Assembly.Document;
using Microsoft.HumanResources.Absence;
using Microsoft.Projects.Project.Job;

page 971 "Activity Details FactBox"
{
    Caption = 'Activity Details';
    PageType = CardPart;
    SourceTable = "Time Sheet Line";

    layout
    {
        area(content)
        {
            field(Comment; Rec.Comment)
            {
                ApplicationArea = Comments;
                Caption = 'Line Comment';
                DrillDown = false;
                ToolTip = 'Specifies that a comment about this document has been entered.';
            }
            field("Total Quantity"; Rec."Total Quantity")
            {
                ApplicationArea = Jobs;
                Caption = 'Line Total';
                DrillDown = false;
                ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
            }
            field(ActivitiID; ActivitiID)
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + ActivityCaption;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    LookupActivity();
                end;
            }
            field(ActivitySubID; ActivitySubID)
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + ActivitySubCaption;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    LookupSubActivity();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        TimeSheetMgt.GetActivityInfo(Rec, ActivityCaption, ActivitiID, ActivitySubCaption, ActivitySubID);
    end;

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        ActivityCaption: Text[30];
        ActivitySubCaption: Text;
        ActivitiID: Code[20];
        ActivitySubID: Code[20];

    procedure SetEmptyLine()
    begin
        ActivityCaption := '';
        ActivitiID := '';
        ActivitySubCaption := '';
        ActivitiID := '';
    end;

    local procedure LookupActivity()
    var
        Job: Record Job;
        CauseOfAbsence: Record "Cause of Absence";
        AssemblyHeader: Record "Assembly Header";
        JobList: Page "Job List";
        CausesOfAbsence: Page "Causes of Absence";
        AssemblyOrders: Page "Assembly Orders";
    begin
        case Rec.Type of
            Rec.Type::Job:
                begin
                    Clear(JobList);
                    if Rec."Job No." <> '' then begin
                        Job.Get(Rec."Job No.");
                        JobList.SetRecord(Job);
                    end;
                    JobList.RunModal();
                end;
            Rec.Type::Absence:
                begin
                    Clear(CausesOfAbsence);
                    if Rec."Cause of Absence Code" <> '' then begin
                        CauseOfAbsence.Get(Rec."Cause of Absence Code");
                        CausesOfAbsence.SetRecord(CauseOfAbsence);
                    end;
                    CausesOfAbsence.RunModal();
                end;
            Rec.Type::"Assembly Order":
                begin
                    Clear(AssemblyOrders);
                    if Rec."Assembly Order No." <> '' then
                        if AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, Rec."Assembly Order No.") then
                            AssemblyOrders.SetRecord(AssemblyHeader);
                    AssemblyOrders.RunModal();
                end;
            else
                OnLookupActivity(Rec);
        end;
    end;

    local procedure LookupSubActivity()
    var
        JobTask: Record "Job Task";
        JobTaskList: Page "Job Task List";
        IsHandled: Boolean;
    begin
        OnBeforeLookupSubActivity(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec.Type = Rec.Type::Job then begin
            Clear(JobTaskList);
            if Rec."Job Task No." <> '' then begin
                JobTask.Get(Rec."Job No.", Rec."Job Task No.");
                JobTaskList.SetRecord(JobTask);
            end;
            JobTaskList.RunModal();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSubActivity(TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupActivity(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;
}

