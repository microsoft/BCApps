// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using System.Utilities;

report 5622 "Insurance Journal - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Insurance/InsuranceJournalTest.rdlc';
    Caption = 'Insurance Journal - Test';

    dataset
    {
        dataitem("Insurance Journal Batch"; "Insurance Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(Insurance_Journal_Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(Insurance_Journal_Batch__Name; "Insurance Journal Batch".Name)
                {
                }
                column(Insurance_Journal_Batch___Journal_Template_Name_; "Insurance Journal Batch"."Journal Template Name")
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(Insurance_Journal_Line__TABLECAPTION__________InsuranceJnlLineFilter; "Insurance Journal Line".TableCaption + ': ' + InsuranceJnlLineFilter)
                {
                }
                column(InsuranceJnlLineFilter; InsuranceJnlLineFilter)
                {
                }
                column(Insurance_Journal_Batch__NameCaption; Insurance_Journal_Batch__NameCaptionLbl)
                {
                }
                column(Insurance_Journal_Batch___Journal_Template_Name_Caption; "Insurance Journal Batch".FieldCaption("Journal Template Name"))
                {
                }
                column(Insurance_Journal___TestCaption; Insurance_Journal___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Insurance_Journal_Line__Posting_Date_Caption; Insurance_Journal_Line__Posting_Date_CaptionLbl)
                {
                }
                column(Insurance_Journal_Line__Document_Type_Caption; "Insurance Journal Line".FieldCaption("Document Type"))
                {
                }
                column(Insurance_Journal_Line__Document_No__Caption; "Insurance Journal Line".FieldCaption("Document No."))
                {
                }
                column(Insurance_Journal_Line__FA_No__Caption; "Insurance Journal Line".FieldCaption("FA No."))
                {
                }
                column(Insurance_Journal_Line_DescriptionCaption; "Insurance Journal Line".FieldCaption(Description))
                {
                }
                column(Insurance_Journal_Line_AmountCaption; "Insurance Journal Line".FieldCaption(Amount))
                {
                }
                column(Insurance_Journal_Line__Insurance_No__Caption; "Insurance Journal Line".FieldCaption("Insurance No."))
                {
                }
                dataitem("Insurance Journal Line"; "Insurance Journal Line")
                {
                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                    DataItemLinkReference = "Insurance Journal Batch";
                    DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Posting Date";
                    column(Insurance_Journal_Line__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Insurance_Journal_Line__Document_Type_; "Document Type")
                    {
                    }
                    column(Insurance_Journal_Line__Document_No__; "Document No.")
                    {
                    }
                    column(Insurance_Journal_Line__FA_No__; "FA No.")
                    {
                    }
                    column(Insurance_Journal_Line_Description; Description)
                    {
                    }
                    column(Insurance_Journal_Line_Amount; Amount)
                    {
                    }
                    column(Insurance_Journal_Line__Insurance_No__; "Insurance No.")
                    {
                    }
                    column(Insurance_Journal_Line_Line_No_; "Line No.")
                    {
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number_; ErrorText[Number])
                        {
                        }
                        column(Warning_Caption; Warning_CaptionLbl)
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

                    trigger OnAfterGetRecord()
                    begin
                        if "Insurance No." <> '' then begin
                            if "Posting Date" = 0D then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    FieldCaption("Posting Date")));
                            if "FA No." = '' then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    FieldCaption("FA No.")))
                            else
                                if not FA.Get("FA No.") then
                                    AddError(
                                      StrSubstNo(
                                        Text001, FA.TableCaption(), FA.FieldCaption("No.")));
                            if "Document No." = '' then
                                AddError(StrSubstNo(Text000, FieldCaption("Document No.")));
                        end;

                        if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                            AddError(DimMgt.GetDimCombErr());

                        TableID[1] := DATABASE::Insurance;
                        No[1] := "Insurance No.";
                        if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                            AddError(DimMgt.GetDimValuePostingErr());
                    end;

                    trigger OnPreDataItem()
                    begin
                        InsuranceJnlTempl.Get("Insurance Journal Batch"."Journal Template Name");
                        Clear(Amount);
                    end;
                }
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
        InsuranceJnlLineFilter := "Insurance Journal Line".GetFilters();
        FASetup.Get();
        FASetup.TestField("Automatic Insurance Posting", true);
    end;

    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        DimMgt: Codeunit DimensionManagement;
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        InsuranceJnlLineFilter: Text;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be specified.';
        Text001: Label '%1 %2 does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Insurance_Journal_Batch__NameCaptionLbl: Label 'Journal Batch';
        Insurance_Journal___TestCaptionLbl: Label 'Insurance Journal - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Insurance_Journal_Line__Posting_Date_CaptionLbl: Label 'Posting Date';
        Warning_CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

