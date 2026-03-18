// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

using Microsoft.Inventory.Item;

pageextension 99000841 "Mfg. Standard Cost Worksheet" extends "Standard Cost Worksheet"
{
    actions
    {
        addbefore("Page")
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest I&tem Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest I&tem Standard Cost';
                    Ellipsis = true;
                    Image = SuggestItemCost;
                    ToolTip = 'Creates suggestions for changing the cost shares of standard costs on Item cards. Note that the suggested changes are not implemented.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        SuggItemStdCost: Report "Suggest Item Standard Cost";
                    begin
                        Item.SetRange("Replenishment System", Item."Replenishment System"::Purchase);
                        SuggItemStdCost.SetTableView(Item);
                        SuggItemStdCost.SetCopyToWksh(CurrWkshName);
                        SuggItemStdCost.RunModal();
                    end;
                }
                action("Suggest &Capacity Standard Cost")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Suggest &Capacity Standard Cost';
                    Ellipsis = true;
                    Image = SuggestCapacity;
                    ToolTip = 'Create suggestions on new worksheet lines for changing the costs and cost shares of standard costs on work center, machine center, or resource cards.';

                    trigger OnAction()
                    var
                        SuggWorkMachCtrStdWksh: Report "Suggest Capacity Standard Cost";
                    begin
                        SuggWorkMachCtrStdWksh.SetCopyToWksh(CurrWkshName);
                        SuggWorkMachCtrStdWksh.RunModal();
                    end;
                }
                action("Copy Standard Cost Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Standard Cost Worksheet';
                    Ellipsis = true;
                    Image = CopyWorksheet;
                    ToolTip = 'Copies standard cost worksheets from several sources into the Standard Cost Worksheet window.';

                    trigger OnAction()
                    var
                        CopyStdCostWksh: Report "Copy Standard Cost Worksheet";
                    begin
                        CopyStdCostWksh.SetCopyToWksh(CurrWkshName);
                        CopyStdCostWksh.RunModal();
                    end;
                }
                action("Roll Up Standard Cost")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Roll Up Standard Cost';
                    Ellipsis = true;
                    Image = RollUpCosts;
                    ToolTip = 'Roll up the standard costs of assembled and manufactured items, for example, with changes in the standard cost of components and changes in the standard cost of production capacity and assembly resources. When you run the function, all changes to the standard costs in the worksheet are introduced in the associated production or assembly BOMs, and the costs are applied at each BOM level.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        RollUpStdCost: Report "Roll Up Standard Cost";
                    begin
                        Clear(RollUpStdCost);
                        Item.SetRange("Costing Method", Item."Costing Method"::Standard);
                        RollUpStdCost.SetTableView(Item);
                        RollUpStdCost.SetStdCostWksh(CurrWkshName);
                        RollUpStdCost.RunModal();
                    end;
                }
                action("&Implement Standard Cost Changes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Implement Standard Cost Changes';
                    Ellipsis = true;
                    Image = ImplementCostChanges;
                    ToolTip = 'Updates the changes in the standard cost in the Item table with the ones in the Standard Cost Worksheet table.';

                    trigger OnAction()
                    var
                        ImplStdCostChg: Report "Implement Standard Cost Change";
                    begin
                        Clear(ImplStdCostChg);
                        ImplStdCostChg.SetStdCostWksh(CurrWkshName);
                        ImplStdCostChg.RunModal();
                    end;
                }
            }
        }
        addafter(Category_Process)
        {
            actionref("Suggest I&tem Standard Cost_Promoted"; "Suggest I&tem Standard Cost")
            {
            }
            actionref("Suggest &Capacity Standard Cost_Promoted"; "Suggest &Capacity Standard Cost")
            {
            }
            actionref("Roll Up Standard Cost_Promoted"; "Roll Up Standard Cost")
            {
            }
            actionref("&Implement Standard Cost Changes_Promoted"; "&Implement Standard Cost Changes")
            {
            }
        }
    }
}
