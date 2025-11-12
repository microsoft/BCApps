// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Setup;
using System.Security.User;
using System.Utilities;

report 5812 "Revaluation Posting - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/RevaluationPostingTest.rdlc';
    Caption = 'Revaluation Posting - Test';

    dataset
    {
        dataitem("Item Journal Batch"; "Item Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(Item_Journal_Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Item_Journal_Batch_Name; Name)
            {
            }
            dataitem("Item Journal Line"; "Item Journal Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                RequestFilterFields = "Posting Date";
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(Item_Journal_Line__Journal_Template_Name_; "Journal Template Name")
                {
                }
                column(Item_Journal_Line__Journal_Batch_Name_; "Journal Batch Name")
                {
                }
                column(Item_Journal_Line__TABLECAPTION__________ItemJnlLineFilter; TableCaption + ': ' + ItemJnlLineFilter)
                {
                }
                column(ItemJnlLineFilter; ItemJnlLineFilter)
                {
                }
                column(Item_Journal_Line__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Item_Journal_Line__Item_No__; "Item No.")
                {
                }
                column(Item_Journal_Line_Description; Description)
                {
                }
                column(Item_Journal_Line_Quantity; Quantity)
                {
                }
                column(Item_Journal_Line_Amount; Amount)
                {
                }
                column(Item_Journal_Line__Unit_Cost__Calculated__; "Unit Cost (Calculated)")
                {
                }
                column(Item_Journal_Line__Unit_Cost__Revalued__; "Unit Cost (Revalued)")
                {
                }
                column(Item_Journal_Line__Inventory_Value__Calculated__; "Inventory Value (Calculated)")
                {
                }
                column(Item_Journal_Line__Inventory_Value__Revalued__; "Inventory Value (Revalued)")
                {
                }
                column(Item_Journal_Line_Amount_Control43; Amount)
                {
                }
                column(Item_Journal_Line_Line_No_; "Line No.")
                {
                }
                column(Revaluation_Posting___TestCaption; Revaluation_Posting___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Item_Journal_Line__Journal_Template_Name_Caption; FieldCaption("Journal Template Name"))
                {
                }
                column(Item_Journal_Line__Journal_Batch_Name_Caption; FieldCaption("Journal Batch Name"))
                {
                }
                column(Item_Journal_Line__Posting_Date_Caption; Item_Journal_Line__Posting_Date_CaptionLbl)
                {
                }
                column(Item_Journal_Line__Item_No__Caption; FieldCaption("Item No."))
                {
                }
                column(Item_Journal_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Item_Journal_Line_QuantityCaption; FieldCaption(Quantity))
                {
                }
                column(Item_Journal_Line_AmountCaption; FieldCaption(Amount))
                {
                }
                column(Item_Journal_Line__Unit_Cost__Calculated__Caption; FieldCaption("Unit Cost (Calculated)"))
                {
                }
                column(Item_Journal_Line__Unit_Cost__Revalued__Caption; FieldCaption("Unit Cost (Revalued)"))
                {
                }
                column(Item_Journal_Line__Inventory_Value__Calculated__Caption; FieldCaption("Inventory Value (Calculated)"))
                {
                }
                column(Item_Journal_Line__Inventory_Value__Revalued__Caption; FieldCaption("Inventory Value (Revalued)"))
                {
                }
                column(Item_Journal_Line_Amount_Control43Caption; Item_Journal_Line_Amount_Control43CaptionLbl)
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Number; Number)
                    {
                    }
                    column(DimensionsCaption; DimensionsCaptionLbl)
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
                        until DimSetEntry.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                        DimSetEntry.SetRange("Dimension Set ID", "Item Journal Line"."Dimension Set ID");
                    end;
                }
                dataitem(ErrorLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
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
                    ItemVariant: Record "Item Variant";
                    UserSetupManagement: Codeunit "User Setup Management";
                    InvtPeriodEndDate: Date;
                    TempErrorText: Text[250];
                    ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
                begin
                    OnBeforeItemJournalLineOnAfterGetRecord("Item Journal Line", ErrorCounter, ErrorText);

                    if ("Item No." = '') and (Quantity = 0) then
                        exit;

                    if "Item No." = '' then
                        AddError(StrSubstNo(Text001, FieldCaption("Item No.")))
                    else
                        if not Item.Get("Item No.") then
                            AddError(StrSubstNo(Text002, Item.TableCaption(), "Item No."))
                        else begin
                            if Item.Blocked then
                                AddError(StrSubstNo(Text003, Item.FieldCaption(Blocked), false, Item.TableCaption(), "Item No."));

                            if "Item Journal Line"."Variant Code" <> '' then begin
                                ItemVariant.SetLoadFields(Blocked);
                                if ItemVariant.Get("Item Journal Line"."Item No.", "Item Journal Line"."Variant Code") then begin
                                    if ItemVariant.Blocked then
                                        AddError(StrSubstNo(Text003, ItemVariant.FieldCaption(Blocked), false, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, "Item Journal Line"."Item No.", "Item Journal Line"."Variant Code")));
                                end else
                                    AddError(StrSubstNo(Text002, StrSubstNo(ItemItemVariantLbl, ItemVariant.TableCaption(), "Item Journal Line"."Item No."), "Item Journal Line"."Variant Code"));
                            end;
                        end;

                    if "Posting Date" = 0D then
                        AddError(StrSubstNo(Text001, FieldCaption("Posting Date")))
                    else begin
                        if "Posting Date" <> NormalDate("Posting Date") then
                            AddError(StrSubstNo(Text004, FieldCaption("Posting Date")));

                        if "Item Journal Batch"."No. Series" <> '' then
                            if NoSeries."Date Order" and ("Posting Date" < LastPostingDate) then
                                AddError(Text005);
                        LastPostingDate := "Posting Date";

                        if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                            AddError(TempErrorText);

                        InvtPeriodEndDate := "Posting Date";
                        if not InvtPeriod.IsValidDate(InvtPeriodEndDate) then
                            AddError(
                              StrSubstNo(
                                Text006, Format("Posting Date")))
                    end;

                    if "Document Date" <> 0D then
                        if "Document Date" <> NormalDate("Document Date") then
                            AddError(StrSubstNo(Text004, FieldCaption("Document Date")));

                    if "Gen. Prod. Posting Group" = '' then
                        AddError(StrSubstNo(Text001, FieldCaption("Gen. Prod. Posting Group")))
                    else
                        if not GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then
                            AddError(
                              StrSubstNo(
                                Text007, GenPostingSetup.TableCaption(),
                                "Gen. Bus. Posting Group", "Gen. Prod. Posting Group"));

                    if "Item Journal Batch"."No. Series" <> '' then begin
                        if LastDocNo <> '' then
                            if ("Document No." <> LastDocNo) and ("Document No." <> IncStr(LastDocNo)) then
                                AddError(Text008);
                        LastDocNo := "Document No.";
                    end;

                    if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                        AddError(DimMgt.GetDimCombErr());

                    TableID[1] := DATABASE::Item;
                    No[1] := "Item No.";
                    TableID[2] := DATABASE::"Salesperson/Purchaser";
                    No[2] := "Salespers./Purch. Code";
                    CheckDimValuePosting("Item Journal Line");

                    OnAfterItemJournalLineOnAfterGetRecord("Item Journal Line", ErrorCounter, ErrorText);
                end;

                trigger OnPreDataItem()
                begin
                    if ItemJnlTemplate.Recurring then
                        AddError(StrSubstNo(Text000));

                    if "Item Journal Batch"."No. Series" <> '' then
                        NoSeries.Get("Item Journal Batch"."No. Series");
                    LastPostingDate := 0D;
                    LastDocNo := '';
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ItemJnlTemplate.Get("Journal Template Name");
                if ItemJnlTemplate.Type <> ItemJnlTemplate.Type::Revaluation then
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Revaluation Posting - Test';
        AboutText = 'The Revaluation Posting - Test report is used to simulate the revaluation of inventory items without actually posting the changes. This report helps you review the potential impact of revaluation on your inventory values before committing to the changes. It provides a detailed preview of the adjustments that would be made to the inventory valuation, allowing you to verify and ensure accuracy.';

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
                        ToolTip = 'Specifies if you want if you want the report to show dimensions.';
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
        ItemJnlLineFilter := "Item Journal Line".GetFilters();
        GLSetup.Get();
        InvtSetup.Get();
    end;

    var
        InvtSetup: Record "Inventory Setup";
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemJnlTemplate: Record "Item Journal Template";
        GenPostingSetup: Record "General Posting Setup";
        NoSeries: Record "No. Series";
        DimSetEntry: Record "Dimension Set Entry";
        InvtPeriod: Record "Inventory Period";
        DimMgt: Codeunit DimensionManagement;
        ItemJnlLineFilter: Text;
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

#pragma warning disable AA0074
        Text000: Label 'You cannot use a recurring journal for revaluations.';
#pragma warning disable AA0470
        Text001: Label '%1 must be specified.';
        Text002: Label '%1 %2 does not exist.';
        Text003: Label '%1 must be %2 for %3 %4.';
        Text004: Label '%1 must not be a closing date.';
#pragma warning restore AA0470
        Text005: Label 'The lines are not listed according to posting date because they were not entered in that order.';
#pragma warning disable AA0470
        Text006: Label '%1 is not within your allowed range of posting dates.';
        Text007: Label '%1 %2 %3 does not exist.';
#pragma warning restore AA0470
        Text008: Label 'There is a gap in the number series.';
#pragma warning restore AA0074
        Revaluation_Posting___TestCaptionLbl: Label 'Revaluation Posting - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item_Journal_Line__Posting_Date_CaptionLbl: Label 'Posting Date';
        Item_Journal_Line_Amount_Control43CaptionLbl: Label 'Total';
        DimensionsCaptionLbl: Label 'Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';

    procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure CheckDimValuePosting(var ItemJournalLine: Record "Item Journal Line")
    begin
        OnBeforeCheckDimValuePosting(TableID, No, ItemJournalLine);
        if not DimMgt.CheckDimValuePosting(TableID, No, ItemJournalLine."Dimension Set ID") then
            AddError(DimMgt.GetDimValuePostingErr());
    end;

    procedure InitializeRequest(NewShowDim: Boolean)
    begin
        ShowDim := NewShowDim;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemJournalLineOnAfterGetRecord(var ItemJournalLine: Record "Item Journal Line"; var ErrorCounter: Integer; var ErrorText: array[30] of Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(var TableID: array[10] of Integer; var No: array[10] of Code[20]; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJournalLineOnAfterGetRecord(var ItemJournalLine: Record "Item Journal Line"; var ErrorCounter: Integer; var ErrorText: array[30] of Text[250])
    begin
    end;
}

