// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.Telemetry;
using System.Utilities;

report 12121 "G/L Book - Print"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/GLBookPrint.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Book - Print';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyInformation_7_; CompanyInformation[7])
            {
            }
            column(CompanyInformation_5_; CompanyInformation[5])
            {
            }
            column(CompanyInformation_4_; CompanyInformation[4])
            {
            }
            column(CompanyInformation_3_; CompanyInformation[3])
            {
            }
            column(CompanyInformation_2_; CompanyInformation[2])
            {
            }
            column(CompanyInformation_1_; CompanyInformation[1])
            {
            }
            column(CompanyInformation_6_; CompanyInformation[6])
            {
            }
            column(PrintCompanyInformations_g1; PrintCompanyInformations)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Register_Company_No_Caption; Register_Company_No_CaptionLbl)
            {
            }
            column(CompanyInformation_6_Caption; CompanyInformation_6_CaptionLbl)
            {
            }
            column(CompanyInformation_5_Caption; CompanyInformation_5_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not PrintCompanyInformations then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                if PrintCompanyInformations then
                    for i := 1 to 6 do
                        if CompanyInformation[i] = '' then
                            Error(Text1049);
                if ReportType <> ReportType::"Test Print" then
                    CompanyInformation[7] := Text1047;
            end;
        }
        dataitem("GL Book Entry"; "GL Book Entry")
        {
            CalcFields = "Debit Amount", "Credit Amount", Amount, Description;
            DataItemTableView = sorting("Official Date") order(ascending);
            column(LastPrintedPageNo; LastPrintedPageNo)
            {
            }
            column(IsTestPrint; ReportType = ReportType::"Test Print")
            {
            }
            column(Text2038; Text2038Lbl)
            {
            }
            column(PrintCompanyInformations; PrintCompanyInformations)
            {
            }
            column(CompanyInformation_6__Control1130207; CompanyInformation[6])
            {
            }
            column(StartCredit; StartCredit)
            {
                AutoFormatType = 1;
            }
            column(StartDebit; StartDebit)
            {
                AutoFormatType = 1;
            }
            column(CreditPage_StartCredit; CreditPage + StartCredit)
            {
                AutoFormatType = 1;
            }
            column(DebitPage_StartDebit; DebitPage + StartDebit)
            {
                AutoFormatType = 1;
            }
            column(Descr; Descr)
            {
            }
            column(GL_Book_Entry__Credit_Amount_; "Credit Amount")
            {
                AutoFormatType = 1;
            }
            column(GL_Book_Entry__Debit_Amount_; "Debit Amount")
            {
                AutoFormatType = 1;
            }
            column(GL_Book_Entry_Description; Description)
            {
            }
            column(GLAcc_Name; GLAcc.Name)
            {
            }
            column(GL_Book_Entry__G_L_Account_No__; "G/L Account No.")
            {
            }
            column(GL_Book_Entry__External_Document_No__; "External Document No.")
            {
            }
            column(GL_Book_Entry__Document_Date_; Format("Document Date"))
            {
            }
            column(GL_Book_Entry__Document_Type_; "Document Type")
            {
            }
            column(GL_Book_Entry__Document_No__; "Document No.")
            {
            }
            column(NORMALDATE__Posting_Date__; Format(NormalDate("Posting Date")))
            {
            }
            column(GL_Book_Entry__Official_Date_; Format("Official Date"))
            {
            }
            column(LastNo; LastNo)
            {
            }
            column(GLEntry_Amount; GLEntry.Amount)
            {
            }
            column(Descr_Control1130060; Descr)
            {
            }
            column(GL_Book_Entry__Credit_Amount__Control1130061; "Credit Amount")
            {
                AutoFormatType = 1;
            }
            column(GL_Book_Entry__Debit_Amount__Control1130062; "Debit Amount")
            {
                AutoFormatType = 1;
            }
            column(GL_Book_Entry_Description_Control1130063; Description)
            {
            }
            column(GLAcc_Name_Control1130064; GLAcc.Name)
            {
            }
            column(GL_Book_Entry__G_L_Account_No___Control1130065; "G/L Account No.")
            {
            }
            column(GL_Book_Entry__External_Document_No___Control1130066; "External Document No.")
            {
            }
            column(GL_Book_Entry__Document_Date__Control1130067; Format("Document Date"))
            {
            }
            column(GL_Book_Entry__Document_Type__Control1130068; "Document Type")
            {
            }
            column(GL_Book_Entry__Document_No___Control1130069; "Document No.")
            {
            }
            column(NORMALDATE__Posting_Date___Control1130070; NormalDate("Posting Date"))
            {
            }
            column(GL_Book_Entry__Official_Date__Control1130071; Format("Official Date"))
            {
            }
            column(LastNo_Control1130072; LastNo)
            {
            }
            column(CreditPage_StartCredit_Control1130016; CreditPage + StartCredit)
            {
                AutoFormatType = 1;
            }
            column(DebitPage_StartDebit_Control1130017; DebitPage + StartDebit)
            {
                AutoFormatType = 1;
            }
            column(TotalDebit_StartDebit; TotalDebit + StartDebit)
            {
                AutoFormatType = 1;
            }
            column(TotalCredit_StartCredit; TotalCredit + StartCredit)
            {
                AutoFormatType = 1;
            }
            column(GL_Book_Entry_Entry_No_; "Entry No.")
            {
            }
            column(PageNoPrefix; StrSubstNo(Text1038, Format(Date2DMY(FiscalYearStartDate, 3))))
            {
            }
            column(CompanyInformation_6__Control1130207Caption; CompanyInformation_6__Control1130207CaptionLbl)
            {
            }
            column(GL_Book_Entry_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(GL_Book_Entry__Debit_Amount_Caption; FieldCaption("Debit Amount"))
            {
            }
            column(GL_Book_Entry__Credit_Amount_Caption; FieldCaption("Credit Amount"))
            {
            }
            column(DescrCaption; DescrCaptionLbl)
            {
            }
            column(GLAcc_NameCaption; GLAcc_NameCaptionLbl)
            {
            }
            column(GL_Book_Entry__G_L_Account_No__Caption; FieldCaption("G/L Account No."))
            {
            }
            column(GL_Book_Entry__External_Document_No__Caption; FieldCaption("External Document No."))
            {
            }
            column(GL_Book_Entry__Document_Date_Caption; GL_Book_Entry__Document_Date_CaptionLbl)
            {
            }
            column(GL_Book_Entry__Document_Type_Caption; FieldCaption("Document Type"))
            {
            }
            column(GL_Book_Entry__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(NORMALDATE__Posting_Date__Caption; NORMALDATE__Posting_Date__CaptionLbl)
            {
            }
            column(GL_Book_Entry__Official_Date_Caption; GL_Book_Entry__Official_Date_CaptionLbl)
            {
            }
            column(LastNoCaption; LastNoCaptionLbl)
            {
            }
            column(Total_on_Previous_PeriodCaption; Total_on_Previous_PeriodCaptionLbl)
            {
            }
            column(Total_on_Previous_PageCaption; Total_on_Previous_PageCaptionLbl)
            {
            }
            column(Total_in_this_PageCaption; Total_in_this_PageCaptionLbl)
            {
            }
            column(Final_TotalCaption; Final_TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if ReportType = ReportType::Reprint then
                    LastNo := "Progressive No."
                else
                    LastNo := LastNo + 1;

                TotalDebit := TotalDebit + "Debit Amount";
                TotalCredit := TotalCredit + "Credit Amount";

                if GLAcc.Get("G/L Account No.") then;

                if "Document Date" <> 0D then
                    "Document Date" := NormalDate("Document Date");
                Descr := '';
                case "Source Type" of
                    "Source Type"::Customer:
                        GetBillToName();
                    "Source Type"::Vendor:
                        GetPayToName();
                    "Source Type"::"Bank Account":
                        begin
                            BankAccount.SetLoadFields(Name);
                            BankAccount.Get("Source No.");
                            Descr := BankAccount.Name;
                        end;
                    "Source Type"::"Fixed Asset":
                        begin
                            FA.SetLoadFields(Description);
                            if FA.Get("Source No.") then
                                Descr := FA.Description;
                        end;
                end;

                if (not CurrReport.Preview) and
                   (ReportType = ReportType::"Final Print")
                then begin
                    TempGLBookEntry."Entry No." := "Entry No.";
                    TempGLBookEntry."Progressive No." := LastNo;
                    TempGLBookEntry.Insert();
                end;

                DebitPage := DebitPage + "Debit Amount";
                CreditPage := CreditPage + "Credit Amount";
            end;

            trigger OnPostDataItem()
            begin
                if (not CurrReport.Preview) and (ReportType = ReportType::"Final Print") then
                    if TempGLBookEntry.FindSet() then
                        repeat
                            GLBookEntry2.Get(TempGLBookEntry."Entry No.");
                            GLBookEntry2."Progressive No." := TempGLBookEntry."Progressive No.";
                            GLBookEntry2.Modify();
                        until TempGLBookEntry.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                GLBookEntry.Reset();
                GLBookEntry.SetCurrentKey("Official Date");
                GLBookEntry.SetRange("Progressive No.", 0);
                GLBookEntry.SetFilter("Official Date", '<%1', StartDate);
                GLBookEntry.SetFilter(Amount, '<>0');

                if GLBookEntry.FindFirst() and
                   (ReportType <> ReportType::"Test Print")
                then
                    Error(Text1037,
                      GLBookEntry.FieldCaption("Entry No."), GLBookEntry."Entry No.");

                if FiscalYearStartDate <> StartDate then begin
                    StartDebit := GLSetup."Official Debit Amount";
                    StartCredit := GLSetup."Official Credit Amount";
                end else begin
                    StartDebit := 0;
                    StartCredit := 0;
                end;

                if ReportType = ReportType::Reprint then begin
                    StartDebit := 0;
                    StartCredit := 0;
                    GLBookEntry2.Reset();
                    GLBookEntry2.SetCurrentKey("Official Date");
                    GLBookEntry2.SetFilter("Official Date", '>=%1&<%2', FiscalYearStartDate, StartDate);
                    if GLBookEntry2.FindSet() then
                        repeat
                            GLBookEntry2.CalcFields("Debit Amount", "Credit Amount");
                            StartDebit := StartDebit + GLBookEntry2."Debit Amount";
                            StartCredit := StartCredit + GLBookEntry2."Credit Amount";
                        until GLBookEntry2.Next() = 0;
                    SetCurrentKey("Progressive No.");
                end;

                SetFilter("Official Date", '%1..%2', StartDate, EndDate);

                if (ReportType = ReportType::"Final Print") or
                   (ReportType = ReportType::"Test Print")
                then
                    SetRange("Progressive No.", 0)
                else
                    SetFilter("Progressive No.", '%1..', FromProgressiveNo);

                if PrintCompanyInformations then
                    LastPrintedPageNo := GLSetup."Last Printed G/L Book Page" - 1
                else
                    LastPrintedPageNo := GLSetup."Last Printed G/L Book Page";

                if ReportType = ReportType::Reprint then begin
                    ReprintInfo.Get(ReprintInfo.Report::"G/L Book - Print", StartDate, EndDate, '');
                    if PrintCompanyInformations then
                        LastPrintedPageNo := ReprintInfo."First Page Number" - 2
                    else
                        LastPrintedPageNo := ReprintInfo."First Page Number" - 1;
                end;

                if (not CurrReport.Preview) and (ReportType = ReportType::"Final Print") then
                    TempGLBookEntry.DeleteAll();
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
                    field(ReportType; ReportType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Type';
                        OptionCaption = 'Test Print,Final Print,Reprint';
                        ToolTip = 'Specifies the report type.';

                        trigger OnValidate()
                        begin
                            if ReportType = ReportType::Reprint then
                                if LastDate = 0D then
                                    Error(Text1039);
                            "From Progressive No.Editable" := ReportType = ReportType::Reprint;
                            if ReportType <> ReportType::Reprint then
                                Clear(FromProgressiveNo);
                        end;
                    }
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the start date.';

                        trigger OnValidate()
                        begin
                            if StartDate = 0D then
                                Error(Text1040);

                            if (ReportType <> ReportType::Reprint) and
                               (StartDate < LastDate)
                            then
                                Error(Text1041, LastDate);

                            ValidateDate();
                        end;
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date.';

                        trigger OnValidate()
                        begin
                            if EndDate = 0D then
                                Error(Text1042);

                            if EndDate < StartDate then
                                Error(Text1043, StartDate);

                            if (ReportType = ReportType::Reprint) and
                               (LastDate <> 0D) and
                               (EndDate > LastDate)
                            then
                                Error(Text1044, LastDate);
                        end;
                    }
                    field("From Progressive No."; FromProgressiveNo)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'From Progressive No.';
                        Editable = "From Progressive No.Editable";
                        ToolTip = 'Specifies the start number of the progressive number range.';
                    }
                    field(PrintCompanyInformations; PrintCompanyInformations)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Informations';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to print your company information.';
                    }
                    field(Name; CompanyInformation[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name.';
                    }
                    field(Address; CompanyInformation[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        ToolTip = 'Specifies the company''s address.';
                    }
                    field("CompanyInformation[3]"; CompanyInformation[3])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code  City  County';
                        ToolTip = 'Specifies the post code, city, and county.';
                    }
                    field(RegisterCompanyNo; CompanyInformation[4])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Register Company No.';
                        ToolTip = 'Specifies the register company number.';
                    }
                    field(VATRegistrationNo; CompanyInformation[5])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Registration No.';
                        ToolTip = 'Specifies the VAT registration number of your company or your tax representative.';
                    }
                    field(FiscalCode; CompanyInformation[6])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Code';
                        ToolTip = 'Specifies the fiscal code.';
                    }
                    field("GLSetup.""Last Printed G/L Book Page"""; GLSetup."Last Printed G/L Book Page")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Printed G/L Book Page';
                        Editable = false;
                        ToolTip = 'Specifies the last printed page for the G/L Book report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            "From Progressive No.Editable" := true;
        end;

        trigger OnOpenPage()
        begin
            "From Progressive No.Editable" := ReportType = ReportType::Reprint;
            PrintCompanyInformations := true;
            CompInfo.Get();
            CompanyInformation[1] := CompInfo.Name;
            CompanyInformation[2] := CompInfo.Address;
            CompanyInformation[3] := CompInfo."Post Code" + '  ' + CompInfo.City + '  ' + CompInfo.County;
            CompanyInformation[4] := CompInfo."Register Company No.";
            CompanyInformation[6] := CompInfo."Fiscal Code";
            CompanyInformation[5] := CompInfo."VAT Registration No.";
            CompanyInformation[7] := Text1048;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        FeatureTelemetry.LogUptake('1000HP8', ITGLBookTok, Enum::"Feature Uptake Status"::Discovered);
        GLSetup.Get();

        LastDate := GLSetup."Last Gen. Jour. Printing Date";
        LastNo := GLSetup."Last General Journal No.";

        if LastDate <> 0D then begin
            StartDate := CalcDate('<+1D>', LastDate);
            ValidateDate();
        end;
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('1000HQ0', ITGLBookTok, Enum::"Feature Uptake Status"::"Used");
        if not CurrReport.Preview and
           (ReportType = ReportType::"Final Print")
        then begin
            ReprintInfo.Report := ReprintInfo.Report::"G/L Book - Print";
            ReprintInfo."Start Date" := StartDate;
            ReprintInfo."End Date" := EndDate;
            ReprintInfo."Vat Register Code" := '';
            ReprintInfo."First Page Number" := GLSetup."Last Printed G/L Book Page" + 1;
            ReprintInfo.Insert();
            GLSetup."Last Gen. Jour. Printing Date" := EndDate;
            GLSetup."Last General Journal No." := LastNo;
            GLSetup."Official Debit Amount" := TotalDebit + StartDebit;
            GLSetup."Official Credit Amount" := TotalCredit + StartCredit;
            GLSetup.Modify();
            if not Confirm(Text1045, false) then
                Error('');
            Message(Text1036);
            Message(Text12100, GLSetup.FieldCaption("Last Printed G/L Book Page"), GLSetup.TableCaption());
        end;
        FeatureTelemetry.LogUsage('1000HQ1', ITGLBookTok, 'IT GL Books and VAT Registers Printed');
    end;

    trigger OnPreReport()
    var
        ITReportManagement: Codeunit "IT - Report Management";
    begin
        FeatureTelemetry.LogUptake('1000HP9', ITGLBookTok, Enum::"Feature Uptake Status"::"Set up");
        if (EndDate <> 0D) and
           (StartDate > EndDate)
        then
            Error(Text1034, EndDate);

        ITReportManagement.CheckSalesDocNoGaps(EndDate, true, false);
        ITReportManagement.CheckPurchDocNoGaps(EndDate, true, false);

        AccPeriod.Reset();
        AccPeriod.SetRange("New Fiscal Year", true);
        AccPeriod.SetFilter("Starting Date", '<=%1', StartDate);

        AccPeriod.FindLast();

        FiscalYearStartDate := AccPeriod."Starting Date";
        if FiscalYearStartDate = StartDate then begin
            GLSetup."Last Printed G/L Book Page" := 0;
            if not CurrReport.Preview and (ReportType = ReportType::"Final Print") then
                GLSetup.Modify();
        end;

        AccPeriod.SetFilter("Starting Date", '<=%1', EndDate);
        AccPeriod.FindLast();

        if FiscalYearStartDate <> AccPeriod."Starting Date" then
            Error(Text1035);

        if StartDate = FiscalYearStartDate then
            LastNo := 0;
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ITGLBookTok: Label 'IT Print and Reprint GL Books and VAT Registers', Locked = true;
        Text1034: Label 'Starting Date must not be greater than %1.';
        Text1035: Label 'You cannot print entries of two different accounting periods.';
        Text1036: Label 'The G/L entries printed have been marked.';
        Text1037: Label '%1 %2 of the previous period has not been printed.';
        Text1038: Label 'Page %1';
        Text1039: Label 'There is nothing to reprint.';
        Text1040: Label 'Starting Date must not be blank.';
        Text1041: Label 'Starting Date must be greater than %1.';
        Text1042: Label 'Ending Date must not be blank.';
        Text1043: Label 'Ending Date must not be less than %1.';
        Text1044: Label 'Ending Date must not be greater than %1.';
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLBookEntry: Record "GL Book Entry";
        BankAccount: Record "Bank Account";
        FA: Record "Fixed Asset";
        AccPeriod: Record "Accounting Period";
        Date: Record Date;
        GLBookEntry2: Record "GL Book Entry";
        ReprintInfo: Record "Reprint Info Fiscal Reports";
        CompInfo: Record "Company Information";
        TempGLBookEntry: Record "GL Book Entry" temporary;
        ReportType: Option "Test Print","Final Print",Reprint;
        StartDate: Date;
        EndDate: Date;
        FiscalYearStartDate: Date;
        LastDate: Date;
        LastNo: Integer;
        CompanyInformation: array[7] of Text[100];
        Descr: Text[100];
        StartDebit: Decimal;
        StartCredit: Decimal;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        DebitPage: Decimal;
        CreditPage: Decimal;
        Text1045: Label 'Has the report been print out correctly?';
        FromProgressiveNo: Integer;
        PrintCompanyInformations: Boolean;
        Text1047: Label 'G/L Book';
        Text1048: Label 'Test G/L Book';
        i: Integer;
        Text1049: Label 'All Company Information related fields should be filled in on the request form.';
        LastPrintedPageNo: Integer;
        "From Progressive No.Editable": Boolean;
        Text12100: Label 'You must update the %1 field in the %2 window when you have printed the report.';
        Register_Company_No_CaptionLbl: Label 'Register Company No.';
        CompanyInformation_6_CaptionLbl: Label 'Fiscal Code';
        CompanyInformation_5_CaptionLbl: Label 'VAT Reg. No.';
        Text2038Lbl: Label 'Page';
        CompanyInformation_6__Control1130207CaptionLbl: Label 'Fiscal Code';
        DescrCaptionLbl: Label 'Description';
        GLAcc_NameCaptionLbl: Label 'Account Name';
        GL_Book_Entry__Document_Date_CaptionLbl: Label 'Document Date';
        NORMALDATE__Posting_Date__CaptionLbl: Label 'Related Date';
        GL_Book_Entry__Official_Date_CaptionLbl: Label 'Entry Date';
        LastNoCaptionLbl: Label 'Progressive No.';
        Total_on_Previous_PeriodCaptionLbl: Label 'Total on Previous Period';
        Total_on_Previous_PageCaptionLbl: Label 'Total on Previous Page';
        Total_in_this_PageCaptionLbl: Label 'Total in this Page';
        Final_TotalCaptionLbl: Label 'Final Total';

    [Scope('OnPrem')]
    procedure ValidateDate()
    begin
        if Date.Get(Date."Period Type"::Month, StartDate) then
            if Date.Find('>') then
                EndDate := Date."Period Start" - 1;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewReportType: Option; NewStartDate: Date; NewEndDate: Date; NewPrintCompanyInfo: Boolean; NewCompanyInformation: array[7] of Text[100])
    var
        I: Integer;
    begin
        ReportType := NewReportType;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        PrintCompanyInformations := NewPrintCompanyInfo;
        for I := 1 to 7 do
            CompanyInformation[I] := NewCompanyInformation[I];
    end;

    local procedure GetBillToName()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesInvHeader.SetLoadFields("Bill-to Name");
        SalesCrMemoHeader.SetLoadFields("Bill-to Name");
        case "GL Book Entry"."Document Type" of
            "GL Book Entry"."Document Type"::Invoice:
                if SalesInvHeader.Get("GL Book Entry"."Document No.") then
                    Descr := SalesInvHeader."Bill-to Name";
            "GL Book Entry"."Document Type"::"Credit Memo":
                if SalesCrMemoHeader.Get("GL Book Entry"."Document No.") then
                    Descr := SalesCrMemoHeader."Bill-to Name";
        end;
    end;

    local procedure GetPayToName()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        case "GL Book Entry"."Document Type" of
            "GL Book Entry"."Document Type"::Invoice:
                if PurchInvHeader.Get("GL Book Entry"."Document No.") then
                    Descr := PurchInvHeader."Pay-to Name";
            "GL Book Entry"."Document Type"::"Credit Memo":
                if PurchCrMemoHeader.Get("GL Book Entry"."Document No.") then
                    Descr := PurchCrMemoHeader."Pay-to Name";
        end;
    end;
}

