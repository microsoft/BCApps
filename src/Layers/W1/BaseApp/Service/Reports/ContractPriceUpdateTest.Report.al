// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Service.Contract;
using System.Utilities;

report 5985 "Contract Price Update - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ContractPriceUpdateTest.rdlc';
    Caption = 'Contract Price Update - Test';

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            CalcFields = Name;
            DataItemTableView = sorting("Next Price Update Date") where("Contract Type" = const(Contract), Status = const(Signed), "Change Status" = const(Locked));
            RequestFilterFields = "Contract No.", "Item Filter";
            RequestFilterHeading = 'Service Contract';
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(UpdateToDate; Format(UpdateToDate))
            {
            }
            column(PriceUpdPct; PriceUpdPct)
            {
            }
            column(Service_Contract_Header__TABLECAPTION__________ServContractFilters; TableCaption + ': ' + ServContractFilters)
            {
            }
            column(ServContractFilters; ServContractFilters)
            {
            }
            column(Service_Contract_Header__Contract_No__; "Contract No.")
            {
            }
            column(Service_Contract_Header__Customer_No__; "Customer No.")
            {
            }
            column(Service_Contract_Header_Name; Name)
            {
            }
            column(MsgTxt; MsgTxt)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Contract_Price_Update___TestCaption; Contract_Price_Update___TestCaptionLbl)
            {
            }
            column(Update_to_dateCaption; Update_to_dateCaptionLbl)
            {
            }
            column(PriceUpdPctCaption; PriceUpdPctCaptionLbl)
            {
            }
            column(Service_Contract_Header__Contract_No__Caption; FieldCaption("Contract No."))
            {
            }
            column(Service_Contract_Header__Customer_No__Caption; FieldCaption("Customer No."))
            {
            }
            column(Service_Contract_Header_NameCaption; FieldCaption(Name))
            {
            }
            column(Price_Update_DateCaption; Price_Update_DateCaptionLbl)
            {
            }
            column(Update_Caption; Update_CaptionLbl)
            {
            }
            column(Old_Annual_AmountCaption; Old_Annual_AmountCaptionLbl)
            {
            }
            column(New_Annual_AmountCaption; New_Annual_AmountCaptionLbl)
            {
            }
            column(MsgTxtCaption; MsgTxtCaptionLbl)
            {
            }
            column(Amount_DifferenceCaption; Amount_DifferenceCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(OldUpdateDate; Format(OldUpdateDate))
                {
                }
                column(OldAnnualAmount; OldAnnualAmount)
                {
                    AutoFormatType = 1;
                }
                column(PriceUpdPct_Control23; PriceUpdPct)
                {
                }
                column(NewAnnualAmount; NewAnnualAmount)
                {
                }
                column(Diff; Diff)
                {
                }
                column(Diff_Control10; Diff)
                {
                }
                column(Total_Caption; Total_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Format(ServContract."Price Update Period") = '' then
                        CurrReport.Break();

                    if NewAnnualAmount > 0 then begin
                        OldAnnualAmount := NewAnnualAmount;
                        OldUpdateDate := CalcDate(ServContract."Price Update Period", OldUpdateDate);
                        OldAnnualAmount2 := OldAnnualAmount;
                        OldUpdateDate2 := OldUpdateDate;
                    end;

                    NewAnnualAmount := 0;

                    if TempServContractLine.Find('-') then
                        repeat
                            TempServContractLine.SuspendStatusCheck(true);
                            TempServContractLine.Validate(
                              "Line Value",
                              Round(
                                TempServContractLine."Line Value" + (TempServContractLine."Line Value" * PriceUpdPct / 100),
                                Currency."Amount Rounding Precision"));
                            OnBeforeTempServiceContractLineModify(TempServContractLine, "Service Contract Header", UpdateToDate, PriceUpdPct);
                            TempServContractLine.Modify(true);
                            NewAnnualAmount := NewAnnualAmount + TempServContractLine."Line Amount";
                        until TempServContractLine.Next() = 0;

                    if NewAnnualAmount <= 0 then begin
                        OldAnnualAmount := OldAnnualAmount2;
                        OldAnnualAmount2 := NewAnnualAmount;
                        OldUpdateDate := OldUpdateDate2;
                        OldUpdateDate2 := CalcDate(ServContract."Price Update Period", OldUpdateDate);
                    end;

                    Diff := NewAnnualAmount - OldAnnualAmount;

                    if OldUpdateDate > UpdateToDate then begin
                        NewAnnualAmount := 0;
                        CurrReport.Break();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(Diff);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempServContractLine.DeleteAll();
                OldAnnualAmount := 0;
                OldAnnualAmount2 := 0;

                ServContract.Get("Contract Type", "Contract No.");
                MsgTxt := '';
                ServContract.CopyFilters("Service Contract Header");
                OldUpdateDate := "Next Price Update Date";
                OldUpdateDate2 := "Next Price Update Date";
                if Format(ServContract."Price Update Period") = '' then
                    MsgTxt := Text005;
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                ServContractLine.SetRange("Contract No.", ServContract."Contract No.");
                if ServContract.GetFilter("Item Filter") <> '' then
                    ServContractLine.SetFilter("Item No.", ServContract.GetFilter("Item Filter"));
                if ServContractLine.Find('-') then
                    repeat
                        OldAnnualAmount += ServContractLine."Line Amount";
                        OldAnnualAmount2 += ServContractLine."Line Amount";
                        TempServContractLine := ServContractLine;
                        TempServContractLine.Insert();
                    until ServContractLine.Next() = 0;
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if PriceUpdPct = 0 then
                    Error(Text000);

                if PriceUpdPct > 10 then
                    if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                        Error(Text002);

                if UpdateToDate = 0D then
                    Error(Text003);

                SetFilter("Next Price Update Date", '<>%1&<=%2', 0D, UpdateToDate);

                Currency.InitRoundingPrecision();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Contract Price Update - Test';
        AboutText = 'Get an overview of service contracts that need price updates up to a date that you specify.';
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
                        ToolTip = 'Specifies the date up to which you want to update prices. The report includes contracts with next price update dates on or before this date.';
                    }
                    field("Price Update %"; PriceUpdPct)
                    {
                        ApplicationArea = Service;
                        Caption = 'Price Update %';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the price update for the service item contract values in percentages.';
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
        if UpdateToDate = 0D then
            UpdateToDate := WorkDate();
    end;

    trigger OnPreReport()
    begin
        ServContractFilters := "Service Contract Header".GetFilters();
    end;

    var
        ServContract: Record "Service Contract Header";
        Currency: Record Currency;
        ServContractLine: Record "Service Contract Line";
        TempServContractLine: Record "Service Contract Line" temporary;
        MsgTxt: Text[80];
        ServContractFilters: Text;
        OldAnnualAmount: Decimal;
        OldAnnualAmount2: Decimal;
        NewAnnualAmount: Decimal;
        PriceUpdPct: Decimal;
        Diff: Decimal;
        OldUpdateDate: Date;
        OldUpdateDate2: Date;
        UpdateToDate: Date;

#pragma warning disable AA0074
        Text000: Label 'You must fill in the Price Update % field.';
        Text001: Label 'The price update % is unusually large.\\Do you want to update it anyway?';
        Text002: Label 'The program has stopped the batch job at your request.';
        Text003: Label 'You must fill in the Update to Date field.';
        Text005: Label 'The price update period is empty.';
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Contract_Price_Update___TestCaptionLbl: Label 'Contract Price Update - Test';
        Update_to_dateCaptionLbl: Label 'Update to Date';
        PriceUpdPctCaptionLbl: Label 'Next Price Update %';
        Price_Update_DateCaptionLbl: Label 'Price Update Date';
        Update_CaptionLbl: Label 'Update%';
        Old_Annual_AmountCaptionLbl: Label 'Old Annual Amount';
        New_Annual_AmountCaptionLbl: Label 'New Annual Amount';
        MsgTxtCaptionLbl: Label 'Message';
        Amount_DifferenceCaptionLbl: Label 'Amount Difference';
        Total_CaptionLbl: Label 'Total:';

    procedure InitVariables(LocalPriceUpdPct: Decimal; LocalUpdateToDate: Date)
    begin
        PriceUpdPct := LocalPriceUpdPct;
        UpdateToDate := LocalUpdateToDate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempServiceContractLineModify(var TempServiceContractLine: Record "Service Contract Line" temporary; ServiceContractHeader: Record "Service Contract Header"; UpdateToDate: Date; PriceUpdPct: Decimal)
    begin
    end;
}

