// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 12217 "Periodic VAT Split"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Periodic VAT Split';
    CardPageID = "Periodic VAT Settl. Card";
    Editable = true;
    PageType = List;
    SourceTable = "Periodic VAT Settlement Entry";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            group(Totals)
            {
                Editable = false;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("VAT Period"; Rec."VAT Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period of time that defines the VAT period.';
                }
                field("Activity Code"; Rec."Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the activity code that is assigned to the VAT settlement transaction.';
                }
                field("Prior Period Input VAT"; Rec."Prior Period Input VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of input VAT from purchases during the previous period.';
                    Visible = true;
                }
                field("Prior Period Output VAT"; Rec."Prior Period Output VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of output VAT from sales during the prior period.';
                }
                field("Add Curr. Prior Per. Inp. VAT"; Rec."Add Curr. Prior Per. Inp. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of input VAT from purchases during the previous period.';
                    Visible = false;
                }
                field("Add Curr. Prior Per. Out VAT"; Rec."Add Curr. Prior Per. Out VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of output VAT from sales during the prior period.';
                    Visible = false;
                }
                field("Prior Year Input VAT"; Rec."Prior Year Input VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of input VAT from purchases during the previous year.';
                }
                field("Prior Year Output VAT"; Rec."Prior Year Output VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of output VAT from sales during the prior year.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateSplitAction)
            {
                ApplicationArea = All;
                Caption = 'Validate Split';
                Tooltip = 'Validates the split of VAT settlement entries.';

                trigger OnAction()
                var
#if CLEAN27
                    PeriodicVATSettlement: Codeunit "Periodic VAT Settlement";
#endif
                begin
#if not CLEAN27
                    if ValidateSplit(Rec."VAT Period") then
                        Message(SplitIsValidMsg)
                    else
                        Message(SplitIsInvalidMsg);
#else
                    if PeriodicVATSettlement.ValidateSplit(Rec."VAT Period") then
                        Message(SplitIsValidMsg)
                    else
                        Message(SplitIsInvalidMsg);
#endif
                end;
            }

        }
        area(Promoted)
        {
            actionref(ValidateSplitAction_Promoted; ValidateSplitAction) { }
        }
    }

    var
        Period: Code[10];
        SplitIsValidMsg: Label 'Periodic VAT Settlement Entry is split correctly between the separate entries.';
        SplitIsInvalidMsg: Label 'Periodic VAT Settlement Entry is not split correctly between the separate entries.';

#if not CLEAN27
    local procedure ValidateSplit(VATPeriod: Code[10]) Valid: Boolean
    var
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
        PeriodicVATSettlementEntry2: Record "Periodic VAT Settlement Entry";
        PriorPeriodOutputVAT, PriorPeriodInputVAT, AddCurrPriorPerInpVAT, AddCurrPriorPerOutVAT, PriorYearInputVAT, PriorYearOutputVAT : Decimal;
    begin
        PeriodicVATSettlementEntry.SetRange("VAT Period", VATPeriod);
        PeriodicVATSettlementEntry.SetRange("Activity Code", '');
        PeriodicVATSettlementEntry.FindFirst();
        PeriodicVATSettlementEntry2.SetRange("VAT Period", VATPeriod);
        PeriodicVATSettlementEntry2.SetFilter("Activity Code", '<>%1', '');
        if PeriodicVATSettlementEntry2.FindSet() then
            repeat
                PriorPeriodOutputVAT += PeriodicVATSettlementEntry2."Prior Period Output VAT";
                PriorPeriodInputVAT += PeriodicVATSettlementEntry2."Prior Period Input VAT";
                AddCurrPriorPerInpVAT += PeriodicVATSettlementEntry2."Add Curr. Prior Per. Inp. VAT";
                AddCurrPriorPerOutVAT += PeriodicVATSettlementEntry2."Add Curr. Prior Per. Out VAT";
                PriorYearInputVAT += PeriodicVATSettlementEntry2."Prior Year Input VAT";
                PriorYearOutputVAT += PeriodicVATSettlementEntry2."Prior Year Output VAT";
            until PeriodicVATSettlementEntry2.Next() = 0;
        Valid := (PeriodicVATSettlementEntry."Prior Period Input VAT" = PriorPeriodInputVAT) and
                 (PeriodicVATSettlementEntry."Prior Period Output VAT" = PriorPeriodOutputVAT) and
                 (PeriodicVATSettlementEntry."Add Curr. Prior Per. Inp. VAT" = AddCurrPriorPerInpVAT) and
                 (PeriodicVATSettlementEntry."Add Curr. Prior Per. Out VAT" = AddCurrPriorPerOutVAT) and
                 (PeriodicVATSettlementEntry."Prior Year Input VAT" = PriorYearInputVAT) and
                 (PeriodicVATSettlementEntry."Prior Year Output VAT" = PriorYearOutputVAT);
    end;
#endif

    internal procedure SetPeriod(NewPeriod: Code[10])
    begin
        Period := NewPeriod;
    end;
}