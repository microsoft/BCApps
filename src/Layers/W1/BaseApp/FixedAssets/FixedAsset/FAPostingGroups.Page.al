// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

page 5613 "FA Posting Groups"
{
    AdditionalSearchTerms = 'fixed asset posting groups';
    ApplicationArea = FixedAssets;
    Caption = 'FA Posting Groups';
    CardPageID = "FA Posting Group Card";
    PageType = List;
    SourceTable = "FA Posting Group";
    UsageCategory = Administration;
    AboutTitle = 'About FA Posting Group';
    AboutText = 'Here you create/ overview all registered FA posting groups with the G/L Accounts for different types of expenses and costs, such as Acquisition Cost Account, Accumulated Depreciation, Depreciation Expense, Maintenance, Gain and Loss Account on disposal.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the G/L account that fixed asset expenses and costs are posted to when the fixed asset card contains this code.';
                }
                field("Acquisition Cost Account"; Rec."Acquisition Cost Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post acquisition cost for fixed assets to in this posting group.';
                }
                field("Accum. Depreciation Account"; Rec."Accum. Depreciation Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post accumulated depreciation to when you post depreciation for fixed assets.';
                }
                field("Write-Down Account"; Rec."Write-Down Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post any write-downs for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Appreciation Account"; Rec."Appreciation Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post appreciation transactions for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Custom 1 Account"; Rec."Custom 1 Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post Custom-1 transactions for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Custom 2 Account"; Rec."Custom 2 Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post Custom-2 transactions for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Acq. Cost Acc. on Disposal"; Rec."Acq. Cost Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post acquisition cost to when you dispose of fixed assets in this posting group.';
                }
                field("Accum. Depr. Acc. on Disposal"; Rec."Accum. Depr. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post accumulated depreciation to when you dispose of fixed assets in this posting group.';
                }
                field("Write-Down Acc. on Disposal"; Rec."Write-Down Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post write-downs of fixed assets to when you dispose of fixed assets in this posting group.';
                    Visible = false;
                }
                field("Appreciation Acc. on Disposal"; Rec."Appreciation Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post appreciation to when you dispose of fixed assets in this posting group.';
                    Visible = false;
                }
                field("Custom 1 Account on Disposal"; Rec."Custom 1 Account on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post Custom-1 transactions to when you dispose of fixed assets in this posting group.';
                    Visible = false;
                }
                field("Custom 2 Account on Disposal"; Rec."Custom 2 Account on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post Custom-2 transactions to when you dispose of fixed assets in this posting group.';
                    Visible = false;
                }
                field("Gains Acc. on Disposal"; Rec."Gains Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post any gains to when you dispose of fixed assets in this posting group.';
                }
                field("Losses Acc. on Disposal"; Rec."Losses Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post any losses to when you dispose of fixed assets in this posting group.';
                }
                field("Book Val. Acc. on Disp. (Gain)"; Rec."Book Val. Acc. on Disp. (Gain)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the G/L account number you want the program to post assets'' book value to when you dispose of fixed assets at a gain on book value.';
                    Visible = false;
                }
                field("Book Val. Acc. on Disp. (Loss)"; Rec."Book Val. Acc. on Disp. (Loss)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the G/L account number to which to post assets'' book value, when you dispose of fixed assets at a loss on book value.';
                    Visible = false;
                }
                field("Sales Acc. on Disp. (Gain)"; Rec."Sales Acc. on Disp. (Gain)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the G/L account number you want to post sales to when you dispose of fixed assets at a gain on book value.';
                    Visible = false;
                }
                field("Sales Acc. on Disp. (Loss)"; Rec."Sales Acc. on Disp. (Loss)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the G/L account number to which you want to post sales, when you dispose of fixed assets at a loss on book value.';
                    Visible = false;
                }
                field("Write-Down Bal. Acc. on Disp."; Rec."Write-Down Bal. Acc. on Disp.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post write-downs of fixed assets to when you dispose of fixed assets.';
                    Visible = false;
                }
                field("Apprec. Bal. Acc. on Disp."; Rec."Apprec. Bal. Acc. on Disp.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post appreciation transactions of fixed assets to when you dispose of fixed assets.';
                    Visible = false;
                }
                field("Custom 1 Bal. Acc. on Disposal"; Rec."Custom 1 Bal. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post custom-1 transactions of fixed assets to when you dispose of fixed assets.';
                    Visible = false;
                }
                field("Custom 2 Bal. Acc. on Disposal"; Rec."Custom 2 Bal. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post custom-2 transactions of fixed assets to when you dispose of fixed assets.';
                    Visible = false;
                }
                field("Maintenance Expense Account"; Rec."Maintenance Expense Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post maintenance expenses for fixed assets to in this posting group.';
                }
                field("Maintenance Bal. Acc."; Rec."Maintenance Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post maintenance expenses for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Acquisition Cost Bal. Acc."; Rec."Acquisition Cost Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post acquisition cost for fixed assets to in this posting group.';
                }
                field("Depreciation Expense Acc."; Rec."Depreciation Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post depreciation expense for fixed assets to in this posting group.';
                }
                field("Write-Down Expense Acc."; Rec."Write-Down Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post write-downs for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Appreciation Bal. Account"; Rec."Appreciation Bal. Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post appreciation for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Custom 1 Expense Acc."; Rec."Custom 1 Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post custom-1 transactions for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Custom 2 Expense Acc."; Rec."Custom 2 Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post custom-2 transactions for fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Sales Bal. Acc."; Rec."Sales Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account to post sales when you dispose of fixed assets to in this posting group.';
                    Visible = false;
                }
                field("Allocated Acquisition Cost %"; Rec."Allocated Acquisition Cost %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                    Visible = false;
                }
                field("Allocated Depreciation %"; Rec."Allocated Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage of depreciation that can be allocated when depreciation is posted.';
                    Visible = false;
                }
                field("Allocated Write-Down %"; Rec."Allocated Write-Down %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage for write-down transactions that can be allocated when write-down transactions are posted.';
                    Visible = false;
                }
                field("Allocated Appreciation %"; Rec."Allocated Appreciation %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage for appreciation transactions that can be allocated when appreciation transactions are posted.';
                    Visible = false;
                }
                field("Allocated Custom 1 %"; Rec."Allocated Custom 1 %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage for custom-1 transactions that can be allocated when custom-1 transactions are posted.';
                    Visible = false;
                }
                field("Allocated Custom 2 %"; Rec."Allocated Custom 2 %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage for custom-2 transactions that can be allocated when custom-2 transactions are posted.';
                    Visible = false;
                }
                field("Allocated Sales Price %"; Rec."Allocated Sales Price %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage of sales price that can be allocated when sales are posted.';
                    Visible = false;
                }
                field("Allocated Maintenance %"; Rec."Allocated Maintenance %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage for maintenance transactions that can be allocated when maintenance transactions are posted.';
                    Visible = false;
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
            group("P&osting Gr.")
            {
                Caption = 'P&osting Gr.';
                Image = Group;
                group(Allocations)
                {
                    Caption = 'Allocations';
                    Image = Allocate;
                    action(Depreciation)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = '&Depreciation';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const(Depreciation);
                        ToolTip = 'View or edit the FA allocation that apply to depreciations.';
                    }
                    action(WriteDown)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = '&Write-Down';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const("Write-Down");
                        ToolTip = 'View or edit the FA allocation that apply to write-downs.';
                    }
                    action(Appreciation)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Appr&eciation';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const(Appreciation);
                        ToolTip = 'View or edit the FA allocations that apply to appreciations.';
                    }
                    action(Custom1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = '&Custom 1';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const("Custom 1");
                        ToolTip = 'View or edit the FA allocation that apply to custom values.';
                    }
                    action(Custom2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'C&ustom 2';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const("Custom 2");
                        ToolTip = 'View or edit the FA allocation that apply to custom values.';
                    }
                    action(Maintenance)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Maintenance';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const(Maintenance);
                        ToolTip = 'View or edit the FA allocations that apply to maintenance.';
                    }
                    action(Gain)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Gain';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const(Gain);
                        ToolTip = 'View or edit the FA allocations that apply to gains.';
                    }
                    action(Loss)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Loss';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const(Loss);
                        ToolTip = 'View or edit the FA allocations that apply to losses.';
                    }
                }
            }
        }
    }
}

