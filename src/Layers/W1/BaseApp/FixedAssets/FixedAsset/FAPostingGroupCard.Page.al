// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

page 5612 "FA Posting Group Card"
{
    Caption = 'FA Posting Group Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "FA Posting Group";
    AboutTitle = 'About FA Posting Group Card';
    AboutText = 'With the **FA Posting Group Card**, you manage information about an FA posting group and specify the G/L accounts for different transactions with fixed assets, such as Acquisition Cost Account, Accumulated Depreciation Account, Depreciation Expense Account, Gain and Loss Account on disposal.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                AboutTitle = 'Manage FA Posting Group G/L Accounts';
                AboutText = 'Specify the G/L accounts which will update when you post the fixed assets transactions such as Acquisition Cost, Accumulated Depreciation, Write Down, Appreciation, Disposal and Disposal Gain/Loss accounts.';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Acquisition Cost Account"; Rec."Acquisition Cost Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Accum. Depreciation Account"; Rec."Accum. Depreciation Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Write-Down Account"; Rec."Write-Down Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Appreciation Account"; Rec."Appreciation Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Custom 1 Account"; Rec."Custom 1 Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Custom 2 Account"; Rec."Custom 2 Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Maintenance Expense Account"; Rec."Maintenance Expense Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Acq. Cost Acc. on Disposal"; Rec."Acq. Cost Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Accum. Depr. Acc. on Disposal"; Rec."Accum. Depr. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Write-Down Acc. on Disposal"; Rec."Write-Down Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Appreciation Acc. on Disposal"; Rec."Appreciation Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Custom 1 Account on Disposal"; Rec."Custom 1 Account on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Custom 2 Account on Disposal"; Rec."Custom 2 Account on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Gains Acc. on Disposal"; Rec."Gains Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Losses Acc. on Disposal"; Rec."Losses Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
            }
            group("Balancing Account")
            {
                Caption = 'Balancing Account';
                AboutTitle = 'Manage FA Posting Group Balancing Account';
                AboutText = 'Specify the balancing G/L accounts which will update when you post the fixed assets transactions such as Acquisition, Depreciation, Appreciation, Write down, Sales and Maintenance.';
                field("Acquisition Cost Bal. Acc."; Rec."Acquisition Cost Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Depreciation Expense Acc."; Rec."Depreciation Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Write-Down Expense Acc."; Rec."Write-Down Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Appreciation Bal. Account"; Rec."Appreciation Bal. Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Custom 1 Expense Acc."; Rec."Custom 1 Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Custom 2 Expense Acc."; Rec."Custom 2 Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Sales Bal. Acc."; Rec."Sales Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Maintenance Bal. Acc."; Rec."Maintenance Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Write-Down Bal. Acc. on Disp."; Rec."Write-Down Bal. Acc. on Disp.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Apprec. Bal. Acc. on Disp."; Rec."Apprec. Bal. Acc. on Disp.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Custom 1 Bal. Acc. on Disposal"; Rec."Custom 1 Bal. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Custom 2 Bal. Acc. on Disposal"; Rec."Custom 2 Bal. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
            }
            group("Gross Disposal")
            {
                Caption = 'Gross Disposal';
                AboutTitle = 'Manage FA Posting Group Gross Disposal Account';
                AboutText = 'Specify the Gain and Loss G/L accounts which will update at the time for fixed asset disposal as per Sales and Book value.';
                group("Sales Acc. on Disposal")
                {
                    Caption = 'Sales Acc. on Disposal';
                    field("Sales Acc. on Disp. (Gain)"; Rec."Sales Acc. on Disp. (Gain)")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Gain Account';
                        ToolTip = 'Specifies the G/L account number you want to post sales to when you dispose of fixed assets at a gain on book value.';
                    }
                    field("Sales Acc. on Disp. (Loss)"; Rec."Sales Acc. on Disp. (Loss)")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Loss Account';
                        ToolTip = 'Specifies the G/L account number to which you want to post sales, when you dispose of fixed assets at a loss on book value.';
                    }
                }
                group("Book Value Acc. on Disposal")
                {
                    Caption = 'Book Value Acc. on Disposal';
                    field("Book Val. Acc. on Disp. (Gain)"; Rec."Book Val. Acc. on Disp. (Gain)")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Gain Account';
                        ToolTip = 'Specifies the G/L account number you want the program to post assets'' book value to when you dispose of fixed assets at a gain on book value.';
                    }
                    field("Book Val. Acc. on Disp. (Loss)"; Rec."Book Val. Acc. on Disp. (Loss)")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Loss Account';
                        ToolTip = 'Specifies the G/L account number to which to post assets'' book value, when you dispose of fixed assets at a loss on book value.';
                    }
                }
            }
            group(Allocation)
            {
                Caption = 'Allocation';
                label(Control102)
                {
                    ApplicationArea = FixedAssets;
                    CaptionClass = Text19064976;
                    ShowCaption = false;
                }
                field("Allocated Acquisition Cost %"; Rec."Allocated Acquisition Cost %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Acquisition Cost';
                }
                field("Allocated Depreciation %"; Rec."Allocated Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation';
                }
                field("Allocated Write-Down %"; Rec."Allocated Write-Down %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Write-Down';
                }
                field("Allocated Appreciation %"; Rec."Allocated Appreciation %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Appreciation';
                }
                field("Allocated Custom 1 %"; Rec."Allocated Custom 1 %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Custom 1';
                }
                field("Allocated Custom 2 %"; Rec."Allocated Custom 2 %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Custom 2';
                }
                field("Allocated Maintenance %"; Rec."Allocated Maintenance %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance';
                }
                label(Control127)
                {
                    ApplicationArea = FixedAssets;
                    CaptionClass = Text19080001;
                    ShowCaption = false;
                }
                field("Allocated Gain %"; Rec."Allocated Gain %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Gain';
                }
                field("Allocated Loss %"; Rec."Allocated Loss %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Loss';
                }
                field("Allocated Book Value % (Gain)"; Rec."Allocated Book Value % (Gain)")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Book Value (Gain)';
                    ToolTip = 'Specifies the sum that applies to book value gains.';
                }
                field("Allocated Book Value % (Loss)"; Rec."Allocated Book Value % (Loss)")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Book Value (Loss)';
                    ToolTip = 'Specifies the sum that applies to book value gains.';
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
                        Caption = 'Depreciation';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const(Depreciation);
                        ToolTip = 'Specifies whether depreciation entries posted to this depreciation book are posted both to the general ledger and the FA ledger.';
                    }
                    action(WriteDown)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Write-Down';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const("Write-Down");
                        ToolTip = 'Specifies whether write-down entries posted to this depreciation book should be posted to the general ledger and the FA ledger.';
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
                        Caption = 'Custom 1';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const("Custom 1");
                        ToolTip = 'View or edit the FA allocations that apply to custom 1 values.';
                    }
                    action(Custom2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'C&ustom 2';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = field(Code),
                                      "Allocation Type" = const("Custom 2");
                        ToolTip = 'View or edit the FA allocations that apply to custom 2 values.';
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

    var
#pragma warning disable AA0074
        Text19064976: Label 'Allocated %';
        Text19080001: Label 'Allocated %';
#pragma warning restore AA0074
}

