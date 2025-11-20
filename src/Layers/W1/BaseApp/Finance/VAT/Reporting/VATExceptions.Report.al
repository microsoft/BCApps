// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;

report 31 "VAT Exceptions"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/VATExceptions.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Exceptions';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            RequestFilterFields = "Posting Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Filter1_VatEntry; TableCaption + ': ' + VATEntryFilter)
            {
            }
            column(MinVatDifference; MinVATDifference)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(MinVatDiffText; MinVATDiffText)
            {
            }
            column(AddCurrAmt_VatEntry; AddCurrAmtTxt)
            {
            }
            column(PostingDate_VatEntry; Format("Posting Date"))
            {
            }
            column(DocumentType_VatEntry; "Document Type")
            {
            }
            column(DocumentNo_VatEntry; "Document No.")
            {
                IncludeCaption = true;
            }
            column(Type_VatEntry; Type)
            {
                IncludeCaption = true;
            }
            column(GenBusPostGrp_VatEntry; "Gen. Bus. Posting Group")
            {
            }
            column(GenProdPostGrp_VatEntry; "Gen. Prod. Posting Group")
            {
            }
            column(Base_VatEntry; Base)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
                IncludeCaption = true;
            }
            column(Amount_VatEntry; Amount)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
                IncludeCaption = true;
            }
            column(VatCalType_VatEntry; "VAT Calculation Type")
            {
            }
            column(BillToPay_VatEntry; "Bill-to/Pay-to No.")
            {
                IncludeCaption = true;
            }
            column(Eu3PartyTrade_VatEntry; Format("EU 3-Party Trade"))
            {
            }
            column(FormatClosed; Format(Closed))
            {
            }
            column(EntrtyNo_VatEntry; "Entry No.")
            {
                IncludeCaption = true;
            }
            column(VatDiff_VatEntry; "VAT Difference")
            {
                IncludeCaption = true;
            }
            column(VATExceptionsCaption; VATExceptionsCaptionLbl)
            {
            }
            column(CurrReportPageNoOCaption; CurrReportPageNoOCaptionLbl)
            {
            }
            column(FORMATEU3PartyTradeCap; FORMATEU3PartyTradeCapLbl)
            {
            }
            column(FORMATClosedCaption; FORMATClosedCaptionLbl)
            {
            }
            column(VATEntryVATCalcTypeCap; VATEntryVATCalcTypeCapLbl)
            {
            }
            column(GenProdPostingGrpCaption; GenProdPostingGrpCaptionLbl)
            {
            }
            column(GenBusPostingGrpCaption; GenBusPostingGrpCaptionLbl)
            {
            }
            column(DocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not PrintReversedEntries then
                    if Reversed then
                        CurrReport.Skip();
                if UseAmtsInAddCurr then begin
                    Base := "Additional-Currency Base";
                    Amount := "Additional-Currency Amount";
                    "VAT Difference" := "Add.-Curr. VAT Difference";
                end;
            end;

            trigger OnPreDataItem()
            begin
                if UseAmtsInAddCurr then
                    SetFilter("Add.-Curr. VAT Difference", '<=%1|>=%2', -Abs(MinVATDifference), Abs(MinVATDifference))
                else
                    SetFilter("VAT Difference", '<=%1|>=%2', -Abs(MinVATDifference), Abs(MinVATDifference));
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About VAT Exceptions';
        AboutText = 'The **VAT Exceptions** report identifies posted transactions where VAT was expected but not calculated or posted, helping users catch inconsistencies before filing returns. Use it for reviewing documents that may be missing VAT data or validating VAT setup to prevent reporting errors.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AmountsInAddReportingCurrency; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    }
                    field(IncludeReversedEntries; PrintReversedEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Reversed Entries';
                        ToolTip = 'Specifies if you want to include reversed entries in the report.';
                    }
                    field(MinVATDifference; MinVATDifference)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = GetCurrency();
                        AutoFormatType = 1;
                        Caption = 'Min. VAT Difference';
                        ToolTip = 'Specifies the minimum VAT difference that you want to include in the report.';

                        trigger OnValidate()
                        begin
                            MinVATDifference := Abs(Round(MinVATDifference));
                        end;
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
        GLSetup.Get();
        VATEntryFilter := "VAT Entry".GetFilters();
        if UseAmtsInAddCurr then
            AddCurrAmtTxt := StrSubstNo(Text000, GLSetup."Additional Reporting Currency");
        MinVATDiffText := StrSubstNo(Text001, "VAT Entry".FieldCaption("VAT Difference"));
    end;

    var
        GLSetup: Record "General Ledger Setup";
        VATEntryFilter: Text;
        UseAmtsInAddCurr: Boolean;
        AddCurrAmtTxt: Text[50];
        MinVATDifference: Decimal;
        MinVATDiffText: Text[250];
        PrintReversedEntries: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Amounts are shown in %1.';
        Text001: Label 'Show %1 equal to or greater than';
#pragma warning restore AA0470
#pragma warning restore AA0074
        VATExceptionsCaptionLbl: Label 'VAT Exceptions';
        CurrReportPageNoOCaptionLbl: Label 'Page';
        FORMATEU3PartyTradeCapLbl: Label 'EU 3-Party Trade';
        FORMATClosedCaptionLbl: Label 'Closed';
        VATEntryVATCalcTypeCapLbl: Label 'VAT Calculation Type';
        GenProdPostingGrpCaptionLbl: Label 'Gen. Prod. Posting Group';
        GenBusPostingGrpCaptionLbl: Label 'Gen. Bus. Posting Group';
        DocumentTypeCaptionLbl: Label 'Document Type';
        PostingDateCaptionLbl: Label 'Posting Date';

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    procedure InitializeRequest(NewUseAmtsInAddCurr: Boolean; NewPrintReversedEntries: Boolean; NewMinVATDifference: Decimal)
    begin
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        PrintReversedEntries := NewPrintReversedEntries;
        MinVATDifference := Abs(Round(NewMinVATDifference));
    end;
}

