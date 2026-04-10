// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Reports;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Ledger;

report 1144 "Cost Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostRegister.rdlc';
    Caption = 'Cost Register';

    dataset
    {
        dataitem("Cost Register"; "Cost Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CostRegisterTableFilter; TableCaption + ': ' + CostRegFilter)
            {
            }
            column(No_CostRegister; "No.")
            {
            }
            column(Amount_CostEntry; "Cost Entry".Amount)
            {
            }
            column(GLRegisterCaption; GLRegisterCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(FORMATPostingDateCaption; FORMATPostingDateCaptionLbl)
            {
            }
            column(CostTypeNameCaption; CostTypeNameCaptionLbl)
            {
            }
            column(GLRegisterNoCaption; GLRegisterNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Cost Entry"; "Cost Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(PostingDate_CostEntry; Format("Posting Date"))
                {
                }
                column(DocNo_CostEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Name_CostType; CostType.Name)
                {
                }
                column(Description_CostEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Amount1_CostEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(No_CostEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(CostTypeNo_CostEntry; "Cost Type No.")
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                begin
                    if not CostType.Get("Cost Type No.") then
                        CostType.Init();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "Cost Register"."From Cost Entry No.", "Cost Register"."To Cost Entry No.");
                    Clear(Amount);
                end;
            }
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
        CostRegFilter := "Cost Register".GetFilters();
    end;

    var
        CostType: Record "Cost Type";
        CostRegFilter: Text;
        GLRegisterCaptionLbl: Label 'Cost Register';
        CurrReportPageNoCaptionLbl: Label 'Page';
        FORMATPostingDateCaptionLbl: Label 'Posting Date';
        CostTypeNameCaptionLbl: Label 'Name';
        GLRegisterNoCaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
}

