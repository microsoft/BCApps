// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Assembly.Document;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Comment;
using Microsoft.Inventory.BOM;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Analysis;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Project.Reports;
using Microsoft.Projects.Project.WIP;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Structure;
using System.Integration.PowerBI;

page 89 "Job List"
{
    AdditionalSearchTerms = 'Project List,Jobs,Job List';
    ApplicationArea = Jobs;
    Caption = 'Projects';
    CardPageID = "Job Card";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Projects';
    AboutText = 'Manage and track projects by organizing tasks, assigning responsibilities, setting billing methods for one or multiple customers, and monitoring project status and invoicing details.';
    QueryCategory = 'Job List';
    SourceTable = Job;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a short description of the project.';
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the customer who pays for the project.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a status for the current project. You can change the status for the project as it progresses. Final calculations can be made on completed projects.';
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the person responsible for the project. You can select a name from the list of resources available in the Resource List window. The name is copied from the No. field in the Resource table. You can choose the field to see a list of resources.';
                    Visible = false;
                }
                field("Next Invoice Date"; Rec."Next Invoice Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the next invoice date for the project.';
                    Visible = false;
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a project posting group code for a project. To see the available codes, choose the field.';
                    Visible = false;
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the additional name for the project. The field is used for searching purposes.';
                }
                field("% of Overdue Planning Lines"; Rec.PercentOverdue())
                {
                    ApplicationArea = Jobs;
                    Caption = '% of Overdue Planning Lines';
                    Editable = false;
                    ToolTip = 'Specifies the percent of planning lines that are overdue for this project.';
                    Visible = false;
                }
                field("% Completed"; Rec.PercentCompleted())
                {
                    ApplicationArea = Jobs;
                    Caption = '% Completed';
                    Editable = false;
                    ToolTip = 'Specifies the completion percentage for this project.';
                    Visible = false;
                }
                field("% Invoiced"; Rec.PercentInvoiced())
                {
                    ApplicationArea = Jobs;
                    Caption = '% Invoiced';
                    Editable = false;
                    ToolTip = 'Specifies the invoiced percentage for this project.';
                    Visible = false;
                }
                field("Project Manager"; Rec."Project Manager")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the person assigned as the manager for this project.';
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                    Visible = false;
                }
                field("Completely Picked"; Rec."Completely Picked")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether all items on the project planning lines have been completely picked.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(PowerBIEmbeddedReportPart; "Power BI Embedded Report Part")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(Control1907234507; "Sales Hist. Bill-to FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("Bill-to Customer No.");
                Visible = false;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("Bill-to Customer No.");
                Visible = false;
            }
            part(Control1905650007; "Job WIP/Recognition FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No.");
            }
            part("Job Details"; "Job Cost Factbox")
            {
                ApplicationArea = Jobs;
                Caption = 'Project Details';
                SubPageLink = "No." = field("No.");
            }
#if not CLEAN25
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ObsoleteTag = '25.0';
                ObsoleteState = Pending;
                ObsoleteReason = 'The "Document Attachment FactBox" has been replaced by "Doc. Attachment List Factbox", which supports multiple files upload.';
                ApplicationArea = All;
                Visible = false;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::Job),
                              "No." = field("No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Job),
                              "No." = field("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Job")
            {
                Caption = '&Project';
                Image = Job;
                action("Job Task &Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Task &Lines';
                    Image = TaskList;
                    RunObject = Page "Job Task Lines";
                    RunPageLink = "Job No." = field("No.");
                    ToolTip = 'Plan how you want to set up your planning information. In this window you can specify the tasks involved in a project. To start planning a project or to post usage for a project, you must set up at least one project task.';
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
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(167),
                                      "No." = field("No.");
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
                            Job: Record Job;
                            DefaultDimensionsMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Job);
                            DefaultDimensionsMultiple.SetMultiRecord(Job, Rec.FieldNo("No."));
                            DefaultDimensionsMultiple.RunModal();
                        end;
                    }
                }
                action("&Statistics")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Statistics';
                    Image = Statistics;
                    RunObject = Page "Job Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View this project''s statistics.';
                }
                action(SalesInvoicesCreditMemos)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Sales &Invoices/Credit Memos';
                    Image = GetSourceDoc;
                    ToolTip = 'View sales invoices or sales credit memos that are related to the selected project.';

                    trigger OnAction()
                    var
                        JobInvoices: Page "Job Invoices";
                    begin
                        JobInvoices.SetPrJob(Rec);
                        JobInvoices.RunModal();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Job),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(AssemblyOrders)
                {
                    AccessByPermission = TableData "BOM Component" = R;
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    Image = AssemblyOrder;
                    ToolTip = 'View ongoing assembly orders related to the project. ';

                    trigger OnAction()
                    var
                        AssembleToOrderLink: Record "Assemble-to-Order Link";
                    begin
                        AssembleToOrderLink.ShowAsmOrders(Rec, '');
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
                    RunPageLink = "Job No." = field("No.");
                    RunPageView = sorting("Job No.", "Job Posting Group", "WIP Posting Date")
                                  order(descending);
                    ToolTip = 'View entries for the project that are posted as work in process.';
                }
                action("WIP &G/L Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'WIP &G/L Entries';
                    Image = WIPLedger;
                    RunObject = Page "Job WIP G/L Entries";
                    RunPageLink = "Job No." = field("No.");
                    RunPageView = sorting("Job No.")
                                  order(descending);
                    ToolTip = 'View the project''s WIP G/L entries.';
                }
                action("WIP Cockpit")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project WIP Cockpit';
                    Image = WIPLedger;
                    RunObject = Page "Job WIP Cockpit";
                    ToolTip = 'View the Project WIP Cockpit.';
                }
            }
            group("&Prices")
            {
                Caption = '&Prices';
                Image = Price;
                Visible = not ExtendedPriceEnabled;
                action("&Resource")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Resource';
                    Image = Resource;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Job Resource Prices";
                    RunPageLink = "Job No." = field("No.");
                    ToolTip = 'View this project''s resource prices.';
                }
                action("&Item")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Item';
                    Image = Item;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Job Item Prices";
                    RunPageLink = "Job No." = field("No.");
                    ToolTip = 'View this project''s item prices.';
                }
                action("&G/L Account")
                {
                    ApplicationArea = Jobs;
                    Caption = '&G/L Account';
                    Image = JobPrice;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Job G/L Account Prices";
                    RunPageLink = "Job No." = field("No.");
                    ToolTip = 'View this project''s G/L account prices.';
                }
            }
            group(Prices)
            {
                Caption = '&Prices';
                Image = Price;
                Visible = ExtendedPriceEnabled;
                action(SalesPriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Price Lists';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lists for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, Enum::"Price Type"::Sale, Enum::"Price Amount Type"::Any);
                    end;
                }
                action(SalesPriceLines)
                {
                    AccessByPermission = TableData "Sales Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Scope = Repeater;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lines for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource, Enum::"Price Type"::Sale);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Price);
                    end;
                }
                action(SalesDiscountLines)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = LineDiscount;
                    Scope = Repeater;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource, Enum::"Price Type"::Sale);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Discount);
                    end;
                }
                action(SalesPriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = false;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, PriceType::Sale, AmountType::Discount);
                    end;
                }
                action(PurchasePriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Price Lists';
                    Image = ResourceCosts;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up purchase price lists for products that you buy from the vendor. An product price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, Enum::"Price Type"::Purchase, Enum::"Price Amount Type"::Any);
                    end;
                }
                action(PurchPriceLines)
                {
                    AccessByPermission = TableData "Purchase Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Prices';
                    Image = Price;
                    Scope = Repeater;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up purchase price lines for products that you buy from the vendor. A product price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource, Enum::"Price Type"::Purchase);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Price);
                    end;
                }
                action(PurchDiscountLines)
                {
                    AccessByPermission = TableData "Purchase Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Discounts';
                    Image = LineDiscount;
                    Scope = Repeater;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for products that you buy from the vendor. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource, Enum::"Price Type"::Purchase);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Discount);
                    end;
                }
                action(PurchasePriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = false;
                    ToolTip = 'View or set up different discounts for products that you buy from the vendor. An product discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, PriceType::Purchase, AmountType::Discount);
                    end;
                }
            }
            group("Plan&ning")
            {
                Caption = 'Plan&ning';
                Image = Planning;
                action("Resource &Allocated per Job")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource &Allocated per Project';
                    Image = ViewJob;
                    RunObject = Page "Resource Allocated per Job";
                    ToolTip = 'View this project''s resource allocation.';
                }
                action("Res. Group All&ocated per Job")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Res. Group All&ocated per Project';
                    Image = ViewJob;
                    RunObject = Page "Res. Gr. Allocated per Job";
                    ToolTip = 'View the project''s resource group allocation.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Job No." = field("No.");
                    RunPageView = sorting("Job No.", "Job Task No.", "Entry Type", "Posting Date")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
            group(Warehouse_Related)
            {
                Caption = 'Warehouse';
                Image = Worksheets;
                action("Put-away/Pick Lines/Movement Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away/Pick Lines/Movement Lines';
                    Image = PutawayLines;
                    ToolTip = 'View the list of ongoing inventory put-aways, picks, or movements for the project.';

                    trigger OnAction()
                    begin
                        OpenWhseActivityLines();
                    end;
                }
                action("Registered P&ick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Pick Lines';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Act.-Lines";
                    RunPageLink = "Source Type" = filter(167),
                                  "Source Subtype" = const("0"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    ToolTip = 'View the list of warehouse picks that have been made for the project.';
                }
            }
        }
        area(processing)
        {
            group("<Action9>")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyJob)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Copy Project';
                    Ellipsis = true;
                    Image = CopyFromTask;
                    ToolTip = 'Copy a project and its project tasks, planning lines, and prices.';

                    trigger OnAction()
                    var
                        CopyJob: Page "Copy Job";
                    begin
                        CopyJob.SetFromJob(Rec);
                        CopyJob.RunModal();
                    end;
                }
                action("Create Job &Sales Invoice")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Create Project &Sales Invoice';
                    Image = JobSalesInvoice;
                    RunObject = Report "Job Create Sales Invoice";
                    ToolTip = 'Use a batch job to help you create project sales invoices for the involved project planning lines.';
                }
                group(Action7)
                {
                    Caption = 'W&IP';
                    Image = WIP;
                    action("<Action151>")
                    {
                        ApplicationArea = Jobs;
                        Caption = '&Calculate WIP';
                        Ellipsis = true;
                        Image = CalculateWIP;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Run the Project Calculate WIP batch job.';

                        trigger OnAction()
                        var
                            Job: Record Job;
                            JobCalculateWIP: Report "Job Calculate WIP";
                        begin
                            Rec.TestField("No.");
                            Job.Copy(Rec);
                            Job.SetRange("No.", Rec."No.");
                            JobCalculateWIP.SetTableView(Job);
                            JobCalculateWIP.Run();
                        end;
                    }
                    action("<Action152>")
                    {
                        ApplicationArea = Jobs;
                        Caption = '&Post WIP to G/L';
                        Ellipsis = true;
                        Image = PostOrder;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Run the Project Post WIP to G/L batch job.';

                        trigger OnAction()
                        var
                            Job: Record Job;
                        begin
                            Rec.TestField("No.");
                            Job.Copy(Rec);
                            Job.SetRange("No.", Rec."No.");
                            REPORT.RunModal(REPORT::"Job Post WIP to G/L", true, false, Job);
                        end;
                    }
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Worksheets;
                action("Create Inventory Pick")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Inventory Pick';
                    Image = CreateInventoryPick;
                    ToolTip = 'Create inventory picks for the item on the project planning lines.';

                    trigger OnAction()
                    begin
                        Rec.CreateInvtPutAwayPick();
                    end;
                }
                action("Create Warehouse Pick")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Warehouse Pick';
                    Image = CreateWarehousePick;
                    ToolTip = 'Create warehouse pick documents for the project planning lines.';

                    trigger OnAction()
                    begin
                        Rec.CreateWarehousePick();
                    end;
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
                ToolTip = 'Analyze the project, such as the budgeted prices, usage prices, and contract prices, and then compares the three sets of prices.';
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
            action("Jobs per Customer")
            {
                ApplicationArea = Jobs;
                Caption = 'Projects per Customer';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Jobs per Customer";
                ToolTip = 'Run the Projects per Customer report.';
            }
            action("Items per Job")
            {
                ApplicationArea = Jobs;
                Caption = 'Items per Project';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Items per Job";
                ToolTip = 'View which items are used for a specific project.';
            }
            action("Jobs per Item")
            {
                ApplicationArea = Jobs;
                Caption = 'Projects per Item';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Jobs per Item";
                ToolTip = 'Run the Projects per item report.';
            }
            action("Report Job Quote")
            {
                ApplicationArea = Jobs;
                Caption = 'Preview Project Quote';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                ToolTip = 'Open the Project Quote report.';

                trigger OnAction()
                var
                    Job: Record Job;
                begin
                    Job := Rec;
                    CurrPage.SetSelectionFilter(Job);
                    Job.PrintRecords(true);
                end;
            }
            action("Send Job Quote")
            {
                ApplicationArea = Jobs;
                Caption = 'Send Project Quote';
                Image = SendTo;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                ToolTip = 'Send the project quote to the customer. You can change the way that the document is sent in the window that appears.';

                trigger OnAction()
                begin
                    CODEUNIT.Run(CODEUNIT::"Jobs-Send", Rec);
                end;
            }
            action(ProjectsAnalysis)
            {
                ApplicationArea = Jobs;
                Caption = 'Analyze Projects';
                Image = Job;
                RunObject = Query ProjectsAnalysis;
                ToolTip = 'Analyze (group, summarize, pivot) your Project Ledger Entries with related Project master data such as Project Task, Resource, Item, and G/L Account.';
            }
            group("Financial Management")
            {
                Caption = 'Financial Management';
                Image = "Report";
                action("Job WIP to G/L")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project WIP to G/L';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Job WIP To G/L";
                    ToolTip = 'View the value of work in process on the projects that you select compared to the amount that has been posted in the general ledger.';
                }
            }
            group(Action23)
            {
                Caption = 'History';
                Image = "Report";
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
                action("Job Register")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Register';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Job Register";
                    ToolTip = 'View one or more selected project registers. By using a filter, you can select only those register entries that you want to see. If you do not set a filter, the report can be impractical because it can contain a large amount of information. On the project journal template, you can indicate that you want the report to print when you post.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CopyJob_Promoted; CopyJob)
                {
                }
                actionref("Create Job &Sales Invoice_Promoted"; "Create Job &Sales Invoice")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Project', Comment = 'Generated from the PromotedActionCategories property index 4.';

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
                actionref("&Statistics_Promoted"; "&Statistics")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(SalesInvoicesCreditMemos_Promoted; SalesInvoicesCreditMemos)
                {
                }
                actionref("Job Task &Lines_Promoted"; "Job Task &Lines")
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Prices & Discounts', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("&Resource_Promoted"; "&Resource")
                {
                }
                actionref("&Item_Promoted"; "&Item")
                {
                }
                actionref("&G/L Account_Promoted"; "&G/L Account")
                {
                }
            }
            group(Category_WIP)
            {
                Caption = 'WIP';

                actionref("<Action151>_Promoted"; "<Action151>")
                {
                }
                actionref("<Action152>_Promoted"; "<Action152>")
                {
                }
                actionref("&WIP Entries_Promoted"; "&WIP Entries")
                {
                }
                actionref("WIP &G/L Entries_Promoted"; "WIP &G/L Entries")
                {
                }
                actionref("WIP Cockpit_Promoted"; "WIP Cockpit")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(SalesPriceLines_Promoted; SalesPriceLines)
                {
                }
                actionref(SalesPriceLists_Promoted; SalesPriceLists)
                {
                }
                actionref(PurchPriceLines_Promoted; PurchPriceLines)
                {
                }
                actionref(PurchasePriceLists_Promoted; PurchasePriceLists)
                {
                }
                actionref(SalesDiscountLines_Promoted; SalesDiscountLines)
                {
                }
                actionref(PurchDiscountLines_Promoted; PurchDiscountLines)
                {
                }
                actionref(SalesPriceListsDiscounts_Promoted; SalesPriceListsDiscounts)
                {
                }
                actionref(PurchasePriceListsDiscounts_Promoted; PurchasePriceListsDiscounts)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

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

    views
    {
        view(Open)
        {
            Caption = 'Open';
            Filters = where(Status = const(Open));
        }
        view(PlannedAndQuoted)
        {
            Caption = 'Planned and Quoted';
            Filters = where(Status = filter(Quote | Planning));
        }
        view(Completed)
        {
            Caption = 'Completed';
            Filters = where(Status = const(Completed));
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Job: Record Job;
    begin
        CurrPage.SetSelectionFilter(Job);
        CurrPage.PowerBIEmbeddedReportPart.PAGE.SetFilterToMultipleValues(Job, Job.FieldNo("No."));
    end;

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    trigger OnInit()
    begin
        CurrPage.PowerBIEmbeddedReportPart.PAGE.SetPageContext(CurrPage.ObjectId(false));
    end;

    var
        ExtendedPriceEnabled: Boolean;

    local procedure OpenWhseActivityLines()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
    begin
        WarehouseActivityLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Job);
        WarehouseActivityLine.SetRange("Whse. Document No.", Rec."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                TempWarehouseActivityLine := WarehouseActivityLine;
                if TempWarehouseActivityLine.Insert() then;
            until WarehouseActivityLine.Next() = 0;

        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code", "Action Type", "Breakbulk No.", "Original Breakbulk");
        WarehouseActivityLine.SetRange("Source Type", Database::Job);
        WarehouseActivityLine.SetRange("Source Subtype", 0);
        WarehouseActivityLine.SetRange("Source No.", Rec."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                TempWarehouseActivityLine := WarehouseActivityLine;
                if TempWarehouseActivityLine.Insert() then;
            until WarehouseActivityLine.Next() = 0;

        TempWarehouseActivityLine.Reset();
        Page.Run(Page::"Warehouse Activity Lines", TempWarehouseActivityLine);
    end;
}

