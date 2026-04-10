// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Analysis;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Utilities;

page 76 "Resource Card"
{
    Caption = 'Resource Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = Resource;
    AdditionalSearchTerms = 'Workforce, Mechanism, Device';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
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
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Jobs;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Jobs;
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Jobs;
                }
                field("Use Time Sheet"; Rec."Use Time Sheet")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if a resource uses a time sheet to record time allocated to various tasks.';
                }
                field("Time Sheet Owner User ID"; Rec."Time Sheet Owner User ID")
                {
                    ApplicationArea = Jobs;
                }
                field("Time Sheet Approver User ID"; Rec."Time Sheet Approver User ID")
                {
                    ApplicationArea = Jobs;
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Jobs;
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
                    Importance = Promoted;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Default Deferral Template';
                }
                field("Automatic Ext. Texts"; Rec."Automatic Ext. Texts")
                {
                    ApplicationArea = Jobs;
                }
                field("IC Partner Purch. G/L Acc. No."; Rec."IC Partner Purch. G/L Acc. No.")
                {
                    ApplicationArea = Jobs;
                }
            }
            group("Personal Data")
            {
                Caption = 'Personal Data';
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = Jobs;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Jobs;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Jobs;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Jobs;
                }
                group(Control47)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field(County; Rec.County)
                    {
                        ApplicationArea = Jobs;
                    }
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Jobs;

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                    end;
                }
                field("Social Security No."; Rec."Social Security No.")
                {
                    ApplicationArea = Jobs;
                    MaskType = Concealed;
                }
                field(Education; Rec.Education)
                {
                    ApplicationArea = Jobs;
                }
                field("Contract Class"; Rec."Contract Class")
                {
                    ApplicationArea = Jobs;
                }
                field("Employment Date"; Rec."Employment Date")
                {
                    ApplicationArea = Jobs;
                }
            }
        }
        area(factboxes)
        {
            part(Control39; "Resource Picture")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No.");
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Resource),
                              "No." = field("No.");
            }
            part(Control1906609707; "Resource Statistics FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No."),
                              "Unit of Measure Filter" = field("Unit of Measure Filter"),
                              "Chargeable Filter" = field("Chargeable Filter");
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
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Unit of Measure Filter" = field("Unit of Measure Filter"),
                                  "Chargeable Filter" = field("Chargeable Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(156),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
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
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
                action("Online Map")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        Rec.DisplayMap();
                    end;
                }
                separator(Action69)
                {
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
                action("Unit Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit Group';
                    Image = UnitOfMeasure;
                    RunObject = Page "Resource Unit Group List";
                    RunPageLink = "Source No." = field("No."), "Source Type" = const(Resource);
                    ToolTip = 'View unit group associated with the resource.';
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
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
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
                action("Resource &Allocated per Job")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource &Allocated per Project';
                    Image = ViewJob;
                    RunObject = Page "Resource Allocated per Job";
                    RunPageLink = "Resource Filter" = field("No.");
                    ToolTip = 'View this project''s resource allocation.';
                }
                action("Resource A&vailability")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource A&vailability';
                    Image = Calendar;
                    RunObject = Page "Resource Availability";
                    RunPageLink = "No." = field("No."),
                                  "Base Unit of Measure" = field("Base Unit of Measure"),
                                  "Chargeable Filter" = field("Chargeable Filter");
                    ToolTip = 'View a summary of resource capacities, the quantity of resource hours allocated to projects on order, the quantity allocated to service orders, the capacity assigned to projects on quote, and the resource availability.';
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
                    Image = ResourceLedger;
                    RunObject = Page "Resource Ledger Entries";
                    RunPageLink = "Resource No." = field("No.");
                    RunPageView = sorting("Resource No.")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(reporting)
        {
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
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateTimeSheets)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Create Time Sheets';
                    Ellipsis = true;
                    Image = NewTimesheet;
                    ToolTip = 'Create new time sheets for the resource.';

                    trigger OnAction()
                    begin
                        Rec.CreateTimeSheets();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreateTimeSheets_Promoted; CreateTimeSheets)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Resource', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref(Attachments_Promoted; Attachments)
                {
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
                actionref("&Picture_Promoted"; "&Picture")
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
            group(Category_Category7)
            {
                Caption = 'Planning', Comment = 'Generated from the PromotedActionCategories property index 6.';

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
                actionref("Unit Group_Promoted"; "Unit Group")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CRMIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
            if Rec."No." <> xRec."No." then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;
    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        if IntegrationTableMapping.Get('RESOURCE-PRODUCT') then
            BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field38=1(0)');
        SetNoFieldVisible();
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        FormatAddress: Codeunit "Format Address";
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BlockedFilterApplied: Boolean;
        ExtendedPriceEnabled: Boolean;
        NoFieldVisible: Boolean;
        IsCountyVisible: Boolean;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.ResourceNoIsVisible();
    end;
}
