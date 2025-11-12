// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using System.Utilities;

report 24 "Sales Taxes Collected"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/SalesTax/SalesTaxesCollected.rdlc';
    Caption = 'Sales Taxes Collected';

    dataset
    {
        dataitem(ReportToJurisdiction; "Tax Jurisdiction")
        {
            DataItemTableView = sorting("Report-to Jurisdiction");

            trigger OnAfterGetRecord()
            begin
                if "Report-to Jurisdiction" = '' then
                    CurrReport.Skip();
                if "Report-to Jurisdiction" <> TempTaxJurisdiction.Code then begin
                    TempTaxJurisdiction.Code := "Report-to Jurisdiction";
                    if LookupTaxJurisdiction.Get("Report-to Jurisdiction") then
                        TempTaxJurisdiction.Description := LookupTaxJurisdiction.Description
                    else
                        TempTaxJurisdiction.Description := Text003;
                    TempTaxJurisdiction.Insert();
                end;
            end;

            trigger OnPostDataItem()
            begin
                NumReportTo := TempTaxJurisdiction.Count();
            end;

            trigger OnPreDataItem()
            begin
                TempTaxJurisdiction.DeleteAll();
                TempTaxJurisdiction.Init();
                SetFilter("Report-to Jurisdiction", ReportToFilter);
            end;
        }
        dataitem(CurReportTo; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem("Tax Jurisdiction"; "Tax Jurisdiction")
            {
                DataItemTableView = sorting(Code);
                RequestFilterFields = "Code", "Report-to Jurisdiction", "Tax Group Filter", "Date Filter";
                column(Title; Title)
                {
                }
                column(Time; Time)
                {
                }
                column(CompanyInfoName; CompanyInfo.Name)
                {
                }
                column(SubTitle; SubTitle)
                {
                }
                column(JurisFilters_TaxJurisdiction; TableCaption + ': ' + JurisFilters)
                {
                }
                column(JurisFilters; JurisFilters)
                {
                }
                column(RepType; ReportType)
                {
                }
                column(TblCptnCode; TableCaption + ' ' + FieldCaption(Code) + ': ' + Code)
                {
                }
                column(Desc_TaxJurisdiction; Description)
                {
                }
                column(Rep_TaxJurisdiction; "Report-to Jurisdiction")
                {
                }
                column(RepJurisdiction; StrSubstNo(Text004, FieldCaption("Report-to Jurisdiction"), "Report-to Jurisdiction"))
                {
                }
                column(SalesTaxAmt; SalesTaxAmount)
                {
                    AutoFormatType = 1;
                }
                column(Code_TaxJurisdiction; Code)
                {
                }
                column(DateFilter_TaxJurisdiction; "Date Filter")
                {
                }
                column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
                {
                }
                column(SalesTaxAmountControl3Caption; SalesTaxAmountControl3CaptionLbl)
                {
                }
                column(TaxableSalesAmountCaption; TaxableSalesAmountCaptionLbl)
                {
                }
                column(NonTaxableSalesAmountCaption; NonTaxableSalesAmountCaptionLbl)
                {
                }
                column(ExemptSalesAmountCaption; ExemptSalesAmountCaptionLbl)
                {
                }
                column(TaxJurisdictionDescriptionCaption; TaxJurisdictionDescriptionCaptionLbl)
                {
                }
                column(VATEntryTaxGroupUsedCaption; VATEntryTaxGroupUsedCaptionLbl)
                {
                }
                column(VATEntryPostingDateCaption; VATEntryPostingDateCaptionLbl)
                {
                }
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemLink = "Tax Jurisdiction Code" = field(Code), "Tax Group Used" = field("Tax Group Filter"), "Posting Date" = field("Date Filter");
                    DataItemTableView = sorting("Tax Jurisdiction Code", "Tax Group Used", "Tax Type", "Use Tax", "Posting Date") where("Tax Type" = const("Sales Tax"));
                    column(Code_TaxGroupUsed; FieldCaption("Tax Group Code") + ': ' + "Tax Group Used")
                    {
                    }
                    column(TaxGroupDesc; TaxGroup.Description)
                    {
                    }
                    column(SalesTaxAmtControl3; SalesTaxAmount)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATEntryBilltoPaytoNo; "Bill-to/Pay-to No.")
                    {
                        IncludeCaption = true;
                    }
                    column(TaxableSalesAmt; TaxableSalesAmount)
                    {
                        AutoFormatType = 1;
                    }
                    column(NonTaxableSalesAmt; NonTaxableSalesAmount)
                    {
                        AutoFormatType = 1;
                    }
                    column(ExemptSalesAmt; ExemptSalesAmount)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATEntryDocNo; "Document No.")
                    {
                        IncludeCaption = true;
                    }
                    column(VATEntryDocType; "Document Type")
                    {
                        IncludeCaption = true;
                    }
                    column(VATEntryPostingDate; Format("Posting Date"))
                    {
                    }
                    column(VATEntryUseTax; "Use Tax")
                    {
                        IncludeCaption = true;
                    }
                    column(UseTaxtxt; UseTaxtxt)
                    {
                    }
                    column(VATEntryTaxGroupUsed; "Tax Group Used")
                    {
                    }
                    column(TaxGroupUsed; StrSubstNo(Text005, FieldCaption("Tax Group Code"), "Tax Group Used"))
                    {
                    }
                    column(VATEntryTaxJurisdictionCode; "Tax Jurisdiction Code")
                    {
                        IncludeCaption = true;
                    }
                    column(CodeCaptn_TaxJurisdiction; StrSubstNo(Text005, FieldCaption("Tax Jurisdiction Code"), "Tax Jurisdiction Code"))
                    {
                    }
                    column(VATEntryPostingDate1; "Posting Date")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ClearTaxAmounts();
                        if ((Type = Type::Purchase) and IncludeUseTax and "Use Tax") or (Type = Type::Sale) then begin
                            if Type = Type::Sale then begin
                                Amount := -Amount;
                                Base := -Base;
                            end;

                            SalesTaxAmount := Amount;
                            if Amount = 0 then
                                if "Tax Liable" then
                                    NonTaxableSalesAmount := Base
                                else
                                    ExemptSalesAmount := Base
                            else
                                TaxableSalesAmount := Base;
                        end else
                            CurrReport.Skip();

                        if ReportType <> ReportType::Summary then
                            if "Tax Group Used" <> '' then
                                TaxGroup.Get("Tax Group Used")
                            else
                                TaxGroup.Init();
                        UseTaxtxt := Format("Use Tax");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    ClearTaxAmounts();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Report-to Jurisdiction", TempTaxJurisdiction.Code);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempTaxJurisdiction.Find('-')
                else
                    TempTaxJurisdiction.Next();
                SubTitle := TempTaxJurisdiction.FieldCaption("Report-to Jurisdiction") +
                  ': ' +
                  TempTaxJurisdiction.Code +
                  '  (' +
                  TempTaxJurisdiction.Description +
                  ')';
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, NumReportTo);
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
                    field(ReportType; ReportType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Type';
                        OptionCaption = 'Summary,Normal,Detail';
                        ToolTip = 'Specifies one of the available report types to determine how detailed you want the report to be.';
                    }
                    field(IncludeUseTax; IncludeUseTax)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Use Tax';
                        ToolTip = 'Specifies if you want the report to include tax entries on which the tax amounts are marked as use tax.';
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

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        ReportToFilter := "Tax Jurisdiction".GetFilter("Report-to Jurisdiction");
        "Tax Jurisdiction".SetRange("Report-to Jurisdiction");
        JurisFilters := "Tax Jurisdiction".GetFilters();

        case ReportType of
            ReportType::Summary:
                Title := Text000;
            ReportType::Normal:
                Title := Text001;
            ReportType::Detail:
                Title := Text002;
        end;
    end;

    var
        CompanyInfo: Record "Company Information";
        TempTaxJurisdiction: Record "Tax Jurisdiction" temporary;
        LookupTaxJurisdiction: Record "Tax Jurisdiction";
        TaxGroup: Record "Tax Group";
        ReportType: Option Summary,Normal,Detail;
        JurisFilters: Text;
        ReportToFilter: Text[250];
        Title: Text[132];
        SubTitle: Text[132];
        NumReportTo: Integer;
        NonTaxableSalesAmount: Decimal;
        TaxableSalesAmount: Decimal;
        ExemptSalesAmount: Decimal;
        SalesTaxAmount: Decimal;
        IncludeUseTax: Boolean;
        UseTaxtxt: Text[30];

#pragma warning disable AA0074
        Text000: Label 'Sales Taxes Collected, Summary';
        Text001: Label 'Sales Taxes Collected';
        Text002: Label 'Sales Taxes Collected, Detail';
        Text003: Label 'Unknown Jurisdiction';
#pragma warning disable AA0470
        Text004: Label 'Total Sales Taxes Collected for %1: %2';
        Text005: Label 'Total for %1: %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrReportPAGENOCaptionLbl: Label 'Page';
        SalesTaxAmountControl3CaptionLbl: Label 'Sales Tax Amount';
        TaxableSalesAmountCaptionLbl: Label 'Taxable Sales Amount';
        NonTaxableSalesAmountCaptionLbl: Label 'Nontaxable Sales Amount';
        ExemptSalesAmountCaptionLbl: Label 'Exempt Sales Amount';
        TaxJurisdictionDescriptionCaptionLbl: Label 'Description';
        VATEntryTaxGroupUsedCaptionLbl: Label 'Tax Group Code';
        VATEntryPostingDateCaptionLbl: Label 'Posting Date';

    local procedure ClearTaxAmounts()
    begin
        NonTaxableSalesAmount := 0;
        TaxableSalesAmount := 0;
        ExemptSalesAmount := 0;
        SalesTaxAmount := 0;
    end;
}

