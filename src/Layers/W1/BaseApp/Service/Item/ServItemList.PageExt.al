// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;

pageextension 6453 "Serv. Item List" extends "Item List"
{
    actions
    {
        addafter(Warehouse)
        {
            group(Service)
            {
                Caption = 'Service';
                Image = ServiceItem;
                action("Ser&vice Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Items';
                    Image = ServiceItem;
                    RunObject = Page "Service Items";
                    RunPageLink = "Item No." = field("No.");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'View instances of the item as service items, such as machines that you maintain or repair for customers through service orders. ';
                }
                action(Troubleshooting)
                {
                    AccessByPermission = TableData "Service Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting';
                    Image = Troubleshoot;
                    ToolTip = 'View or edit information about technical problems with a service item.';

                    trigger OnAction()
                    var
                        TroubleshootingHeader: Record "Troubleshooting Header";
                    begin
                        TroubleshootingHeader.ShowForItem(Rec);
                    end;
                }
                action("Troubleshooting Setup")
                {
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting Setup';
                    Image = Troubleshoot;
                    RunObject = Page "Troubleshooting Setup";
                    RunPageLink = Type = const(Item),
                                  "No." = field("No.");
                    ToolTip = 'View or edit your settings for troubleshooting service items.';
                }
            }
            group(Resources)
            {
                Caption = 'Resources';
                Image = Resource;
                action("Resource &Skills")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource &Skills';
                    Image = ResourceSkills;
                    RunObject = Page "Resource Skills";
                    RunPageLink = Type = const(Item),
                                  "No." = field("No.");
                    ToolTip = 'View the assignment of skills to resources, items, service item groups, and service items. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
                }
                action("Skilled R&esources")
                {
                    AccessByPermission = TableData "Service Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Skilled R&esources';
                    Image = ResourceSkills;
                    ToolTip = 'View a list of all registered resources with information about whether they have the skills required to service the particular service item group, item, or service item.';

                    trigger OnAction()
                    var
                        ResourceSkill: Record "Resource Skill";
                        SkilledResourceList: Page "Skilled Resource List";
                    begin
                        Clear(SkilledResourceList);
                        SkilledResourceList.Initialize(ResourceSkill.Type::Item, Rec."No.", Rec.Description);
                        SkilledResourceList.RunModal();
                    end;
                }
            }
        }
    }
}
