// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using System.Utilities;

report 1010 "Job WIP To G/L"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Project/Reports/JobWIPToGL.rdlc';
    AdditionalSearchTerms = 'work in process to general ledger,work in progress to general ledger, Job WIP To G/L';
    ApplicationArea = Jobs;
    Caption = 'Project WIP To G/L';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Posting Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Job_TABLECAPTION__________JobFilter; TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(Job_WIP_To_G_LCaption; Job_WIP_To_G_LCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Acc__No_Caption; G_L_Acc__No_CaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Job_Posting_GroupCaption; Job_Posting_GroupCaptionLbl)
            {
            }
            column(AccountCaption; AccountCaptionLbl)
            {
            }
            column(WIP_AmountCaption; WIP_AmountCaptionLbl)
            {
            }
            column(G_L_BalanceCaption; G_L_BalanceCaptionLbl)
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                TempJobBuffer2.InsertWorkInProgress(Job);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(GLAcc__No__; GLAcc."No.")
            {
            }
            column(JobBuffer__Amount_1_; TempJobBuffer."Amount 1")
            {
            }
            column(JobBuffer__Account_No__2_; TempJobBuffer."Account No. 2")
            {
            }
            column(GLAcc_Name; GLAcc.Name)
            {
            }
            column(WIPText; WIPText)
            {
            }
            column(WIPText1; WIPText1)
            {
            }
            column(JobBuffer__Amount_2_; TempJobBuffer."Amount 2")
            {
            }
            column(WIPText2; WIPText2)
            {
            }
            column(JobBuffer__Amount_4_; TempJobBuffer."Amount 4")
            {
            }
            column(WIPText3; WIPText3)
            {
            }
            column(JobBuffer__Amount_5_; TempJobBuffer."Amount 5")
            {
            }
            column(WIPText4; WIPText4)
            {
            }
            column(GLAccJobTotal; GLAccJobTotal)
            {
            }
            column(JobBuffer__Amount_3_; TempJobBuffer."Amount 3")
            {
            }
            column(GLAccJobTotal___JobBuffer__Amount_3_; GLAccJobTotal - TempJobBuffer."Amount 3")
            {
            }
            column(NewTotal; TempJobBuffer."New Total")
            {
            }
            column(GLJobTotal; GLJobTotal)
            {
            }
            column(GLTotal; GLTotal)
            {
            }
            column(GLJobTotal___GLTotal; GLJobTotal - GLTotal)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempJobBuffer.Find('-') then
                        CurrReport.Break();
                end else
                    if TempJobBuffer.Next() = 0 then
                        CurrReport.Break();
                GLAcc.Name := '';
                GLAcc."No." := '';

                if OldAccNo <> TempJobBuffer."Account No. 1" then begin
                    if GLAcc.Get(TempJobBuffer."Account No. 1") then;
                    GLAccJobTotal := 0;
                end;
                OldAccNo := TempJobBuffer."Account No. 1";
                GLAccJobTotal := GLAccJobTotal + TempJobBuffer."Amount 1" + TempJobBuffer."Amount 2" + TempJobBuffer."Amount 4" + TempJobBuffer."Amount 5";
                GLJobTotal := GLJobTotal + TempJobBuffer."Amount 1" + TempJobBuffer."Amount 2" + TempJobBuffer."Amount 4" + TempJobBuffer."Amount 5";
                if TempJobBuffer."New Total" then
                    GLTotal := GLTotal + TempJobBuffer."Amount 3";

                if TempJobBuffer."Amount 1" <> 0 then
                    WIPText1 := SelectStr(1, TEXT000);
                if TempJobBuffer."Amount 2" <> 0 then
                    WIPText2 := SelectStr(2, TEXT000);
                if TempJobBuffer."Amount 4" <> 0 then
                    WIPText3 := SelectStr(4, TEXT000);
                if TempJobBuffer."Amount 5" <> 0 then
                    WIPText4 := SelectStr(3, TEXT000);
            end;

            trigger OnPreDataItem()
            begin
                TempJobBuffer2.GetJobBuffer(Job, TempJobBuffer);
                OldAccNo := '';
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Project WIP To G/L';
        AboutText = 'Get an overview of the status of ongoing projects in your company''s financial statements.';

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
        TempJobBuffer2.InitJobBuffer();
        JobFilter := Job.GetFilters();
    end;

    var
        TempJobBuffer: Record "Job Buffer" temporary;
        TempJobBuffer2: Record "Job Buffer" temporary;
        GLAcc: Record "G/L Account";
        JobFilter: Text;
        WIPText: Text[50];
#pragma warning disable AA0074
        TEXT000: Label 'WIP Cost Amount,WIP Accrued Costs Amount,WIP Accrued Sales Amount,WIP Invoiced Sales Amount';
#pragma warning restore AA0074
        WIPText1: Text[50];
        WIPText2: Text[50];
        WIPText3: Text[50];
        WIPText4: Text[50];
        OldAccNo: Code[20];
        GLAccJobTotal: Decimal;
        GLJobTotal: Decimal;
        GLTotal: Decimal;
        Job_WIP_To_G_LCaptionLbl: Label 'Project WIP To G/L';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        G_L_Acc__No_CaptionLbl: Label 'G/L Acc. No.';
        DescriptionCaptionLbl: Label 'Description';
        Job_Posting_GroupCaptionLbl: Label 'Project Posting Group';
        AccountCaptionLbl: Label 'Account';
        WIP_AmountCaptionLbl: Label 'WIP Amount';
        G_L_BalanceCaptionLbl: Label 'G/L Balance';
        DifferenceCaptionLbl: Label 'Difference';
        TotalCaptionLbl: Label 'Total';
}

