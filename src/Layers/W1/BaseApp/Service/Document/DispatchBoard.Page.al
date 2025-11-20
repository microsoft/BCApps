// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Reports;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using Microsoft.Utilities;

page 6000 "Dispatch Board"
{
    ApplicationArea = Service;
    Caption = 'Dispatch Board';
    DataCaptionFields = Status;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Service Header";
    SourceTableView = sorting(Status, "Response Date", "Response Time", Priority);
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ResourceFilter; ResourceFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Filter';
                    ToolTip = 'Specifies the filter that displays an overview of documents with service item lines that a certain resource is allocated to.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Res.Reset();
                        if PAGE.RunModal(0, Res) = ACTION::LookupOK then begin
                            Text := Res."No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetResourceFilter();
                        ResourceFilterOnAfterValidate();
                    end;
                }
                field(ResourceGroupFilter; ResourceGroupFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Group Filter';
                    ToolTip = 'Specifies the filter that displays an overview of documents with service item lines that a certain resource group is allocated to.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ResourceGroup.Reset();
                        if PAGE.RunModal(0, ResourceGroup) = ACTION::LookupOK then begin
                            Text := ResourceGroup."No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetResourceGroupFilter();
                        ResourceGroupFilterOnAfterVali();
                    end;
                }
                field(RespDateFilter; RespDateFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Response Date Filter';
                    ToolTip = 'Specifies the filter that displays an overview of documents with the specified value in the Response Date field.';

                    trigger OnValidate()
                    begin
                        SetRespDateFilter();
                        RespDateFilterOnAfterValidate();
                    end;
                }
                field(AllocationFilter; AllocationFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Allocation Filter';
                    OptionCaption = ' ,No or Partial Allocation,Full Allocation,Reallocation Needed';
                    ToolTip = 'Specifies the filter that displays the overview of documents from their allocation analysis point of view.';

                    trigger OnValidate()
                    begin
                        SetAllocFilter();
                        AllocationFilterOnAfterValidat();
                    end;
                }
                field(DocFilter; DocFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Document Filter';
                    OptionCaption = 'Order,Quote,All';
                    ToolTip = 'Specifies the filter that displays the overview of the documents of the specified type.';

                    trigger OnValidate()
                    begin
                        SetDocFilter();
                        DocFilterOnAfterValidate();
                    end;
                }
                field(ServOrderFilter; ServOrderFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'No. Filter';
                    ToolTip = 'Specifies the filter that is used to see the specified document.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ServHeader.Reset();
                        SetDocFilter(ServHeader);
                        if PAGE.RunModal(0, ServHeader) = ACTION::LookupOK then begin
                            Text := ServHeader."No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetServOrderFilter();
                        ServOrderFilterOnAfterValidate();
                    end;
                }
                field(StatusFilter; StatusFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Status Filter';
                    OptionCaption = ' ,Pending,In Process,Finished,On Hold';
                    ToolTip = 'Specifies the filter that displays an overview of documents with a certain value in the Status field.';

                    trigger OnValidate()
                    begin
                        SetStatusFilter();
                        StatusFilterOnAfterValidate();
                    end;
                }
                field(CustomFilter; CustomFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer Filter';
                    ToolTip = 'Specifies the filter that displays an overview of documents with a certain value in the Customer No. field.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Cust.Reset();
                        if PAGE.RunModal(0, Cust) = ACTION::LookupOK then begin
                            Text := Cust."No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetCustFilter();
                        CustomFilterOnAfterValidate();
                    end;
                }
                field(ContractFilter; ContractFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Contract Filter';
                    ToolTip = 'Specifies all billable prices for the project task.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ServiceContract.Reset();
                        ServiceContract.SetRange("Contract Type", ServiceContract."Contract Type"::Contract);
                        if PAGE.RunModal(0, ServiceContract) = ACTION::LookupOK then begin
                            Text := ServiceContract."Contract No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetContractFilter();
                        ContractFilterOnAfterValidate();
                    end;
                }
                field(ZoneFilter; ZoneFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Zone Filter';
                    ToolTip = 'Specifies the filter that displays an overview of documents with a certain value in the Service Zone Code field.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ServiceZones.Reset();
                        if PAGE.RunModal(0, ServiceZones) = ACTION::LookupOK then begin
                            Text := ServiceZones.Code;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetZoneFilter();
                        ZoneFilterOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated date when work on the order should start, that is, when the service order status changes from Pending, to In Process.';
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time when work on the order starts, that is, when the service order status changes from Pending, to In Process.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the priority of the service order.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service document on the line.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a short description of the service document, such as Order 2001.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order status, which reflects the repair or maintenance status of all service items on the service order.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the items in the service document.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer to whom the items on the document will be shipped.';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contract associated with the order.';
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service zone code of the customer''s ship-to address in the service order.';
                }
                field("No. of Allocations"; Rec."No. of Allocations")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of resource allocations to service items in this order.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when the service order was created.';
                }
                field("Reallocation Needed"; Rec."Reallocation Needed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you must reallocate resources to at least one service item in this service order.';
                }
            }
            group(Control94)
            {
                ShowCaption = false;
                field(Description2; Rec.Description)
                {
                    ApplicationArea = Service;
                    Caption = 'Service Order Description';
                    Editable = false;
                    ToolTip = 'Specifies a short description of the service document, such as Order 2001.';
                }
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
            group("&Dispatch Board")
            {
                Caption = '&Dispatch Board';
                Image = ServiceMan;
                action("&Show Document")
                {
                    ApplicationArea = Service;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        PageManagement.PageRunModal(Rec);
                    end;
                }
            }
            group("Pla&nning")
            {
                Caption = 'Pla&nning';
                Image = Planning;
                action("Resource &Allocations")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource &Allocations';
                    Image = ResourcePlanning;
                    RunObject = Page "Resource Allocations";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "Document No." = field("No.");
                    RunPageView = sorting(Status, "Document Type", "Document No.", "Service Item Line No.", "Allocation Date", "Starting Time", Posted)
                                  where(Status = filter(<> Canceled));
                    ToolTip = 'View or allocate resources, such as technicians or resource groups to service items. The allocation can be made by resource number or resource group number, allocation date and allocated hours. You can also reallocate and cancel allocations. You can only have one active allocation per service item.';
                }
                action("Demand Overview")
                {
                    ApplicationArea = Service;
                    Caption = 'Demand Overview';
                    Image = Forecast;
                    ToolTip = 'Get an overview of demand for your items when planning sales, production, projects, or service management and when they will be available.';

                    trigger OnAction()
                    var
                        DemandOverview: Page "Demand Overview";
                    begin
                        DemandOverview.SetCalculationParameter(true);
                        DemandOverview.SetParameters(0D, Microsoft.Inventory.Requisition."Demand Order Source Type"::"Service Demand", '', '', '');
                        DemandOverview.RunModal();
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Print &Dispatch Board")
                {
                    ApplicationArea = Service;
                    Caption = 'Print &Dispatch Board';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Print the information on the dispatch board.';

                    trigger OnAction()
                    begin
                        REPORT.Run(REPORT::"Dispatch Board", true, true, Rec);
                    end;
                }
                action("Print Service &Order")
                {
                    ApplicationArea = Service;
                    Caption = 'Print Service &Order';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Print the selected service order.';

                    trigger OnAction()
                    begin
                        Clear(ServHeader);
                        ServHeader.SetRange("Document Type", Rec."Document Type");
                        ServHeader.SetRange("No.", Rec."No.");
                        REPORT.Run(REPORT::"Service Order", true, true, ServHeader);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Show Document_Promoted"; "&Show Document")
                {
                }
                actionref("Resource &Allocations_Promoted"; "Resource &Allocations")
                {
                }
                actionref("Demand Overview_Promoted"; "Demand Overview")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();
        SetAllFilters();

        if Rec.IsEmpty() then begin
            ServOrderFilter := '';
            SetServOrderFilter();
        end;
    end;

    var
        ServiceZones: Record "Service Zone";
        Cust: Record Customer;
        Res: Record Resource;
        ResourceGroup: Record "Resource Group";
        ServHeader: Record "Service Header";
        ServiceContract: Record "Service Contract Header";
        DocFilter: Option "Order",Quote,All;
        StatusFilter: Option " ",Pending,"In Process",Finished,"On Hold";
        RespDateFilter: Text;
        ServOrderFilter: Text;
        CustomFilter: Text;
        ZoneFilter: Text;
        ContractFilter: Text;
        ResourceFilter: Text;
        ResourceGroupFilter: Text;
        AllocationFilter: Option " ","No or Partial Allocation","Full Allocation","Reallocation Needed";

    procedure SetAllFilters()
    begin
        SetDocFilter();
        SetStatusFilter();
        SetRespDateFilter();
        SetServOrderFilter();
        SetCustFilter();
        SetZoneFilter();
        SetContractFilter();
        SetResourceFilter();
        SetResourceGroupFilter();
        SetAllocFilter();
    end;

    procedure SetDocFilter()
    begin
        Rec.FilterGroup(2);
        SetDocFilter(Rec);
        Rec.FilterGroup(0);
    end;

    procedure SetDocFilter(var ServHeader: Record "Service Header")
    begin
        ServHeader.FilterGroup(2);
        case DocFilter of
            DocFilter::Order:
                ServHeader.SetRange("Document Type", ServHeader."Document Type"::Order);
            DocFilter::Quote:
                ServHeader.SetRange("Document Type", ServHeader."Document Type"::Quote);
            DocFilter::All:
                ServHeader.SetFilter("Document Type", '%1|%2', ServHeader."Document Type"::Order, ServHeader."Document Type"::Quote);
        end;
        ServHeader.FilterGroup(0);
    end;

    procedure SetStatusFilter()
    begin
        Rec.FilterGroup(2);
        case StatusFilter of
            StatusFilter::" ":
                Rec.SetRange(Status);
            StatusFilter::Pending:
                Rec.SetRange(Status, Rec.Status::Pending);
            StatusFilter::"In Process":
                Rec.SetRange(Status, Rec.Status::"In Process");
            StatusFilter::Finished:
                Rec.SetRange(Status, Rec.Status::Finished);
            StatusFilter::"On Hold":
                Rec.SetRange(Status, Rec.Status::"On Hold");
        end;
        Rec.FilterGroup(0);
    end;

    procedure SetRespDateFilter()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Response Date", RespDateFilter);
        RespDateFilter := Rec.GetFilter("Response Date");
        Rec.FilterGroup(0);
    end;

    procedure SetServOrderFilter()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("No.", ServOrderFilter);
        ServOrderFilter := Rec.GetFilter("No.");
        Rec.FilterGroup(0);
    end;

    procedure SetCustFilter()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Customer No.", CustomFilter);
        CustomFilter := Rec.GetFilter("Customer No.");
        Rec.FilterGroup(0);
    end;

    procedure SetZoneFilter()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Service Zone Code", ZoneFilter);
        ZoneFilter := Rec.GetFilter("Service Zone Code");
        Rec.FilterGroup(0);
    end;

    procedure SetContractFilter()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Contract No.", ContractFilter);
        ContractFilter := Rec.GetFilter("Contract No.");
        Rec.FilterGroup(0);
    end;

    procedure SetResourceFilter()
    begin
        Rec.FilterGroup(2);
        if ResourceFilter <> '' then begin
            Rec.SetFilter("No. of Allocations", '>0');
            Rec.SetFilter("Resource Filter", ResourceFilter);
            ResourceFilter := Rec.GetFilter("Resource Filter");
        end else begin
            if ResourceGroupFilter = '' then
                Rec.SetRange("No. of Allocations");
            Rec.SetRange("Resource Filter");
        end;
        Rec.FilterGroup(0);
    end;

    procedure SetResourceGroupFilter()
    begin
        Rec.FilterGroup(2);
        if ResourceGroupFilter <> '' then begin
            Rec.SetFilter("No. of Allocations", '>0');
            Rec.SetFilter("Resource Group Filter", ResourceGroupFilter);
            ResourceGroupFilter := Rec.GetFilter("Resource Group Filter");
        end else begin
            if ResourceFilter = '' then
                Rec.SetRange("No. of Allocations");
            Rec.SetRange("Resource Group Filter");
        end;
        Rec.FilterGroup(0);
    end;

    procedure SetAllocFilter()
    begin
        Rec.FilterGroup(2);
        case AllocationFilter of
            AllocationFilter::" ":
                begin
                    Rec.SetRange("No. of Unallocated Items");
                    Rec.SetRange("Reallocation Needed");
                end;
            AllocationFilter::"No or Partial Allocation":
                begin
                    Rec.SetFilter("No. of Unallocated Items", '>0');
                    Rec.SetRange("Reallocation Needed", false);
                end;
            AllocationFilter::"Full Allocation":
                begin
                    Rec.SetRange("No. of Unallocated Items", 0);
                    Rec.SetRange("Reallocation Needed", false);
                end;
            AllocationFilter::"Reallocation Needed":
                begin
                    Rec.SetRange("No. of Unallocated Items");
                    Rec.SetRange("Reallocation Needed", true);
                end;
        end;
        Rec.FilterGroup(0);
    end;

    local procedure RespDateFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ServOrderFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure StatusFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ZoneFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure CustomFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ContractFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ResourceFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure DocFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure AllocationFilterOnAfterValidat()
    begin
        CurrPage.Update(false);
    end;

    local procedure ResourceGroupFilterOnAfterVali()
    begin
        CurrPage.Update(false);
    end;
}

