// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Foundation.Enums;

page 6060 "Contract Trendscape"
{
    Caption = 'Contract Trendscape';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = "Service Contract Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ContractNo; ContractNo)
                {
                    ApplicationArea = Service;
                    Caption = 'Contract No.';
                    ToolTip = 'Specifies billable profits for the project task that are related to items, expressed in the local currency.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Clear(ServContract);
                        ServContract.SetRange("Contract Type", ServContract."Contract Type"::Contract);
                        ServContract."Contract No." := ContractNo;
                        if PAGE.RunModal(0, ServContract) = ACTION::LookupOK then begin
                            Rec.Get(ServContract."Contract Type"::Contract, ServContract."Contract No.");
                            Rec.SetRange("Contract Type", Rec."Contract Type"::Contract);
                            Rec.SetRange("Contract No.", ServContract."Contract No.");
                            ContractNo := ServContract."Contract No.";
                            CurrPage.Update(false);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Clear(ServContract);
                        ServContract.SetRange("Contract Type", ServContract."Contract Type"::Contract);
                        ServContract.SetRange("Contract No.", ContractNo);
                        if ServContract.FindFirst() then begin
                            Rec.Get(ServContract."Contract Type"::Contract, ServContract."Contract No.");
                            Rec.SetRange("Contract No.", ServContract."Contract No.");
                            Rec.SetRange("Contract Type", Rec."Contract Type"::Contract);
                            ContractNo := ServContract."Contract No.";
                        end;
                        ContractNoOnAfterValidate();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer in the service contract.';
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Service;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        if PeriodType = PeriodType::"Accounting Period" then
                            PeriodPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Year then
                            YearPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Quarter then
                            QuarterPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Month then
                            MonthPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Week then
                            WeekPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Day then
                            DayPeriodTypeOnValidate();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Service;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        if AmountType = AmountType::"Balance at Date" then
                            BalanceatDateAmountTypeOnValid();
                        if AmountType = AmountType::"Net Change" then
                            NetChangeAmountTypeOnValidate();
                    end;
                }
            }
            part(TrendLines; "Contract Trend Lines")
            {
                ApplicationArea = Service;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        ContractNo := Rec."Contract No.";
        UpdateSubForm();
    end;

    var
        ServContract: Record "Service Contract Header";
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        ContractNo: Code[20];

    local procedure UpdateSubform()
    begin
        CurrPage.TrendLines.PAGE.SetLines(Rec, PeriodType, AmountType);
    end;

    local procedure ContractNoOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure DayPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure WeekPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure MonthPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure QuarterPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure YearPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure PeriodPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure BalanceatDateAmountTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure NetChangeAmountTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure DayPeriodTypeOnValidate()
    begin
        DayPeriodTypeOnPush();
    end;

    local procedure WeekPeriodTypeOnValidate()
    begin
        WeekPeriodTypeOnPush();
    end;

    local procedure MonthPeriodTypeOnValidate()
    begin
        MonthPeriodTypeOnPush();
    end;

    local procedure QuarterPeriodTypeOnValidate()
    begin
        QuarterPeriodTypeOnPush();
    end;

    local procedure YearPeriodTypeOnValidate()
    begin
        YearPeriodTypeOnPush();
    end;

    local procedure PeriodPeriodTypeOnValidate()
    begin
        PeriodPeriodTypeOnPush();
    end;

    local procedure NetChangeAmountTypeOnValidate()
    begin
        NetChangeAmountTypeOnPush();
    end;

    local procedure BalanceatDateAmountTypeOnValid()
    begin
        BalanceatDateAmountTypeOnPush();
    end;
}

