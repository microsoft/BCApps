// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;

report 13 "VAT Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/VATRegister.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Register';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GLSetupLCYCode; GLSetup."LCY Code")
            {
            }
            column(GLSetupAddReportCurr; GLSetup."Additional Reporting Currency")
            {
            }
            column(AllamountsareIn; AllamountsareInLbl)
            {
            }
            column(GLRegFilter_GLRegister; TableCaption + ': ' + GLRegFilter)
            {
            }
            column(GLRegFilter; GLRegFilter)
            {
            }
            column(No_GLRegister; "No.")
            {
            }
            column(VATRegisterCaption; VATRegisterCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(VATReportingDateCaption; VATReportingDateLbl)
            {
            }
            column(DocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(GenBusPostingGroupCaption; GenBusPostingGroupCaptionLbl)
            {
            }
            column(GenProdPostingGroupCaption; GenProdPostingGroupCaptionLbl)
            {
            }
            column(VATCalculationTypeCaption; VATCalculationTypeCaptionLbl)
            {
            }
            column(EU3PartyTradeCaption; EU3PartyTradeCaptionLbl)
            {
            }
            column(VATEntryClosedCaption; CaptionClassTranslate("VAT Entry".FieldCaption(Closed)))
            {
            }
            column(GLRegisterNoCaption; GLRegisterNoCaptionLbl)
            {
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(VATDate_VatEntry; Format("VAT Reporting Date"))
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
                column(GenBusPostGroup_VatEntry; "Gen. Bus. Posting Group")
                {
                }
                column(GenPostGroup_VatEntry; "Gen. Prod. Posting Group")
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
                column(Closed_VatEntry; Format(Closed))
                {
                }
                column(ClosedEntryNo_VatEntry; "Closed by Entry No.")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_VatEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(AdditionalCurr_VatEntry; UseAmtsInAddCurr)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if UseAmtsInAddCurr then begin
                        Base := "Additional-Currency Base";
                        Amount := "Additional-Currency Amount";
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From VAT Entry No.", "G/L Register"."To VAT Entry No.");
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About VAT Register';
        AboutText = 'The **VAT Register** report displays all posted VAT transactions from sales, purchases, and journals, with filters for posting date, VAT business posting group, and document number. Use it for reviewing individual VAT entries before filing returns or investigating discrepancies, ensuring audit readiness and accurate tax tracking.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
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
        GLRegFilter := "G/L Register".GetFilters();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLRegFilter: Text;
        UseAmtsInAddCurr: Boolean;
        AllamountsareInLbl: Label 'All amounts are in';
        VATRegisterCaptionLbl: Label 'VAT Register';
        PageNoCaptionLbl: Label 'Page';
        VATReportingDateLbl: Label 'VAT Reporting Date';
        DocumentTypeCaptionLbl: Label 'Document Type';
        GenBusPostingGroupCaptionLbl: Label 'Gen. Bus. Posting Group';
        GenProdPostingGroupCaptionLbl: Label 'Gen. Prod. Posting Group';
        VATCalculationTypeCaptionLbl: Label 'VAT Calculation Type';
        EU3PartyTradeCaptionLbl: Label 'EU 3-Party Trade';
        GLRegisterNoCaptionLbl: Label 'Register No.';

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    procedure InitializeRequest(NewUseAmtsInAddCurr: Boolean)
    begin
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
    end;
}

