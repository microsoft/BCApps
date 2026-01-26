// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Utilities;
using System.Utilities;

report 1115 "Resource - Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Resources/Reports/ResourcePriceList.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Resource - Price List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Resource; Resource)
        {
            RequestFilterFields = Type, "No.";
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(CompanyAddr7; CompanyAddr[7])
            {
            }
            column(CompanyAddr8; CompanyAddr[8])
            {
            }
            column(StrsubsnoAsofFormatWorkDt; StrSubstNo(Text004, Format(WorkDate(), 0, 4)))
            {
            }
            column(PhoneNo_CompanyInfo; CompanyInfo."Phone No.")
            {
            }
            column(VATResgNo_CompanyInfo; CompanyInfo."VAT Registration No.")
            {
            }
            column(GiroNo_CompanyInfo; CompanyInfo."Giro No.")
            {
            }
            column(BankName_CompanyInfo; CompanyInfo."Bank Name")
            {
            }
            column(BankAccNo_CompanyInfo; CompanyInfo."Bank Account No.")
            {
            }
            column(ResFldCaptUnitPriceCurrTxt; ResPrice.FieldCaption("Unit Price") + CurrencyText)
            {
            }
            column(No_Resource; "No.")
            {
            }
            column(Type_Resource; Type)
            {
                IncludeCaption = true;
            }
            column(UnitPrice_Resource; "Unit Price")
            {
            }
            column(HomePage_CompanyInfo; CompanyInfo."Home Page")
            {
            }
            column(Email_CompanyInfo; CompanyInfo."E-Mail")
            {
            }
            column(ResourceName; Name)
            {
            }
            column(ResourcePriceListCaption; ResourcePriceListCaptionLbl)
            {
            }
            column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(CompanyInfoVATRegistrationNoCaption; CompanyInfoVATRegistrationNoCaptionLbl)
            {
            }
            column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
            {
            }
            column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
            {
            }
            column(CompanyInfoBankAccountNoCaption; CompanyInfoBankAccountNoCaptionLbl)
            {
            }
            column(ResourceNoCaption; ResourceNoCaptionLbl)
            {
            }
            column(WorkTypeCaption; WorkTypeCaptionLbl)
            {
            }
            column(ResourceNameCaption; ResourceNameCaptionLbl)
            {
            }
            column(WorkTypeDescriptionCaption; WorkTypeDescriptionCaptionLbl)
            {
            }
            column(CompanyInfoBusinessIdCode; CompanyInfo."Business Identity Code")
            {
            }
            column(CompanyInfoRegHomeCity; CompanyInfo."Registered Home City")
            {
            }
            column(CompanyInfoBusinessIdentityCodeCaption; CompanyInfoBusinessIdentityCodeLbl)
            {
            }
            column(CompanyInfoRegisteredHomeCityCaption; CompanyInfoRegisteredHomeCityLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(UnitPrice_ResPrice; ResPrice."Unit Price")
                {
                    AutoFormatType = 2;
                }
                column(WorkTypeCode_ResPrice; ResPrice."Work Type Code")
                {
                }
                column(Description_WorkType; WorkType.Description)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PriceInCurrency := false;

                    if Number = 1 then
                        Ok := TempResourcePrice.Find('-')
                    else
                        Ok := TempResourcePrice.Next() <> 0;
                    if not Ok then
                        CurrReport.Break();
                    if TempResourcePrice."Work Type Code" = '' then
                        CurrReport.Skip();

                    ResPrice.Type := ResPrice.Type::Resource;
                    ResPrice.Code := Resource."No.";
                    ResPrice."Work Type Code" := TempResourcePrice."Work Type Code";
                    ResPrice."Currency Code" := Currency.Code;
                    CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResPrice);
                    WorkType.Get(ResPrice."Work Type Code");
                    PriceInCurrency := ResPrice."Currency Code" <> '';

                    if (Currency.Code <> '') and (not PriceInCurrency) then
                        ResPrice."Unit Price" :=
                          Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              WorkDate(), Currency.Code, ResPrice."Unit Price",
                              CurrExchRate.ExchangeRate(
                                WorkDate(), Currency.Code)),
                            Currency."Unit-Amount Rounding Precision");
                end;

                trigger OnPostDataItem()
                begin
                    TempResourcePrice.SetRange(Type, TempResourcePrice.Type::Resource, TempResourcePrice.Type::"Group(Resource)");
                    TempResourcePrice.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    ResPrice.SetFilter(Code, '%1|%2', Resource."No.", '');
                    TempResourcePrice.Reset();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PriceInCurrency := false;
                ResPrice."Currency Code" := Currency.Code;
                ResPrice.Code := "No.";
                ResPrice."Work Type Code" := '';
                CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResPrice);
                "Unit Price" := ResPrice."Unit Price";
                PriceInCurrency := ResPrice."Currency Code" <> '';
                if (Currency.Code <> '') and (not PriceInCurrency) then
                    "Unit Price" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          WorkDate(), Currency.Code, "Unit Price",
                          CurrExchRate.ExchangeRate(
                            WorkDate(), Currency.Code)),
                        Currency."Unit-Amount Rounding Precision");

                ResPrice.SetRange(Type, ResPrice.Type::Resource);
                ResPrice.SetRange(Code, "No.");
                FindWorkTypes();
                ResPrice.SetRange(Type, ResPrice.Type::"Group(Resource)");
                ResPrice.SetRange(Code, "Resource Group No.");
                FindWorkTypes();
            end;

            trigger OnPreDataItem()
            begin
                ResPrice.SetFilter("Currency Code", '%1|%2', Currency.Code, '');

                TempResourcePrice.Init();
                ResPrice.SetRange(Type, ResPrice.Type::All);
                if ResPrice.Find('-') then
                    repeat
                        TempResourcePrice.Type := ResPrice.Type;
                        TempResourcePrice."Work Type Code" := ResPrice."Work Type Code";
                        Ok := TempResourcePrice.Insert();
                    until ResPrice.Next() = 0;
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
                    field("Currency.Code"; Currency.Code)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Code';
                        TableRelation = Currency;
                        ToolTip = 'Specifies the code for the currency that amounts are shown in.';
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
        EMailIdCaption = 'EMail';
        HomePageCaption = 'Home Page';
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);
        if Currency.Code <> '' then
            CurrencyText := ' (' + Currency.Code + ')';
    end;

    var
        CompanyInfo: Record "Company Information";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ResPrice: Record "Resource Price";
        TempResourcePrice: Record "Resource Price" temporary;
        WorkType: Record "Work Type";
        FormatAddr: Codeunit "Format Address";
        CompanyAddr: array[8] of Text[100];
        PriceInCurrency: Boolean;
        Ok: Boolean;
        CurrencyText: Text[30];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'As of %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ResourcePriceListCaptionLbl: Label 'Resource - Price List';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccountNoCaptionLbl: Label 'Account No.';
        ResourceNoCaptionLbl: Label 'Resource No.';
        WorkTypeCaptionLbl: Label 'Work Type';
        ResourceNameCaptionLbl: Label 'Resource Name';
        WorkTypeDescriptionCaptionLbl: Label 'Work Type Description';
        CompanyInfoBusinessIdentityCodeLbl: Label 'Business Identity Code';
        CompanyInfoRegisteredHomeCityLbl: Label 'Registered Home City';

    local procedure FindWorkTypes()
    begin
        if ResPrice.Find('-') then
            repeat
                TempResourcePrice.SetRange("Work Type Code", ResPrice."Work Type Code");
                if not TempResourcePrice.Find('-') then begin
                    TempResourcePrice.Type := ResPrice.Type;
                    TempResourcePrice."Work Type Code" := ResPrice."Work Type Code";
                    Ok := TempResourcePrice.Insert();
                end;
            until ResPrice.Next() = 0;
    end;

    procedure InitializeRequest(CurrencyCodeFrom: Code[10])
    begin
        Currency.Code := CurrencyCodeFrom;
    end;
}
