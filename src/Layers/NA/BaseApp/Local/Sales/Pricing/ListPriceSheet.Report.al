// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Customer;
using System.Utilities;

report 10148 "List Price Sheet"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Pricing/ListPriceSheet.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'List Price Sheet';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Inventory Posting Group", "Variant Filter";
            column(MainTitle; MainTitle)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(SalesPrice_FIELDCAPTION__Currency_Code____________Currency_Code; SalesPrice.FieldCaption("Currency Code") + ': ' + Currency.Code)
            {
            }
            column(CustPriceGr_TABLECAPTION__________CustPriceGrCode; CustPriceGr.TableCaption + ': ' + CustPriceGrCode)
            {
            }
            column(All_Customers_; 'All Customers')
            {
            }
            column(Cust_TABLECAPTION__________CustNo; Cust.TableCaption + ': ' + CustNo)
            {
            }
            column(Campaign_TABLECAPTION__________CampNo; Campaign.TableCaption + ': ' + CampNo)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Currency_Code; Currency.Code)
            {
            }
            column(ShowSalesType; ShowSalesType)
            {
            }
            column(CustPriceGrCode; CustPriceGrCode)
            {
            }
            column(CustNo; CustNo)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(CampNo; CampNo)
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(Sales_Price__Unit_of_Measure_Code_Caption; "Sales Price".FieldCaption("Unit of Measure Code"))
            {
            }
            column(Sales_Price__Variant_Code_Caption; "Sales Price".FieldCaption("Variant Code"))
            {
            }
            column(Sales_Price__Minimum_Quantity_Caption; "Sales Price".FieldCaption("Minimum Quantity"))
            {
            }
            column(Sales_Price__Unit_Price_Caption; "Sales Price".FieldCaption("Unit Price"))
            {
            }
            column(Sales_Price__Starting_Date_Caption; "Sales Price".FieldCaption("Starting Date"))
            {
            }
            column(Sales_Price__Ending_Date_Caption; "Sales Price".FieldCaption("Ending Date"))
            {
            }
            dataitem("Sales Price"; "Sales Price")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter");
                DataItemTableView = sorting("Item No.", "Sales Type", "Sales Code", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity");
                column(Sales_Price__Unit_of_Measure_Code_; "Unit of Measure Code")
                {
                }
                column(Sales_Price__Variant_Code_; "Variant Code")
                {
                }
                column(Sales_Price__Minimum_Quantity_; "Minimum Quantity")
                {
                }
                column(Sales_Price__Unit_Price_; "Unit Price")
                {
                }
                column(Sales_Price__Starting_Date_; "Starting Date")
                {
                }
                column(Sales_Price__Ending_Date_; "Ending Date")
                {
                }
                column(Sales_Price_Item_No_; "Item No.")
                {
                }
                column(Sales_Price_Sales_Type; "Sales Type")
                {
                }
                column(Sales_Price_Sales_Code; "Sales Code")
                {
                }
                column(Sales_Price_Currency_Code; "Currency Code")
                {
                }
                column(AnySalesPriceFound_; AnySalesPriceFound)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Unit of Measure Code" = '' then
                        "Unit of Measure Code" := Item."Base Unit of Measure";

                    if "Currency Code" <> Currency.Code then
                        "Unit Price" :=
                          CurrencyExchRate.ExchangeAmtFCYToFCY(DateReq, "Currency Code", Currency.Code, "Unit Price");
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Sales Type", SalesType);

                    SetRange("Sales Code", SalesCode);
                    SetFilter("Currency Code", '%1|%2', Currency.Code, '');
                    SetRange("Starting Date", 0D, DateReq);
                    SetFilter("Ending Date", '%1|%2..', 0D, DateReq);
                    AnySalesPriceFound := Find('+');
                    if AnySalesPriceFound then begin
                        SetRange("Starting Date", "Starting Date");
                        SetRange("Ending Date");
                    end else
                        CurrReport.Break();
                end;
            }
            dataitem(NoSalesPrice; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Sales_Price___Unit_Price_; "Sales Price"."Unit Price")
                {
                }
                column(Sales_Price___Unit_of_Measure_Code_; "Sales Price"."Unit of Measure Code")
                {
                }
                column(NoSalesPrice_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear("Sales Price");
                    "Sales Price"."Unit Price" := Item."Unit Price";
                    "Sales Price"."Unit of Measure Code" := Item."Base Unit of Measure";
                    if "Sales Price"."Currency Code" <> Currency.Code then
                        "Sales Price"."Unit Price" :=
                          CurrencyExchRate.ExchangeAmtFCYToFCY(
                            DateReq, "Sales Price"."Currency Code", Currency.Code, "Sales Price"."Unit Price");
                end;

                trigger OnPreDataItem()
                begin
                    if AnySalesPriceFound then
                        CurrReport.Break();
                end;
            }

            trigger OnPreDataItem()
            begin
                CustNo := '';
                CustPriceGrCode := '';
                CampNo := '';
                ShowSalesType := 0;
                case SalesType of
                    SalesType::Customer:
                        begin
                            Cust.Get(SalesCode);
                            CustNo := Cust."No.";
                            CustPriceGrCode := Cust."Customer Price Group";
                            ShowSalesType := 1;
                        end;
                    SalesType::"Customer Price Group":
                        begin
                            CustPriceGr.Get(SalesCode);
                            CustPriceGrCode := SalesCode;
                            ShowSalesType := 2;
                        end;
                    SalesType::Campaign:
                        begin
                            Campaign.Get(SalesCode);
                            CampNo := Campaign."No.";
                            ShowSalesType := 3;
                        end;
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DateReq; DateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date';
                        ToolTip = 'Specifies the date when the prices are valid.';
                    }
                    field(SalesType; SalesType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Type';
                        OptionCaption = 'Customer,Customer Price Group,All Customers,Campaign';
                        ToolTip = 'Specifies the type of sales that you want to print on the report, such as customer or campaign.';

                        trigger OnValidate()
                        begin
                            SalesCodeCtrlEnable := (SalesType <> SalesType::"All Customers");
                            SalesCode := '';
                        end;
                    }
                    field(SalesCodeCtrl; SalesCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Code';
                        Enabled = SalesCodeCtrlEnable;
                        ToolTip = 'Specifies the customer or the campaign that you want to include in the report. The available options depend on your selection in the Sales Type field.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            CustList: Page "Customer List";
                            CustPriceGrList: Page "Customer Price Groups";
                            CampList: Page "Campaign List";
                        begin
                            case SalesType of
                                SalesType::Customer:
                                    begin
                                        CustList.LookupMode := true;
                                        CustList.SetRecord(Cust);
                                        if CustList.RunModal() = ACTION::LookupOK then begin
                                            CustList.GetRecord(Cust);
                                            SalesCode := Cust."No.";
                                        end;
                                    end;
                                SalesType::"Customer Price Group":
                                    begin
                                        CustPriceGrList.LookupMode := true;
                                        CustPriceGrList.SetRecord(CustPriceGr);
                                        if CustPriceGrList.RunModal() = ACTION::LookupOK then begin
                                            CustPriceGrList.GetRecord(CustPriceGr);
                                            SalesCode := CustPriceGr.Code;
                                        end;
                                    end;
                                SalesType::Campaign:
                                    begin
                                        CampList.LookupMode := true;
                                        CampList.SetRecord(Campaign);
                                        if CampList.RunModal() = ACTION::LookupOK then begin
                                            CampList.GetRecord(Campaign);
                                            SalesCode := Campaign."No.";
                                        end;
                                    end;
                            end;
                        end;
                    }
                    field("Currency.Code"; Currency.Code)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Currency Code';
                        TableRelation = Currency;
                        ToolTip = 'Specifies the currency that prices are shown in.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            SalesCodeCtrlEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if DateReq = 0D then
                DateReq := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureEnabled();
    end;

    trigger OnPreReport()
    begin
        MainTitle := StrSubstNo(Text000, DateReq);
        CompanyInformation.Get();
        SubTitle := StrSubstNo(Text001, CompanyInformation."Phone No.");
        if CustPriceGr.Code <> '' then
            CustPriceGr.Find();
        if Currency.Code = '' then
            CurrencyExchRate."Exchange Rate Amount" := 100
        else begin
            Currency.Find();
            CurrencyExchRate.SetRange("Currency Code", Currency.Code);
            CurrencyExchRate.SetRange("Starting Date", 0D, WorkDate());
            CurrencyExchRate.FindLast();
        end;
        ItemFilter := Item.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        CustPriceGr: Record "Customer Price Group";
        Cust: Record Customer;
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        SalesPrice: Record "Sales Price";
        Campaign: Record Campaign;
        DateReq: Date;
        MainTitle: Text[132];
        SubTitle: Text[132];
        ItemFilter: Text;
        Text000: Label 'List Price Sheet as of %1';
        Text001: Label 'Phone: %1';
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
        SalesCode: Code[20];
        CustNo: Code[20];
        CustPriceGrCode: Code[20];
        CampNo: Code[20];
        AnySalesPriceFound: Boolean;
        ShowSalesType: Integer;
        SalesCodeCtrlEnable: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}
