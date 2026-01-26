// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

report 12126 "Annual VAT Comm. - 2010"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/AnnualVATComm2010.rdlc';
    Caption = 'Annual VAT Comm. - 2010';

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            column(VAT_Statement_Name_Statement_Template_Name; "Statement Template Name")
            {
            }
            column(VAT_Statement_Name_Name; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name") where(Print = const(true));

                trigger OnAfterGetRecord()
                begin
                    CalcLineTotal("VAT Statement Line", TotalAmount, 0);

                    if "Print with" = "Print with"::"Opposite Sign" then
                        TotalAmount := -TotalAmount;
                    if "Round Factor" = "Round Factor"::"1" then
                        TotalAmount := Round(TotalAmount, 1, '=');
                    if "Annual VAT Comm. Field" <> 0 then
                        VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"] := TotalAmount;

                    VATCommAmts[15] := VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD4 - Payable VAT"] -
                      VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD5 - Receivable VAT"];
                    if VATCommAmts[15] < 0 then begin
                        VATCommAmts[16] := -VATCommAmts[15];
                        Clear(VATCommAmts[15]);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    for i := 1 to ArrayLen(VATCommAmts) do
                        Clear(VATCommAmts[i]);

                    if SeparateLedger then
                        SeparateLedgerTxt := 'X';
                    if GroupSettlement then
                        GroupSettlementTxt := 'X';
                    if ExceptionalEvent then
                        ExceptionalEventTxt := 'X';
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyInfo_Name; CompanyInfo.Name)
                {
                }
                column(CompanyInfo__Fiscal_Code_; CompanyInfo."Fiscal Code")
                {
                }
                column(DATE2DMY_StartDate__3____1; Date2DMY(StartDate, 3) + 1)
                {
                }
                column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                {
                }
                column(ActivityCode_Code; ActivityCode2.Code)
                {
                }
                column(SeparateLedgerTxt; SeparateLedgerTxt)
                {
                }
                column(GroupSettlementTxt; GroupSettlementTxt)
                {
                }
                column(ExceptionalEventTxt; ExceptionalEventTxt)
                {
                }
                column(Vendor__Fiscal_Code_; Vendor."Fiscal Code")
                {
                }
                column(AppointmentCode_Code; AppointmentCode.Code)
                {
                }
                column(Vendor__VAT_Registration_No__; Vendor."VAT Registration No.")
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Total_sales__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD1 - Total sales"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Sales_with_zero_VAT__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD1 - Sales with zero VAT"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___VAT_exempt_sales__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD1 - VAT exempt sales"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___EU_sales__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD1 - EU sales"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Total_purchases__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD2 - Total purchases"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Purchases_with_zero_VAT__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD2 - Purchases with zero VAT"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___VAT_exempt_purchases__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD2 - VAT exempt purchases"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___EU_purchases__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD2 - EU purchases"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____9__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD3 - Gold and Silver Base"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____11__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD3 - Scrap and Recycl. Base"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____10__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD3 - Gold and Silver Amount"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____12__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD3 - Scrap and Recycl. Amount"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Purchases_Of_Capital_Goods__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD2 - Purchases of Capital Goods"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Sales_Of_Capital_Goods__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD1 - Sales of Capital Goods"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD4___Payable_VAT__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD4 - Payable VAT"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD5___Receivable_VAT__; VATCommAmts["VAT Statement Line"."Annual VAT Comm. Field"::"CD5 - Receivable VAT"])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____15__; VATCommAmts[15])
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____16__; VATCommAmts[16])
                {
                }
                column(EmptyString; '')
                {
                }
                column(EmptyString_Control1130089; '')
                {
                }
                column(Integer_Number; Number)
                {
                }
                column(CompanyInfo_NameCaption; CompanyInfo_NameCaptionLbl)
                {
                }
                column(CompanyInfo__Fiscal_Code_Caption; CompanyInfo__Fiscal_Code_CaptionLbl)
                {
                }
                column(SEC__I_GENERAL_DATACaption; SEC__I_GENERAL_DATACaptionLbl)
                {
                }
                column(DATE2DMY_StartDate__3____1Caption; DATE2DMY_StartDate__3____1CaptionLbl)
                {
                }
                column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
                {
                }
                column(TAXPAYER__Caption; TAXPAYER__CaptionLbl)
                {
                }
                column(ActivityCode_CodeCaption; ActivityCode_CodeCaptionLbl)
                {
                }
                column(SeparateLedgerTxtCaption; SeparateLedgerTxtCaptionLbl)
                {
                }
                column(GroupSettlementTxtCaption; GroupSettlementTxtCaptionLbl)
                {
                }
                column(ExceptionalEventTxtCaption; ExceptionalEventTxtCaptionLbl)
                {
                }
                column(DECLARANT__COMPLETE_IF_DIFFERENT_FROM_THE_TAXPAYER___Caption; DECLARANT__COMPLETE_IF_DIFFERENT_FROM_THE_TAXPAYER___CaptionLbl)
                {
                }
                column(Vendor__Fiscal_Code_Caption; Vendor__Fiscal_Code_CaptionLbl)
                {
                }
                column(AppointmentCode_CodeCaption; AppointmentCode_CodeCaptionLbl)
                {
                }
                column(Vendor__VAT_Registration_No__Caption; Vendor__VAT_Registration_No__CaptionLbl)
                {
                }
                column(SEC__II_INFORMATION_RELATING_TO_TRANSACTIONS_CARRIED_OUTCaption; SEC__II_INFORMATION_RELATING_TO_TRANSACTIONS_CARRIED_OUTCaptionLbl)
                {
                }
                column(ASSET_TRANSACTION__Caption; ASSET_TRANSACTION__CaptionLbl)
                {
                }
                column(LIABILITY_TRANSACTIONS__Caption; LIABILITY_TRANSACTIONS__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Total_sales__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Total_sales__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Sales_with_zero_VAT__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Sales_with_zero_VAT__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___VAT_exempt_sales__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___VAT_exempt_sales__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___EU_sales__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___EU_sales__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Total_purchases__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Total_purchases__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Purchases_with_zero_VAT__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Purchases_with_zero_VAT__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___VAT_exempt_purchases__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___VAT_exempt_purchases__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___EU_purchases__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___EU_purchases__CaptionLbl)
                {
                }
                column(IMPORTATION_WITHOUT_PAYING_VAT_ON_ENTRY_INTO_CUSTOMS__Caption; IMPORTATION_WITHOUT_PAYING_VAT_ON_ENTRY_INTO_CUSTOMS__CaptionLbl)
                {
                }
                column(CD_3Caption; CD_3CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____9__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____9__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____11__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____11__CaptionLbl)
                {
                }
                column(TaxableCaption; TaxableCaptionLbl)
                {
                }
                column(TaxableCaption_Control1130077; TaxableCaption_Control1130077Lbl)
                {
                }
                column(TaxCaption; TaxCaptionLbl)
                {
                }
                column(TaxCaption_Control1130079; TaxCaption_Control1130079Lbl)
                {
                }
                column(CD_1Caption; CD_1CaptionLbl)
                {
                }
                column(CD_2Caption; CD_2CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Purchases_Of_Capital_Goods__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Purchases_Of_Capital_Goods__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Sales_Of_Capital_Goods__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Sales_Of_Capital_Goods__CaptionLbl)
                {
                }
                column(SEC__III_CALCULA__TION_OF_OUTPUT_OR_INPUT_TAXCaption; SEC__III_CALCULA__TION_OF_OUTPUT_OR_INPUT_TAXCaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD4___Payable_VAT__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD4___Payable_VAT__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD5___Receivable_VAT__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD5___Receivable_VAT__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____15__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____15__CaptionLbl)
                {
                }
                column(VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____16__Caption; VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____16__CaptionLbl)
                {
                }
                column(CD_4Caption; CD_4CaptionLbl)
                {
                }
                column(CD_5Caption; CD_5CaptionLbl)
                {
                }
                column(CD_6Caption; CD_6CaptionLbl)
                {
                }
                column(SIGNING_THE_COMMUNICA__TIONCaption; SIGNING_THE_COMMUNICA__TIONCaptionLbl)
                {
                }
                column(SignatureCaption; SignatureCaptionLbl)
                {
                }
                column(UNDERTAKING_TO_SUBMIT_ELECTRONICAL_LYCaption; UNDERTAKING_TO_SUBMIT_ELECTRONICAL_LYCaptionLbl)
                {
                }
                column(Reserved_for_IntermediaryCaption; Reserved_for_IntermediaryCaptionLbl)
                {
                }
                column(EmptyStringCaption; EmptyStringCaptionLbl)
                {
                }
                column(EmptyString_Control1130089Caption; EmptyString_Control1130089CaptionLbl)
                {
                }
                column(Undertaking_to_submit_the_communication_prepared_by_the_taxpayer_electronicallyCaption; Undertaking_to_submit_the_communication_prepared_by_the_taxpayer_electronicallyCaptionLbl)
                {
                }
                column(Undertaking_to_submit_the_taxpayer_s_communication_prepared_by_the_sender_electronicallyCaption; Undertaking_to_submit_the_taxpayer_s_communication_prepared_by_the_sender_electronicallyCaptionLbl)
                {
                }
                column(Date_of_the_under__takingCaption; Date_of_the_under__takingCaptionLbl)
                {
                }
                column(SIGNATURE_OF_INTERME__DIARYCaption; SIGNATURE_OF_INTERME__DIARYCaptionLbl)
                {
                }
                column(day__month___yearCaption; day__month___yearCaptionLbl)
                {
                }
            }

            trigger OnPreDataItem()
            begin
                "VAT Statement Name".SetRange("Statement Template Name", "VAT Statement Name"."Statement Template Name");
                "VAT Statement Name".SetFilter(Name, '%1', "VAT Statement Name".Name);
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
                    field("CompanyInfo.Name"; CompanyInfo.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the name of the company.';
                    }
                    field(StatementTemplate; "VAT Statement Name"."Statement Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statement Template';
                        TableRelation = "VAT Statement Template".Name;
                        ToolTip = 'Specifies the statement template.';

                        trigger OnValidate()
                        begin
                            "VAT Statement Name".SetRange("Statement Template Name", "VAT Statement Name"."Statement Template Name");
                        end;
                    }
                    field(StatementName; "VAT Statement Name".Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statement Name';
                        ToolTip = 'Specifies the statement name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if ACTION::LookupOK = PAGE.RunModal(0, "VAT Statement Name", "VAT Statement Name".Name) then;
                        end;
                    }
                    field(ActivityCode; ActivityCode2.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Activity Code';
                        TableRelation = "Activity Code".Code;
                        ToolTip = 'Specifies a code that describes a primary activity for the company.';
                    }
                    field(SeparateLedger; SeparateLedger)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Separate Ledger';
                        ToolTip = 'Specifies the separate ledger.';
                    }
                    field(GroupSettlement; GroupSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group Settlement';
                        ToolTip = 'Specifies the related group settlement.';
                    }
                    field(ExceptionalEvent; ExceptionalEvent)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exceptional Event';
                        ToolTip = 'Specifies if this is for an exceptional event.';
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the start date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the end date.';
                    }
                    field(AppointmentCodeControl; AppointmentCode.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Appointment Code';
                        Enabled = AppointmentCodeControlEnable;
                        TableRelation = "Appointment Code".Code;
                        ToolTip = 'Specifies a code for the capacity in which the company can submit VAT statements on behalf of other legal entities.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            AppointmentCodeControlEnable := true;
        end;

        trigger OnOpenPage()
        begin
            AppointmentCodeControlEnable := CompanyInfo."Tax Representative No." <> '';
            if "VAT Statement Name"."Statement Template Name" <> '' then
                "VAT Statement Name".SetRange("Statement Template Name", "VAT Statement Name"."Statement Template Name");
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        GeneralLedgerSetup.GetRecordOnce();
    end;

    trigger OnPreReport()
    begin
        if CompanyInfo."Tax Representative No." <> '' then begin
            Vendor.Get(CompanyInfo."Tax Representative No.");
            Vendor.TestField("Fiscal Code");
            Vendor.TestField("VAT Registration No.");
            AppointmentCode.TestField(Code);
        end else
            Clear(AppointmentCode);

        "VAT Statement Name".SetRange("Statement Template Name", "VAT Statement Name"."Statement Template Name");
        if GeneralLedgerSetup."Use Activity Code" then
            "VAT Statement Line".SetFilter("Activity Code Filter", '%1', ActivityCode2.Code);
        "VAT Statement Line".SetRange("Date Filter", StartDate, EndDate);

        Selection := Selection::"Open and Closed";
        PeriodSelection := PeriodSelection::"Within Period";
        PrintInIntegers := false;
        VATPeriod := '';
        InitializeVATStatement("VAT Statement Name", "VAT Statement Line", Selection, PeriodSelection, PrintInIntegers,
          false, VATPeriod);
    end;

    var
        Vendor: Record Vendor;
        AppointmentCode: Record "Appointment Code";
        ActivityCode2: Record "Activity Code";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        VATStatement: Report "VAT Statement";
        SeparateLedger: Boolean;
        GroupSettlement: Boolean;
        ExceptionalEvent: Boolean;
        PrintInIntegers: Boolean;
        i: Integer;
        TotalAmount: Decimal;
        VATCommAmts: array[18] of Decimal;
        EndDate: Date;
        StartDate: Date;
        VATPeriod: Code[10];
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        SeparateLedgerTxt: Text[1];
        GroupSettlementTxt: Text[1];
        ExceptionalEventTxt: Text[1];
        AppointmentCodeControlEnable: Boolean;
        CompanyInfo_NameCaptionLbl: Label 'COMPANY NAME OR SURNAME AND NAME';
        CompanyInfo__Fiscal_Code_CaptionLbl: Label 'TAX CODE';
        SEC__I_GENERAL_DATACaptionLbl: Label 'SEC. I\GENERAL DATA';
        DATE2DMY_StartDate__3____1CaptionLbl: Label 'Fiscal Year';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT registration no.';
        TAXPAYER__CaptionLbl: Label '- TAXPAYER -';
        ActivityCode_CodeCaptionLbl: Label 'Activity code';
        SeparateLedgerTxtCaptionLbl: Label 'Separate accounting';
        GroupSettlementTxtCaptionLbl: Label 'Communication by a company belonging to a VAT group';
        ExceptionalEventTxtCaptionLbl: Label 'Special occurrences';
        DECLARANT__COMPLETE_IF_DIFFERENT_FROM_THE_TAXPAYER___CaptionLbl: Label '- DECLARANT (COMPLETE IF DIFFERENT FROM THE TAXPAYER) -';
        Vendor__Fiscal_Code_CaptionLbl: Label 'Tax code';
        AppointmentCode_CodeCaptionLbl: Label 'Appointment code';
        Vendor__VAT_Registration_No__CaptionLbl: Label 'Tax code of the\declarant company';
        SEC__II_INFORMATION_RELATING_TO_TRANSACTIONS_CARRIED_OUTCaptionLbl: Label 'SEC. II\INFORMATION\RELATING TO\TRANSACTIONS\CARRIED OUT';
        ASSET_TRANSACTION__CaptionLbl: Label '- ASSET TRANSACTION -';
        LIABILITY_TRANSACTIONS__CaptionLbl: Label '- LIABILITY TRANSACTIONS -';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Total_sales__CaptionLbl: Label 'Total of the asset transactions (net of VAT)';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___Sales_with_zero_VAT__CaptionLbl: Label 'of which: non-taxable transactions', Comment = 'Total of the asset transactions (net of VAT) of which: non-taxable transactions.';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___VAT_exempt_sales__CaptionLbl: Label 'Exempt Transactions.';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD1___EU_sales__CaptionLbl: Label 'Intra-community sale of goods.';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Total_purchases__CaptionLbl: Label 'Total liability transactions (net of VAT)';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Purchases_with_zero_VAT__CaptionLbl: Label 'of which: non-taxable purchases', Comment = 'Total liability transactions (net of VAT) of which: non-taxable purchases.';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___VAT_exempt_purchases__CaptionLbl: Label 'Exempt Purchases.';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___EU_purchases__CaptionLbl: Label 'Intra-community purchases of goods.';
        IMPORTATION_WITHOUT_PAYING_VAT_ON_ENTRY_INTO_CUSTOMS__CaptionLbl: Label '- IMPORTATION WITHOUT PAYING VAT ON ENTRY INTO CUSTOMS -';
        CD_3CaptionLbl: Label 'CD 3';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____9__CaptionLbl: Label 'Industrial gold and pure silver';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____11__CaptionLbl: Label 'Scrap and other recycled material';
        TaxableCaptionLbl: Label 'Taxable';
        TaxableCaption_Control1130077Lbl: Label 'Taxable';
        TaxCaptionLbl: Label 'Tax';
        TaxCaption_Control1130079Lbl: Label 'Tax';
        CD_1CaptionLbl: Label 'CD 1';
        CD_2CaptionLbl: Label 'CD 2';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Purchases_Of_Capital_Goods__CaptionLbl: Label 'Purchases of capital goods';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD2___Sales_Of_Capital_Goods__CaptionLbl: Label 'Sales of capital goods';
        SEC__III_CALCULA__TION_OF_OUTPUT_OR_INPUT_TAXCaptionLbl: Label 'SEC. III CALCULA-\TION OF OUTPUT\OR INPUT TAX';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD4___Payable_VAT__CaptionLbl: Label 'Input tax';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____CD5___Receivable_VAT__CaptionLbl: Label 'VAT deducted';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____15__CaptionLbl: Label 'Output tax';
        VATCommAmts__VAT_Statement_Line___Annual_VAT_Comm__Field____16__CaptionLbl: Label 'Or input tax';
        CD_4CaptionLbl: Label 'CD 4';
        CD_5CaptionLbl: Label 'CD 5';
        CD_6CaptionLbl: Label 'CD 6';
        SIGNING_THE_COMMUNICA__TIONCaptionLbl: Label 'SIGNING THE\COMMUNICA-\TION';
        SignatureCaptionLbl: Label 'Signature';
        UNDERTAKING_TO_SUBMIT_ELECTRONICAL_LYCaptionLbl: Label 'UNDERTAKING\TO SUBMIT\ELECTRONICAL\LY';
        Reserved_for_IntermediaryCaptionLbl: Label 'Reserved for\Intermediary';
        EmptyStringCaptionLbl: Label 'Tax code of the intermediary';
        EmptyString_Control1130089CaptionLbl: Label 'C.A.F. registration no.';
        Undertaking_to_submit_the_communication_prepared_by_the_taxpayer_electronicallyCaptionLbl: Label 'Undertaking to submit the communication prepared by the taxpayer electronically';
        Undertaking_to_submit_the_taxpayer_s_communication_prepared_by_the_sender_electronicallyCaptionLbl: Label 'Undertaking to submit the taxpayer''s communication prepared by the sender electronically';
        Date_of_the_under__takingCaptionLbl: Label 'Date of the under-\taking';
        SIGNATURE_OF_INTERME__DIARYCaptionLbl: Label 'SIGNATURE OF INTERME-\DIARY';
        day__month___yearCaptionLbl: Label ' day  month   year', Comment = 'Day / Month / Year';

    [Scope('OnPrem')]
    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    begin
        VATStatement.CalcLineTotal(VATStmtLine2, TotalAmount, Level);
    end;

    [Scope('OnPrem')]
    procedure InitializeVATStatement(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; NewVATPeriod: Code[10])
    begin
        VATStatement.InitializeRequest(
          NewVATStmtName, NewVATStatementLine, NewSelection, NewPeriodSelection, NewPrintInIntegers, NewUseAmtsInAddCurr, NewVATPeriod);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewStatementTemplateName: Code[20]; NewStatementName: Code[20]; NewAppointmentCode: Code[2]; NewStartDate: Date; NewEndDate: Date)
    begin
        InitializeRequestWithActivityCode(NewStatementTemplateName, NewStatementName, '', NewAppointmentCode, NewStartDate, NewEndDate);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequestWithActivityCode(NewStatementTemplateName: Code[20]; NewStatementName: Code[20]; NewActivityCode: Code[6]; NewAppointmentCode: Code[2]; NewStartDate: Date; NewEndDate: Date)
    begin
        "VAT Statement Name"."Statement Template Name" := NewStatementTemplateName;
        "VAT Statement Name".Name := NewStatementName;
        ActivityCode2.Code := NewActivityCode;
        AppointmentCode.Code := NewAppointmentCode;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
    end;
}

