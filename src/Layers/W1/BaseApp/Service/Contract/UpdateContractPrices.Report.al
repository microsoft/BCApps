// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.Currency;
using Microsoft.Service.Reports;
using Microsoft.Service.Setup;
using System.Utilities;

report 6031 "Update Contract Prices"
{
    ApplicationArea = Service;
    Caption = 'Update Service Contract Prices';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            CalcFields = Name, "Calcd. Annual Amount";
            DataItemTableView = sorting("Next Price Update Date") where("Contract Type" = const(Contract), Status = const(Signed), "Change Status" = const(Locked));
            RequestFilterFields = "Contract No.", "Item Filter";

            trigger OnAfterGetRecord()
            var
                NumberOfPeriods: Integer;
                IsHandled: Boolean;
            begin
                ServContract.Get("Contract Type", "Contract No.");
                ServContract.SuspendStatusCheck(true);
                UpdateServContract := true;

                OldAnnualAmount := "Annual Amount";

                "Last Price Update %" := PriceUpdPct;
                CalcFields("Calcd. Annual Amount");
                if Format("Price Update Period") = '' then
                    UpdateServContract := false;

                TotOldAnnualAmount := TotOldAnnualAmount + OldAnnualAmount;
                TotSignedAmount := TotSignedAmount + "Calcd. Annual Amount";

                TotContractLinesAmount := 0;
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                ServContractLine.SetRange("Contract No.", "Contract No.");
                if GetFilter("Item Filter") <> '' then
                    ServContractLine.SetFilter("Item No.", GetFilter("Item Filter"));
                if ServContractLine.Find('-') then
                    repeat
                        ServContractLine2 := ServContractLine;
                        ServContractLine.SuspendStatusCheck(true);
                        if UpdateServContract then begin
                            ServContractLine.Validate(
                              "Line Value",
                              Round(
                                ServContractLine."Line Value" + (ServContractLine."Line Value" * PriceUpdPct / 100),
                                Currency."Amount Rounding Precision"));

                            OnBeforeServiceContractLineModify(
                              ServContractLine, "Service Contract Header", UpdateToDate, PriceUpdPct);

                            if ServMgtSetup."Register Contract Changes" then
                                ServContractLine.LogContractLineChanges(ServContractLine2);
                            ServContractLine.Modify(true);
                        end;
                        TotContractLinesAmount := TotContractLinesAmount + ServContractLine."Line Amount";
                    until ServContractLine.Next() = 0;

                if UpdateServContract then begin
                    ServContract."Last Price Update Date" := WorkDate();
                    ServContract."Next Price Update Date" := CalcDate(ServContract."Price Update Period", ServContract."Next Price Update Date");
                    ServContract."Last Price Update %" := PriceUpdPct;
                    ContractGainLossEntry.CreateEntry(
                      "Service Contract Change Type"::"Price Update",
                      ServContract."Contract Type", ServContract."Contract No.",
                      TotContractLinesAmount - ServContract."Annual Amount", '');

                    ServContract."Annual Amount" := TotContractLinesAmount;
                    IsHandled := false;
                    OnBeforeCalcAnnualAmt(ServContract, IsHandled);
                    if not IsHandled then begin
                        NumberOfPeriods := ReturnNoOfPer(ServContract."Invoice Period");
                        if NumberOfPeriods = 0 then
                            ServContract."Amount per Period" := 0
                        else
                            ServContract."Amount per Period" :=
                                Round(ServContract."Annual Amount" / NumberOfPeriods, Currency."Amount Rounding Precision");
                    end;
                    if OldAnnualAmount <> ServContract."Annual Amount" then
                        ServContract."Print Increase Text" := true;
                    ServContract.Modify();
                    if ServMgtSetup."Register Contract Changes" then
                        ServContract.UpdContractChangeLog("Service Contract Header");
                    TotNewAmount := TotNewAmount + ServContract."Annual Amount";
                end;
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if PerformUpd = PerformUpd::"Print Only" then begin
                    Clear(ContractPriceUpdateTest);
                    ContractPriceUpdateTest.InitVariables(PriceUpdPct, UpdateToDate);
                    ContractPriceUpdateTest.SetTableView("Service Contract Header");
                    ContractPriceUpdateTest.RunModal();
                    CurrReport.Break();
                end;

                TotOldAnnualAmount := 0;
                TotNewAmount := 0;
                TotSignedAmount := 0;
                if PriceUpdPct = 0 then
                    Error(Text000);

                if PriceUpdPct > 10 then
                    if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                        Error(Text002);

                if UpdateToDate = 0D then
                    Error(Text003);

                SetFilter("Next Price Update Date", '<>%1&<=%2', 0D, UpdateToDate);

                Currency.InitRoundingPrecision();
                ServMgtSetup.Get();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UpdateToDate; UpdateToDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Update to Date';
                        ToolTip = 'Specifies the date up to which you want to update prices. The batch job includes contracts with next price update dates on or before this date.';
                    }
                    field("Price Update %"; PriceUpdPct)
                    {
                        ApplicationArea = Service;
                        Caption = 'Price Update %';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the price update for the service item contract values in percentages.';
                    }
                    field(PerformUpd; PerformUpd)
                    {
                        ApplicationArea = Service;
                        Caption = 'Action';
                        OptionCaption = 'Update Contract Prices,Print Only';
                        ToolTip = 'Specifies the desired action relating to updating service contract prices.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        UpdateToDate := WorkDate();
    end;

    var
        ServContract: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        ServContractLine2: Record "Service Contract Line";
        Currency: Record Currency;
        ServMgtSetup: Record "Service Mgt. Setup";
        ContractPriceUpdateTest: Report "Contract Price Update - Test";
        OldAnnualAmount: Decimal;
        TotOldAnnualAmount: Decimal;
        TotNewAmount: Decimal;
        TotSignedAmount: Decimal;
        TotContractLinesAmount: Decimal;
        PriceUpdPct: Decimal;
        UpdateToDate: Date;
        PerformUpd: Option "Update Contract Prices","Print Only";
        UpdateServContract: Boolean;

#pragma warning disable AA0074
        Text000: Label 'You must fill in the Price Update % field.';
        Text001: Label 'The price update % is unusually large.\\Confirm that this is the correct percentage.';
        Text002: Label 'The program has stopped the batch job at your request.';
        Text003: Label 'You must fill in the Update to Date field.';
#pragma warning restore AA0074

    procedure InitializeRequest(UpdateToDateFrom: Date; PricePercentage: Decimal; PerformUpdate: Option)
    begin
        UpdateToDate := UpdateToDateFrom;
        PriceUpdPct := PricePercentage;
        PerformUpd := PerformUpdate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceContractLineModify(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header"; UpdateToDate: Date; PriceUpdPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAnnualAmt(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;
}

