// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Reports;
using Microsoft.Utilities;
using System.Text;

page 5915 "Service Tasks"
{
    ApplicationArea = Service;
    Caption = 'Service Tasks';
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Service Item Line";
    SourceTableView = sorting("Response Date", "Response Time", Priority);
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
                    ToolTip = 'Specifies the filter that displays service tasks corresponding to service item lines that a certain resource is allocated to.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Res.Reset();
                        if PAGE.RunModal(0, Res) = ACTION::LookupOK then begin
                            Text := Res."No.";
                            SetResourceFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.FilterGroup(2);
                        TempTextFilter := Rec.GetFilter("Resource Filter");
                        Rec.FilterGroup(0);
                        SetResourceFilter();
                        if not TestFilter() then begin
                            ResourceFilter := TempTextFilter;
                            SetResourceFilter();
                            Error(Text000, Rec.TableCaption);
                        end;
                        ResourceFilterOnAfterValidate();
                    end;
                }
                field(ResourceGroupFilter; ResourceGroupFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Group Filter';
                    ToolTip = 'Specifies the filter that displays service tasks corresponding to service item lines with the specified resource group allocated to each of them.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ResourceGroup.Reset();
                        if PAGE.RunModal(0, ResourceGroup) = ACTION::LookupOK then begin
                            Text := ResourceGroup."No.";
                            SetResourceGroupFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.FilterGroup(2);
                        TempTextFilter := Rec.GetFilter("Resource Group Filter");
                        Rec.FilterGroup(0);
                        SetResourceGroupFilter();
                        if not TestFilter() then begin
                            ResourceGroupFilter := TempTextFilter;
                            SetResourceGroupFilter();
                            Error(Text000, Rec.TableCaption);
                        end;
                        ResourceGroupFilterOnAfterVali();
                    end;
                }
                field(RespDateFilter; RespDateFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Response Date Filter';
                    ToolTip = 'Specifies the filter that displays service tasks corresponding to service item lines with the specified value in the Response Date field.';

                    trigger OnValidate()
                    begin
                        Rec.FilterGroup(2);
                        TempTextFilter := Rec.GetFilter("Response Date");
                        Rec.FilterGroup(0);
                        SetRespDateFilter();
                        if not TestFilter() then begin
                            RespDateFilter := TempTextFilter;
                            SetRespDateFilter();
                            Error(Text000, Rec.TableCaption);
                        end;
                        RespDateFilterOnAfterValidate();
                    end;
                }
                field(AllocationStatus; AllocationStatus)
                {
                    ApplicationArea = Service;
                    Caption = 'Allocation Status Filter';
                    OptionCaption = ' ,Nonactive,Active,Finished,Canceled,Reallocation Needed';
                    ToolTip = 'Specifies the filter that displays the service tasks corresponding to service item lines with a certain value in the Status Code of Resource Allocations.';

                    trigger OnValidate()
                    begin
                        TempAllocationStatus := Rec."Allocation Status Filter";
                        SetAllocationFilter();
                        if not TestFilter() then begin
                            AllocationStatus := TempAllocationStatus;
                            SetAllocationFilter();
                            Error(Text000, Rec.TableCaption);
                        end;
                        AllocationStatusOnAfterValidat();
                    end;
                }
                field(DocFilter; DocFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Document Filter';
                    OptionCaption = 'Order,Quote,All';
                    ToolTip = 'Specifies the filter that displays all service tasks corresponding to documents of the specified type.';

                    trigger OnValidate()
                    begin
                        ServOrderFilter := '';
                        SetServOrderFilter();
                        SetDocFilter();
                        DocFilterOnAfterValidate();
                    end;
                }
                field(ServOrderFilter; ServOrderFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'No. Filter';
                    ToolTip = 'Specifies the filter that displays service tasks corresponding to the service item lines within the specified document.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ServHeader.Reset();
                        SetDocFilterHeader(ServHeader);
                        if PAGE.RunModal(0, ServHeader) = ACTION::LookupOK then begin
                            Text := ServHeader."No.";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.FilterGroup(2);
                        TempTextFilter := Rec.GetFilter("Document No.");
                        Rec.FilterGroup(0);
                        SetServOrderFilter();
                        if not TestFilter() then begin
                            ServOrderFilter := TempTextFilter;
                            SetServOrderFilter();
                            Error(Text000, Rec.TableCaption());
                        end;
                        ServOrderFilterOnAfterValidate();
                    end;
                }
                field(RepairStatusFilter; RepairStatusFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Repair Status Code Filter';
                    ToolTip = 'Specifies the Repair Status Code filter to view service tasks corresponding to service item lines with the specified repair status code.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        RepairStatus.Reset();
                        if PAGE.RunModal(0, RepairStatus) = ACTION::LookupOK then begin
                            Text := RepairStatus.Code;
                            SetRepStatFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.FilterGroup(2);
                        TempTextFilter := Rec.GetFilter("Repair Status Code");
                        Rec.FilterGroup(0);
                        SetRepStatFilter();
                        if not TestFilter() then begin
                            RepairStatusFilter := TempTextFilter;
                            SetRepStatFilter();
                            Error(Text000, Rec.TableCaption);
                        end;
                        RepairStatusFilterOnAfterValid();
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
                    ToolTip = 'Specifies the estimated date when service should start on this service item line.';
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time when service should start on this service item.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service priority for this item.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the service document is a service order or service quote.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order linked to this service item line.';
                }
                field("Repair Status Code"; Rec."Repair Status Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the repair status of this service item.';
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item number registered in the Service Item table.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the customer number associated with the service contract.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Cust.Name"; Cust.Name)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the name of the customer.';
                    Visible = false;
                }
                field("Service Shelf No."; Rec."Service Shelf No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service shelf this item is stored on.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item number linked to this service item.';
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service item group for this item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of this item.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ItemLedgerEntry);
                        ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
                        ItemLedgerEntry.SetRange("Variant Code", Rec."Variant Code");
                        ItemLedgerEntry.SetRange("Serial No.", Rec."Serial No.");
                        PAGE.Run(PAGE::"Item Ledger Entries", ItemLedgerEntry);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of this service item.';
                    Visible = false;
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that warranty on either parts or labor exists for this item.';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract associated with the item or service on the line.';
                }
                field("No. of Allocations"; Rec."No. of Allocations")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of resource allocations with the allocation status specified in the Allocation Status Filter field.';
                }
            }
            group(Control44)
            {
                ShowCaption = false;
                field(Description2; Rec.Description)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies a description of this service item.';
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
            group("&Service Tasks")
            {
                Caption = '&Service Tasks';
                Image = ServiceTasks;
                action("&Show Document")
                {
                    ApplicationArea = Service;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    var
                        ServItemLine: Record "Service Item Line";
                        PageManagement: Codeunit "Page Management";
                    begin
                        if ServHeader.Get(Rec."Document Type", Rec."Document No.") then begin
                            PageManagement.PageRunModal(ServHeader);

                            if ServOrderFilter <> '' then begin
                                ServItemLine.CopyFilters(Rec);
                                if ServItemLine.GetRangeMin("Document No.") = ServItemLine.GetRangeMax("Document No.") then
                                    if ServItemLine.IsEmpty() then begin
                                        ServOrderFilter := '';
                                        SetServOrderFilter();
                                    end
                            end;
                        end;
                    end;
                }
                action("&Item Worksheet")
                {
                    ApplicationArea = Service;
                    Caption = '&Item Worksheet';
                    Image = ItemWorksheet;
                    RunObject = Page "Service Item Worksheet";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "Document No." = field("Document No."),
                                  "Line No." = field("Line No."),
                                  "Resource Filter" = field("Resource Filter");
                    ToolTip = 'View or edit information about service items, such as repair status, fault comments and codes, and cost. In this window, you can update information on the items such as repair status and fault and resolution codes. You can also enter new service lines for resource hours, for the use of spare parts and for specific service costs.';
                }
            }
        }
        area(processing)
        {
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Service &Tasks")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Tasks';
                    Ellipsis = true;
                    Image = ServiceTasks;
                    ToolTip = 'View information about service items on service orders, for example, repair status, response time and service shelf number.';

                    trigger OnAction()
                    var
                        ServItemLine: Record "Service Item Line";
                    begin
                        Rec.FilterGroup(2);
                        ServItemLine.SetView(Rec.GetView());
                        Rec.FilterGroup(0);
                        ServItemLine.SetRange("No. of Allocations");
                        ServItemLine.SetRange("No. of Active/Finished Allocs");

                        REPORT.Run(REPORT::"Service Tasks", true, true, ServItemLine);
                    end;
                }
                action("Service Item &Worksheet")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item &Worksheet';
                    Ellipsis = true;
                    Image = ServiceItemWorksheet;
                    ToolTip = 'Prepare to record service hours and spare parts used, repair status, fault comments, and cost.';

                    trigger OnAction()
                    var
                        ServItemLine: Record "Service Item Line";
                        ServDocumentPrint: Codeunit "Serv. Document Print";
                    begin
                        ServItemLine := Rec;
                        ServItemLine.SetRecFilter();
                        ServDocumentPrint.PrintServiceItemWorksheet(ServItemLine);
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
                actionref("&Item Worksheet_Promoted"; "&Item Worksheet")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ServHeader.Get(Rec."Document Type", Rec."Document No.");

        if not Cust.Get(ServHeader."Customer No.") then
            Clear(Cust);

        Rec.CalcFields("No. of Active/Finished Allocs");
    end;

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
        ItemLedgerEntry: Record "Item Ledger Entry";
        RepairStatus: Record "Repair Status";
        Cust: Record Customer;
        ServHeader: Record "Service Header";
        Res: Record Resource;
        ResourceGroup: Record "Resource Group";
        AllocationStatus: Option " ",Nonactive,Active,Finished,Canceled,"Reallocation Needed";
        DocFilter: Option "Order",Quote,All;
        TempTextFilter: Text;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'There is no %1 within the filter.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TempAllocationStatus: Option " ",Nonactive,Active,Finished,Canceled,"Reallocation Needed";

    protected var
        RepairStatusFilter: Text;
        RespDateFilter: Text;
        ServOrderFilter: Text;
        ResourceFilter: Text;
        ResourceGroupFilter: Text;

    procedure SetAllFilters()
    begin
        SetRepStatFilter();
        SetRespDateFilter();
        SetDocFilter();
        SetServOrderFilter();
        SetResourceFilter();
        SetResourceGroupFilter();
        SetAllocationFilter();

        OnAfterSetAllFilters(Rec);
    end;

    procedure SetRepStatFilter()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Repair Status Code", RepairStatusFilter);
        RepairStatusFilter := Rec.GetFilter("Repair Status Code");
        Rec.FilterGroup(0);
    end;

    procedure SetRespDateFilter()
    var
        FilterTokens: Codeunit "Filter Tokens";
    begin
        Rec.FilterGroup(2);
        FilterTokens.MakeDateFilter(RespDateFilter);
        Rec.SetFilter("Response Date", RespDateFilter);
        RespDateFilter := Rec.GetFilter("Response Date");
        Rec.FilterGroup(0);
    end;

    procedure SetDocFilter()
    begin
        Rec.FilterGroup(2);
        case DocFilter of
            DocFilter::Order:
                Rec.SetRange("Document Type", Rec."Document Type"::Order);
            DocFilter::Quote:
                Rec.SetRange("Document Type", Rec."Document Type"::Quote);
            DocFilter::All:
                Rec.SetRange("Document Type");
        end;
        Rec.FilterGroup(0);
    end;

    procedure SetDocFilterHeader(var ServHeader: Record "Service Header")
    begin
        ServHeader.FilterGroup(2);
        case DocFilter of
            DocFilter::Order:
                ServHeader.SetRange("Document Type", ServHeader."Document Type"::Order);
            DocFilter::Quote:
                ServHeader.SetRange("Document Type", ServHeader."Document Type"::Quote);
            DocFilter::All:
                ServHeader.SetRange("Document Type");
        end;
        ServHeader.FilterGroup(0);
    end;

    procedure SetServOrderFilter()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Document No.", ServOrderFilter);
        ServOrderFilter := Rec.GetFilter("Document No.");
        Rec.FilterGroup(0);
    end;

    procedure SetResourceFilter()
    begin
        Rec.FilterGroup(2);
        if ResourceFilter <> '' then begin
            Rec.SetFilter("No. of Active/Finished Allocs", '>0');
            Rec.SetFilter("Resource Filter", ResourceFilter);
            ResourceFilter := Rec.GetFilter("Resource Filter");
        end else begin
            if ResourceGroupFilter = '' then
                Rec.SetRange("No. of Active/Finished Allocs");
            Rec.SetRange("Resource Filter");
        end;
        Rec.FilterGroup(0);
    end;

    procedure SetResourceGroupFilter()
    begin
        Rec.FilterGroup(2);
        if ResourceGroupFilter <> '' then begin
            Rec.SetFilter("No. of Active/Finished Allocs", '>0');
            Rec.SetFilter("Resource Group Filter", ResourceGroupFilter);
            ResourceGroupFilter := Rec.GetFilter("Resource Group Filter");
        end else begin
            if ResourceFilter = '' then
                Rec.SetRange("No. of Active/Finished Allocs");
            Rec.SetRange("Resource Group Filter");
        end;
        Rec.FilterGroup(0);
    end;

    procedure SetAllocationFilter()
    begin
        Rec.FilterGroup(2);
        case AllocationStatus of
            AllocationStatus::" ":
                begin
                    Rec.SetRange("Allocation Status Filter");
                    Rec.SetRange("No. of Allocations");
                end;
            AllocationStatus::Nonactive:
                begin
                    Rec.SetRange("Allocation Status Filter", Rec."Allocation Status Filter"::Nonactive);
                    Rec.SetFilter("No. of Allocations", '>0');
                end;
            AllocationStatus::Active:
                begin
                    Rec.SetRange("Allocation Status Filter", Rec."Allocation Status Filter"::Active);
                    Rec.SetFilter("No. of Allocations", '>0');
                end;
            AllocationStatus::Finished:
                begin
                    Rec.SetRange("Allocation Status Filter", Rec."Allocation Status Filter"::Finished);
                    Rec.SetFilter("No. of Allocations", '>0');
                end;
            AllocationStatus::Canceled:
                begin
                    Rec.SetRange("Allocation Status Filter", Rec."Allocation Status Filter"::Canceled);
                    Rec.SetFilter("No. of Allocations", '>0');
                end;
            AllocationStatus::"Reallocation Needed":
                begin
                    Rec.SetRange("Allocation Status Filter", Rec."Allocation Status Filter"::"Reallocation Needed");
                    Rec.SetFilter("No. of Allocations", '>0');
                end;
        end;
        Rec.FilterGroup(0);
    end;

    local procedure TestFilter(): Boolean
    begin
        if ServOrderFilter <> '' then begin
            Rec.FilterGroup(2);
            if Rec.GetRangeMin("Document No.") = Rec.GetRangeMax("Document No.") then
                if Rec.IsEmpty() then begin
                    Rec.FilterGroup(0);
                    exit(false);
                end;
            Rec.FilterGroup(0);
        end;
        exit(true);
    end;

    local procedure RepairStatusFilterOnAfterValid()
    begin
        CurrPage.Update(false);
    end;

    local procedure ResourceFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure AllocationStatusOnAfterValidat()
    begin
        CurrPage.Update(false);
    end;

    local procedure DocFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ServOrderFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure RespDateFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ResourceGroupFilterOnAfterVali()
    begin
        CurrPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAllFilters(var ServiceItemLine: Record "Service Item Line")
    begin
    end;
}

