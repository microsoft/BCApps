// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

report 2500 "Day Book VAT Entry"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/DayBookVATEntry.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Day Book VAT Entry';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ReqVATEntry; "VAT Entry")
        {
            DataItemTableView = sorting(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date");
            RequestFilterFields = Type, "VAT Reporting Date";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Date));
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(All_amounts_are_in___GLSetup__LCY_Code_; StrSubstNo(Text000Lbl, GLSetup."LCY Code"))
            {
            }
            column(UseAmtsInAddCurr; UseAmtsInAddCurr)
            {
            }
            column(VAT_Entry__TABLENAME__________VATEntryFilter; "VAT Entry".TableCaption + ': ' + VATEntryFilter)
            {
            }
            column(VATEntryFilter; VATEntryFilter)
            {
            }
            column(Total_for_____FORMAT_Date__Period_Start__0_4_; StrSubstNo(Text002Lbl, Format(Date."Period Start", 0, 4)))
            {
            }
            column(VAT_Entry__Base; "VAT Entry".Base)
            {
                AutoFormatType = 1;
            }
            column(VAT_Entry__Amount; "VAT Entry".Amount)
            {
                AutoFormatType = 1;
            }
            column(VAT_Entry__NDBase; "VAT Entry"."Non-Deductible VAT Base")
            {
                AutoFormatType = 1;
            }
            column(VAT_Entry__NDAmount; "VAT Entry"."Non-Deductible VAT Amount")
            {
                AutoFormatType = 1;
            }
            column(Total_for_____FORMAT_Date__Period_Start__0_4__Control41; StrSubstNo(Text002Lbl, Format(Date."Period Start", 0, 4)))
            {
            }
            column(VAT_Entry___Additional_Currency_Base_; "VAT Entry"."Additional-Currency Base")
            {
                AutoFormatType = 1;
            }
            column(VAT_Entry___Additional_Currency_NDBase_; "VAT Entry"."Non-Deductible VAT Base ACY")
            {
                AutoFormatType = 1;
            }
            column(VAT_Entry___Add__Currency_Unrealized_Amt__; "VAT Entry"."Add.-Currency Unrealized Amt.")
            {
                AutoFormatType = 1;
            }
            column(Total_for______VAT_Entry__TABLENAME__________VATEntryFilter; StrSubstNo(Text003Lbl, "VAT Entry".TableCaption(), VATEntryFilter))
            {
            }
            column(VAT_Entry__Amount_Control47; "VAT Entry".Amount)
            {
                AutoFormatType = 1;
            }
            column(VAT_Entry__Base_Control48; "VAT Entry".Base)
            {
                AutoFormatType = 1;
            }
            column(Total_for______VAT_Entry__TABLENAME__________VATEntryFilter_Control52; StrSubstNo(Text003Lbl, "VAT Entry".TableCaption(), VATEntryFilter))
            {
            }
            column(VAT_Entry___Additional_Currency_Base__Control55; "VAT Entry"."Additional-Currency Base")
            {
                AutoFormatType = 1;
            }
            column(VAT_Entry___Add__Currency_Unrealized_Amt___Control56; "VAT Entry"."Add.-Currency Unrealized Amt.")
            {
                AutoFormatType = 1;
            }
            column(Date_Period_Type; "Period Type")
            {
            }
            column(Date_Period_Start; "Period Start")
            {
            }
            column(Day_Book_VAT_EntryCaption; Day_Book_VAT_EntryCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(All_amounts_are_in_Add__Reporting_CurrencyCaption; All_amounts_are_in_Add__Reporting_CurrencyCaptionLbl)
            {
            }
            column(SellToBuyFromNameCaption; SellToBuyFromNameCaptionLbl)
            {
            }
            column(VAT_Entry__Document_No__Caption; "VAT Entry".FieldCaption("Document No."))
            {
            }
            column(VAT_Entry__External_Document_No__Caption; "VAT Entry".FieldCaption("External Document No."))
            {
            }
            column(Sell_to__Buy_from_No_Caption; Sell_to__Buy_from_No_CaptionLbl)
            {
            }
            column(VAT_Entry_BaseCaption; "VAT Entry".FieldCaption(Base))
            {
            }
            column(VAT_Entry_AmountCaption; "VAT Entry".FieldCaption(Amount))
            {
            }
            column(VAT_Entry_NDBaseCaption; "VAT Entry".FieldCaption("Non-Deductible VAT Base"))
            {
            }
            column(VAT_Entry_NDAmountCaption; "VAT Entry".FieldCaption("Non-Deductible VAT Amount"))
            {
            }
            column(VAT_Entry__VAT_Base_Discount___Caption; "VAT Entry".FieldCaption("VAT Base Discount %"))
            {
            }
            column(VAT_Entry__VAT_Calculation_Type_Caption; "VAT Entry".FieldCaption("VAT Calculation Type"))
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(VAT_Entry__FIELDNAME__VAT_Date__________FORMAT_Date__Period_Start__0_4_; "VAT Entry".FieldCaption("VAT Reporting Date") + ' ' + Format(Date."Period Start", 0, 4))
                {
                }
                column(Integer_Number; Number)
                {
                }
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemTableView = sorting("Document No.", "VAT Reporting Date");
                    column(FIELDNAME_Type__________FORMAT_Type_; FieldCaption(Type) + ' ' + Format(Type))
                    {
                    }
                    column(VAT_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(VAT_Entry__External_Document_No__; "External Document No.")
                    {
                    }
                    column(VAT_Entry__Bill_to_Pay_to_No__; "Bill-to/Pay-to No.")
                    {
                    }
                    column(VAT_Entry_Base; Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry_Amount; Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry_NDBase; "Non-Deductible VAT Base")
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry_NDAmount; "Non-Deductible VAT Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(SellToBuyFromName; SellToBuyFromName)
                    {
                    }
                    column(VAT_Entry__VAT_Base_Discount___; "VAT Base Discount %")
                    {
                    }
                    column(VAT_Entry__VAT_Calculation_Type_; "VAT Calculation Type")
                    {
                    }
                    column(VAT_Entry__Document_No___Control10; "Document No.")
                    {
                    }
                    column(VAT_Entry__External_Document_No___Control15; "External Document No.")
                    {
                    }
                    column(VAT_Entry__Bill_to_Pay_to_No___Control16; "Bill-to/Pay-to No.")
                    {
                    }
                    column(VAT_Entry__Additional_Currency_Base_; "Additional-Currency Base")
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry__Additional_Currency_Amount_; "Additional-Currency Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry__Additional_Currency_NDBase_; "Non-Deductible VAT Base ACY")
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry__Additional_Currency_NDAmount_; "Non-Deductible VAT Amount ACY")
                    {
                        AutoFormatType = 1;
                    }
                    column(SellToBuyFromName_Control23; SellToBuyFromName)
                    {
                    }
                    column(VAT_Entry__VAT_Base_Discount____Control25; "VAT Base Discount %")
                    {
                    }
                    column(VAT_Entry__VAT_Calculation_Type__Control26; "VAT Calculation Type")
                    {
                    }
                    column(Total_for___FIELDNAME_Type________FORMAT_Type_; StrSubstNo(Text001Lbl, FieldCaption(Type), Format(Type)))
                    {
                    }
                    column(VAT_Entry_Base_Control38; Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry_Amount_Control39; Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(Total_for___FIELDNAME_Type________FORMAT_Type__Control27; StrSubstNo(Text001Lbl, FieldCaption(Type), Format(Type)))
                    {
                    }
                    column(VAT_Entry__Additional_Currency_Base__Control33; "Additional-Currency Base")
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry__Additional_Currency_Amount__Control37; "Additional-Currency Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(VAT_Entry_Type; Type)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        case Type of
                            Type::Purchase:
                                if ("Bill-to/Pay-to No." <> Vendor."No.") or (Type <> PrevType) then
                                    if Vendor.Get("Bill-to/Pay-to No.") then
                                        SellToBuyFromName := Vendor.Name
                                    else
                                        SellToBuyFromName := '';
                            Type::Sale:
                                if ("Bill-to/Pay-to No." <> Customer."No.") or (Type <> PrevType) then
                                    if Customer.Get("Bill-to/Pay-to No.") then
                                        SellToBuyFromName := Customer.Name
                                    else
                                        SellToBuyFromName := '';
                            else
                                SellToBuyFromName := '';
                        end;

                        PrevType := Type;
                    end;

                    trigger OnPreDataItem()
                    begin
                        CopyFilters(ReqVATEntry);
                        SetRange("VAT Reporting Date", Date."Period Start");
                        FilterGroup(5);
                        SetFilter(Type, Format(Integer.Number));
                        Clear(Base);
                        Clear(Amount);
                        Clear("Non-Deductible VAT Base");
                        Clear("Non-Deductible VAT Amount");
                        FilterGroup(0);
                    end;
                }

                trigger OnPreDataItem()
                var
                    PostingDateStart: Date;
                    PostingDateEnd: Date;
                begin
                    SetRange(Number, 0, 3);

                    if ReqVATEntry.GetFilter("VAT Reporting Date") = '' then
                        Error(MissingDateRangeFilterErr);

                    PostingDateStart := ReqVATEntry.GetRangeMin("VAT Reporting Date");
                    PostingDateEnd := CalcDate('<+1Y>', PostingDateStart);

                    if ReqVATEntry.GetRangeMax("VAT Reporting Date") > PostingDateEnd then
                        Error(MaxPostingDateErr);
                end;
            }

            trigger OnPreDataItem()
            begin
                ReqVATEntry.CopyFilter("VAT Reporting Date", "Period Start");
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
        VATEntryFilter := ReqVATEntry.GetFilters();
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        Vendor: Record Vendor;
        SellToBuyFromName: Text;
        VATEntryFilter: Text;
        PrevType: Enum "General Posting Type";
        UseAmtsInAddCurr: Boolean;
#pragma warning disable AA0470
        Text000Lbl: Label 'All amounts are in %1.', Comment = 'All amounts are in GBP';
        Text001Lbl: Label 'Total for %1 %2.', Comment = 'Total for VAT date 12122012';
        Text002Lbl: Label 'Total for %1.', Comment = 'total for 121212';
        Text003Lbl: Label 'Total for  %1 : %2.', Comment = 'Total for VAT Entry Vat%       ';
#pragma warning restore AA0470
        Day_Book_VAT_EntryCaptionLbl: Label 'Day Book VAT Entry';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_Add__Reporting_CurrencyCaptionLbl: Label 'All amounts are in Add. Reporting Currency';
        SellToBuyFromNameCaptionLbl: Label 'Sell-to/Buy-from Name';
        Sell_to__Buy_from_No_CaptionLbl: Label 'Sell-to/\Buy-from No.';
        MaxPostingDateErr: Label 'VAT Date period must not be longer than 1 year.';
        MissingDateRangeFilterErr: Label 'VAT Date filter must be set.';
}

