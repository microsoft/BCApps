// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using System.Utilities;

report 23 "G/L Document Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/GLDocumentNos.rdlc';
    Caption = 'G/L Document Nos.';

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = sorting("Document No.");
            RequestFilterFields = "Document No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text004_GLEntryFilter_; StrSubstNo(Text004, GLEntryFilter))
            {
            }
            column(GLEntryFilter; GLEntryFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(NextPageGroupNo; NextPageGroupNo)
            {
            }
            column(G_L_Entry_Entry_No_; "Entry No.")
            {
            }
            column(G_L_Document_Nos_Caption; G_L_Document_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(GLEntry__Document_No__Caption; GLEntry.FieldCaption("Document No."))
            {
            }
            column(GLEntry__Source_Code_Caption; GLEntry.FieldCaption("Source Code"))
            {
            }
            column(GLEntry__User_ID_Caption; GLEntry.FieldCaption("User ID"))
            {
            }
            column(GLEntry_DescriptionCaption; GLEntry.FieldCaption(Description))
            {
            }
            column(GLEntry__G_L_Account_No__Caption; GLEntry.FieldCaption("G/L Account No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(GLEntry__Posting_Date_Caption; GLEntry__Posting_Date_CaptionLbl)
            {
            }
            dataitem(ErrorLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ErrorText_Number_; ErrorText[Number])
                {
                }
                column(ErrorText_Number__Control15; ErrorText[Number])
                {
                }
                column(ErrorText_Number__Control15Caption; ErrorText_Number__Control15CaptionLbl)
                {
                }

                trigger OnPostDataItem()
                begin
                    ErrorCounter := 0;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, ErrorCounter);
                end;
            }
            dataitem(GLEntry; "G/L Entry")
            {
                DataItemLink = "Entry No." = field("Entry No.");
                DataItemTableView = sorting("Entry No.");
                column(GLEntry__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(GLEntry__Source_Code_; "Source Code")
                {
                }
                column(GLEntry_Description; Description)
                {
                }
                column(GLEntry__G_L_Account_No__; "G/L Account No.")
                {
                }
                column(GLEntry__Document_No__; "Document No.")
                {
                }
                column(GLEntry__Posting_Date_; Format("Posting Date"))
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Source Code" <> SourceCode.Code then
                    if not SourceCode.Get("Source Code") then
                        SourceCode.Init();
                if "No. Series" <> NoSeries.Code then
                    if not NoSeries.Get("No. Series") then
                        NoSeries.Init();

                if ("No. Series" <> LastNoSeriesCode) or FirstRecord then begin
                    if "No. Series" = '' then
                        AddError(Text000)
                    else
                        AddError(
                          StrSubstNo(
                            Text001,
                            "No. Series", NoSeries.Description));
                    NewPage := true;
                end else begin
                    if LastDocNo <> '' then
                        if not ("Document No." in [LastDocNo, IncStr(LastDocNo)]) then
                            AddError(Text002)
                        else
                            if "Posting Date" < LastPostingDate then
                                AddError(Text003);
                    NewPage := false;
                end;

                LastDocNo := "Document No.";
                LastPostingDate := "Posting Date";
                LastNoSeriesCode := "No. Series";
                FirstRecord := false;

                PageGroupNo := NextPageGroupNo;
                if NewPage then
                    NextPageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;

                FirstRecord := true;
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
        GLEntryFilter := "G/L Entry".GetFilters();
    end;

    var
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        GLEntryFilter: Text;
        LastDocNo: Code[20];
        LastPostingDate: Date;
        LastNoSeriesCode: Code[20];
        FirstRecord: Boolean;
        NewPage: Boolean;
        ErrorText: array[10] of Text[250];
        ErrorCounter: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'No number series has been used for the following entries:';
#pragma warning disable AA0470
        Text001: Label 'The number series %1 %2 has been used for the following entries:';
#pragma warning restore AA0470
        Text002: Label 'There is a gap in the number series.';
        Text003: Label 'The documents are not listed according to Posting Date because they were not entered in that order.';
#pragma warning disable AA0470
        Text004: Label 'G/L Entry: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        G_L_Document_Nos_CaptionLbl: Label 'G/L Document Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        SourceCode_DescriptionCaptionLbl: Label 'Source Description';
        GLEntry__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

