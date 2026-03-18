// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Reports;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Journal;
using System.Utilities;

report 1128 "Cost Acctg. Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostAcctgJournal.rdlc';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Acctg. Journal';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cost Journal Line"; "Cost Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Posting Date", "Line No.", "Cost Center Code", "Cost Object Code";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column("Filter"; Text011 + GetFilters)
            {
            }
            column(CostTypeNo_CostJourLine; "Cost Type No.")
            {
            }
            column(PostingDate_CostJourLine; Format("Posting Date"))
            {
            }
            column(DocNo_CostJourLine; "Document No.")
            {
                IncludeCaption = true;
            }
            column(Text_CostJourLine; Description)
            {
                IncludeCaption = true;
            }
            column(BalCostTypeNo_CostJourLine; "Bal. Cost Type No.")
            {
            }
            column(Amount_CostJourLine; Amount)
            {
                IncludeCaption = true;
            }
            column(CostCentCode_CostJourLine; "Cost Center Code")
            {
            }
            column(CostObjCode_CostJourLine; "Cost Object Code")
            {
            }
            column(BlCostCntCode_CostJourLine; "Bal. Cost Center Code")
            {
                IncludeCaption = true;
            }
            column(BlCostObjCode_CostJourLine; "Bal. Cost Object Code")
            {
                IncludeCaption = true;
            }
            column(Balance_CostJourLine; Balance)
            {
            }
            column(JourBatchName_CostJourLine; "Journal Batch Name")
            {
            }
            column(LineNo_CostJourLine; "Line No.")
            {
            }
            column(CAJournalCaption; CAJournalCaptionLbl)
            {
            }
            column(BalCTCaption; BalCTCaptionLbl)
            {
            }
            column(COCaption; COCaptionLbl)
            {
            }
            column(CCCaption; CCCaptionLbl)
            {
            }
            column(CostTypeCaption; CostTypeCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(TotalAmountCaption; TotalAmountCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ErrorlineNumber; Errorline[Number])
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Errorline[Number] = '' then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if not WithError then
                        CurrReport.Break();

                    SetRange(Number, 1, 20);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if WithError then begin
                    Lineno := 0;
                    Clear(Errorline);

                    if "Posting Date" = 0D then
                        WriteErrorLine(Text000);

                    if "Document No." = '' then
                        WriteErrorLine(Text001);

                    if ("Cost Type No." = '') and ("Bal. Cost Type No." = '') then
                        WriteErrorLine(Text002);

                    if "Cost Type No." <> '' then begin
                        CostType.Get("Cost Type No.");
                        if CostType.Blocked then
                            WriteErrorLine(Text003);

                        if CostType.Type <> CostType.Type::"Cost Type" then
                            WriteErrorLine(StrSubstNo(Text004, CostType.Type));

                        if ("Cost Center Code" = '') and ("Cost Object Code" = '') then
                            WriteErrorLine(Text005);

                        if ("Cost Center Code" <> '') and ("Cost Object Code" <> '') then
                            WriteErrorLine(Text006);
                    end;

                    if "Bal. Cost Type No." <> '' then begin
                        CostType.Get("Bal. Cost Type No.");
                        if CostType.Blocked then
                            WriteErrorLine(Text007);

                        if CostType.Type <> CostType.Type::"Cost Type" then
                            WriteErrorLine(StrSubstNo(Text008, CostType.Type));

                        if ("Bal. Cost Center Code" = '') and ("Bal. Cost Object Code" = '') then
                            WriteErrorLine(Text009);

                        if ("Bal. Cost Center Code" <> '') and ("Bal. Cost Object Code" <> '') then
                            WriteErrorLine(Text010);
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                Clear(Amount);
                Clear(Balance);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Cost Acctg. Journal';
        AboutText = 'The **Cost Acctg. Journal** report displays cost entries recorded in journals, including amounts, dates, and dimensions. Use it for validating posted cost transactions by reviewing journalized entries and ensuring accuracy in cost postings.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(WithErrorMessages; WithError)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'With Error Messages';
                        ToolTip = 'Specifies that a plausibility check has been performed, with the appropriate message is displayed.';
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

    var
        CostType: Record "Cost Type";
        WithError: Boolean;
        Errorline: array[20] of Text[80];
        Lineno: Integer;

#pragma warning disable AA0074
        Text000: Label 'Posting date is not defined.';
        Text001: Label 'Document no. is not defined.';
        Text002: Label 'Define cost type or balance cost type.';
        Text003: Label 'Cost type is blocked.';
#pragma warning disable AA0470
        Text004: Label 'Cost type must not be line type %1.';
#pragma warning restore AA0470
        Text005: Label 'Cost center or cost object must be defined.';
        Text006: Label 'Cost center and cost object cannot be both defined concurrently.';
        Text007: Label 'Balance cost type is blocked.';
#pragma warning disable AA0470
        Text008: Label 'Balance cost type must have line type %1.';
#pragma warning restore AA0470
        Text009: Label 'Balance cost center or cost object must be defined.';
        Text010: Label 'Balance cost center and cost object cannot be both defined concurrently.';
        Text011: Label 'Filter: ';
#pragma warning restore AA0074
        CAJournalCaptionLbl: Label 'Cost Accounting Journal';
        BalCTCaptionLbl: Label 'Balance CT';
        COCaptionLbl: Label 'CO';
        CCCaptionLbl: Label 'CC';
        CostTypeCaptionLbl: Label 'CostType';
        PostingDateCaptionLbl: Label 'Posting Date';
        BalanceCaptionLbl: Label 'Balance';
        TotalAmountCaptionLbl: Label 'Total Amount';

    local procedure WriteErrorLine(ErrorTxt: Text[80])
    begin
        Lineno := Lineno + 1;
        Errorline[Lineno] := ErrorTxt;
    end;
}

