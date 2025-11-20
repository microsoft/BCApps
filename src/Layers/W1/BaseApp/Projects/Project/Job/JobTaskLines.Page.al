// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Finance.Dimension;
using Microsoft.Projects.Project.Ledger;
#if not CLEAN25
using Microsoft.Integration.Dataverse;
#endif
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Reports;
using Microsoft.Projects.Project.WIP;
using Microsoft.Purchases.Document;

page 1002 "Job Task Lines"
{
    Caption = 'Project Task Lines';
    DataCaptionFields = "Job No.";
    PageType = List;
    SaveValues = true;
    SourceTable = "Job Task";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related project.';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related project task.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies a description of the project task. You can enter anything that is meaningful in describing the task. The description is copied and used in descriptions on the project planning line.';
                }
                field("Job Task Type"; Rec."Job Task Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the purpose of the account. Newly created accounts are automatically assigned the Posting account type, but you can change this. Choose the field to select one of the following five options:';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an interval or a list of project task numbers.';
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project posting group of the task.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the location code of the task.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a bin code for specific location of the task.';
                }
                field("WIP-Total"; Rec."WIP-Total")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project tasks you want to group together when calculating Work In Process (WIP) and Recognition.';
                }
                field("WIP Method"; Rec."WIP Method")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the Work in Process calculation method that is associated with a project. The value in this field comes from the WIP method specified on the project card.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the start date for the project task. The date is based on the date on the related project planning line.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the end date for the project task. The date is based on the date on the related project planning line.';
                }
                field("Schedule (Total Cost)"; Rec."Schedule (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in the local currency, the total budgeted cost for the project task during the time period in the Planning Date Filter field.';
                }
                field("Schedule (Total Price)"; Rec."Schedule (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in local currency, the total budgeted price for the project task during the time period in the Planning Date Filter field.';
                }
                field("Usage (Total Cost)"; Rec."Usage (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in local currency, the total cost of the usage of items, resources and general ledger expenses posted on the project task during the time period in the Posting Date Filter field.';
                }
                field("Usage (Total Price)"; Rec."Usage (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in the local currency, the total price of the usage of items, resources and general ledger expenses posted on the project task during the time period in the Posting Date Filter field.';
                }
                field("Contract (Total Cost)"; Rec."Contract (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in local currency, the total billable cost for the project task during the time period in the Planning Date Filter field.';
                }
                field("Contract (Total Price)"; Rec."Contract (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in the local currency, the total billable price for the project task during the time period in the Planning Date Filter field.';
                }
                field("Contract (Invoiced Cost)"; Rec."Contract (Invoiced Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in the local currency, the total billable cost for the project task that has been invoiced during the time period in the Posting Date Filter field.';
                }
                field("Contract (Invoiced Price)"; Rec."Contract (Invoiced Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in the local currency, the total billable price for the project task that has been invoiced during the time period in the Posting Date Filter field.';
                }
                field("Remaining (Total Cost)"; Rec."Remaining (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the remaining total cost (LCY) as the sum of costs from project planning lines associated with the project task. The calculation occurs when you have specified that there is a usage link between the project ledger and the project planning lines.';
                }
                field("Remaining (Total Price)"; Rec."Remaining (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the remaining total price (LCY) as the sum of prices from project planning lines associated with the project task. The calculation occurs when you have specified that there is a usage link between the project ledger and the project planning lines.';
                }
                field("EAC (Total Cost)"; Rec.CalcEACTotalCost())
                {
                    ApplicationArea = Jobs;
                    Caption = 'EAC (Total Cost)';
                    ToolTip = 'Specifies the estimate at completion (EAC) total cost for a project task line. If the Apply Usage Link check box on the project is selected, then the EAC (Total Cost) field is calculated as follows:  Usage (Total Cost) + Remaining (Total Cost).';
                }
                field("EAC (Total Price)"; Rec.CalcEACTotalPrice())
                {
                    ApplicationArea = Jobs;
                    Caption = 'EAC (Total Price)';
                    ToolTip = 'Specifies the estimate at completion (EAC) total price for a project task line. If the Apply Usage Link check box on the project is selected, then the EAC (Total Price) field is calculated as follows: Usage (Total Price) + Remaining (Total Price).';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Outstanding Orders"; Rec."Outstanding Orders")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the sum of outstanding orders, in local currency, for this project task. The value of the Outstanding Amount (LCY) field is used for entries in the Purchase Line table of document type Order to calculate and update the contents of this field.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        PurchLine: Record "Purchase Line";
                    begin
                        SetPurchLineFilters(PurchLine, Rec."Job No.", Rec."Job Task No.");
                        PurchLine.SetFilter("Outstanding Amt. Ex. VAT (LCY)", '<> 0');
                        PAGE.RunModal(PAGE::"Purchase Lines", PurchLine);
                    end;
                }
                field("Amt. Rcd. Not Invoiced"; Rec."Amt. Rcd. Not Invoiced")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the sum for items that have been received but have not yet been invoiced. The value in the Amt. Rcd. Not Invoiced (LCY) field is used for entries in the Purchase Line table of document type Order to calculate and update the contents of this field.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        PurchLine: Record "Purchase Line";
                    begin
                        SetPurchLineFilters(PurchLine, Rec."Job No.", Rec."Job Task No.");
                        PurchLine.SetFilter("Amt. Rcd. Not Invoiced (LCY)", '<> 0');
                        PAGE.RunModal(PAGE::"Purchase Lines", PurchLine);
                    end;
                }
#if not CLEAN25
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                    ToolTip = 'Specifies if the project task is coupled to an entity in Field Service.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
#endif
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Job Task")
            {
                Caption = '&Project Task';
                Image = Task;
                action(JobPlanningLines)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project &Planning Lines';
                    Image = JobLines;
                    ToolTip = 'View all planning lines for the project. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a project (budget) or you can specify what you actually agreed with your customer that they should pay for the project (billable).';

                    trigger OnAction()
                    var
                        JobPlanningLine: Record "Job Planning Line";
                        JobPlanningLines: Page "Job Planning Lines";
                    begin
                        Rec.TestField("Job Task Type", Rec."Job Task Type"::Posting);
                        Rec.TestField("Job No.");
                        Rec.TestField("Job Task No.");
                        JobPlanningLine.SetRange("Job No.", Rec."Job No.");
                        JobPlanningLine.SetRange("Job Task No.", Rec."Job Task No.");
                        JobPlanningLines.SetJobTaskNoVisible(false);
                        JobPlanningLines.SetTableView(JobPlanningLine);
                        JobPlanningLines.Run();
                    end;
                }
                action(JobTaskStatistics)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Task &Statistics';
                    Image = StatisticsDocument;
                    RunObject = Page "Job Task Statistics";
                    RunPageLink = "Job No." = field("Job No."),
                                  "Job Task No." = field("Job Task No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistics for the project task.';
                }
                action("Job &Task Card")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project &Task Card';
                    Image = Task;
                    RunObject = Page "Job Task Card";
                    RunPageLink = "Job No." = field("Job No."),
                                  "Job Task No." = field("Job Task No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about a project task, such as the description of the task and the type, which can be either a heading, a posting, a begin-total, an end-total, or a total.';
                }
                separator("-")
                {
                    Caption = '-';
                }
                group("&Dimensions")
                {
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    action("Dimensions-&Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Single';
                        Image = Dimensions;
                        RunObject = Page "Job Task Dimensions";
                        RunPageLink = "Job No." = field("Job No."),
                                      "Job Task No." = field("Job Task No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            JobTask: Record "Job Task";
                            JobTaskDimensionsMultiple: Page "Job Task Dimensions Multiple";
                        begin
                            CurrPage.SetSelectionFilter(JobTask);
                            JobTaskDimensionsMultiple.SetMultiJobTask(JobTask);
                            JobTaskDimensionsMultiple.RunModal();
                        end;
                    }
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("Sales &Invoices/Credit Memos")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Sales &Invoices/Credit Memos';
                    Image = GetSourceDoc;
                    ToolTip = 'View sales invoices or sales credit memos that are related to the selected project task.';

                    trigger OnAction()
                    var
                        JobInvoices: Page "Job Invoices";
                    begin
                        JobInvoices.SetPrJobTask(Rec);
                        JobInvoices.RunModal();
                    end;
                }
            }
            group("W&IP")
            {
                Caption = 'W&IP';
                Image = WIP;
                action("&WIP Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = '&WIP Entries';
                    Image = WIPEntries;
                    RunObject = Page "Job WIP Entries";
                    RunPageLink = "Job No." = field("Job No.");
                    RunPageView = sorting("Job No.", "Job Posting Group", "WIP Posting Date");
                    ToolTip = 'View entries for the project that are posted as work in process.';
                }
                action("WIP &G/L Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'WIP &G/L Entries';
                    Image = WIPLedger;
                    RunObject = Page "Job WIP G/L Entries";
                    RunPageLink = "Job No." = field("Job No.");
                    RunPageView = sorting("Job No.");
                    ToolTip = 'View the project''s WIP G/L entries.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Job Ledger E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Ledger E&ntries';
                    Image = JobLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Job No." = field("Job No."),
                                  "Job Task No." = field("Job Task No.");
                    RunPageView = sorting("Job No.", "Job Task No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the project ledger entries.';
                }
            }
#if not CLEAN25
            group(ActionGroupFS)
            {
                Caption = 'Dynamics 365 Field Service';
                Visible = false;
                ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                ObsoleteState = Pending;
                ObsoleteTag = '25.0';

                action(CRMGoToProduct)
                {
                    ApplicationArea = Suite;
                    Caption = 'Project Task in Field Service';
                    Image = CoupledItem;
                    ToolTip = 'Open the coupled Dynamics 365 Field Service entity.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Field Service.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Field Service entity.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';

                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Field Service entity.';
                        ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '25.0';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Field Service entity.';
                        ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '25.0';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(Rec.RecordId);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for this table.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
#endif
        }
        area(processing)
        {
            group("New Documents")
            {
                Caption = 'New Documents';
                Image = Invoice;
                action("Create &Sales Invoice")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Create &Sales Invoice';
                    Ellipsis = true;
                    Image = JobSalesInvoice;
                    ToolTip = 'Use a batch job to help you create sales invoices for the involved project tasks.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                        JobTask: Record "Job Task";
                    begin
                        Rec.TestField("Job No.");
                        Job.Get(Rec."Job No.");
                        if Job.Blocked = Job.Blocked::All then
                            Job.TestBlocked();

                        JobTask.SetRange("Job No.", Job."No.");
                        if Rec."Job Task No." <> '' then
                            JobTask.SetRange("Job Task No.", Rec."Job Task No.");

                        REPORT.RunModal(REPORT::"Job Create Sales Invoice", true, false, JobTask);
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Split &Planning Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Split &Planning Lines';
                    Ellipsis = true;
                    Image = Splitlines;
                    ToolTip = 'Split planning lines of type Budget and Billable into two separate planning lines: Budget and Billable.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                        JobTask: Record "Job Task";
                    begin
                        Rec.TestField("Job No.");
                        Job.Get(Rec."Job No.");
                        if Job.Blocked = Job.Blocked::All then
                            Job.TestBlocked();

                        Rec.TestField("Job Task No.");
                        JobTask.SetRange("Job No.", Job."No.");
                        JobTask.SetRange("Job Task No.", Rec."Job Task No.");

                        REPORT.RunModal(REPORT::"Job Split Planning Line", true, false, JobTask);
                    end;
                }
                action("Change &Dates")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Change &Dates';
                    Ellipsis = true;
                    Image = ChangeDate;
                    ToolTip = 'Use a batch job to help you move planning lines on a project from one date interval to another.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                        JobTask: Record "Job Task";
                    begin
                        Rec.TestField("Job No.");
                        Job.Get(Rec."Job No.");
                        if Job.Blocked = Job.Blocked::All then
                            Job.TestBlocked();

                        JobTask.SetRange("Job No.", Job."No.");
                        if Rec."Job Task No." <> '' then
                            JobTask.SetRange("Job Task No.", Rec."Job Task No.");

                        REPORT.RunModal(REPORT::"Change Job Dates", true, false, JobTask);
                    end;
                }
                action("<Action7>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'I&ndent Project Tasks';
                    Image = Indent;
                    RunObject = Codeunit "Job Task-Indent";
                    ToolTip = 'Move the selected lines in one position to show that the tasks are subcategories of other tasks. Project tasks that are totaled are the ones that lie between one pair of corresponding Begin-Total and End-Total project tasks.';
                }
                group("&Copy")
                {
                    Caption = '&Copy';
                    Image = Copy;
                    action("Copy Job Planning Lines &from...")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Copy Project Planning Lines &from...';
                        Ellipsis = true;
                        Image = CopyToTask;
                        ToolTip = 'Use a batch job to help you copy planning lines from one project task to another. You can copy from a project task within the project you are working with or from a project task linked to a different project.';

                        trigger OnAction()
                        var
                            CopyJobPlanningLines: Page "Copy Job Planning Lines";
                        begin
                            Rec.TestField("Job Task Type", Rec."Job Task Type"::Posting);
                            CopyJobPlanningLines.SetToJobTask(Rec);
                            CopyJobPlanningLines.RunModal();
                        end;
                    }
                    action("Copy Job Planning Lines &to...")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Copy Project Planning Lines &to...';
                        Ellipsis = true;
                        Image = CopyFromTask;
                        ToolTip = 'Use a batch job to help you copy planning lines from one project task to another. You can copy from a project task within the project you are working with or from a project task linked to a different project.';

                        trigger OnAction()
                        var
                            CopyJobPlanningLines: Page "Copy Job Planning Lines";
                        begin
                            Rec.TestField("Job Task Type", Rec."Job Task Type"::Posting);
                            CopyJobPlanningLines.SetFromJobTask(Rec);
                            CopyJobPlanningLines.RunModal();
                        end;
                    }
                }
                group("<Action13>")
                {
                    Caption = 'W&IP';
                    Image = WIP;
                    action("<Action48>")
                    {
                        ApplicationArea = Jobs;
                        Caption = '&Calculate WIP';
                        Ellipsis = true;
                        Image = CalculateWIP;
                        ToolTip = 'Run the Project Calculate WIP batch job.';

                        trigger OnAction()
                        var
                            Job: Record Job;
                            JobCalculateWIP: Report "Job Calculate WIP";
                        begin
                            Rec.TestField("Job No.");
                            Job.Get(Rec."Job No.");
                            Job.SetRange("No.", Job."No.");
                            Clear(JobCalculateWIP);
                            JobCalculateWIP.SetTableView(Job);
                            JobCalculateWIP.Run();
                        end;
                    }
                    action("<Action49>")
                    {
                        ApplicationArea = Jobs;
                        Caption = '&Post WIP to G/L';
                        Ellipsis = true;
                        Image = PostOrder;
                        ShortCutKey = 'F9';
                        ToolTip = 'Run the Project Post WIP to G/L batch job.';

                        trigger OnAction()
                        var
                            Job: Record Job;
                        begin
                            Rec.TestField("Job No.");
                            Job.Get(Rec."Job No.");
                            Job.SetRange("No.", Job."No.");
                            REPORT.RunModal(REPORT::"Job Post WIP to G/L", true, false, Job);
                        end;
                    }
                }
            }
        }
        area(reporting)
        {
            action("Job Actual to Budget")
            {
                ApplicationArea = Jobs;
                Caption = 'Project Actual to Budget';
                Image = "Report";
                RunObject = Report "Job Actual To Budget";
                ToolTip = 'Compare budgeted and usage amounts for selected projects. All lines of the selected project show quantity, total cost, and line amount.';
            }
            action("Job Analysis")
            {
                ApplicationArea = Jobs;
                Caption = 'Project Analysis';
                Image = "Report";
                RunObject = Report "Job Analysis";
                ToolTip = 'Analyze the project, such as the budgeted prices, usage prices, and billable prices, and then compares the three sets of prices.';
            }
            action("Job - Planning Lines")
            {
                ApplicationArea = Jobs;
                Caption = 'Project - Planning Lines';
                Image = "Report";
                RunObject = Report "Job - Planning Lines";
                ToolTip = 'View all planning lines for the project. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a project (budget) or you can specify what you actually agreed with your customer that he should pay for the project (billable).';
            }
            action("Job - Suggested Billing")
            {
                ApplicationArea = Jobs;
                Caption = 'Project - Suggested Billing';
                Image = "Report";
                RunObject = Report "Job Suggested Billing";
                ToolTip = 'View a list of all projects, grouped by customer, how much the customer has already been invoiced, and how much remains to be invoiced, that is, the suggested billing.';
            }
            action("Jobs - Transaction Detail")
            {
                ApplicationArea = Jobs;
                Caption = 'Projects - Transaction Detail';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Job - Transaction Detail";
                ToolTip = 'View all postings with entries for a selected project for a selected period, which have been charged to a certain project. At the end of each project list, the amounts are totaled separately for the Sales and Usage entry types.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group("Category_Copy Lines")
                {
                    Caption = 'Copy Lines';

                    actionref("Copy Job Planning Lines &from..._Promoted"; "Copy Job Planning Lines &from...")
                    {
                    }
                    actionref("Copy Job Planning Lines &to..._Promoted"; "Copy Job Planning Lines &to...")
                    {
                    }
                }
                actionref("Create &Sales Invoice_Promoted"; "Create &Sales Invoice")
                {
                }
                actionref("Split &Planning Lines_Promoted"; "Split &Planning Lines")
                {
                }
            }
            group("Category_Job Task")
            {
                Caption = 'Project Task';

                actionref(JobPlanningLines_Promoted; JobPlanningLines)
                {
                }
                actionref("Sales &Invoices/Credit Memos_Promoted"; "Sales &Invoices/Credit Memos")
                {
                }
                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref("Dimensions-&Multiple_Promoted"; "Dimensions-&Multiple")
                    {
                    }
                    actionref("Dimensions-&Single_Promoted"; "Dimensions-&Single")
                    {
                    }
                }
                actionref(JobTaskStatistics_Promoted; JobTaskStatistics)
                {
                }
                actionref("Job &Task Card_Promoted"; "Job &Task Card")
                {
                }
            }
            group(Category_WIP)
            {
                Caption = 'WIP';

                actionref("<Action48>_Promoted"; "<Action48>")
                {
                }
                actionref("<Action49>_Promoted"; "<Action49>")
                {
                }
                actionref("&WIP Entries_Promoted"; "&WIP Entries")
                {
                }
                actionref("WIP &G/L Entries_Promoted"; "WIP &G/L Entries")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Job - Planning Lines_Promoted"; "Job - Planning Lines")
                {
                }
                actionref("Job Actual to Budget_Promoted"; "Job Actual to Budget")
                {
                }
                actionref("Job Analysis_Promoted"; "Job Analysis")
                {
                }
                actionref("Job - Suggested Billing_Promoted"; "Job - Suggested Billing")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := Rec.Indentation;
        StyleIsStrong := Rec."Job Task Type" <> Rec."Job Task Type"::Posting;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.ClearTempDim();
    end;

    var
        DescriptionIndent: Integer;

    protected var
        StyleIsStrong: Boolean;

    procedure SetPurchLineFilters(var PurchLine: Record "Purchase Line"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        Rec.ApplyPurchaseLineFilters(PurchLine, JobNo, JobTaskNo);
    end;
}

