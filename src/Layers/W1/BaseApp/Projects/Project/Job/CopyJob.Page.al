// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Project.Setup;
using Microsoft.Sales.Customer;

page 1040 "Copy Job"
{
    Caption = 'Copy Project';
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
                        TargetJobDescription := SourceJob.Description;
                        TargetSellToCustomerNo := SourceJob."Sell-to Customer No.";
                        TargetBillToCustomerNo := SourceJob."Bill-to Customer No.";

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
                    ToolTip = 'Specifies the project number.';
                }
                field(TargetJobDescription; TargetJobDescription)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Description';
                    ToolTip = 'Specifies a description of the project.';
                }
                field(TargetSellToCustomerNo; TargetSellToCustomerNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Sell-To Customer No.';
                    TableRelation = Customer;
                    ToolTip = 'Specifies the number of an alternate customer that the project is sold to instead of the main customer.';
                }
                field(TargetBillToCustomerNo; TargetBillToCustomerNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Bill-To Customer No.';
                    TableRelation = Customer;
                    ToolTip = 'Specifies the number of an alternate customer that the project is billed to instead of the main customer.';
                }
            }
            group(Apply)
            {
                Caption = 'Apply';
                field(CopyJobPrices; CopyJobPrices)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Copy Project Prices';
                    ToolTip = 'Specifies that item prices, resource prices, and G/L prices will be copied from the project that you specified on the Copy From FastTab.';
                }
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
                    ToolTip = 'Specifies that the dimensions will be copied to the new project.';
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
        ValidateSource();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TargetJob: Record Job;
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            ValidateUserInput();
            CopyJob.SetCopyOptions(CopyJobPrices, CopyQuantity, CopyDimensions, Source, PlanningLineType, LedgerEntryType);
            CopyJob.SetJobTaskRange(FromJobTaskNo, ToJobTaskNo);
            CopyJob.SetJobTaskDateRange(FromDate, ToDate);
            CopyJob.CopyJob(SourceJob, TargetJobNo, TargetJobDescription, TargetSellToCustomerNo, TargetBillToCustomerNo);
            TargetJob.Get(TargetJobNo);
            Message(Text001, SourceJob."No.", TargetJob."No.", TargetJob.Status);
        end
    end;

    var
        CopyJob: Codeunit "Copy Job";
        FromDate: Date;
        ToDate: Date;
        Source: Option "Job Planning Lines","Job Ledger Entries","None";
        PlanningLineType: Option "Budget+Billable",Budget,Billable;
        LedgerEntryType: Option "Usage+Sale",Usage,Sale;
        PlanningLineTypeEnable: Boolean;
        LedgerEntryLineTypeEnable: Boolean;

#pragma warning disable AA0074
        Text001: Label 'The project no. %1 was successfully copied to the new project no. %2 with the status %3.', Comment = '%1 - The "No." of source project; %2 - The "No." of target project, %3 - project status.';
#pragma warning disable AA0470
        Text002: Label 'Project No. %1 will be assigned to the new Project. Do you want to continue?';
        Text003: Label '%1 %2 does not exist.', Comment = 'Project Task 1000 does not exist.';
        Text004: Label 'Provide a valid source %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        SourceJob: Record Job;
        SourceJobNo: Code[20];
        FromJobTaskNo: Code[20];
        ToJobTaskNo: Code[20];
        TargetJobNo: Code[20];
        TargetJobDescription: Text[100];
        TargetSellToCustomerNo: Code[20];
        TargetBillToCustomerNo: Code[20];
        CopyJobPrices: Boolean;
        CopyQuantity: Boolean;
        CopyDimensions: Boolean;

    local procedure ValidateUserInput()
    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        if (SourceJobNo = '') or not SourceJob.Get(SourceJob."No.") then
            Error(Text004, SourceJob.TableCaption());
        IsHandled := false;
        OnValidateUserInputOnBeforeCheckTargetJobNo(SourceJob, TargetJobNo, IsHandled);
        if not IsHandled then begin
            JobsSetup.Get();
            JobsSetup.TestField("Job Nos.");
            if TargetJobNo = '' then begin
                TargetJobNo := NoSeries.GetNextNo(JobsSetup."Job Nos.", 0D);
                if not Confirm(Text002, true, TargetJobNo) then begin
                    TargetJobNo := '';
                    Error('');
                end;
            end else
                NoSeries.TestManual(JobsSetup."Job Nos.");
        end;
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
        TargetJobDescription := SourceJob.Description;
        TargetSellToCustomerNo := SourceJob."Sell-to Customer No.";
        TargetBillToCustomerNo := SourceJob."Bill-to Customer No.";

        OnAfterSetFromJob(SourceJob, FromDate, ToDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFromJob(SourceJob: Record Job; var FromDate: Date; var ToDate: Date)
    begin
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
    local procedure OnValidateUserInputOnBeforeCheckTargetJobNo(SourceJob: Record Job; var TargetJobNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

