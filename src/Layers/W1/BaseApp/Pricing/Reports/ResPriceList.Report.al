// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Utilities;

report 7054 "Res. Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Pricing/Reports/ResPriceList.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Resource Price List';
    PreviewMode = PrintLayout;
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
            column(StrsubsnoAsofFormatWorkDt; StrSubstNo(AsOfTok, Format(DateReq, 0, 4)))
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
            column(ResFldCaptUnitPriceCurrTxt; FieldCaption("Unit Price") + CurrencyText)
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
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(UnitPrice_ResPrice; UnitPrice)
                {
                    AutoFormatType = 2;
                }
                column(WorkTypeCode_ResPrice; WorkType.Code)
                {
                }
                column(Description_WorkType; WorkType.Description)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        Ok := TempWorkTypePriceListLine.FindSet()
                    else
                        Ok := TempWorkTypePriceListLine.Next() <> 0;
                    if not Ok then
                        CurrReport.Break();

                    if not FindPrice(TempWorkTypePriceListLine."Work Type Code") then
                        CurrReport.Skip();

                    WorkType.Get(TempPriceListLine."Work Type Code");

                    UnitPrice := TempPriceListLine."Unit Price";
                    if (Currency.Code <> '') and (TempPriceListLine."Currency Code" = '') then
                        UnitPrice :=
                          Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              DateReq, Currency.Code, UnitPrice,
                              CurrExchRate.ExchangeRate(
                                DateReq, Currency.Code)),
                            Currency."Unit-Amount Rounding Precision");
                end;

                trigger OnPostDataItem()
                begin
                    TempWorkTypePriceListLine.Reset();
                    TempWorkTypePriceListLine.SetFilter("Asset No.", '<>%1', '');
                    TempWorkTypePriceListLine.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    TempWorkTypePriceListLine.Reset();
                end;
            }

            trigger OnAfterGetRecord()
            var
                PriceListLine: Record "Price List Line";
            begin
                if FindPrice('') then
                    "Unit Price" := TempPriceListLine."Unit Price";
                if (Currency.Code <> '') and (TempPriceListLine."Currency Code" = '') then
                    "Unit Price" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          DateReq, Currency.Code, "Unit Price",
                          CurrExchRate.ExchangeRate(
                            DateReq, Currency.Code)),
                        Currency."Unit-Amount Rounding Precision");

                PriceListLine.SetRange("Asset Type", "Price Asset Type"::Resource);
                PriceListLine.SetRange("Asset No.", "No.");
                FindWorkTypes(PriceListLine);
                PriceListLine.SetRange("Asset Type", "Price Asset Type"::"Resource Group");
                PriceListLine.SetRange("Asset No.", "Resource Group No.");
                FindWorkTypes(PriceListLine);
            end;

            trigger OnPreDataItem()
            var
                PriceListLine: Record "Price List Line";
                LineNo: Integer;
            begin
                PriceListLine.SetFilter("Currency Code", '%1|%2', Currency.Code, '');
                PriceListLine.SetRange("Asset Type", "Price Asset Type"::Resource);
                PriceListLine.SetRange("Asset No.", '');
                PriceListLine.SetFilter("Work Type Code", '<>%1', '');
                if PriceListLine.FindSet() then
                    repeat
                        TempWorkTypePriceListLine.Init();
                        TempWorkTypePriceListLine."Asset Type" := PriceListLine."Asset Type";
                        TempWorkTypePriceListLine."Work Type Code" := PriceListLine."Work Type Code";
                        LineNo += 1;
                        TempWorkTypePriceListLine."Line No." := LineNo;
                        TempWorkTypePriceListLine.Insert();
                    until PriceListLine.Next() = 0;
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
                    field(Date; DateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date';
                        ToolTip = 'Specifies the period for which the prices apply, such as 10/01/20...12/31/20.';
                    }
                    field(Method; PriceCalcMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation Method';
                        ToolTip = 'Specifies the price calculation method.';

                        trigger OnValidate()
                        begin
                            ValidateMethod();
                        end;
                    }
                    field(Handler; format(PriceCalculationHandler))
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation Handler';
                        ToolTip = 'Specifies the price calculation handler that is defined for the calculation of sales prices for the selected method.';

                        trigger OnAssistEdit()
                        begin
                            Page.RunModal(Page::"Price Calculation Methods");
                        end;
                    }
                    field(SourceTypeCtrl; SourceType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assign-to Type';
                        ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                        trigger OnValidate()
                        begin
                            PriceSource.Validate("Source Type", SourceType.AsInteger());
                            SourceNoCtrlEnable := PriceSource.IsSourceNoAllowed();
                            ParentSourceNo := PriceSource."Parent Source No.";
                            SourceNo := PriceSource."Source No.";
                        end;
                    }
                    field(ParentSourceNoCtrl; ParentSourceNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assign-to Project No.';
                        Editable = false;
                        ToolTip = 'Specifies the project to which the prices are assigned. If you choose an entity, the price list will be used only for that entity.';
                    }
                    field(SourceNoCtrl; SourceNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assign-to';
                        Enabled = SourceNoCtrlEnable;
                        ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';

                        trigger OnLookup(var Text: Text) Result: Boolean
                        begin
                            Result := PriceSource.LookupNo();
                            if Result then begin
                                ParentSourceNo := PriceSource."Parent Source No.";
                                SourceNo := PriceSource."Source No.";
                                LookupIsComplete := true;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if LookupIsComplete then begin
                                SourceNo := PriceSource."Source No.";
                                ParentSourceNo := PriceSource."Parent Source No.";
                            end;
                            if (SourceNo = '') and SourceNoCtrlEnable then
                                Error(MissSourceNoErr);

                            PriceSource.Validate("Source No.", SourceNo);
                            LookupIsComplete := false;

                            Currency.Code := PriceSource."Currency Code";
                            ParentSourceNo := PriceSource."Parent Source No.";
                            SourceNo := PriceSource."Source No.";
                        end;
                    }
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

        trigger OnOpenPage()
        begin
            if SourceType.AsInteger() = 0 then
                SourceType := SourceType::"All Jobs";
            if DateReq = 0D then
                DateReq := WorkDate();

            PriceSource.Validate("Source Type", SourceType);
            SourceNoCtrlEnable := PriceSource.IsSourceNoAllowed();
        end;

        trigger OnAfterGetCurrRecord()
        begin
            ValidateMethod();
        end;
    }

    labels
    {
        EMailIdCaption = 'EMail';
        HomePageCaption = 'Home Page';
    }

    trigger OnPreReport()
    begin
        if (SourceNo = '') and SourceNoCtrlEnable then
            Error(MissSourceNoErr);
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);
        if Currency.Code <> '' then
            CurrencyText := ' (' + Currency.Code + ')';

        PriceSource.Validate("Source Type", SourceType);
        PriceSource.Validate("Parent Source No.", ParentSourceNo);
        PriceSource.Validate("Source No.", SourceNo);
        PriceSource."Currency Code" := Currency.Code;
    end;

    protected var
        Currency: Record Currency;
        PriceSource: Record "Price Source";
        WorkType: Record "Work Type";
        TempPriceListLine: Record "Price List Line" temporary;
        TempWorkTypePriceListLine: Record "Price List Line" temporary;
        DateReq: Date;

    var
        CompanyInfo: Record "Company Information";
        CurrExchRate: Record "Currency Exchange Rate";
        FormatAddr: Codeunit "Format Address";
        PriceCalcMethod: Enum "Price Calculation Method";
        PriceCalculationHandler: Enum "Price Calculation Handler";
        SourceType: Enum "Price Source Type";
        CompanyAddr: array[8] of Text[100];
        LookupIsComplete: Boolean;
        Ok: Boolean;
        CurrencyText: Text[30];
        SourceNoCtrlEnable: Boolean;
        ParentSourceNo: Code[20];
        SourceNo: Code[20];
        UnitPrice: Decimal;
        AsOfTok: Label 'As of %1', Comment = '%1 - a date';
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
        MissSourceNoErr: Label 'You must specify an Assign-to, if the Assign-to Type is different from All Projects.';

    local procedure FindPrice(WorkTypeCode: Code[10]): Boolean;
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceSourceList: Codeunit "Price Source List";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
    begin
        SalesLine.Init();
        SalesLine.Type := SalesLine.Type::Resource;
        SalesLine."No." := Resource."No.";
        SalesLine."Work Type Code" := WorkTypeCode;
        SalesLine."Posting Date" := DateReq;
        if Currency.Code <> '' then begin
            SalesHeader."Posting Date" := DateReq;
            SalesHeader."Currency Code" := Currency.Code;
            SalesHeader.UpdateCurrencyFactor();
        end;
        SalesLine.GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);
        GetSourceList(PriceSourceList);
        LineWithPrice.SetSources(PriceSourceList);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);

        TempPriceListLine.Reset();
        TempPriceListLine.DeleteAll();
        Clear(TempPriceListLine);
        exit(PriceCalculation.FindPrice(TempPriceListLine, false));
    end;

    local procedure GetSourceList(var PriceSourceList: Codeunit "Price Source List")
    begin
        PriceSourceList.Add("Price Source Type"::"All Customers");

        if SourceType = SourceType::Job then
            PriceSourceList.AddJobAsSources(SourceNo, '')
        else
            if SourceType = SourceType::"Job Task" then
                PriceSourceList.AddJobAsSources(ParentSourceNo, SourceNo)
    end;

    local procedure GetPriceHandler(Method: Enum "Price Calculation Method"): Enum "Price Calculation Handler";
    var
        PriceCalculationSetup: record "Price Calculation Setup";
    begin
        if PriceCalculationSetup.FindDefault(Method, PriceCalculationSetup.Type::Sale) then
            exit(PriceCalculationSetup.Implementation);
    end;

    local procedure ValidateMethod()
    begin
        if PriceCalcMethod = PriceCalcMethod::" " then
            PriceCalcMethod := PriceCalcMethod::"Lowest Price";
        PriceCalculationHandler := GetPriceHandler(PriceCalcMethod);
    end;

    local procedure FindWorkTypes(var PriceListLine: Record "Price List Line")
    var
        LineNo: Integer;
    begin
        TempWorkTypePriceListLine.Reset();
        if TempWorkTypePriceListLine.FindLast() then
            LineNo := TempWorkTypePriceListLine."Line No.";

        PriceListLine.SetFilter("Work Type Code", '<>%1', '');
        if PriceListLine.FindSet() then
            repeat
                TempWorkTypePriceListLine.SetRange("Work Type Code", PriceListLine."Work Type Code");
                if TempWorkTypePriceListLine.IsEmpty() then begin
                    TempWorkTypePriceListLine."Asset Type" := PriceListLine."Asset Type";
                    TempWorkTypePriceListLine."Asset No." := PriceListLine."Asset No.";
                    TempWorkTypePriceListLine."Work Type Code" := PriceListLine."Work Type Code";
                    LineNo += 1;
                    TempWorkTypePriceListLine."Line No." := LineNo;
                    TempWorkTypePriceListLine.Insert();
                end;
            until PriceListLine.Next() = 0;
    end;

    procedure InitializeRequest(NewDateReq: Date; NewSourceType: Enum "Job Price Source Type"; NewSourceNo: Code[20]; NewCurrencyCode: Code[10])
    begin
        DateReq := NewDateReq;
        SourceType := "Price Source Type".FromInteger(NewSourceType.AsInteger());
        SourceNo := NewSourceNo;
        Currency.Code := NewCurrencyCode;

        PriceSource.Validate("Source Type", SourceType);
        PriceSource.Validate("Source No.", SourceNo);
        PriceSource."Currency Code" := Currency.Code;
    end;
}

