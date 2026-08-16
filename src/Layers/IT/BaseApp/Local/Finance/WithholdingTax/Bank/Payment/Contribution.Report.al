// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Vendor;

report 12102 Contribution
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/WithholdingTax/Bank/Payment/Contribution.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Contribution';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(INPS; Contributions)
        {
            DataItemTableView = sorting("Social Security Code", "Vendor No.") order(ascending);
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(MonthDescr; MonthDescr)
            {
            }
            column(INPS_Year; Year)
            {
            }
            column(COMPANYNAME_Control1130028; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4__Control1130037; Format(Today, 0, 4))
            {
            }
            column(MonthDescr_Control1130022; MonthDescr)
            {
            }
            column(INPS_Year_Control1130032; Year)
            {
            }
            column(Vend__No_____________Vend_Name; Vend."No." + ' - ' + Vend.Name)
            {
            }
            column(ContributionType; SelectedContributionType)
            {
            }
            column(ParamYear; SelectedYear)
            {
            }
            column(ParamMonth; SelectedMonth)
            {
            }
            column(FinalPrinting; SelectedFinalPrinting)
            {
            }
            column(INPS_INPS__Vendor_No__; "Vendor No.")
            {
            }
            column(INPS_INPS__Social_Security_Code_; "Social Security Code")
            {
            }
            column(PrintDetails; SelectedPrintDetails)
            {
            }
            column(INPS__Gross_Amount_; "Gross Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Non_Taxable_Amount_; "Non Taxable Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Contribution_Base_; "Contribution Base")
            {
                AutoFormatType = 1;
            }
            column(INPS__Total_Social_Security_Amount_; "Total Social Security Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Free_Lance_Amount_; "Free-Lance Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Company_Amount_; "Company Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Document_Date_; Format("Document Date"))
            {
            }
            column(INPS__External_Document_No__; "External Document No.")
            {
            }
            column(INPS__Gross_Amount__Control1130018; "Gross Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Non_Taxable_Amount__Control1130019; "Non Taxable Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Contribution_Base__Control1130222; "Contribution Base")
            {
                AutoFormatType = 1;
            }
            column(INPS__Total_Social_Security_Amount__Control1130221; "Total Social Security Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Free_Lance_Amount__Control1130223; "Free-Lance Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Company_Amount__Control1130224; "Company Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Social_Security_Code_; "Social Security Code")
            {
            }
            column(INPS__Company_Amount__Control1130025; "Company Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Free_Lance_Amount__Control1130226; "Free-Lance Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Total_Social_Security_Amount__Control1130227; "Total Social Security Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Contribution_Base__Control1130238; "Contribution Base")
            {
                AutoFormatType = 1;
            }
            column(INPS__Non_Taxable_Amount__Control1130255; "Non Taxable Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Gross_Amount__Control1130256; "Gross Amount")
            {
                AutoFormatType = 1;
            }
            column(INPS__Social_Security_Code__Control1130059; "Social Security Code")
            {
            }
            column(INPS_Entry_No_; "Entry No.")
            {
            }
            column(INPS_PaymentCaption; INPS_PaymentCaptionLbl)
            {
            }
            column(MonthDescrCaption; MonthDescrCaptionLbl)
            {
            }
            column(INPS__Social_Security_Code_Caption; FieldCaption("Social Security Code"))
            {
            }
            column(INPS__Gross_Amount_Caption; FieldCaption("Gross Amount"))
            {
            }
            column(INPS__Non_Taxable_Amount_Caption; FieldCaption("Non Taxable Amount"))
            {
            }
            column(INPS__Contribution_Base_Caption; FieldCaption("Contribution Base"))
            {
            }
            column(INPS__Total_Social_Security_Amount_Caption; FieldCaption("Total Social Security Amount"))
            {
            }
            column(INPS__Free_Lance_Amount_Caption; FieldCaption("Free-Lance Amount"))
            {
            }
            column(INPS__Company_Amount_Caption; FieldCaption("Company Amount"))
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(INPS_PaymentCaption_Control1130013; INPS_PaymentCaption_Control1130013Lbl)
            {
            }
            column(INPS__Social_Security_Code_Caption_Control1130134; FieldCaption("Social Security Code"))
            {
            }
            column(INPS__Gross_Amount_Caption_Control1130135; FieldCaption("Gross Amount"))
            {
            }
            column(MonthDescr_Control1130022Caption; MonthDescr_Control1130022CaptionLbl)
            {
            }
            column(INPS__Non_Taxable_Amount_Caption_Control1130136; FieldCaption("Non Taxable Amount"))
            {
            }
            column(INPS__Contribution_Base_Caption_Control1130137; FieldCaption("Contribution Base"))
            {
            }
            column(INPS__Total_Social_Security_Amount_Caption_Control1130138; FieldCaption("Total Social Security Amount"))
            {
            }
            column(INPS__Free_Lance_Amount_Caption_Control1130139; FieldCaption("Free-Lance Amount"))
            {
            }
            column(INPS__Company_Amount_Caption_Control1130140; FieldCaption("Company Amount"))
            {
            }
            column(INPS__Document_Date_Caption; INPS__Document_Date_CaptionLbl)
            {
            }
            column(INPS__External_Document_No__Caption; FieldCaption("External Document No."))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if SelectedContributionType = SelectedContributionType::INAIL then
                    CurrReport.Skip();

                Vend.Get("Vendor No.");
                if SelectedFinalPrinting and
                   not CurrReport.Preview
                then begin
                    "INPS Paid" := true;
                    Modify();
                end;

                if (PrevSocialSecurCode <> "Social Security Code") and
                   SelectedFinalPrinting and
                   not CurrReport.Preview
                then begin
                    Payment.LockTable();
                    Payment.Reset();

                    if Payment.FindLast() then
                        NoEnt := Payment."Entry No." + 1
                    else
                        NoEnt := 1;

                    Payment.Init();
                    Payment."Entry No." := NoEnt;

                    Payment."Contribution Type" := Payment."Contribution Type"::INPS;

                    Payment.Month := Month;
                    Payment.Year := Year;
                    Payment."Gross Amount" := "Gross Amount";
                    Payment."Non Taxable Amount" := "Non Taxable Amount";
                    Payment."Contribution Base" := "Contribution Base";
                    Payment."Total Social Security Amount" := "Total Social Security Amount";
                    Payment."Free-Lance Amount" := "Free-Lance Amount";
                    Payment."Company Amount" := "Company Amount";
                    Payment.Insert();
                end;

                PrevSocialSecurCode := "Social Security Code";
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Social Security Code", '<>%1', '');
                SetRange(Month, SelectedMonth);
                SetRange(Year, SelectedYear);

                if SelectedFinalPrinting and
                   not CurrReport.Preview
                then begin
                    Payment.SetCurrentKey("Contribution Type", Year, Month);
                    Payment.SetFilter("Contribution Type", '%1', SelectedContributionType);
                    Payment.SetRange(Year, SelectedYear);
                    Payment.SetRange(Month, SelectedMonth);

                    if Payment.FindFirst() then begin
                        if not Confirm(PeriodAlreadyPrintedQst, false, SelectedMonth, SelectedYear) then
                            CurrReport.Quit();
                        Payment.DeleteAll();
                        case SelectedContributionType of
                            SelectedContributionType::INPS:
                                ModifyAll("INPS Paid", false);
                            SelectedContributionType::INAIL:
                                ModifyAll("INAIL Paid", false);
                        end;
                    end;
                end;

                if SelectedMonth = 0 then
                    Error(MissingMonthErr);

                Clear(Payment);

                PrevSocialSecurCode := '';
                if (SelectedMonth > 0) and (SelectedMonth < 13) then
                    MonthDescr := Format(DMY2Date(1, SelectedMonth, 1998), 0, '<Month Text>');
            end;
        }
        dataitem(INAIL; Contributions)
        {
            DataItemTableView = sorting("INAIL Code", "Vendor No.") order(ascending);
            column(COMPANYNAME_Control98; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4__Control99; Format(Today, 0, 4))
            {
            }
            column(INAIL_Year; Year)
            {
            }
            column(MonthDescr_Control1130003; MonthDescr)
            {
            }
            column(COMPANYNAME_Control111; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4__Control112; Format(Today, 0, 4))
            {
            }
            column(INAIL_Year_Control1130000; Year)
            {
            }
            column(MonthDescr_Control1130001; MonthDescr)
            {
            }
            column(Vend__No_____________Vend_Name_Control1130072; Vend."No." + ' - ' + Vend.Name)
            {
            }
            column(INAIL_INAIL__INAIL_Code_; "INAIL Code")
            {
            }
            column(ContributionType_Control1130044; SelectedContributionType)
            {
            }
            column(INAIL_INAIL__Vendor_No__; "Vendor No.")
            {
            }
            column(PrintDetails_Control1130042; SelectedPrintDetails)
            {
            }
            column(FinalPrinting_Control1130043; SelectedFinalPrinting)
            {
            }
            column(Imp__Lordo_Sogg__a_Contr_INAIL; "INAIL Gross Amount")
            {
                AutoFormatType = 1;
            }
            column(Quota_non_Imponibile_INAIL; "INAIL Non Taxable Amount")
            {
                AutoFormatType = 1;
            }
            column(Imponibile_Contributivo_INAIL; "INAIL Contribution Base")
            {
                AutoFormatType = 1;
            }
            column(Importo_Tot__Contributo_INAIL; "INAIL Total Amount")
            {
                AutoFormatType = 1;
            }
            column(Quota_a_Carico_Collab__INAIL; "INAIL Free-Lance Amount")
            {
                AutoFormatType = 1;
            }
            column(Quota_a_Carico_Comm__INAIL; "INAIL Company Amount")
            {
                AutoFormatType = 1;
            }
            column(Date_Documento; Format("Document Date"))
            {
            }
            column(Nr__Documento_Esterno; "External Document No.")
            {
            }
            column(Cod__Contributo_INAIL; "INAIL Code")
            {
            }
            column(INAIL__INAIL_Gross_Amount_; "INAIL Gross Amount")
            {
                AutoFormatType = 1;
            }
            column(Quota_non_Imponibile_INAIL_Control1130084; "INAIL Non Taxable Amount")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Contribution_Base_; "INAIL Contribution Base")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Total_Amount_; "INAIL Total Amount")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Free_Lance_Amount_; "INAIL Free-Lance Amount")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Company_Amount_; "INAIL Company Amount")
            {
                AutoFormatType = 1;
            }
            column(Cod__Contributo_INAIL_; "INAIL Code")
            {
            }
            column(INAIL__INAIL_Gross_Amount__Control1130091; "INAIL Gross Amount")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Non_Taxable_Amount_; "INAIL Non Taxable Amount")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Contribution_Base__Control1130093; "INAIL Contribution Base")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Total_Amount__Control1130094; "INAIL Total Amount")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Free_Lance_Amount__Control1130095; "INAIL Free-Lance Amount")
            {
                AutoFormatType = 1;
            }
            column(INAIL__INAIL_Company_Amount__Control1130096; "INAIL Company Amount")
            {
                AutoFormatType = 1;
            }
            column(INAIL_Entry_No_; "Entry No.")
            {
            }
            column(INAIL_PaymentCaption; INAIL_PaymentCaptionLbl)
            {
            }
            column(MonthDescr_Control1130003Caption; MonthDescr_Control1130003CaptionLbl)
            {
            }
            column(Cod__Contributo_INAILCaption; Cod__Contributo_INAILCaptionLbl)
            {
            }
            column(Imp__Lordo_Sogg__a_Contr_INAILCaption; FieldCaption("INAIL Gross Amount"))
            {
            }
            column(Quota_non_Imponibile_INAILCaption; FieldCaption("INAIL Non Taxable Amount"))
            {
            }
            column(Imponibile_Contributivo_INAILCaption; FieldCaption("INAIL Contribution Base"))
            {
            }
            column(Importo_Tot__Contributo_INAILCaption; FieldCaption("INAIL Total Amount"))
            {
            }
            column(Quota_a_Carico_Collab__INAILCaption; FieldCaption("INAIL Free-Lance Amount"))
            {
            }
            column(Quota_a_Carico_Comm__INAILCaption; Quota_a_Carico_Comm__INAILCaptionLbl)
            {
            }
            column(INAIL_PaymentCaption_Control1130016; INAIL_PaymentCaption_Control1130016Lbl)
            {
            }
            column(MonthDescr_Control1130001Caption; MonthDescr_Control1130001CaptionLbl)
            {
            }
            column(Cod__Contributo_INAILCaption_Control1130118; Cod__Contributo_INAILCaption_Control1130118Lbl)
            {
            }
            column(Imp__Lordo_Sogg__a_Contr_INAILCaption_Control1130119; FieldCaption("INAIL Gross Amount"))
            {
            }
            column(Quota_non_Imponibile_INAILCaption_Control1130120; FieldCaption("INAIL Non Taxable Amount"))
            {
            }
            column(Imponibile_Contributivo_INAILCaption_Control1130121; FieldCaption("INAIL Contribution Base"))
            {
            }
            column(Importo_Tot__Contributo_INAILCaption_Control1130122; FieldCaption("INAIL Total Amount"))
            {
            }
            column(Quota_a_Carico_Collab__INAILCaption_Control1130123; FieldCaption("INAIL Free-Lance Amount"))
            {
            }
            column(Quota_a_Carico_Comm__INAILCaption_Control1130124; Quota_a_Carico_Comm__INAILCaption_Control1130124Lbl)
            {
            }
            column(Date_DocumentoCaption; Date_DocumentoCaptionLbl)
            {
            }
            column(Nr__Documento_EsternoCaption; FieldCaption("External Document No."))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if SelectedContributionType = SelectedContributionType::INPS then
                    CurrReport.Skip();

                Vend.Get("Vendor No.");
                if SelectedFinalPrinting and
                   not CurrReport.Preview
                then begin
                    "INAIL Paid" := true;
                    Modify();
                end;

                if (PrevINAILCode <> "INAIL Code") and
                   SelectedFinalPrinting and
                   not CurrReport.Preview
                then begin
                    Payment.LockTable();
                    Payment.Reset();

                    if Payment.FindLast() then
                        NoEnt := Payment."Entry No." + 1
                    else
                        NoEnt := 1;

                    Payment.Init();
                    Payment."Entry No." := NoEnt;

                    Payment."Contribution Type" := SelectedContributionType::INAIL;

                    Payment.Month := Month;
                    Payment.Year := Year;
                    Payment."Gross Amount" := "INAIL Gross Amount";
                    Payment."Non Taxable Amount" := "INAIL Non Taxable Amount";
                    Payment."Contribution Base" := "INAIL Contribution Base";
                    Payment."Total Social Security Amount" := "INAIL Total Amount";
                    Payment."Free-Lance Amount" := "INAIL Free-Lance Amount";
                    Payment."Company Amount" := "INAIL Company Amount";
                    Payment.Insert();
                end;

                PrevINAILCode := "INAIL Code";
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("INAIL Code", '<>%1', '');
                SetRange(Year, SelectedYear);
                SetRange(Month, SelectedMonth);

                PrevINAILCode := '';
                if (SelectedMonth > 0) and (SelectedMonth < 13) then
                    MonthDescr := Format(DMY2Date(1, SelectedMonth, 1998), 0, '<Month Text>');
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
                    field(ContributionType; SelectedContributionType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contribution Type';
                        OptionCaption = 'INPS,INAIL';
                        ToolTip = 'Specifies the contribution type.';
                    }
                    field(ParamMonth; SelectedMonth)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Referring Month';
                        ToolTip = 'Specifies the referring month.';
                    }
                    field(ParamYear; SelectedYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Referring Year';
                        ToolTip = 'Specifies the referring year.';
                    }
                    field(PrintDetails; SelectedPrintDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Details';
                        ToolTip = 'Specifies if you want to print the details section.';
                    }
                    field(FinalPrinting; SelectedFinalPrinting)
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

        trigger OnOpenPage()
        begin
            SelectedMonth := Date2DMY(WorkDate(), 2);
            SelectedYear := Date2DMY(WorkDate(), 3);
            SelectedPrintDetails := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        MonthDescr := '';
        if (SelectedMonth > 0) and (SelectedMonth < 13) then
            MonthDescr := Format(DMY2Date(1, SelectedMonth, 9999), 0, '<Month Text>');
    end;

    var
        Vend: Record Vendor;
        Payment: Record "Contribution Payment";
        NoEnt: Integer;
        SelectedMonth: Integer;
        SelectedYear: Integer;
        SelectedFinalPrinting: Boolean;
        SelectedPrintDetails: Boolean;
        SelectedContributionType: Option INPS,INAIL;
        MonthDescr: Text[30];
        PrevSocialSecurCode: Code[20];
        PrevINAILCode: Code[20];

        PeriodAlreadyPrintedQst: Label 'Period %1/%2 has already been printed. Do you want to print it again?', Comment = '%1 - Month, %2 - Year';
        MissingMonthErr: Label 'Please enter a month.';
        INPS_PaymentCaptionLbl: Label 'INPS Payment';
        MonthDescrCaptionLbl: Label 'Referring Period';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        INPS_PaymentCaption_Control1130013Lbl: Label 'INPS Payment';
        MonthDescr_Control1130022CaptionLbl: Label 'Referring Period';
        INPS__Document_Date_CaptionLbl: Label 'Document Date';
        INAIL_PaymentCaptionLbl: Label 'INAIL Payment';
        MonthDescr_Control1130003CaptionLbl: Label 'Referring Period';
        Cod__Contributo_INAILCaptionLbl: Label 'INAIL Contribution Code';
        Quota_a_Carico_Comm__INAILCaptionLbl: Label 'INAIL Company Amount';
        INAIL_PaymentCaption_Control1130016Lbl: Label 'INAIL Payment';
        MonthDescr_Control1130001CaptionLbl: Label 'Referring Period';
        Cod__Contributo_INAILCaption_Control1130118Lbl: Label 'INAIL Contribution Code';
        Quota_a_Carico_Comm__INAILCaption_Control1130124Lbl: Label 'INAIL Company Amount';
        Date_DocumentoCaptionLbl: Label 'Document Date';
}

