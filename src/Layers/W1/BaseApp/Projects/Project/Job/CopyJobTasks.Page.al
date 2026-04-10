// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

page 1041 "Copy Job Tasks"
{
    Caption = 'Copy Project Tasks';
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
                    begin
                        if (SourceJobNo <> '') and not SourceJob.Get(SourceJobNo) then
                            Error(Text003, SourceJob.TableCaption(), SourceJobNo);

                        FromJobTaskNo := '';
                        ToJobTaskNo := '';
                    end;
                }
                field(FromJobTaskNo; FromJobTaskNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Task No. from';
                    ToolTip = 'Specifies the first project task number to be copied from. Only planning lines with a project task number equal to or higher than the number specified in this field will be included.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        JobTask: Record "Job Task";
                    begin
                        if SourceJob."No." <> '' then begin
                            JobTask.SetRange("Job No.", SourceJob."No.");
                            OnLookupFromJobTaskNoOnAfterSetJobTaskFilters(JobTask);
                            if PAGE.RunModal(PAGE::"Job Task List", JobTask) = ACTION::LookupOK then
                                FromJobTaskNo := JobTask."Job Task No.";
                        end;
                    end;

                    trigger OnValidate()
                    var
                        JobTask: Record "Job Task";
                    begin
                        if (FromJobTaskNo <> '') and not JobTask.Get(SourceJob."No.", FromJobTaskNo) then
                            Error(Text003, JobTask.TableCaption(), FromJobTaskNo);
                    end;
                }
                field(ToJobTaskNo; ToJobTaskNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Task No. to';
                    ToolTip = 'Specifies the last project task number to be copied from. Only planning lines with a project task number equal to or lower than the number specified in this field will be included.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        JobTask: Record "Job Task";
                    begin
                        if SourceJobNo <> '' then begin
                            JobTask.SetRange("Job No.", SourceJobNo);
                            OnLookupToJobTaskNoOnAfterSetJobTaskFilters(JobTask);
                            if PAGE.RunModal(PAGE::"Job Task List", JobTask) = ACTION::LookupOK then
                                ToJobTaskNo := JobTask."Job Task No.";
                        end;
                    end;

                    trigger OnValidate()
                    var
                        JobTask: Record "Job Task";
                    begin
                        if (ToJobTaskNo <> '') and not JobTask.Get(SourceJobNo, ToJobTaskNo) then
                            Error(Text003, JobTask.TableCaption(), ToJobTaskNo);
                    end;
                }
                field("From Source"; Source)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Source';
                    OptionCaption = 'Project Planning Lines,Project Ledger Entries,None';
                    ToolTip = 'Specifies the basis on which you want the planning lines to be copied. If, for example, you want the planning lines to reflect actual usage and invoicing of items, resources, and general ledger expenses on the project you copy from, then select Project Ledger Entries in this field.';

                    trigger OnValidate()
                    begin
                        ValidateSource();
                    end;
                }
                field("Planning Line Type"; PlanningLineType)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Incl. Planning Line Type';
                    Enabled = PlanningLineTypeEnable;
                    OptionCaption = 'Budget+Billable,Budget,Billable';
                    ToolTip = 'Specifies how copy planning lines. Budget+Billable: All planning lines are copied. Budget: Only lines of type Budget or type Both Budget and Billable are copied. Billable: Only lines of type Billable or type Both Budget and Billable are copied.';
                }
                field("Ledger Entry Line Type"; LedgerEntryType)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Incl. Ledger Entry Line Type';
                    Enabled = LedgerEntryLineTypeEnable;
                    OptionCaption = 'Usage+Sale,Usage,Sale';
                    ToolTip = 'Specifies how to copy project ledger entries. Usage+Sale: All project ledger entries are copied. Entries of type Usage are copied to new planning lines of type Budget. Entries of type Sale are copied to new planning lines of type Billable. Usage: All project ledger entries of type Usage are copied to new planning lines of type Budget. Sale: All project ledger entries of type Sale are copied to new planning lines of type Billable.';
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
                    begin
                        if (TargetJobNo <> '') and not TargetJob.Get(TargetJobNo) then
                            Error(Text003, TargetJob.TableCaption(), TargetJobNo);
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
                field(CopyDimensions; CopyDimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Copy Dimensions';
                    ToolTip = 'Specifies that the dimensions will be copied to the new project task.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        PlanningLineType := PlanningLineType::"Budget+Billable";
        LedgerEntryType := LedgerEntryType::"Usage+Sale";
        OnOpenPageOnBeforeValidateSource(CopyQuantity, CopyDimensions, Source, PlanningLineType, LedgerEntryType);
        ValidateSource();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnQueryClosePage(CloseAction, SourceJob, TargetJob, IsHandled, CopyQuantity, CopyDimensions, Source, PlanningLineType, LedgerEntryType, FromJobTaskNo, ToJobTaskNo, FromDate, ToDate);
        if IsHandled then
            exit(IsHandled);

        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            ValidateUserInput();
            CopyJob.SetCopyOptions(false, CopyQuantity, CopyDimensions, Source, PlanningLineType, LedgerEntryType);
            CopyJob.SetJobTaskRange(FromJobTaskNo, ToJobTaskNo);
            CopyJob.SetJobTaskDateRange(FromDate, ToDate);
            OnQueryClosePageOnBeforeCopyJobTasks(CopyJob, CopyQuantity, CopyDimensions, Source, PlanningLineType, LedgerEntryType);
            CopyJob.CopyJobTasks(SourceJob, TargetJob);
            Message(Text001);
        end
    end;

    var
#pragma warning disable AA0074
        Text001: Label 'The project was successfully copied.';
#pragma warning disable AA0470
        Text003: Label '%1 %2 does not exist.', Comment = 'Project Task 1000 does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PlanningLineTypeEnable: Boolean;
        LedgerEntryLineTypeEnable: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Provide a valid source %1.';
        Text005: Label 'Provide a valid target %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        SourceJob, TargetJob : Record Job;
        CopyJob: Codeunit "Copy Job";
        SourceJobNo, FromJobTaskNo, ToJobTaskNo, TargetJobNo : Code[20];
        FromDate, ToDate : Date;
        Source: Option "Job Planning Lines","Job Ledger Entries","None";
        PlanningLineType: Option "Budget+Billable",Budget,Billable;
        LedgerEntryType: Option "Usage+Sale",Usage,Sale;
        CopyQuantity, CopyDimensions : Boolean;

    local procedure ValidateUserInput()
    begin
        if (SourceJobNo = '') or not SourceJob.Get(SourceJobNo) then
            Error(Text004, SourceJob.TableCaption());

        if (TargetJobNo = '') or not TargetJob.Get(TargetJobNo) then
            Error(Text005, TargetJob.TableCaption());
    end;

    local procedure ValidateSource()
    begin
        case true of
            Source = Source::"Job Planning Lines":
                begin
                    PlanningLineTypeEnable := true;
                    LedgerEntryLineTypeEnable := false;
                end;
            Source = Source::"Job Ledger Entries":
                begin
                    PlanningLineTypeEnable := false;
                    LedgerEntryLineTypeEnable := true;
                end;
            Source = Source::None:
                begin
                    PlanningLineTypeEnable := false;
                    LedgerEntryLineTypeEnable := false;
                end;
        end;
    end;

    procedure SetFromJob(SourceJob2: Record Job)
    begin
        SourceJob := SourceJob2;
        SourceJobNo := SourceJob."No.";
    end;

    procedure SetToJob(TargetJob2: Record Job)
    begin
        TargetJob := TargetJob2;
        TargetJobNo := TargetJob."No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupFromJobTaskNoOnAfterSetJobTaskFilters(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupToJobTaskNoOnAfterSetJobTaskFilters(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnQueryClosePage(var CloseAction: Action; var SourceJob: Record Job; var TargetJob: Record Job; var IsHandled: Boolean; var CopyQuantity: Boolean; var CopyDimensions: Boolean; var Source: Option "Job Planning Lines","Job Ledger Entries","None"; var PlanningLineType: Option "Budget+Billable",Budget,Billable; var LedgerEntryType: Option "Usage+Sale",Usage,Sale; var FromJobTaskNo: Code[20]; var ToJobTaskNo: Code[20]; var FromDate: Date; var ToDate: Date)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOpenPageOnBeforeValidateSource(var CopyQuantity: Boolean; var CopyDimensions: Boolean; var Source: Option "Job Planning Lines","Job Ledger Entries","None"; var PlanningLineType: Option "Budget+Billable",Budget,Billable; var LedgerEntryType: Option "Usage+Sale",Usage,Sale);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnQueryClosePageOnBeforeCopyJobTasks(var CopyJob: Codeunit "Copy Job"; var CopyQuantity: Boolean; var CopyDimensions: Boolean; var Source: Option "Job Planning Lines","Job Ledger Entries","None"; var PlanningLineType: Option "Budget+Billable",Budget,Billable; var LedgerEntryType: Option "Usage+Sale",Usage,Sale);
    begin
    end;
}

