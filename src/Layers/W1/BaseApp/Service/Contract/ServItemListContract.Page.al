// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Inventory.Item;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;

page 6076 "Serv. Item List (Contract)"
{
    Caption = 'Service Item List';
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract or service contract quote associated with the service contract line.';
                    Visible = false;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the service item that is subject to the service contract.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of the service item that is subject to the contract.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the item linked to the service item in the service contract.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the service item that is subject to the contract.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer associated with the service contract.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
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
            group("&Serv. Item")
            {
                Caption = '&Serv. Item';
                Image = ServiceItem;
                action(Card)
                {
                    ApplicationArea = Service;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Service Item Card";
                    RunPageLink = "No." = field("Service Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = field("Service Item No.");
                    RunPageView = sorting("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = field("Service Item No.");
                    RunPageView = sorting("Service Item No. (Serviced)", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action("Com&ponent List")
                {
                    ApplicationArea = Service;
                    Caption = 'Com&ponent List';
                    Image = Components;
                    RunObject = Page "Service Item Component List";
                    RunPageLink = Active = const(true),
                                  "Parent Service Item No." = field("Service Item No.");
                    RunPageView = sorting(Active, "Parent Service Item No.", "Line No.");
                    ToolTip = 'View the list of components in the service item.';
                }
                action("Troubleshooting Set&up")
                {
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting Set&up';
                    Image = Troubleshoot;
                    RunObject = Page "Troubleshooting Setup";
                    RunPageLink = Type = const("Service Item"),
                                  "No." = field("Service Item No.");
                    ToolTip = 'Set up troubleshooting.';
                }
                action("&Troubleshooting")
                {
                    ApplicationArea = Service;
                    Caption = '&Troubleshooting';
                    Image = Troubleshoot;
                    ToolTip = 'View or edit information about technical problems with a service item.';

                    trigger OnAction()
                    var
                        ServItem: Record "Service Item";
                        TblshtgHeader: Record "Troubleshooting Header";
                    begin
                        ServItem.Get(Rec."Service Item No.");
                        TblshtgHeader.ShowForServItem(ServItem);
                    end;
                }
                action("Resource Skills")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Skills';
                    Image = ResourceSkills;
                    ToolTip = 'View the assignment of skills to resources, items, service item groups, and service items. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';

                    trigger OnAction()
                    var
                        ResourceSkill: Record "Resource Skill";
                    begin
                        case true of
                            Rec."Service Item No." <> '':
                                begin
                                    ResourceSkill.SetRange(Type, ResourceSkill.Type::"Service Item");
                                    ResourceSkill.SetRange("No.", Rec."Service Item No.");
                                end;
                            Rec."Item No." <> '':
                                begin
                                    ResourceSkill.SetRange(Type, ResourceSkill.Type::Item);
                                    ResourceSkill.SetRange("No.", Rec."Item No.");
                                end;
                        end;
                        PAGE.RunModal(PAGE::"Resource Skills", ResourceSkill);
                    end;
                }
                action("S&killed Resources")
                {
                    ApplicationArea = Service;
                    Caption = 'S&killed Resources';
                    Image = ResourceSkills;
                    ToolTip = 'View the list of resources that have the skills required to handle service items.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        ServiceItem: Record "Service Item";
                        ResourceSkill: Record "Resource Skill";
                        SkilledResourceList: Page "Skilled Resource List";
                    begin
                        if Rec."Service Item No." <> '' then begin
                            if ServiceItem.Get(Rec."Service Item No.") then begin
                                SkilledResourceList.Initialize(
                                  ResourceSkill.Type::"Service Item",
                                  Rec."Service Item No.",
                                  ServiceItem.Description);
                                SkilledResourceList.RunModal();
                            end;
                        end else
                            if Rec."Item No." <> '' then
                                if Item.Get(Rec."Item No.") then begin
                                    SkilledResourceList.Initialize(
                                      ResourceSkill.Type::Item,
                                      Rec."Item No.",
                                      Item.Description);
                                    SkilledResourceList.RunModal();
                                end;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Contract"),
                                  "Table Subtype" = field("Contract Type"),
                                  "No." = field("Contract No."),
                                  "Table Line No." = field("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Service Item Statistics";
                    RunPageLink = "No." = field("Service Item No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Tr&endscape")
                {
                    ApplicationArea = Service;
                    Caption = 'Tr&endscape';
                    Image = Trendscape;
                    RunObject = Page "Service Item Trendscape";
                    RunPageLink = "No." = field("Service Item No.");
                    ToolTip = 'View a detailed account of service item transactions by time intervals.';
                }
                action("Service Item Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Lo&g';
                    Image = Log;
                    RunObject = Page "Service Item Log";
                    RunPageLink = "Service Item No." = field("Service Item No.");
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';
                }
                action("Ser&vice Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Contracts';
                    Image = ServiceAgreement;
                    RunObject = Page "Serv. Contr. List (Serv. Item)";
                    RunPageLink = "Service Item No." = field("Service Item No.");
                    RunPageView = sorting("Service Item No.", "Contract Status");
                    ToolTip = 'Open the list of ongoing service contracts.';
                }
                group("S&ervice Orders")
                {
                    Caption = 'S&ervice Orders';
                    Image = "Order";
                    action("&Item Lines")
                    {
                        ApplicationArea = Service;
                        Caption = '&Item Lines';
                        Image = ItemLines;
                        RunObject = Page "Service Item Lines";
                        RunPageLink = "Service Item No." = field("Service Item No.");
                        RunPageView = sorting("Service Item No.");
                        ToolTip = 'View ongoing service item lines for the item. ';
                    }
                    action("&Service Lines")
                    {
                        ApplicationArea = Service;
                        Caption = '&Service Lines';
                        Image = ServiceLines;
                        RunObject = Page "Service Line List";
                        RunPageLink = "Service Item No." = field("Service Item No.");
                        RunPageView = sorting("Service Item No.");
                        ToolTip = 'View ongoing service lines for the item.';
                    }
                }
                group("Service Shi&pments")
                {
                    Caption = 'Service Shi&pments';
                    Image = Shipment;
                    action(Action41)
                    {
                        ApplicationArea = Service;
                        Caption = 'Shipped &Item Lines';
                        Image = ItemLines;
                        RunObject = Page "Posted Shpt. Item Line List";
                        RunPageLink = "Service Item No." = field("Service Item No.");
                        RunPageView = sorting("Service Item No.");
                        ToolTip = 'View shipped service item lines for the item. ';
                    }
                    action(Action42)
                    {
                        ApplicationArea = Service;
                        Caption = 'Shipped &Service Lines';
                        Image = ServiceLines;
                        RunObject = Page "Posted Serv. Shpt. Line List";
                        RunPageLink = "Service Item No." = field("Service Item No.");
                        RunPageView = sorting("Service Item No.");
                        ToolTip = 'View shipped service lines for the item.';
                    }
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }
}

