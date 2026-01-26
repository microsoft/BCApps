// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

report 11312 "Checklist Revenue and VAT"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/ChecklistRevenueandVAT.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Checklist Revenue and VAT';
    UsageCategory = ReportsAndAnalysis;
    UseRequestPage = true;

    dataset
    {
        dataitem("Amounts per Account/Period"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(G_L_Account__TABLECAPTION________GlAccountFilter; "G/L Account".TableCaption + ':' + GlAccountFilter)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Heading; Heading)
            {
            }
            column(SkipHeader_1_; SkipHeader[1])
            {
            }
            column(Number; Number)
            {
            }
            column(Checklist_between_Revenue_and_VATCaption; Checklist_between_Revenue_and_VATCaptionLbl)
            {
            }
            column(Amounts_per_account_per_periodCaption; Amounts_per_account_per_periodCaptionLbl)
            {
            }
            dataitem("G/L Account"; "G/L Account")
            {
                DataItemTableView = where("Account Type" = filter(Posting));
                RequestFilterFields = "No.";
                column(DateName_1__; DateName[1])
                {
                }
                column(DateName_2__; DateName[2])
                {
                }
                column(DateName_4__; DateName[4])
                {
                }
                column(DateName_3__; DateName[3])
                {
                }
                column(DateName_8__; DateName[8])
                {
                }
                column(DateName_7__; DateName[7])
                {
                }
                column(DateName_6__; DateName[6])
                {
                }
                column(DateName_5__; DateName[5])
                {
                }
                column(DateName_12__; DateName[12])
                {
                }
                column(DateName_11__; DateName[11])
                {
                }
                column(DateName_10__; DateName[10])
                {
                }
                column(DateName_9__; DateName[9])
                {
                }
                column(DateName_13__; DateName[13])
                {
                }
                column(G_L_Account__No__; "No.")
                {
                }
                column(G_L_Account_Name; Name)
                {
                }
                column(TotalAmount_4_; TotalAmount[4])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_5_; TotalAmount[5])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_6_; TotalAmount[6])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_2_; TotalAmount[2])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_3_; TotalAmount[3])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_1_; TotalAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_8_; TotalAmount[8])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_9_; TotalAmount[9])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_7_; TotalAmount[7])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_10_; TotalAmount[10])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_11_; TotalAmount[11])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_12_; TotalAmount[12])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_13_; TotalAmount[13])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_4__Control214; TotalAmount[4])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_5__Control215; TotalAmount[5])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_6__Control216; TotalAmount[6])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_2__Control217; TotalAmount[2])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_3__Control218; TotalAmount[3])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_1__Control219; TotalAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_8__Control220; TotalAmount[8])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_9__Control221; TotalAmount[9])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_7__Control222; TotalAmount[7])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_10__Control223; TotalAmount[10])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_11__Control224; TotalAmount[11])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_12__Control225; TotalAmount[12])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_13__Control226; TotalAmount[13])
                {
                    AutoFormatType = 1;
                }
                column(No_Caption; No_CaptionLbl)
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(TotalsCaption; TotalsCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(TotalAmount[NoOfPeriods + 1]);
                    for i := 1 to NoOfPeriods do begin
                        SetFilter("Date Filter", DateFilter[i]);
                        CalcFields("Net Change");
                        TotalAmount[i] := -"Net Change";
                        TotalAmount[NoOfPeriods + 1] := TotalAmount[NoOfPeriods + 1] + TotalAmount[i];
                    end;
                    Mark(true);

                    TotRevenue := TotRevenue + TotalAmount[NoOfPeriods + 1];
                end;

                trigger OnPostDataItem()
                begin
                    SkipHeader[1] := true;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(TotRevenue);
                    "G/L Account".ClearMarks();
                    GLAccount.Reset();
                    GLAccount.CopyFilters("G/L Account");
                end;
            }
        }
        dataitem("Amounts not sales"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME_Control74; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Heading_Control75; Heading)
            {
            }
            column(G_L_Account__TABLECAPTION________GlAccountFilter_Control77; "G/L Account".TableCaption + ':' + GlAccountFilter)
            {
            }
            column(G_L_Account__TABLECAPTION________GLEntry1_FIELDCAPTION__Gen__Posting_Type_____GLEntry1_GETFILTER__Gen__Posting_Type___; "G/L Account".TableCaption + ':' + GLEntry1.FieldCaption("Gen. Posting Type") + GLEntry1.GetFilter("Gen. Posting Type"))
            {
            }
            column(SkipHeader_2_; SkipHeader[2])
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Checklist_between_Revenue_and_VATCaption_Control76; Checklist_between_Revenue_and_VATCaption_Control76Lbl)
            {
            }
            column(Amounts_which_are_not_posted_as_salesCaption; Amounts_which_are_not_posted_as_salesCaptionLbl)
            {
            }
            column(Amounts_not_sales_Number; Number)
            {
            }
            dataitem("<G/L Account2>"; "G/L Account")
            {
                DataItemTableView = sorting("No.") where("Account Type" = filter(Posting));
                column(DateName_1___Control229; DateName[1])
                {
                }
                column(DateName_2___Control230; DateName[2])
                {
                }
                column(DateName_4___Control231; DateName[4])
                {
                }
                column(DateName_3___Control232; DateName[3])
                {
                }
                column(DateName_8___Control233; DateName[8])
                {
                }
                column(DateName_7___Control234; DateName[7])
                {
                }
                column(DateName_6___Control235; DateName[6])
                {
                }
                column(DateName_5___Control236; DateName[5])
                {
                }
                column(DateName_12___Control237; DateName[12])
                {
                }
                column(DateName_11___Control238; DateName[11])
                {
                }
                column(DateName_10___Control239; DateName[10])
                {
                }
                column(DateName_9___Control240; DateName[9])
                {
                }
                column(DateName_13___Control241; DateName[13])
                {
                }
                column(G_L_Account2___No__; "No.")
                {
                }
                column(G_L_Account2__Name; Name)
                {
                }
                column(TotalAmount_4__Control259; TotalAmount[4])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_5__Control260; TotalAmount[5])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_6__Control261; TotalAmount[6])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_2__Control262; TotalAmount[2])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_3__Control263; TotalAmount[3])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_1__Control264; TotalAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_8__Control265; TotalAmount[8])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_9__Control266; TotalAmount[9])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_7__Control267; TotalAmount[7])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_10__Control268; TotalAmount[10])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_11__Control269; TotalAmount[11])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_12__Control270; TotalAmount[12])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_13__Control271; TotalAmount[13])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_4__Control273; TotalAmount[4])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_5__Control274; TotalAmount[5])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_6__Control275; TotalAmount[6])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_2__Control276; TotalAmount[2])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_3__Control277; TotalAmount[3])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_1__Control278; TotalAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_8__Control279; TotalAmount[8])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_9__Control280; TotalAmount[9])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_7__Control281; TotalAmount[7])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_10__Control282; TotalAmount[10])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_11__Control283; TotalAmount[11])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_12__Control284; TotalAmount[12])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount_13__Control285; TotalAmount[13])
                {
                    AutoFormatType = 1;
                }
                column(No_Caption_Control227; No_Caption_Control227Lbl)
                {
                }
                column(NameCaption_Control228; NameCaption_Control228Lbl)
                {
                }
                column(TotalsCaption_Control272; TotalsCaption_Control272Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(TotalAmount[NoOfPeriods + 1]);
                    for i := 1 to NoOfPeriods do begin
                        Clear(TotalAmount[i]);
                        GLEntry1.SetFilter("G/L Account No.", "No.");
                        GLEntry1.SetFilter("Posting Date", DateFilter[i]);
                        if GLEntry1.FindSet() then
                            repeat
                                TotalAmount[i] := TotalAmount[i] - GLEntry1.Amount;
                            until GLEntry1.Next() = 0;

                        TotalAmount[NoOfPeriods + 1] := TotalAmount[NoOfPeriods + 1] + TotalAmount[i];
                    end;

                    Total1 := Total1 + TotalAmount[NoOfPeriods + 1];
                    TotNotRevenue := TotNotRevenue + TotalAmount[NoOfPeriods + 1];
                end;

                trigger OnPostDataItem()
                begin
                    SkipHeader[2] := true;
                end;

                trigger OnPreDataItem()
                begin
                    CopyFilters(GLAccount);
                    Clear(TotalAmount);
                    Clear(TotNotRevenue);
                    Clear(Total1);

                    GLEntry1.SetFilter("Posting Date", DateFilter[i]);
                    GLEntry1.SetFilter("G/L Account No.", "No.");
                end;
            }

            trigger OnPreDataItem()
            begin
                GLEntry1.Reset();
                GLEntry1.SetCurrentKey("G/L Account No.", "Posting Date");
                GLEntry1.SetFilter("Gen. Posting Type", '<> %1', GLEntry1."Gen. Posting Type"::Sale);

                GLEntry2.Reset();
                GLEntry2.SetCurrentKey("G/L Account No.", "Posting Date");
                GLEntry2.SetFilter("Gen. Posting Type", '= %1', GLEntry2."Gen. Posting Type"::Sale);
            end;
        }
        dataitem("Sales not posted"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(USERID_Control22; UserId)
            {
            }
            column(FORMAT_TODAY_0_4__Control108; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME_Control112; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Heading_Control113; Heading)
            {
            }
            column(G_L_Account__TABLECAPTION___________________GlAccountFilter; "G/L Account".TableCaption + ':' + '  <>  ' + GlAccountFilter)
            {
            }
            column(G_L_Entry__TABLECAPTION________GLEntry2_FIELDCAPTION__Gen__Posting_Type____GLEntry2_GETFILTER__Gen__Posting_Type__; "G/L Entry".TableCaption + ':' + GLEntry2.FieldCaption("Gen. Posting Type") + GLEntry2.GetFilter("Gen. Posting Type"))
            {
            }
            column(SkipHeader_3_; SkipHeader[3])
            {
            }
            column(Checklist_between_Revenue_and_VATCaption_Control114; Checklist_between_Revenue_and_VATCaption_Control114Lbl)
            {
            }
            column(Sales_not_posted_in_the_selected_range_of_accounts_Caption; Sales_not_posted_in_the_selected_range_of_accounts_CaptionLbl)
            {
            }
            column(Sales_not_posted_Number; Number)
            {
            }
            dataitem("<G/L Account3>"; "G/L Account")
            {
                DataItemTableView = sorting("No.") where("Account Type" = filter(Posting));
                column(CreditAmt; CreditAmt)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 2 : 2;
                }
                column(DebitAmt; DebitAmt)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 2 : 2;
                }
                column(TotalDebitAmt; TotalDebitAmt)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 2 : 2;
                }
                column(TotalCreditAmt; TotalCreditAmt)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 2 : 2;
                }
                column(G_L_Account_No_Caption; G_L_Account_No_CaptionLbl)
                {
                }
                column(Doc__TypeCaption; Doc__TypeCaptionLbl)
                {
                }
                column(Document_No_Caption; Document_No_CaptionLbl)
                {
                }
                column(Posting_DateCaption; Posting_DateCaptionLbl)
                {
                }
                column(Source_TypeCaption; Source_TypeCaptionLbl)
                {
                }
                column(Source_No_Caption; Source_No_CaptionLbl)
                {
                }
                column(Debit_AmountCaption; Debit_AmountCaptionLbl)
                {
                }
                column(Credit_AmountCaption; Credit_AmountCaptionLbl)
                {
                }
                column(Journal_NameCaption; Journal_NameCaptionLbl)
                {
                }
                column(TotalsCaption_Control129; TotalsCaption_Control129Lbl)
                {
                }
                column(G_L_Account3__No_; "No.")
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = field("No.");
                    DataItemTableView = sorting("G/L Account No.", "Posting Date") where("Gen. Posting Type" = filter(Sale));
                    column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                    {
                    }
                    column(G_L_Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(G_L_Entry__Posting_Date_; "Posting Date")
                    {
                    }
                    column(G_L_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(G_L_Entry__Debit_Amount_; "Debit Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry__Credit_Amount_; "Credit Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry__Source_Type_; "Source Type")
                    {
                    }
                    column(G_L_Entry__Source_No__; "Source No.")
                    {
                    }
                    column(G_L_Entry__Journal_Template_Name_; "Journal Templ. Name")
                    {
                    }
                    column(G_L_Entry__G_L_Entry___Debit_Amount_; "G/L Entry"."Debit Amount")
                    {
                    }
                    column(G_L_Entry__G_L_Entry___Credit_Amount_; "G/L Entry"."Credit Amount")
                    {
                    }
                    column(G_L_Entry_Entry_No_; "Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DebitAmt := DebitAmt + "Debit Amount";
                        CreditAmt := CreditAmt + "Credit Amount";
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", '%1..%2', StartDate, Calender."Period End");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    "G/L Account".Get("No.");
                    if "G/L Account".Mark() then
                        CurrReport.Skip();
                    Clear(TotalDebitAmt);
                    Clear(TotalCreditAmt);
                    if DebitAmt > CreditAmt then
                        TotalDebitAmt := DebitAmt - CreditAmt
                    else
                        TotalCreditAmt := CreditAmt - DebitAmt;
                end;

                trigger OnPostDataItem()
                begin
                    SkipHeader[3] := true;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(DebitAmt);
                    Clear(CreditAmt);
                end;
            }
        }
        dataitem("Difference amount"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(USERID_Control10; UserId)
            {
            }
            column(FORMAT_TODAY_0_4__Control14; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME_Control15; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Heading_Control18; Heading)
            {
            }
            column(G_L_Entry__TABLECAPTION_Control20; "G/L Entry".TableCaption + ':' + GLEntry2.FieldCaption("Gen. Posting Type") + GLEntry2.GetFilter("Gen. Posting Type"))
            {
            }
            column(SkipHeader_4_; SkipHeader[4])
            {
            }
            column(Checklist_between_Revenue_and_VATCaption_Control19; Checklist_between_Revenue_and_VATCaption_Control19Lbl)
            {
            }
            column(Total___Posted_revenues_with_difference_between_posted_Amount_and_VAT_Base_AmountCaption; Total___Posted_revenues_with_difference_between_posted_Amount_and_VAT_Base_AmountCaptionLbl)
            {
            }
            column(Difference_amount_Number; Number)
            {
            }
            dataitem("<G/L Entry2>"; "G/L Entry")
            {
                DataItemTableView = sorting("Journal Templ. Name", "Posting Date", "Document No.") where("Gen. Posting Type" = const(Sale));
                column(G_L_Entry2___Posting_Date_; "Posting Date")
                {
                }
                column(G_L_Entry2___Journal_Template_Name_; "Journal Templ. Name")
                {
                }
                column(G_L_Entry2___Document_No__; "Document No.")
                {
                }
                column(G_L_Entry2___Source_Type_; "Source Type")
                {
                }
                column(G_L_Entry2___Source_No__; "Source No.")
                {
                }
                column(Amount; -Amount)
                {
                    AutoFormatType = 1;
                }
                column(SourceName; SourceName)
                {
                }
                column(BaseVAT; -BaseVAT)
                {
                    AutoFormatType = 1;
                }
                column(BaseBefPmtDisc_BaseVAT; -BaseBefPmtDisc + BaseVAT)
                {
                    AutoFormatType = 1;
                }
                column(Amount___BaseBefPmtDisc; -Amount + BaseBefPmtDisc)
                {
                    AutoFormatType = 1;
                }
                column(Amount___BaseVAT; -Amount + BaseVAT)
                {
                    AutoFormatType = 1;
                }
                column(Amount1; -Amount1)
                {
                }
                column(Amount1_BaseVAT; -Amount1 + BaseVAT)
                {
                }
                column(Amount1_BaseBefPmtDisc; -Amount1 + BaseBefPmtDisc)
                {
                }
                column(LastDocumentNo; LastDocumentNo)
                {
                }
                column(TotBaseVAT; -TotBaseVAT)
                {
                    AutoFormatType = 1;
                }
                column(TotAmount; -TotAmount)
                {
                    AutoFormatType = 1;
                }
                column(TotBaseBefPmtDisc___TotBaseVAT; -TotBaseBefPmtDisc + TotBaseVAT)
                {
                    AutoFormatType = 1;
                }
                column(TotAmount___TotBaseBefPmtDisc; -TotAmount + TotBaseBefPmtDisc)
                {
                    AutoFormatType = 1;
                }
                column(TotAmount___TotBaseVAT; -TotAmount + TotBaseVAT)
                {
                    AutoFormatType = 1;
                }
                column(Journal_NameCaption_Control146; Journal_NameCaption_Control146Lbl)
                {
                }
                column(G_L_Entry2___Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(G_L_Entry2___Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(G_L_Entry2___Source_Type_Caption; FieldCaption("Source Type"))
                {
                }
                column(G_L_Entry2___Source_No__Caption; FieldCaption("Source No."))
                {
                }
                column(Source_NameCaption; Source_NameCaptionLbl)
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(Base_VATCaption; Base_VATCaptionLbl)
                {
                }
                column(DifferenceCaption; DifferenceCaptionLbl)
                {
                }
                column(Pmt__Disc_Caption; Pmt__Disc_CaptionLbl)
                {
                }
                column(OtherCaption; OtherCaptionLbl)
                {
                }
                column(TotalsCaption_Control180; TotalsCaption_Control180Lbl)
                {
                }
                column(G_L_Entry2__Entry_No_; "Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(SourceName);
                    if "Source Type" = "Source Type"::Customer then
                        if Cust.Get("Source No.") then
                            SourceName := Cust.Name;

                    if "Source Type" = "Source Type"::Vendor then
                        if Vend.Get("Source No.") then
                            SourceName := Vend.Name;

                    Clear(BaseVAT);
                    Clear(BaseBefPmtDisc);
                    Clear(Amount1);
                    VATEntry.Reset();
                    GLEntry2.Reset();
                    VATEntry.SetCurrentKey("Document No.", "Posting Date");
                    VATEntry.SetRange("Posting Date", "Posting Date");
                    VATEntry.SetRange("Document No.", "Document No.");
                    VATEntry.SetRange(Type, VATEntry.Type::Sale);
                    if VATEntry.FindSet() then
                        repeat
                            BaseVAT := BaseVAT + VATEntry.Base;
                            BaseBefPmtDisc := BaseBefPmtDisc + VATEntry."Base Before Pmt. Disc.";
                        until VATEntry.Next() = 0;

                    GLEntry2.SetRange("Document No.", "Document No.");
                    GLEntry2.SetRange("Gen. Posting Type", "Gen. Posting Type"::Sale);
                    if GLEntry2.FindSet() then
                        repeat
                            Amount1 := Amount1 + GLEntry2.Amount;
                        until GLEntry2.Next() = 0;

                    if LastDocumentNo <> "Document No." then begin
                        LastDocumentNo := "Document No.";
                        if BaseVAT <> Amount1 then begin
                            TotBaseVAT := TotBaseVAT + BaseVAT;
                            TotAmount := TotAmount + Amount1;
                            TotBaseBefPmtDisc := TotBaseBefPmtDisc + BaseBefPmtDisc;
                        end else
                            CurrReport.Skip();
                    end else
                        CurrReport.Skip();
                end;

                trigger OnPostDataItem()
                begin
                    SkipHeader[4] := true;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(TotBaseVAT);
                    Clear(TotBaseBefPmtDisc);
                    Clear(TotAmount);
                    SetFilter("Posting Date", '%1..%2', StartDate, Calender."Period End");
                    LastDocumentNo := '';
                end;
            }
        }
        dataitem(Summary; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(USERID_Control183; UserId)
            {
            }
            column(FORMAT_TODAY_0_4__Control186; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME_Control187; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Heading_Control188; Heading)
            {
            }
            column(TotBaseVAT_TotAmount; -TotBaseVAT + TotAmount)
            {
                AutoFormatType = 1;
            }
            column(CreditAmt_DebitAmt; CreditAmt - DebitAmt)
            {
                AutoFormatType = 1;
            }
            column(TotNotRevenue; -TotNotRevenue)
            {
                AutoFormatType = 1;
            }
            column(TotRevenue; TotRevenue)
            {
                AutoFormatType = 1;
            }
            column(TotRevenue_TotNotRevenue_CreditAmt_DebitAmt_TotBaseVAT_TotAmount; TotRevenue - Total1 + CreditAmt - DebitAmt - TotBaseVAT + TotAmount)
            {
                AutoFormatType = 1;
            }
            column(TotTVAStatement; TotTVAStatement)
            {
                AutoFormatType = 1;
            }
            column(TotTVAStatement__TotRevenue_TotNotRevenue_CreditAmt_DebitAmt_TotBaseVAT_TotAmount_; TotTVAStatement - (TotRevenue - Total1 + CreditAmt - DebitAmt - TotBaseVAT + TotAmount))
            {
                AutoFormatType = 1;
            }
            column(Total1; Total1)
            {
            }
            column(Checklist_between_Revenue_and_VATCaption_Control189; Checklist_between_Revenue_and_VATCaption_Control189Lbl)
            {
            }
            column(Summary__Caption; Summary__CaptionLbl)
            {
            }
            column(Total___Revenues_accounts_in_the_selected_rangeCaption; Total___Revenues_accounts_in_the_selected_rangeCaptionLbl)
            {
            }
            column(Total___Revenues_which_are_no_sales_or_credit_memos__Caption; Total___Revenues_which_are_no_sales_or_credit_memos__CaptionLbl)
            {
            }
            column(Total___Sales_not_posted_in_the_selected_range_of_accounts__Revenues_Caption; Total___Sales_not_posted_in_the_selected_range_of_accounts__Revenues_CaptionLbl)
            {
            }
            column(Total___Posted_revenues_with_difference_between_posted_Amount_and_Base_VATCaption; Total___Posted_revenues_with_difference_between_posted_Amount_and_Base_VATCaptionLbl)
            {
            }
            column(Total__1_Caption; Total__1_CaptionLbl)
            {
            }
            column(VAT_statement_amount__2_Caption; VAT_statement_amount__2_CaptionLbl)
            {
            }
            column(Difference__2_____1_Caption; Difference__2_____1_CaptionLbl)
            {
            }
            column(Summary_Number; Number)
            {
            }

            trigger OnPreDataItem()
            var
                CorrectionAmount: Decimal;
                Dummy: Decimal;
            begin
                Clear(TotTVAStatement);
                VATStatName.Get(GLSetup."VAT Statement Template Name", GLSetup."VAT Statement Name");

                VATDateFilter := Format(StartDate) + '..' + Format(Calender."Period End");
                VATStatLine.SetFilter("Date Filter", VATDateFilter);
                VATStatLine."Statement Template Name" := GLSetup."VAT Statement Template Name";
                VATStatLine."Statement Name" := GLSetup."VAT Statement Name";
                VATStatLine.Type := VATStatLine.Type::"Row Totaling";
                VATStatLine."Row Totaling" := '00|01|02|03|44|45|46|47|48|49';
                VATStatement.InitializeRequest(
                  VATStatName, VATStatLine, Selection::"Open and Closed",
                  PeriodSelection::"Within Period", false, false);
                VATStatement.CalcLineTotal(VATStatLine, TotTVAStatement, CorrectionAmount, Dummy, '', 0);
                TotTVAStatement := TotTVAStatement + CorrectionAmount;
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Periods';
                        MaxValue = 12;
                        MinValue = 1;
                        ToolTip = 'Specifies the number of periods to be included in the report. The length of the periods is determined by the length of the periods in the Accounting Period table.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (StartDate = 0D) or (NoOfPeriods = 0) then begin
                StartDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
                NoOfPeriods := 12;
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLSetup.Get();
        GLSetup.TestField("VAT Statement Template Name");
        GLSetup.TestField("VAT Statement Name");

        Calender."Period Start" := StartDate;
        PeriodType := PeriodType::"Accounting Period";

        for i := 1 to NoOfPeriods do begin
            if i <> 1 then
                PeriodPageManagement.NextDate(1, Calender, PeriodType)
            else
                if not PeriodPageManagement.FindDate('=', Calender, PeriodType) then begin
                    PeriodType := PeriodType::Month;
                    if not PeriodPageManagement.FindDate('=', Calender, PeriodType) then
                        Error(Text11300);
                end;

            DateName[i] := PeriodPageManagement.CreatePeriodFormat(PeriodType, Calender."Period Start");
            DateFilter[i] := Format(Calender."Period Start") + '..' + Format(Calender."Period End");

            AccountingPeriod.Reset();
            AccountingPeriod.SetRange("Starting Date", Calender."Period Start");
            AccountingPeriod.SetRange(Name, Calender."Period Name");
            if AccountingPeriod.FindFirst() then
                DateName[i] := AccountingPeriod.Name;
        end;
        DateName[NoOfPeriods + 1] := Text11301;
        GlAccountFilter := "G/L Account".GetFilters();
        Heading := Text11302 + Format(StartDate) + '..' + Format(Calender."Period End");
    end;

    var
        Text11300: Label 'Unable to find period.';
        Text11301: Label 'Total';
        Text11302: Label 'Period: ';
        GLSetup: Record "General Ledger Setup";
        AccountingPeriod: Record "Accounting Period";
        Cust: Record Customer;
        Vend: Record Vendor;
        VATEntry: Record "VAT Entry";
        GLAccount: Record "G/L Account";
        GLEntry1: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        Calender: Record Date;
        VATStatName: Record "VAT Statement Name";
        VATStatLine: Record "VAT Statement Line";
        VATStatement: Report "VAT Statement";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        PeriodType: Enum "Analysis Period Type";
        TotalAmount: array[13] of Decimal;
        GlAccountFilter: Text[250];
        Heading: Text[50];
        StartDate: Date;
        NoOfPeriods: Integer;
        i: Integer;
        DateName: array[13] of Text[20];
        DateFilter: array[12] of Text[20];
        VATDateFilter: Text[20];
        DebitAmt: Decimal;
        TotalDebitAmt: Decimal;
        CreditAmt: Decimal;
        TotalCreditAmt: Decimal;
        SourceName: Text[100];
        BaseVAT: Decimal;
        BaseBefPmtDisc: Decimal;
        TotAmount: Decimal;
        TotBaseVAT: Decimal;
        TotBaseBefPmtDisc: Decimal;
        TotRevenue: Decimal;
        TotNotRevenue: Decimal;
        TotTVAStatement: Decimal;
        SkipHeader: array[4] of Boolean;
        Amount1: Decimal;
        LastDocumentNo: Code[20];
        Total1: Decimal;
        Checklist_between_Revenue_and_VATCaptionLbl: Label 'Checklist between Revenue and VAT';
        Amounts_per_account_per_periodCaptionLbl: Label 'Amounts per account per period';
        No_CaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        TotalsCaptionLbl: Label 'Totals';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Checklist_between_Revenue_and_VATCaption_Control76Lbl: Label 'Checklist between Revenue and VAT';
        Amounts_which_are_not_posted_as_salesCaptionLbl: Label 'Amounts which are not posted as sales';
        No_Caption_Control227Lbl: Label 'No.';
        NameCaption_Control228Lbl: Label 'Name';
        TotalsCaption_Control272Lbl: Label 'Totals';
        Checklist_between_Revenue_and_VATCaption_Control114Lbl: Label 'Checklist between Revenue and VAT';
        Sales_not_posted_in_the_selected_range_of_accounts_CaptionLbl: Label 'Sales not posted in the selected range of accounts.';
        G_L_Account_No_CaptionLbl: Label 'G/L Account No.';
        Doc__TypeCaptionLbl: Label 'Doc. Type';
        Document_No_CaptionLbl: Label 'Document No.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Source_TypeCaptionLbl: Label 'Source Type';
        Source_No_CaptionLbl: Label 'Source No.';
        Debit_AmountCaptionLbl: Label 'Debit Amount';
        Credit_AmountCaptionLbl: Label 'Credit Amount';
        Journal_NameCaptionLbl: Label 'Journal Name';
        TotalsCaption_Control129Lbl: Label 'Totals';
        Checklist_between_Revenue_and_VATCaption_Control19Lbl: Label 'Checklist between Revenue and VAT';
        Total___Posted_revenues_with_difference_between_posted_Amount_and_VAT_Base_AmountCaptionLbl: Label 'Total - Posted revenues with difference between posted Amount and VAT Base Amount';
        Journal_NameCaption_Control146Lbl: Label 'Journal Name';
        Source_NameCaptionLbl: Label 'Source Name';
        AmountCaptionLbl: Label 'Amount';
        Base_VATCaptionLbl: Label 'Base VAT';
        DifferenceCaptionLbl: Label 'Difference';
        Pmt__Disc_CaptionLbl: Label 'Pmt. Disc.';
        OtherCaptionLbl: Label 'Other';
        TotalsCaption_Control180Lbl: Label 'Totals';
        Checklist_between_Revenue_and_VATCaption_Control189Lbl: Label 'Checklist between Revenue and VAT';
        Summary__CaptionLbl: Label 'Summary :';
        Total___Revenues_accounts_in_the_selected_rangeCaptionLbl: Label 'Total - Revenues accounts in the selected range';
        Total___Revenues_which_are_no_sales_or_credit_memos__CaptionLbl: Label 'Total - Revenues which are no sales or credit memos  ';
        Total___Sales_not_posted_in_the_selected_range_of_accounts__Revenues_CaptionLbl: Label 'Total - Sales not posted in the selected range of accounts (Revenues)';
        Total___Posted_revenues_with_difference_between_posted_Amount_and_Base_VATCaptionLbl: Label 'Total - Posted revenues with difference between posted Amount and Base VAT';
        Total__1_CaptionLbl: Label 'Total (1)';
        VAT_statement_amount__2_CaptionLbl: Label 'VAT statement amount (2)';
        Difference__2_____1_CaptionLbl: Label 'Difference (2) - (1)';
}

