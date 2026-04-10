// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Reports;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Pricing;
using System.Text;

page 77 "Resource List"
{
    AdditionalSearchTerms = 'Workforce List, Mechanism List, Device List';
    ApplicationArea = Jobs;
    Caption = 'Resources';
    CardPageID = "Resource Card";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Resources';
    AboutText = 'Manage and organize project resources, including people and machines, by defining their availability, costs, pricing, and work schedules to support accurate project planning and allocation.';
    QueryCategory = 'Resource List';
    SourceTable = Resource;
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
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Jobs;
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    Visible = false;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the address of the resouce.';
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the city of the resouce.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Jobs;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Price/Profit Calculation"; Rec."Price/Profit Calculation")
                {
                    ApplicationArea = Jobs;
                }
                field("Profit %"; Rec."Profit %")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Jobs;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Jobs;
                }
                field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Default Deferral Template';
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    Visible = CRMIntegrationEnabled;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Resource), "No." = field("No.");
            }
            part(Control1906609707; "Resource Statistics FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No."),
                              "Chargeable Filter" = field("Chargeable Filter"),
                              "Unit of Measure Filter" = field("Unit of Measure Filter");
                Visible = true;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No."),
                              "Chargeable Filter" = field("Chargeable Filter"),
                              "Unit of Measure Filter" = field("Unit of Measure Filter");
                Visible = true;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Resource")
            {
                Caption = '&Resource';
                Image = Resource;
                action(Statistics)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Resource Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Resource),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(156),
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
                            Res: Record Resource;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Res);
                            DefaultDimMultiple.SetMultiRecord(Res, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("&Picture")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Picture';
                    Image = Picture;
                    RunObject = Page "Resource Picture";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View or add a picture of the resource or, for example, the company''s logo.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ledger E&ntries';
                    Image = ResourceLedger;
                    RunObject = Page "Resource Ledger Entries";
                    RunPageLink = "Resource No." = field("No.");
                    RunPageView = sorting("Resource No.")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const(Resource),
                                  "No." = field("No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View the extended description that is set up.';
                }
                action("Units of Measure")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Units of Measure';
                    Image = UnitOfMeasure;
                    RunObject = Page "Resource Units of Measure";
                    RunPageLink = "Resource No." = field("No.");
                    ToolTip = 'View or edit the units of measure that are set up for the resource.';
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                Enabled = (BlockedFilterApplied and (not Rec.Blocked)) or not BlockedFilterApplied;
                action(CRMGoToProduct)
                {
                    ApplicationArea = Suite;
                    Caption = 'Product';
                    Image = CoupledItem;
                    ToolTip = 'Open the coupled Dynamics 365 Sales product.';

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
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        Resource: Record Resource;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        ResourceRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Resource);
                        Resource.Next();

                        if Resource.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Resource.RecordId)
                        else begin
                            ResourceRecordRef.GetTable(Resource);
                            CRMIntegrationManagement.UpdateMultipleNow(ResourceRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledItem;
                        ToolTip = 'Couple resources to products in Dynamics 365 Sales based on matching criteria.';

                        trigger OnAction()
                        var
                            Resource: Record Resource;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Resource);
                            RecRef.GetTable(Resource);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            Resource: Record Resource;
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Resource);
                            RecRef.GetTable(Resource);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the resource table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
            group("&Prices")
            {
                Caption = '&Prices';
                Image = Price;
                action(Costs)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Costs';
                    Image = ResourceCosts;
                    RunObject = Page "Resource Costs";
                    RunPageLink = Type = const(Resource),
                                  Code = field("No.");
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View or change detailed information about costs for the resource.';
                }
                action(Prices)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Prices';
                    Image = Price;
                    RunObject = Page "Resource Prices";
                    RunPageLink = Type = const(Resource),
                                  Code = field("No.");
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View or edit prices for the resource.';
                }
                action(PurchPriceLists)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Purchase Prices';
                    Image = ResourceCosts;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or change detailed information about costs for the resource.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Any);
                    end;
                }
                action(SalesPriceLists)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Sales Prices';
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or edit prices for the resource.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Sale, AmountType::Any);
                    end;
                }
            }
            group("Plan&ning")
            {
                Caption = 'Plan&ning';
                Image = Planning;
                action("Resource &Capacity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource &Capacity';
                    Image = Capacity;
                    RunObject = Page "Resource Capacity";
                    RunPageOnRec = true;
                    ToolTip = 'View this project''s resource capacity.';
                }
                action("Resource A&vailability")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource A&vailability';
                    Image = Calendar;
                    RunObject = Page "Resource Availability";
                    RunPageLink = "No." = field("No."),
                                  "Unit of Measure Filter" = field("Unit of Measure Filter"),
                                  "Chargeable Filter" = field("Chargeable Filter");
                    ToolTip = 'View a summary of resource capacities, the quantity of resource hours allocated to projects on order, the quantity allocated to service orders, the capacity assigned to projects on quote, and the resource availability.';
                }
            }
        }
        area(creation)
        {
            action("New Resource Group")
            {
                ApplicationArea = Jobs;
                Caption = 'New Resource Group';
                Image = NewResourceGroup;
                RunObject = Page "Resource Groups";
                RunPageMode = Create;
                ToolTip = 'Create a new resource.';
            }
        }
        area(reporting)
        {
            action("Resource - List")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - List';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Resource - List";
                ToolTip = 'View the list of resources.';
            }
            action("Resource Statistics")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Statistics';
                Image = "Report";
                RunObject = Report "Resource Statistics";
                ToolTip = 'View detailed, historical information for the resource.';
            }
            action("Resource Usage")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Usage';
                Image = "Report";
                RunObject = Report "Resource Usage";
                ToolTip = 'View the resource utilization that has taken place. The report includes the resource capacity, quantity of usage, and the remaining balance.';
            }
            action("Resource - Cost Breakdown")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - Cost Breakdown';
                Image = "Report";
                RunObject = Report "Resource - Cost Breakdown";
                ToolTip = 'View the direct unit costs and the total direct costs for each resource. Only usage postings are considered in this report. Resource usage can be posted in the resource journal or the project journal.';
            }
            action("Resource - Price List")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - Price List';
                Image = "Report";
                Visible = not ExtendedPriceEnabled;
                RunObject = Report "Resource - Price List";
                ToolTip = 'Specifies a list of unit prices for the selected resources. By default, a unit price is based on the price in the Resource Prices window. If there is no valid alternative price, then the unit price from the resource card is used. The report can be used by the company''s salespeople or sent to customers.';
            }
            action("Res. Price List")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - Price List';
                Image = "Report";
                Visible = ExtendedPriceEnabled;
                RunObject = Report "Res. Price List";
                ToolTip = 'Specifies a list of unit prices for the selected resources. By default, a unit price is based on the price in the Resource Prices window. If there is no valid alternative price, then the unit price from the resource card is used. The report can be used by the company''s salespeople or sent to customers.';
            }
            action("Resource Register")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Register';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Resource Register";
                ToolTip = 'View a list of all the resource registers. Every time a resource entry is posted, a register is created. Every register shows the first and last entry numbers of its entries. You can use the information in a resource register to document when entries were posted.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Time Sheets")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Create Time Sheets';
                    Ellipsis = true;
                    Image = NewTimesheet;
                    ToolTip = 'Create new time sheets for the selected resource.';

                    trigger OnAction()
                    begin
                        Rec.CreateTimeSheets();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

                actionref("New Resource Group_Promoted"; "New Resource Group")
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Create Time Sheets_Promoted"; "Create Time Sheets")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Resource', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref("Dimensions-&Multiple_Promoted"; "Dimensions-&Multiple")
                    {
                    }
                    actionref("Dimensions-Single_Promoted"; "Dimensions-Single")
                    {
                    }
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref(SalesPriceLists_Promoted; SalesPriceLists)
                {
                }
                actionref(PurchPriceLists_Promoted; PurchPriceLists)
                {
                }
                actionref("Units of Measure_Promoted"; "Units of Measure")
                {
                }
                actionref(Costs_Promoted; Costs)
                {
                }
                actionref(Prices_Promoted; Prices)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Prices';

            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Resource Statistics_Promoted"; "Resource Statistics")
                {
                }
                actionref("Resource Usage_Promoted"; "Resource Usage")
                {
                }
                actionref("Resource - Cost Breakdown_Promoted"; "Resource - Cost Breakdown")
                {
                }
                actionref("Resource - Price List_Promoted"; "Resource - Price List")
                {
                }
                actionref("Res. Price List_Promoted"; "Res. Price List")
                {
                }
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CRMIntegrationEnabled;

                group(Category_Coupling)
                {
                    Caption = 'Coupling';
                    ShowAs = SplitButton;

                    actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                    {
                    }
                    actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                    {
                    }
                    actionref(MatchBasedCoupling_Promoted; MatchBasedCoupling)
                    {
                    }
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(CRMGoToProduct_Promoted; CRMGoToProduct)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        if CRMIntegrationEnabled then
            if IntegrationTableMapping.Get('RESOURCE-PRODUCT') then
                BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field38=1(0)');
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BlockedFilterApplied: Boolean;
        ExtendedPriceEnabled: Boolean;

    procedure GetSelectionFilter(): Text
    var
        Resource: Record Resource;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Resource);
        exit(SelectionFilterManagement.GetSelectionFilterForResource(Resource));
    end;

    procedure SetSelection(var Resource: Record Resource)
    begin
        CurrPage.SetSelectionFilter(Resource);
    end;
}
