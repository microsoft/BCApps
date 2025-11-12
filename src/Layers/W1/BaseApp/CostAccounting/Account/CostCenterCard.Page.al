// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Account;

using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Setup;
using System.Security.User;

page 1111 "Cost Center Card"
{
    Caption = 'Cost Center Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Cost Center";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the code for the cost center.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the cost center card.';
                }
                field("Cost Subtype"; Rec."Cost Subtype")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the subtype of the cost center. This is an information field and is not used for any other purposes. Choose the field to select the cost subtype.';
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the purpose of the cost object, such as Cost Object, Heading, or Begin-Total. Newly created cost objects are automatically assigned the Cost Object type, but you can change this.';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a comment that applies to the cost center.';
                }
                field("Responsible Person"; Rec."Responsible Person")
                {
                    ApplicationArea = CostAccounting;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the person who is responsible for the cost center.';
                }
                field("Balance at Date"; Rec."Balance at Date")
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies the cost type balance on the last date that is included in the Date Filter field. The contents of the field are calculated by using the entries in the Amount field in the Cost Entry table.';
                }
                field("Balance to Allocate"; Rec."Balance to Allocate")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the balance that has not yet been allocated. The entry in the Allocated field determines if the entry is included in the Balance to Allocate field. The value in the Allocated field is set automatically during the cost allocation.';
                }
                field("Sorting Order"; Rec."Sorting Order")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the sorting order of the cost center.';
                }
                field("Blank Line"; Rec."Blank Line")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether you want a blank line to appear immediately after this cost center when you print the chart of cost centers. The New Page, Blank Line, and Indentation fields define the layout of the chart of cost centers.';
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies if you want a new page to start immediately after this cost center when you print the chart of cash flow accounts.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cost Center")
            {
                Caption = '&Cost Center';
                Image = CostCenter;
                action("E&ntries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'E&ntries';
                    Image = Entries;
                    RunObject = Page "Cost Entries";
                    RunPageLink = "Cost Center Code" = field(Code);
                    RunPageView = sorting("Cost Center Code", "Cost Type No.", Allocated, "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the entries for the cost center.';
                }
                separator(Action4)
                {
                }
                action("&Balance")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Balance';
                    Image = Balance;
                    ShortCutKey = 'F7';
                    ToolTip = 'View a summary of the balance at date or the net change for different time periods for the cost center that you select. You can select different time intervals and set filters on the cost centers and cost objects that you want to see.';

                    trigger OnAction()
                    var
                        CostType: Record "Cost Type";
                    begin
                        if Rec.Totaling = '' then
                            CostType.SetFilter("Cost Center Filter", Rec.Code)
                        else
                            CostType.SetFilter("Cost Center Filter", Rec.Totaling);

                        PAGE.Run(PAGE::"Cost Type Balance", CostType);
                    end;
                }
            }
        }
        area(processing)
        {
            action(PageDimensionValues)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimension Values';
                Image = Dimensions;
                ToolTip = 'View or edit the dimension values for the current dimension.';

                trigger OnAction()
                var
                    CostAccSetup: Record "Cost Accounting Setup";
                    CostAccMgt: Codeunit "Cost Account Mgt";
                begin
                    CostAccMgt.OpenDimValueListFiltered(CostAccSetup.FieldNo("Cost Center Dimension"));
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(PageDimensionValues_Promoted; PageDimensionValues)
                {
                }
            }
            group("Category_Cost Center")
            {
                Caption = 'Cost Center';

                actionref("&Balance_Promoted"; "&Balance")
                {
                }
                actionref("E&ntries_Promoted"; "E&ntries")
                {
                }
            }
        }
    }
}

