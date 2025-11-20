// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;

page 5909 "Service Item Groups"
{
    ApplicationArea = Service;
    Caption = 'Service Item Groups';
    PageType = List;
    SourceTable = "Service Item Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the service item group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service item group.';
                }
                field("Default Contract Discount %"; Rec."Default Contract Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount percentage used as the default quote discount in a service contract quote.';
                }
                field("Default Serv. Price Group Code"; Rec."Default Serv. Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service price group code used as the default service price group in the Service Price Group table.';
                }
                field("Default Response Time (Hours)"; Rec."Default Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default response time for the service item group.';
                }
                field("Create Service Item"; Rec."Create Service Item")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that when you ship an item associated with this group, the item is registered as a service item in the Service Item table.';
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
            group("&Group")
            {
                Caption = '&Group';
                Image = Group;
                action("Resource Skills")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Skills';
                    Image = ResourceSkills;
                    RunObject = Page "Resource Skills";
                    RunPageLink = Type = const("Service Item Group"),
                                  "No." = field(Code);
                    ToolTip = 'View the assignment of skills to resources, items, service item groups, and service items. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
                }
                action("Skilled Resources")
                {
                    ApplicationArea = Service;
                    Caption = 'Skilled Resources';
                    Image = ResourceSkills;
                    ToolTip = 'View a list of all registered resources with information about whether they have the skills required to service the particular service item group, item, or service item.';

                    trigger OnAction()
                    var
                        ResourceSkill: Record "Resource Skill";
                    begin
                        Clear(SkilledResourceList);
                        SkilledResourceList.Initialize(ResourceSkill.Type::"Service Item Group", Rec.Code, Rec.Description);
                        SkilledResourceList.RunModal();
                    end;
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
                        RunPageLink = "Table ID" = const(5904),
                                      "No." = field(Code);
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
                            ServiceItemGroup: Record "Service Item Group";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(ServiceItemGroup);
                            DefaultDimMultiple.SetMultiRecord(ServiceItemGroup, Rec.FieldNo(Code));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("Trou&bleshooting Setup")
                {
                    ApplicationArea = Service;
                    Caption = 'Trou&bleshooting Setup';
                    Image = Troubleshoot;
                    RunObject = Page "Troubleshooting Setup";
                    RunPageLink = Type = const("Service Item Group"),
                                  "No." = field(Code);
                    ToolTip = 'Define how you troubleshoot service items.';
                }
                action("S&td. Serv. Item Gr. Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'S&td. Serv. Item Gr. Codes';
                    Image = ItemGroup;
                    RunObject = Page "Standard Serv. Item Gr. Codes";
                    RunPageLink = "Service Item Group Code" = field(Code);
                    ToolTip = 'View or edit recurring service item groups that you add to service lines. ';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Skilled Resources_Promoted"; "Skilled Resources")
                {
                }
                group(Category_Group)
                {
                    Caption = 'Group';

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
                }
                actionref("Resource Skills_Promoted"; "Resource Skills")
                {
                }
                actionref("Trou&bleshooting Setup_Promoted"; "Trou&bleshooting Setup")
                {
                }
                actionref("S&td. Serv. Item Gr. Codes_Promoted"; "S&td. Serv. Item Gr. Codes")
                {
                }
            }
        }
    }

    var
        SkilledResourceList: Page "Skilled Resource List";
}

