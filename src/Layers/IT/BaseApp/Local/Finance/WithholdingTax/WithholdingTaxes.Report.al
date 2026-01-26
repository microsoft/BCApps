// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Vendor;
using System.Telemetry;

report 12101 "Withholding Taxes"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/WithholdingTax/WithholdingTaxes.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Withholding Taxes';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Withholding Tax"; "Withholding Tax")
        {
            DataItemTableView = sorting("Tax Code", "Vendor No.") order(ascending);
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Year_WithholdingTax; Year)
            {
            }
            column(MonthDescr; MonthDescr)
            {
            }
            column(TaxCode_WithholdingTax; "Tax Code")
            {
            }
            column(WithholdingTaxAmtCaption; WithholdingTaxAmtCaptionLbl)
            {
            }
            column(TaxableBaseCaption; TaxableBaseCaptionLbl)
            {
            }
            column(NonTaxableAmtCaption; NonTaxableAmtCaptionLbl)
            {
            }
            column(NonTaxableAmtByTreatyCaption; NonTaxableAmtByTreatyCaptionLbl)
            {
            }
            column(WithholdingTaxesPmtCaption; WithholdingTaxesPmtCaptionLbl)
            {
            }
            column(BaseExcludedAmtCaption; BaseExcludedAmtCaptionLbl)
            {
            }
            column(ReferringPeriodCaption; ReferringPeriodCaptionLbl)
            {
            }
            column(TotalAmtCaption; TotalAmtCaptionLbl)
            {
            }
            column(TaxCodeCaption_WithholdingTax; WithholdingTax2.FieldCaption("Tax Code"))
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AmtToPayCaption; AmtToPayCaptionLbl)
            {
            }
            column(ExternalDocNoCaption_WithholdingTax; WithholdingTax2.FieldCaption("External Document No."))
            {
            }
            column(DocDateCaption; DocDateCaptionLbl)
            {
            }
            column(TaxableBaseCaption_WithholdingTax; WithholdingTax2.FieldCaption("Taxable Base"))
            {
            }
            column(TotalAmtCaption_WithholdingTax; WithholdingTax2.FieldCaption("Total Amount"))
            {
            }
            dataitem(WithholdingTax2; "Withholding Tax")
            {
                DataItemLink = "Tax Code" = field("Tax Code");
                DataItemTableView = sorting("Tax Code", "Vendor No.") order(ascending);
                column(VendNoVendName; Vend."No." + ' - ' + Vend.Name)
                {
                }
                column(VendNo; Vend."No.")
                {
                }
                column(TotalAmt_WithholdingTax2; "Total Amount")
                {
                    AutoFormatType = 1;
                }
                column(BaseExcludedAmt_WithholdingTax2; "Base - Excluded Amount")
                {
                    AutoFormatType = 1;
                }
                column(NonTaxableAmtByTreaty_WithholdingTax2; "Non Taxable Amount By Treaty")
                {
                    AutoFormatType = 1;
                }
                column(NonTaxableAmt_WithholdingTax2; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(TaxableBase_WithholdingTax2; "Taxable Base")
                {
                    AutoFormatType = 1;
                }
                column(WithholdingTaxAmt_WithholdingTax2; "Withholding Tax Amount")
                {
                    AutoFormatType = 1;
                }
                column(DocDateFormat_WithholdingTax2; Format("Document Date"))
                {
                }
                column(ExternalDocNo_WithholdingTax2; "External Document No.")
                {
                }
                column(PrintDetails; PrintDetails)
                {
                }
                column(TotalAmount; TotalAmount)
                {
                }
                column(BaseExclAmount; BaseExclAmount)
                {
                }
                column(NonTaxAmountbyTreaty; NonTaxAmountbyTreaty)
                {
                }
                column(NonTaxAmount; NonTaxAmount)
                {
                }
                column(TaxableBase; TaxableBase)
                {
                }
                column(WithhTaxAmount; WithhTaxAmount)
                {
                }
                column(TaxCode_WithholdingTax2; "Tax Code")
                {
                }
                column(PayableAmtRoundedOff; Round(PayableAmount))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Vend.Get("Vendor No.");
                    TotalAmount += "Total Amount";
                    BaseExclAmount += "Base - Excluded Amount";
                    NonTaxAmountbyTreaty += "Non Taxable Amount By Treaty";
                    NonTaxAmount += "Non Taxable Amount";
                    TaxableBase += "Taxable Base";
                    WithhTaxAmount += "Withholding Tax Amount";
                    PayableAmount := WithhTaxAmount;
                end;

                trigger OnPostDataItem()
                begin
                    if FinalPrinting and not CurrReport.Preview then begin
                        if PayableAmount <> 0 then begin
                            if WithholdingTaxPayment.FindLast() then
                                EntryNo := WithholdingTaxPayment."Entry No." + 1
                            else
                                EntryNo := 1;
                            WithholdingTaxPayment.Init();
                            WithholdingTaxPayment."Entry No." := EntryNo;
                            WithholdingTaxPayment.Month := MonthParam;
                            WithholdingTaxPayment.Year := YearParam;
                            WithholdingTaxPayment."Tax Code" := "Tax Code";
                            WithholdingTaxPayment."Total Amount" := TotalAmount;
                            WithholdingTaxPayment."Base - Excluded Amount" := BaseExclAmount;
                            WithholdingTaxPayment."Non Taxable Amount By Treaty" := NonTaxAmountbyTreaty;
                            WithholdingTaxPayment."Non Taxable Amount" := NonTaxAmount;
                            WithholdingTaxPayment."Taxable Amount" := TaxableBase;
                            WithholdingTaxPayment."Withholding Tax Amount" := WithhTaxAmount;
                            WithholdingTaxPayment."Payable Amount" := Round(PayableAmount);
                            WithholdingTaxPayment.Insert();
                        end;
                        ModifyAll(Paid, true)
                    end;
                    PrevTaxCode := "Tax Code";
                    FirstRecord := false;
                end;

                trigger OnPreDataItem()
                begin
                    PrevTaxCode := '';
                    SetRange(Month, MonthParam);
                    SetRange(Year, YearParam);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if (PrevTaxCode = "Tax Code") and (not FirstRecord) then
                    CurrReport.Skip();
                if PrevTaxCode <> "Tax Code" then begin
                    TotalAmount := 0;
                    BaseExclAmount := 0;
                    NonTaxAmountbyTreaty := 0;
                    NonTaxAmount := 0;
                    TaxableBase := 0;
                    WithhTaxAmount := 0;
                    PayableAmount := 0;
                end;
            end;

            trigger OnPreDataItem()
            begin
                MonthDescr := '';
                if (MonthParam > 0) and (MonthParam < 13) then
                    MonthDescr := Format(DMY2Date(1, MonthParam, 1998), 0, '<Month Text>');

                SetRange(Month, MonthParam);
                SetRange(Year, YearParam);

                if FinalPrinting and not CurrReport.Preview then begin
                    WithholdingTaxPayment.SetCurrentKey(Year, Month);
                    WithholdingTaxPayment.SetRange(Month, MonthParam);
                    WithholdingTaxPayment.SetRange(Year, YearParam);
                    if WithholdingTaxPayment.FindFirst() then begin
                        if not Confirm(Text1033, false, MonthParam, YearParam) then
                            CurrReport.Quit();
                        WithholdingTaxPayment.DeleteAll();
                        ModifyAll(Paid, false);
                    end;
                end;

                Clear(WithholdingTaxPayment);
                FirstRecord := true;
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
                    field(ReferenceMonth; MonthParam)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reference Month';
                        ToolTip = 'Specifies the reference month.';
                    }
                    field(ReferenceYear; YearParam)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reference Year';
                        ToolTip = 'Specifies the reference year.';
                    }
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Details';
                        ToolTip = 'Specifies if you want to print the details section.';
                    }
                    field(FinalPrinting; FinalPrinting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Final Printing';
                        ToolTip = 'Specifies if this is the final printing.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            MonthParam := Date2DMY(WorkDate(), 2);
            YearParam := Date2DMY(WorkDate(), 3);
            PrintDetails := true;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('1000HQ4', ITTaxTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('1000HQ5', ITTaxTok, 'IT Set Up Withholding Tax Completed');
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ITTaxTok: Label 'IT Withholding Tax', Locked = true;
        Text1033: Label 'Period %1/%2 has already been printed. Do you want to print it again?';
        Vend: Record Vendor;
        WithholdingTaxPayment: Record "Withholding Tax Payment";
        MonthParam: Integer;
        YearParam: Integer;
        EntryNo: Integer;
        FinalPrinting: Boolean;
        PrintDetails: Boolean;
        FirstRecord: Boolean;
        PayableAmount: Decimal;
        TotalAmount: Decimal;
        BaseExclAmount: Decimal;
        NonTaxAmountbyTreaty: Decimal;
        NonTaxAmount: Decimal;
        TaxableBase: Decimal;
        WithhTaxAmount: Decimal;
        MonthDescr: Text[30];
        PrevTaxCode: Text[4];
        WithholdingTaxAmtCaptionLbl: Label 'Withholding Tax Amount';
        TaxableBaseCaptionLbl: Label 'Taxable Base';
        NonTaxableAmtCaptionLbl: Label 'Non Taxable Amount';
        NonTaxableAmtByTreatyCaptionLbl: Label 'Non Taxable Amount By Treaty';
        WithholdingTaxesPmtCaptionLbl: Label 'Withholding Taxes Payment';
        BaseExcludedAmtCaptionLbl: Label 'Base - Excluded Amount';
        ReferringPeriodCaptionLbl: Label 'Referring Period';
        TotalAmtCaptionLbl: Label 'Total Amount';
        PageCaptionLbl: Label 'Page';
        AmtToPayCaptionLbl: Label 'Amount to Pay';
        DocDateCaptionLbl: Label 'Document Date';
}

