// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

report 28090 "Post Dated Checks"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Journal/PostDatedChecks.rdlc';
    Caption = 'Post Dated Checks';

    dataset
    {
        dataitem("Post Dated Check Line 2"; "Post Dated Check Line")
        {
            DataItemTableView = sorting("Check Date");
            RequestFilterFields = "Check Date", "Account No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ReportFilter; ReportFilter)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(Post_Dated_Check_Line_2__Account_Type_; "Account Type")
            {
            }
            column(Marked; Marked)
            {
            }
            column(Post_Dated_Check_Line_2__Check_Date_; Format("Check Date"))
            {
            }
            column(Post_Dated_Check_Line_2__Account_No__; "Account No.")
            {
            }
            column(Post_Dated_Check_Line_2_Description; Description)
            {
            }
            column(Post_Dated_Check_Line_2__Check_No__; "Check No.")
            {
            }
            column(Post_Dated_Check_Line_2__Currency_Code_; "Currency Code")
            {
            }
            column(Post_Dated_Check_Line_2_Amount; Amount)
            {
            }
            column(Post_Dated_Check_Line_2__Amount__LCY__; "Amount (LCY)")
            {
            }
            column(Post_Dated_Check_Line_2__Date_Received_; Format("Date Received"))
            {
            }
            column(Post_Dated_Check_Line_2__Replacement_Check_; Format("Replacement Check"))
            {
            }
            column(Post_Dated_Check_Line_2_Comment; Comment)
            {
            }
            column(TotalFor___FIELDCAPTION__Check_Date__; TotalFor + FieldCaption("Check Date"))
            {
            }
            column(Post_Dated_Check_Line_2_Amount_Control1500030; Amount)
            {
            }
            column(myCheck_Date; FieldNo("Check Date"))
            {
            }
            column(myflag; flag)
            {
            }
            column(Post_Dated_Check_Line_2_Amount_Control1500031; Amount)
            {
            }
            column(ReportTotal; ReportTotal)
            {
            }
            column(Post_Dated_Check_Line_2_Template_Name; "Template Name")
            {
            }
            column(Post_Dated_Check_Line_2_Batch_Name; "Batch Name")
            {
            }
            column(Post_Dated_Check_Line_2_Line_Number; "Line Number")
            {
            }
            column(Post_Dated_Check_Line_2_Check_Date; "Check Date")
            {
            }
            column(Post_Dated_ChecksCaption; Post_Dated_ChecksCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Post_Dated_Check_Line_2__Check_Date_Caption; Post_Dated_Check_Line_2__Check_Date_CaptionLbl)
            {
            }
            column(Post_Dated_Check_Line_2__Account_Type_Caption; FieldCaption("Account Type"))
            {
            }
            column(Post_Dated_Check_Line_2__Account_No__Caption; FieldCaption("Account No."))
            {
            }
            column(Post_Dated_Check_Line_2_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Post_Dated_Check_Line_2__Check_No__Caption; FieldCaption("Check No."))
            {
            }
            column(Post_Dated_Check_Line_2__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(Post_Dated_Check_Line_2_AmountCaption; FieldCaption(Amount))
            {
            }
            column(Post_Dated_Check_Line_2__Amount__LCY__Caption; FieldCaption("Amount (LCY)"))
            {
            }
            column(Post_Dated_Check_Line_2__Date_Received_Caption; Post_Dated_Check_Line_2__Date_Received_CaptionLbl)
            {
            }
            column(Post_Dated_Check_Line_2__Replacement_Check_Caption; Post_Dated_Check_Line_2__Replacement_Check_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Check Date" <= WorkDate() then
                    Marked := 'BANK'
                else
                    Marked := '';
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("Check Date");
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        ReportFilter := "Post Dated Check Line 2".GetFilters();
    end;

    var
        ReportFilter: Text[250];
        LastFieldNo: Integer;
        Marked: Text[10];
        TotalFor: Label 'Total for ';
        ReportTotal: Label 'Report Total';
        flag: Integer;
        Post_Dated_ChecksCaptionLbl: Label 'Post Dated Checks';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Post_Dated_Check_Line_2__Check_Date_CaptionLbl: Label 'Check Date';
        Post_Dated_Check_Line_2__Date_Received_CaptionLbl: Label 'Date Received';
        Post_Dated_Check_Line_2__Replacement_Check_CaptionLbl: Label 'Replacement Check';
}

