// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Foundation.Enums;

page 5983 "Service Item Trendscape"
{
    Caption = 'Service Item Trendscape';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = "Service Item";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ServItemNo; ServItemNo)
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item No.';
                    ToolTip = 'Specifies the number of the service ledger entry that is related to a specific service item.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Clear(ServItem);
                        ServItem."No." := ServItemNo;
                        if PAGE.RunModal(0, ServItem) = ACTION::LookupOK then begin
                            Rec.Get(ServItem."No.");
                            Rec.SetRange("No.", ServItem."No.");
                            ServItemNo := ServItem."No.";
                            CurrPage.Update(false);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Clear(ServItem);
                        ServItem."No." := ServItemNo;
                        if ServItem.FindFirst() then begin
                            Rec.Get(ServItem."No.");
                            Rec.SetRange("No.", ServItem."No.");
                            ServItemNo := ServItem."No.";
                        end;
                        ServItemNoOnAfterValidate();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies a description of this item.';
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
            part(ServLedgEntry; "Service Item Trend Lines")
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
        ServItemNo := Rec."No.";
        UpdateSubForm();
    end;

    var
        ServItem: Record "Service Item";
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        ServItemNo: Code[20];

    local procedure UpdateSubForm()
    begin
        CurrPage.ServLedgEntry.PAGE.SetLines(Rec, PeriodType, AmountType);
    end;

    local procedure ServItemNoOnAfterValidate()
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

