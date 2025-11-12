// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using System.Utilities;

report 5636 "Fixed Asset Document Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetDocumentNos.rdlc';
    Caption = 'Fixed Asset Document Nos.';

    dataset
    {
        dataitem("FA Ledger Entry"; "FA Ledger Entry")
        {
            DataItemTableView = sorting("Document Type", "Document No.");
            RequestFilterFields = "Document Type", "Document No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text004_FALedgEntryFilter_; StrSubstNo(Text004, FALedgEntryFilter))
            {
            }
            column(FALedgEntryFilter; FALedgEntryFilter)
            {
            }
            column(GoupNo; GoupNo)
            {
            }
            column(FA_Ledger_Entry___Entry_No__; "Entry No.")
            {
            }
            column(NewPage; NewPage)
            {
            }
            column(Fixed_Asset_Document_Nos_Caption; Fixed_Asset_Document_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(FALedgEntry__Document_No__Caption; FALedgEntry.FieldCaption("Document No."))
            {
            }
            column(FALedgEntry__Source_Code_Caption; FALedgEntry.FieldCaption("Source Code"))
            {
            }
            column(FALedgEntry__User_ID_Caption; FALedgEntry.FieldCaption("User ID"))
            {
            }
            column(FA_DescriptionCaption; FA_DescriptionCaptionLbl)
            {
            }
            column(FALedgEntry__FA_No__Caption; FALedgEntry.FieldCaption("FA No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(FALedgEntry__Posting_Date_Caption; FALedgEntry__Posting_Date_CaptionLbl)
            {
            }
            column(FALedgEntry__Document_Type_Caption; FALedgEntry.FieldCaption("Document Type"))
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
            dataitem(FALedgEntry; "FA Ledger Entry")
            {
                DataItemLink = "Entry No." = field("Entry No.");
                DataItemTableView = sorting("Entry No.");
                column(FALedgEntry__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(FALedgEntry__Source_Code_; "Source Code")
                {
                }
                column(FA_Description; FA.Description)
                {
                }
                column(FALedgEntry__FA_No__; "FA No.")
                {
                }
                column(FALedgEntry__Document_No__; "Document No.")
                {
                }
                column(FALedgEntry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(FALedgEntry__Document_Type_; "Document Type")
                {
                }
                column(FALedgEntry__Entry_No__; "Entry No.")
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "FA No." <> FA."No." then
                    if not FA.Get("FA No.") then
                        FA.Init();
                if "Source Code" <> SourceCode.Code then
                    if not SourceCode.Get("Source Code") then
                        SourceCode.Init();
                if "No. Series" <> NoSeries.Code then
                    if not NoSeries.Get("No. Series") then
                        NoSeries.Init();

                if ("No. Series" <> LastNoSeriesCode) or ("Document Type" <> LastDocType) or FirstRecord then begin
                    if "No. Series" = '' then
                        AddError(Text000)
                    else
                        AddError(
                          StrSubstNo(
                            Text001,
                            "No. Series", NoSeries.Description));
                    if not FirstRecord then
                        GoupNo += 1;
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

                LastDocType := "Document Type";
                LastDocNo := "Document No.";
                LastPostingDate := "Posting Date";
                LastNoSeriesCode := "No. Series";
                FirstRecord := false;
            end;

            trigger OnPreDataItem()
            begin
                FirstRecord := true;
                GoupNo := 0;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Fixed Asset Document Nos.';
        AboutText = 'Get a list of fixed asset ledger entries, sorted by document type and number. Use it when you audit your fixed asset transactions.';

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
        FALedgEntryFilter := "FA Ledger Entry".GetFilters();
    end;

    var
        FA: Record "Fixed Asset";
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        FALedgEntryFilter: Text;
        LastDocNo: Code[20];
        LastDocType: Enum "Gen. Journal Document Type";
        LastPostingDate: Date;
        LastNoSeriesCode: Code[20];
        FirstRecord: Boolean;
        NewPage: Boolean;
        ErrorText: array[10] of Text[250];
        ErrorCounter: Integer;
        GoupNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'No number series has been used for the following entries:';
#pragma warning disable AA0470
        Text001: Label 'The number series %1 %2 has been used for the following entries:';
#pragma warning restore AA0470
        Text002: Label 'There is a gap in the number series.';
        Text003: Label 'The documents are not listed according to Posting Date because they were not entered in that order.';
#pragma warning disable AA0470
        Text004: Label 'Fixed Asset Entry: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Fixed_Asset_Document_Nos_CaptionLbl: Label 'Fixed Asset Document Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        FA_DescriptionCaptionLbl: Label 'FA Description';
        SourceCode_DescriptionCaptionLbl: Label 'Source Description';
        FALedgEntry__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

