// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;

page 5988 "Service Items"
{
    Caption = 'Service Items';
    CardPageID = "Service Item Card";
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = "Service Item";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of this item.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item number linked to the service item.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of this item.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns this item.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Warranty Starting Date (Parts)"; Rec."Warranty Starting Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the spare parts warranty for this item.';
                }
                field("Warranty Ending Date (Parts)"; Rec."Warranty Ending Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the spare parts warranty for this item.';
                }
                field("Warranty Starting Date (Labor)"; Rec."Warranty Starting Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the labor warranty for this item.';
                }
                field("Warranty Ending Date (Labor)"; Rec."Warranty Ending Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the labor warranty for this item.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service item is blocked from being used in service contracts or used and posted in transactions via service documents, except credit memos.';
                }
            }
        }
        area(factboxes)
        {
#if not CLEAN25
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ObsoleteTag = '25.0';
                ObsoleteState = Pending;
                ObsoleteReason = 'The "Document Attachment FactBox" has been replaced by "Doc. Attachment List Factbox", which supports multiple files upload.';
                ApplicationArea = Service;
                Caption = 'Attachments';
                Visible = false;
                SubPageLink = "Table ID" = const(Database::"Service Item"),
                              "No." = field("No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Item"),
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
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Item"),
                                  "Table Subtype" = const("0"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = field("No."),
                                  "Service Order No." = field("Service Order Filter"),
                                  "Service Contract No." = field("Contract Filter"),
                                  "Posting Date" = field("Date Filter");
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
                    RunPageLink = "Service Item No. (Serviced)" = field("No.");
                    RunPageView = sorting("Service Item No. (Serviced)", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Service Item Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("&Trendscape")
                {
                    ApplicationArea = Service;
                    Caption = '&Trendscape';
                    Image = Trendscape;
                    RunObject = Page "Service Item Trendscape";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View a scrollable summary of service ledger entries that are related to a specific service item. This summary is generated for a specific time period.';
                }
                action("L&og")
                {
                    ApplicationArea = Service;
                    Caption = 'L&og';
                    Image = Approve;
                    RunObject = Page "Service Item Log";
                    RunPageLink = "Service Item No." = field("No.");
                    ToolTip = 'View the list of the service item changes that have been logged, for example, when the warranty has changed or a component has been added. This window displays the field that was changed, the old value and the new value, and the date and time that the field was changed.';
                }
                action("Com&ponents")
                {
                    ApplicationArea = Service;
                    Caption = 'Com&ponents';
                    Image = Components;
                    RunObject = Page "Service Item Component List";
                    RunPageLink = Active = const(true),
                                  "Parent Service Item No." = field("No.");
                    RunPageView = sorting(Active, "Parent Service Item No.", "Line No.");
                    ToolTip = 'View the list of components in the service item.';
                }
                separator(Action38)
                {
                }
                group("Trou&bleshooting  Setup")
                {
                    Caption = 'Trou&bleshooting  Setup';
                    Image = Troubleshoot;
                    action(ServiceItemGroup)
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Group';
                        Image = ServiceItemGroup;
                        RunObject = Page "Troubleshooting Setup";
                        RunPageLink = Type = const("Service Item Group"),
                                      "No." = field("Service Item Group Code");
                        ToolTip = 'View or edit groupings of service items.';
                    }
                    action(ServiceItem)
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item';
                        Image = "Report";
                        RunObject = Page "Troubleshooting Setup";
                        RunPageLink = Type = const("Service Item"),
                                      "No." = field("No.");
                        ToolTip = 'Create a new service item.';
                    }
                    action(Item)
                    {
                        ApplicationArea = Service;
                        Caption = 'Item';
                        Image = Item;
                        RunObject = Page "Troubleshooting Setup";
                        RunPageLink = Type = const(Item),
                                      "No." = field("Item No.");
                        ToolTip = 'View and edit detailed information for the item.';
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

    var
#pragma warning disable AA0074
        Text000: Label '%1 %2', Comment = '%1=Cust."No."  %2=Cust.Name';
        Text001: Label '%1 %2', Comment = '%1 = Item no, %2 = Item description';
#pragma warning restore AA0074

    local procedure GetCaption(): Text
    var
        Cust: Record Customer;
        Item: Record Item;
    begin
        case true of
            Rec.GetFilter("Customer No.") <> '':
                begin
                    if Cust.Get(Rec.GetRangeMin("Customer No.")) then
                        exit(StrSubstNo(Text000, Cust."No.", Cust.Name));
                    exit(StrSubstNo('%1 %2', Rec.GetRangeMin("Customer No.")));
                end;
            Rec.GetFilter("Item No.") <> '':
                begin
                    if Item.Get(Rec.GetRangeMin("Item No.")) then
                        exit(StrSubstNo(Text001, Item."No.", Item.Description));
                    exit(StrSubstNo('%1 %2', Rec.GetRangeMin("Item No.")));
                end;
            else
                exit('');
        end;
    end;
}

