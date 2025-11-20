// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;
using System.Security.User;
using System.Utilities;

report 1102 "Resource Journal - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Resources/Reports/ResourceJournalTest.rdlc';
    Caption = 'Resource Journal - Test';

    dataset
    {
        dataitem("Res. Journal Batch"; "Res. Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(JnlTemplateName_ResJnlBatch; "Journal Template Name")
            {
            }
            column(Name_ResJnlBatch; Name)
            {
            }
            dataitem("Res. Journal Line"; "Res. Journal Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                RequestFilterFields = "Posting Date";
                column(CompName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(ResJnlLineTableCaption; TableCaption + ': ' + ResJnlLineFilter)
                {
                }
                column(ResJnlLineFilter; ResJnlLineFilter)
                {
                }
                column(LineNo_ResJnlLine; "Line No.")
                {
                }
                column(EntryType_ResJnlLine; "Entry Type")
                {
                }
                column(DocNo_ResJnlLine; "Document No.")
                {
                }
                column(ResNo_ResJnlLine; "Resource No.")
                {
                }
                column(WorkTypeCode_ResJnlLine; "Work Type Code")
                {
                }
                column(UOMCode_ResJnlLine; "Unit of Measure Code")
                {
                }
                column(Qty_ResJnlLine; Quantity)
                {
                }
                column(UnitCost_ResJnlLine; "Unit Cost")
                {
                }
                column(TotalCost_ResJnlLine; "Total Cost")
                {
                }
                column(UnitPrice_ResJnlLine; "Unit Price")
                {
                }
                column(TotalPrice_ResJnlLine; "Total Price")
                {
                }
                column(PostingDateFormatted_ResJnlLine; Format("Posting Date"))
                {
                }
                column(GetTotalPrice; GetTotalPrice)
                {
                }
                column(GetTotalCost; GetTotalCost)
                {
                }
                column(PageCaption; PageCaptionLbl)
                {
                }
                column(ResJnlTestCaption; ResJnlTestCaptionLbl)
                {
                }
                column(JnlTemplateNameCaption_ResJnlLine; FieldCaption("Journal Template Name"))
                {
                }
                column(JnlBatchNameCaption_ResJnlLine; FieldCaption("Journal Batch Name"))
                {
                }
                column(UnitPriceCaption_ResJnlLine; FieldCaption("Unit Price"))
                {
                }
                column(TotalPriceCaption_ResJnlLine; FieldCaption("Total Price"))
                {
                }
                column(UnitCostCaption_ResJnlLine; FieldCaption("Unit Cost"))
                {
                }
                column(TotalCostCaption_ResJnlLine; FieldCaption("Total Cost"))
                {
                }
                column(QtyCaption_ResJnlLine; FieldCaption(Quantity))
                {
                }
                column(UOMCodeCaption_ResJnlLine; FieldCaption("Unit of Measure Code"))
                {
                }
                column(WorkTypeCodeCaption_ResJnlLine; FieldCaption("Work Type Code"))
                {
                }
                column(ResNoCaption_ResJnlLine; FieldCaption("Resource No."))
                {
                }
                column(DocNoCaption_ResJnlLine; FieldCaption("Document No."))
                {
                }
                column(EntryTypeCaption_ResJnlLine; FieldCaption("Entry Type"))
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(DimLoopNumber; Number)
                    {
                    }
                    column(DimCaption; DimCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.FindSet() then
                                CurrReport.Break();
                        end else
                            if not Continue then
                                CurrReport.Break();

                        Clear(DimText);
                        Continue := false;
                        repeat
                            OldDimText := DimText;
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                DimText := OldDimText;
                                Continue := true;
                                exit;
                            end;
                        until (DimSetEntry.Next() = 0);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                        DimSetEntry.SetRange("Dimension Set ID", "Res. Journal Line"."Dimension Set ID");
                    end;
                }
                dataitem(ErrorLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorTextNumber; ErrorText[Number])
                    {
                    }
                    column(WarningCaption; WarningCaptionLbl)
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
                var
                    UserSetupManagement: Codeunit "User Setup Management";
                    TempErrorText: Text[250];
                begin
                    if EmptyLine() then
                        exit;

                    MakeRecurringTexts("Res. Journal Line");

                    if "Resource No." = '' then
                        AddError(StrSubstNo(Text001, FieldCaption("Resource No.")))
                    else
                        if not Res.Get("Resource No.") then
                            AddError(
                              StrSubstNo(
                                Text002,
                                Res.TableCaption(), "Resource No."))
                        else begin
                            if Res."Privacy Blocked" then
                                AddError(StrSubstNo(Text003, Res.FieldCaption("Privacy Blocked"), false, Res.TableCaption(), "Resource No."));
                            if Res.Blocked then
                                AddError(
                                  StrSubstNo(
                                    Text003,
                                    Res.FieldCaption(Blocked), false, Res.TableCaption(), "Resource No."));
                        end;

                    if "Gen. Prod. Posting Group" = '' then
                        AddError(StrSubstNo(Text001, FieldCaption("Gen. Prod. Posting Group")))
                    else
                        if not GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then
                            AddError(
                              StrSubstNo(
                                Text004, GenPostingSetup.TableCaption(),
                                "Gen. Bus. Posting Group", "Gen. Prod. Posting Group"));

                    CheckRecurringLine("Res. Journal Line");

                    if "Posting Date" = 0D then
                        AddError(StrSubstNo(Text001, FieldCaption("Posting Date")))
                    else begin
                        if "Posting Date" <> NormalDate("Posting Date") then
                            AddError(StrSubstNo(Text005, FieldCaption("Posting Date")));

                        if "Res. Journal Batch"."No. Series" <> '' then
                            if NoSeries."Date Order" and ("Posting Date" < LastPostingDate) then
                                AddError(Text006);
                        LastPostingDate := "Posting Date";

                        if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                            AddError(TempErrorText);
                    end;

                    if "Document Date" <> 0D then
                        if "Document Date" <> NormalDate("Document Date") then
                            AddError(StrSubstNo(Text005, FieldCaption("Document Date")));

                    if "Res. Journal Batch"."No. Series" <> '' then begin
                        if LastDocNo <> '' then
                            if ("Document No." <> LastDocNo) and ("Document No." <> IncStr(LastDocNo)) then
                                AddError(Text008);
                        LastDocNo := "Document No.";
                    end;

                    if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                        AddError(DimMgt.GetDimCombErr());

                    TableID[1] := Database::Resource;
                    No[1] := "Resource No.";
                    TableID[2] := Database::"Resource Group";
                    No[2] := "Resource Group No.";
                    TableID[3] := Database::Job;
                    No[3] := "Job No.";
                    if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                        AddError(DimMgt.GetDimValuePostingErr());

                    GetTotalCost += "Total Cost";
                    GetTotalPrice += "Total Price";
                end;

                trigger OnPreDataItem()
                begin
                    ResJnlTemplate.Get("Res. Journal Batch"."Journal Template Name");
                    if ResJnlTemplate.Recurring then begin
                        if GetFilter("Posting Date") <> '' then
                            AddError(
                              StrSubstNo(
                                Text000, FieldCaption("Posting Date")));
                        SetRange("Posting Date", 0D, WorkDate());
                        if GetFilter("Expiration Date") <> '' then
                            AddError(
                              StrSubstNo(
                                Text000,
                                FieldCaption("Expiration Date")));
                        SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
                    end;
                    if "Res. Journal Batch"."No. Series" <> '' then
                        NoSeries.Get("Res. Journal Batch"."No. Series");
                    LastPostingDate := 0D;
                    LastDocNo := '';
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GetTotalCost := 0;
                GetTotalPrice := 0;
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
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies that the dimensions for each entry or posting group are included.';
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

    trigger OnPreReport()
    begin
        ResJnlLineFilter := "Res. Journal Line".GetFilters();
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        Res: Record Resource;
        ResJnlTemplate: Record "Res. Journal Template";
        GenPostingSetup: Record "General Posting Setup";
        NoSeries: Record "No. Series";
        DimSetEntry: Record "Dimension Set Entry";
        DimMgt: Codeunit DimensionManagement;
        ResJnlLineFilter: Text;
        ErrorCounter: Integer;
        ErrorText: array[30] of Text[250];
        LastPostingDate: Date;
        LastDocNo: Code[20];
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowDim: Boolean;
        Continue: Boolean;
        GetTotalCost: Decimal;
        GetTotalPrice: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be filtered when you post recurring journals.';
        Text001: Label '%1 must be specified.';
        Text002: Label '%1 %2 does not exist.';
        Text003: Label '%1 must be %2 for %3 %4.';
        Text004: Label '%1 %2 %3 does not exist.';
        Text005: Label '%1 must not be a closing date.';
#pragma warning restore AA0470
        Text006: Label 'The lines are not listed according to Posting Date because they were not entered in that order.';
        Text008: Label 'There is a gap in the number series.';
#pragma warning disable AA0470
        Text009: Label '%1 cannot be specified.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PageCaptionLbl: Label 'Page';
        ResJnlTestCaptionLbl: Label 'Resource Journal - Test';
        PostingDateCaptionLbl: Label 'Posting Date';
        DimCaptionLbl: Label 'Dimensions';
        WarningCaptionLbl: Label 'Warning!';
        TotalCaptionLbl: Label 'Total';

    local procedure CheckRecurringLine(ResJnlLine2: Record "Res. Journal Line")
    begin
        if ResJnlTemplate.Recurring then begin
            if ResJnlLine2."Recurring Method" = 0 then
                AddError(StrSubstNo(Text001, ResJnlLine2.FieldCaption("Recurring Method")));
            if Format(ResJnlLine2."Recurring Frequency") = '' then
                AddError(StrSubstNo(Text001, ResJnlLine2.FieldCaption("Recurring Frequency")));
            if ResJnlLine2."Recurring Method" = ResJnlLine2."Recurring Method"::Variable then
                if ResJnlLine2.Quantity = 0 then
                    AddError(StrSubstNo(Text001, ResJnlLine2.FieldCaption(Quantity)));
        end else begin
            if ResJnlLine2."Recurring Method" <> 0 then
                AddError(StrSubstNo(Text009, ResJnlLine2.FieldCaption("Recurring Method")));
            if Format(ResJnlLine2."Recurring Frequency") <> '' then
                AddError(StrSubstNo(Text009, ResJnlLine2.FieldCaption("Recurring Frequency")));
        end;
    end;

    local procedure MakeRecurringTexts(var ResJnlLine2: Record "Res. Journal Line")
    begin
        if (ResJnlLine2."Posting Date" <> 0D) and (ResJnlLine2."Resource No." <> '') and (ResJnlLine2."Recurring Method" <> 0) then
            AccountingPeriod.MakeRecurringTexts(ResJnlLine2."Posting Date", ResJnlLine2."Document No.", ResJnlLine2.Description);
    end;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    procedure InitializeRequest(ShowDimFrom: Boolean)
    begin
        ShowDim := ShowDimFrom;
    end;
}

