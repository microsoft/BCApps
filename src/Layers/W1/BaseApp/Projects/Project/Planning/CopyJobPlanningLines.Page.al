// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;

page 1042 "Copy Job Planning Lines"
{
    Caption = 'Copy Project Planning Lines';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group("Copy from")
            {
                Caption = 'Copy from';
                field(SourceJobNo; SourceJobNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project No.';
                    TableRelation = Job;
                    ToolTip = 'Specifies the project number.';

                    trigger OnValidate()
                    var
                        SourceJob: Record Job;
                    begin
                        if (SourceJobNo <> '') and not SourceJob.Get(SourceJobNo) then
                            Error(Text003, SourceJob.TableCaption(), SourceJobNo);

                        SourceJobTaskNo := '';
                    end;
                }
                field(SourceJobTaskNo; SourceJobTaskNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Task No.';
                    ToolTip = 'Specifies the project task number.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        JobTask: Record "Job Task";
                    begin
                        if SourceJobNo <> '' then begin
                            JobTask.SetRange("Job No.", SourceJobNo);
                            if PAGE.RunModal(PAGE::"Job Task List", JobTask) = ACTION::LookupOK then
                                SourceJobTaskNo := JobTask."Job Task No.";
                        end;
                    end;

                    trigger OnValidate()
                    var
                        JobTask: Record "Job Task";
                    begin
                        if (SourceJobTaskNo <> '') and not JobTask.Get(SourceJobNo, SourceJobTaskNo) then
                            Error(Text003, JobTask.TableCaption(), SourceJobTaskNo);
                    end;
                }
                field("Planning Line Type"; PlanningLineType)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Incl. Planning Line Type';
                    OptionCaption = 'Budget+Billable,Budget,Billable';
                    ToolTip = 'Specifies how copy planning lines. Budget+Billable: All planning lines are copied. Budget: Only lines of type Budget or type Both Budget and Billable are copied. Billable: Only lines of type Billable or type Both Budget and Billable are copied.';
                }
                field(FromDate; FromDate)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which the report or batch job processes information.';
                }
                field(ToDate; ToDate)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date to which the report or batch job processes information.';
                }
            }
            group("Copy to")
            {
                Caption = 'Copy to';
                field(TargetJobNo; TargetJobNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project No.';
                    TableRelation = Job;
                    ToolTip = 'Specifies the project number.';

                    trigger OnValidate()
                    var
                        TargetJob: Record Job;
                    begin
                        if (TargetJobNo <> '') and not TargetJob.Get(TargetJobNo) then
                            Error(Text003, TargetJob.TableCaption(), TargetJobNo);

                        TargetJobTaskNo := '';
                    end;
                }
                field(TargetJobTaskNo; TargetJobTaskNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Task No.';
                    ToolTip = 'Specifies the project task number.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        JobTask: Record "Job Task";
                    begin
                        if TargetJobNo <> '' then begin
                            JobTask.SetRange("Job No.", TargetJobNo);
                            if PAGE.RunModal(PAGE::"Job Task List", JobTask) = ACTION::LookupOK then
                                TargetJobTaskNo := JobTask."Job Task No.";
                        end;
                    end;

                    trigger OnValidate()
                    var
                        JobTask: Record "Job Task";
                    begin
                        if (TargetJobTaskNo <> '') and not JobTask.Get(TargetJobNo, TargetJobTaskNo) then
                            Error(Text003, JobTask.TableCaption(), TargetJobTaskNo);
                    end;
                }
            }
            group(Apply)
            {
                Caption = 'Apply';
                field(CopyQuantity; CopyQuantity)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Copy Quantity';
                    ToolTip = 'Specifies that the quantities will be copied to the new project.';
                }
                field(CopyJobPrices; CopyJobPrices)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Copy Project Prices';
                    ToolTip = 'Specifies that item prices, resource prices, and G/L prices will be copied from the project that you specified on the Copy From FastTab.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            ValidateUserInput();
            CopyJob.SetCopyQuantity(CopyQuantity);
            CopyJob.SetCopyPrices(CopyJobPrices);
            CopyJob.SetCopyJobPlanningLineType(PlanningLineType);
            CopyJob.SetJobTaskDateRange(FromDate, ToDate);
            OnQueryClosePageOnBeforeCopyJobPlanningLines(SourceJobNo, SourceJobTaskNo, PlanningLineType, FromDate, ToDate, TargetJobNo, TargetJobTaskNo, CopyQuantity);
            CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);
            OnQueryClosePageOnAfterCopyJobPlanningLines(SourceJobTask, TargetJobTask);
            Message(Text001);
        end
    end;

    var
        SourceJobTask: Record "Job Task";
        TargetJobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
        SourceJobNo: Code[20];
        SourceJobTaskNo: Code[20];
        TargetJobNo: Code[20];
        TargetJobTaskNo: Code[20];
#pragma warning disable AA0074
        Text001: Label 'The project was successfully copied.';
#pragma warning disable AA0470
        Text003: Label '%1 %2 does not exist.', Comment = 'Project Task 1000 does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PlanningLineType: Option "Budget+Billable",Budget,Billable;
        FromDate: Date;
        ToDate: Date;
        CopyQuantity: Boolean;
        CopyJobPrices: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Provide a valid source %1.';
        Text005: Label 'Provide a valid target %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ValidateUserInput()
    var
        Job: Record Job;
    begin
        if SourceJobNo = '' then
            Error(Text004, Job.TableCaption());
        if (SourceJobTaskNo = '') or not SourceJobTask.Get(SourceJobNo, SourceJobTaskNo) then
            Error(Text004, SourceJobTask.TableCaption());

        if TargetJobNo = '' then
            Error(Text005, Job.TableCaption());
        if (TargetJobTaskNo = '') or not TargetJobTask.Get(TargetJobNo, TargetJobTaskNo) then
            Error(Text005, TargetJobTask.TableCaption());
    end;

    procedure SetFromJobTask(SourceJobTask2: Record "Job Task")
    begin
        SourceJobNo := SourceJobTask2."Job No.";
        SourceJobTask := SourceJobTask2;
        SourceJobTaskNo := SourceJobTask2."Job Task No.";
    end;

    procedure SetToJobTask(TargetJobTask2: Record "Job Task")
    begin
        TargetJobNo := TargetJobTask2."Job No.";
        TargetJobTask := TargetJobTask2;
        TargetJobTaskNo := TargetJobTask2."Job Task No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQueryClosePageOnBeforeCopyJobPlanningLines(SourceJobNo: Code[20]; SourceJobTaskNo: Code[20]; PlanningLineType: Option; FromDate: Date; ToDate: Date; TargetJobNo: Code[20]; TargetJobTaskNo: Code[20]; CopyQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQueryClosePageOnAfterCopyJobPlanningLines(SourceJobTask: Record "Job Task"; TargetJobTask: Record "Job Task")
    begin
    end;
}

