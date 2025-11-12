// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using System.Utilities;

report 1002 "Post Inventory Cost to G/L"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Costing/PostInventoryCosttoGL.rdlc';
    AdditionalSearchTerms = 'reconcile inventory';
    ApplicationArea = Basic, Suite;
    Caption = 'Post Inventory Cost to G/L';
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Invt. Posting Buffer" = r,
#if not CLEAN28
                  TableData Microsoft.Manufacturing.Document."Prod. Order Line" = r,
#endif
                  TableData "Value Entry" = rm,
                  TableData "Post Value Entry to G/L" = rd,
                  TableData Microsoft.Manufacturing.Capacity."Capacity Ledger Entry" = rm;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(PageLoop; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(PostedCaption; StrSubstNo(PostedPostingTypeTxt, SelectStr(PostMethod + 1, PostingTypeTxt)))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Post; Post)
            {
            }
            column(DocNo; DocNo)
            {
            }
            column(PostMethodInt; PostMethodInt)
            {
            }
            column(ItemValueEntryTableCaption; ItemValueEntry.TableCaption + ': ' + ValueEntryFilter)
            {
            }
            column(ValueEntryFilter; ValueEntryFilter)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(PostInvCosttoGLCaption; PostInvCosttoGLCaptionLbl)
            {
            }
            column(TestReportnotpostedCaption; TestReportnotpostedCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            dataitem(PerEntryLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(PerEntryLoopNumber; Number)
                {
                }
                column(TotalCOGSAmt; TotalCOGSAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalInvtAdjmtAmt; TotalInvtAdjmtAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalDirCostAmt; TotalDirCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalOvhdCostAmt; TotalOvhdCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalVarPurchCostAmt; TotalVarPurchCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalVarMfgDirCostAmt; TotalVarMfgDirCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalVarMfgOvhdCostAmt; TotalVarMfgOvhdCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalWIPInvtAmt; TotalWIPInvtAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalInvtAmt; TotalInvtAmt)
                {
                    AutoFormatType = 1;
                }
                column(EntryNoCaption; EntryNoCaptionLbl)
                {
                }
                column(ItemLedgerEntryTypeCaption; ItemLedgerEntryTypeCaptionLbl)
                {
                }
                column(SourceNoCaption; SourceNoCaptionLbl)
                {
                }
                column(InvPostingGroupCaption; InvPostingGroupCaptionLbl)
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(COGSCaption; COGSCaptionLbl)
                {
                }
                column(InventoryAdjustmentCaption; InventoryAdjustmentCaptionLbl)
                {
                }
                column(DirectCostAppliedCaption; DirectCostAppliedCaptionLbl)
                {
                }
                column(OverheadAppliedCaption; OverheadAppliedCaptionLbl)
                {
                }
                column(PurchaseVarianceCaption; PurchaseVarianceCaptionLbl)
                {
                }
                column(VarMfgDirectCostAppliedCaption; VarMfgDirectCostAppliedCaptionLbl)
                {
                }
                column(MfgOvhdVarianceCaption; MfgOvhdVarianceCaptionLbl)
                {
                }
                column(WIPInventoryCaption; WIPInventoryCaptionLbl)
                {
                }
                column(InventoryCaption; InventoryCaptionLbl)
                {
                }
                column(ExpectedCostCaption; ExpectedCostCaptionLbl)
                {
                }
                column(InventoryCostPostedtoGLCaption; InventoryCostPostedtoGLCaptionLbl)
                {
                }
                dataitem(PostValueEntryToGL; "Post Value Entry to G/L")
                {
                    DataItemTableView = sorting("Item No.", "Posting Date");
                    RequestFilterFields = "Item No.", "Posting Date";
                    column(ItemDescription; Item.Description)
                    {
                    }
                    column(ItemNo_PostValueEntryToGL; "Item No.")
                    {
                    }
                    column(ItemValueEntryPostingDate; Format(ItemValueEntry."Posting Date"))
                    {
                    }
                    column(ItemValueEntryInvPostingGroup; ItemValueEntry."Inventory Posting Group")
                    {
                    }
                    column(ItemValueEntryDocumentNo; ItemValueEntry."Document No.")
                    {
                    }
                    column(ItemValueEntryItemLedgerEntryType; Format(ItemValueEntry."Item Ledger Entry Type"))
                    {
                    }
                    column(ItemValueEntryEntryNo; ItemValueEntry."Entry No.")
                    {
                    }
                    column(ItemValueEntrySourceNo; ItemValueEntry."Source No.")
                    {
                    }
                    column(ItemValueEntryExpectedCost; Format(ItemValueEntry."Expected Cost"))
                    {
                    }
                    column(InvtAmt; InvtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(WIPInvtAmt; WIPInvtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarMfgOvhdAmt; VarMfgOvhdAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarMfgDirCostAmt; VarMfgDirCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarPurchCostAmt; VarPurchCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(OvhdCostAmt; OvhdCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(DirCostAmt; DirCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(InvtAdjmtAmt; InvtAdjmtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(COGSAmt; COGSAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(ItemCaption; ItemCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        GetItemValueEntry("Value Entry No.");
                        if ItemValueEntry."Item Ledger Entry No." = 0 then begin
                            TempCapValueEntry."Entry No." := ItemValueEntry."Entry No.";
                            TempCapValueEntry."Order Type" := ItemValueEntry."Order Type";
                            TempCapValueEntry."Order No." := ItemValueEntry."Order No.";
                            TempCapValueEntry.Insert();
                        end;

                        if (ItemValueEntry."Item Ledger Entry No." = 0) or not ItemValueEntry.Inventoriable or
                           ((ItemValueEntry."Cost Amount (Actual)" = 0) and (ItemValueEntry."Cost Amount (Expected)" = 0) and
                            (ItemValueEntry."Cost Amount (Actual) (ACY)" = 0) and (ItemValueEntry."Cost Amount (Expected) (ACY)" = 0))
                        then
                            CurrReport.Skip();

                        if not InvtPostToGL.BufferInvtPosting(ItemValueEntry) then begin
                            InsertValueEntryNoBuf(ItemValueEntry);
                            CurrReport.Skip();
                        end;

                        UpdateAmounts();
                        Mark(true);
                        if Post and (PostMethod = PostMethod::"per Entry") then
                            PostEntryToGL(ItemValueEntry);

                        if GuiAllowed then
                            Window.Update(1, "Item No.");
                        if not Item.Get("Item No.") then
                            Item.Description := ItemNoLongerExistTxt;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if Post then begin
                            MarkedOnly(true);
                            DeleteAll();
                        end;
                        if GuiAllowed then
                            Window.Close();
                    end;

                    trigger OnPreDataItem()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        if GuiAllowed then
                            Window.Open(ProcessingItemsTxt);
                        if Post then begin
                            GLEntry.LockTable();
                            GLEntry.GetLastEntryNo();
                        end;

                        OnAfterOnPreDataItem(PostValueEntryToGL, CompanyName());
                    end;
                }
                dataitem(CapValueEntryLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(OrderNo_CapValueEntryProd; CapValueEntry."Order No.")
                    {
                        IncludeCaption = true;
                    }
                    column(ExpectedCost_CapValueEntry; Format(CapValueEntry."Expected Cost"))
                    {
                    }
                    column(InvtAmt2; InvtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(WIPInvtAmt2; WIPInvtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarMfgOvhdAmt2; VarMfgOvhdAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarMfgDirCostAmt2; VarMfgDirCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarPurchCostAmt2; VarPurchCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(OvhdCostAmt2; OvhdCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(DirCostAmt2; DirCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(InvtAdjmtAmt2; InvtAdjmtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(COGSAmt2; COGSAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(PostingDate_CapValueEntry; Format(CapValueEntry."Posting Date"))
                    {
                    }
                    column(InvPostingGroup_CapValueEntry; CapValueEntry."Inventory Posting Group")
                    {
                    }
                    column(SourceNo_CapValueEntry; CapValueEntry."Source No.")
                    {
                    }
                    column(DocumentNo_CapValueEntry; CapValueEntry."Document No.")
                    {
                    }
                    column(ItemLedgEntryType_CapValueEntry; CapValueEntry."Item Ledger Entry Type")
                    {
                    }
                    column(EntryNo_CapValueEntry; CapValueEntry."Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CapValueEntry.Get(TempCapValueEntry."Entry No.");
                        if TempCapValueEntry.Next() = 0 then;
                        if not InvtPostToGL.BufferInvtPosting(CapValueEntry) then begin
                            InsertValueEntryNoBuf(CapValueEntry);
                            CurrReport.Skip();
                        end;

                        UpdateAmounts();
                        PostValueEntryToGL.Get(CapValueEntry."Entry No.");
                        PostValueEntryToGL.Mark(true);
                        if Post and (PostMethod = PostMethod::"per Entry") then
                            PostEntryToGL(CapValueEntry);

                        if GuiAllowed and (PrevCapValueEntryOrderNo <> CapValueEntry."Order No.") then begin
                            Window.Update(1, CapValueEntry."Order No.");
                            PrevCapValueEntryOrderNo := CapValueEntry."Order No.";
                        end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempCapValueEntry.DeleteAll();
                        if Post then begin
                            PostValueEntryToGL.MarkedOnly(true);
                            PostValueEntryToGL.DeleteAll();
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempCapValueEntry.Count);

                        TempCapValueEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
                        if TempCapValueEntry.FindSet() and GuiAllowed then
                            Window.Open(ProcessingProdOrdersTxt);
                    end;
                }

                trigger OnPreDataItem()
                begin
                    GLSetup.GetRecordOnce();
                    if not GLSetup."Journal Templ. Name Mandatory" then
                        case PostMethod of
                            PostMethod::"per Posting Group":
                                if DocNo = '' then
                                    Error(
                                      EnterWhenPostingErr,
                                      ItemValueEntry.FieldCaption("Document No."), SelectStr(PostMethod + 1, PostingTypeTxt));
                            PostMethod::"per Entry":
                                if DocNo <> '' then
                                    Error(
                                      DoNotEnterWhenPostingErr,
                                      ItemValueEntry.FieldCaption("Document No."), SelectStr(PostMethod + 1, PostingTypeTxt));
                        end;
                end;
            }
            dataitem(InvtPostingBufferLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(InvtPostBufAccTypeFormatted; Format(TempInvtPostBuf."Account Type"))
                {
                }
                column(DimText; DimText)
                {
                }
                column(GenPostingSetupTxt; GenPostingSetupTxt)
                {
                }
                column(InvtPostBufAmount; TempInvtPostBuf.Amount)
                {
                }
                column(InvtPostBufPostingDate; Format(TempInvtPostBuf."Posting Date"))
                {
                }
                column(EntryTypeCaption; EntryTypeCaptionLbl)
                {
                }
                column(DimTextCaption; DimTextCaptionLbl)
                {
                }
                column(GenPostingSetupTxtCaption; GenPostingSetupTxtCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(InvtPostBufAmountCaption; InvtPostBufAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    DimSetEntry: Record "Dimension Set Entry";
                begin
                    if Number = 1 then begin
                        if not TempInvtPostBuf.FindSet() then
                            CurrReport.Break();
                    end else
                        if TempInvtPostBuf.Next() = 0 then
                            CurrReport.Break();

                    DimSetEntry.SetRange("Dimension Set ID", TempInvtPostBuf."Dimension Set ID");
                    GetDimText(DimSetEntry);

                    if TempInvtPostBuf.UseInvtPostSetup() then
                        GenPostingSetupTxt :=
                          StrSubstNo('%1,%2', TempInvtPostBuf."Location Code", TempInvtPostBuf."Inventory Posting Group")
                    else
                        GenPostingSetupTxt :=
                          StrSubstNo('%1,%2', TempInvtPostBuf."Gen. Bus. Posting Group", TempInvtPostBuf."Gen. Prod. Posting Group");
                end;

                trigger OnPostDataItem()
                var
                    ValueEntry: Record "Value Entry";
                begin
                    if Post and (PostMethod = PostMethod::"per Posting Group") then begin
                        ValueEntry."Document No." := DocNo;
                        PostEntryToGL(ValueEntry);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if PostMethod = PostMethod::"per Posting Group" then
                        InvtPostToGL.GetInvtPostBuf(TempInvtPostBuf);
                    TempInvtPostBuf.Reset();
                end;
            }
            dataitem(SkippedValueEntry; "Value Entry")
            {
                DataItemTableView = sorting("Item No.");
                column(ItemNo_SkippedValueEntry; "Item No.")
                {
                }
                column(CostAmt; CostAmt)
                {
                }
                column(ExpectedCost_SkippedValueEntry; Format("Expected Cost"))
                {
                }
                column(GenProdPostingGroup_SkippedValueEntry; "Gen. Prod. Posting Group")
                {
                    IncludeCaption = true;
                }
                column(GenBusPostingGroup_SkippedValueEntry; "Gen. Bus. Posting Group")
                {
                    IncludeCaption = true;
                }
                column(LocationCode_SkippedValueEntry; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(InventoryPostingGroup_SkippedValueEntry; "Inventory Posting Group")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_SkippedValueEntry; Format("Posting Date"))
                {
                }
                column(SourceNo_SkippedValueEntry; "Source No.")
                {
                    IncludeCaption = true;
                }
                column(DocumentNo_SkippedValueEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(EntryType_SkippedValueEntry; "Entry Type")
                {
                    IncludeCaption = true;
                }
                column(ItemLedgEntryType_SkippedValueEntry; "Item Ledger Entry Type")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_SkippedValueEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(CostAmtCaption; CostAmtCaptionLbl)
                {
                }
                column(ExpectedCost_SkippedValueEntryCaption; ExpectedCost_SkippedValueEntryCaptionLbl)
                {
                }
                column(SkippedItemsCaption; SkippedItemsCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    ShouldSkip: Boolean;
                begin
                    if TempValueEntry.Next() = 0 then
                        Clear(TempValueEntry);

                    ShouldSkip := false;
                    OnSkippedvalueEntryOnOfterGetRecordOnBeforeSkip(TempValueEntry, ShouldSkip);
                    if ShouldSkip then
                        CurrReport.Skip();

                    SetRange("Item No.", TempValueEntry."Item No.");
                    SetRange("Entry No.", TempValueEntry."Entry No.");

                    if Item.Get("Item No.") then;
                    if "Expected Cost" then
                        CostAmt := "Cost Amount (Expected)"
                    else
                        CostAmt := "Cost Amount (Actual)";
                end;

                trigger OnPreDataItem()
                begin
                    TempValueEntry.SetCurrentKey("Item No.");
                    if not TempValueEntry.FindSet() then
                        CurrReport.Break();

                    SetRange("Item No.", TempValueEntry."Item No.");
                    SetRange("Entry No.", TempValueEntry."Entry No.");
                end;
            }

            trigger OnPreDataItem()
            begin
                PostMethodInt := PostMethod;
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
                    field(PostMethod; PostMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Method';
                        OptionCaption = 'Per Posting Group,Per Entry';
                        ToolTip = 'Specifies if the batch job tests the posting of inventory value to the general ledger per inventory posting group or per posted value entry. If you post per entry, you achieve a detailed specification of how the inventory affects the general ledger.';
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                        Visible = not IsJournalTemplNameMandatory;
                    }
                    field(Post; Post)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies that the inventory value will be posted to the general ledger when you run the batch job.';
                    }
                    field(JnlTemplateName; GenJnlLineReq."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameMandatory;

                        trigger OnValidate()
                        begin
                            GenJnlLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JnlBatchName; GenJnlLineReq."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                        Visible = IsJournalTemplNameMandatory;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJnlManagement.SetJnlBatchName(GenJnlLineReq);
                            if GenJnlLineReq."Journal Batch Name" <> '' then
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLineReq."Journal Batch Name" <> '' then begin
                                GenJnlLineReq.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            OnBeforeOnOpenPage(DocNo);
            GLSetup.GetRecordOnce();
            if GLSetup."Journal Templ. Name Mandatory" then begin
                IsJournalTemplNameMandatory := true;
                if GenJnlLineReq."Journal Template Name" = '' then
                    GenJnlLineReq."Journal Template Name" := GLSetup."Apply Jnl. Template Name";
                if GenJnlLineReq."Journal Batch Name" = '' then
                    GenJnlLineReq."Journal Batch Name" := GLSetup."Apply Jnl. Batch Name";
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        TotalValueEntriesPostedToGL := 0;
    end;

    trigger OnPostReport()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        if Post then
            UpdateAnalysisView.UpdateAll(0, true);
        DisplayStatistics(Post);
    end;

    trigger OnPreReport()
    var
        NoSeries: Codeunit "No. Series";
    begin
        OnBeforePreReport(Item, ItemValueEntry, PostValueEntryToGL, Post);

        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            if GenJnlLineReq."Journal Template Name" = '' then
                Error(MissingJournalFieldErr, GenJnlLineReq.FieldCaption("Journal Template Name"));
            if GenJnlLineReq."Journal Batch Name" = '' then
                Error(MissingJournalFieldErr, GenJnlLineReq.FieldCaption("Journal Batch Name"));

            Clear(DocNo);
            GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            DocNo := NoSeries.GetNextNo(GenJnlBatch."No. Series", 0D);
        end;
        OnPreReportOnAfterSetDocNo(DocNo, Post);

        ValueEntryFilter := PostValueEntryToGL.GetFilters();
        InvtSetup.Get();
    end;

    var
        EnterWhenPostingErr: Label 'Please enter a %1 when posting %2.', Comment = '%1 - field caption, %2 - posting type';
        DoNotEnterWhenPostingErr: Label 'Do not enter a %1 when posting %2.', Comment = '%1 - field caption, %2 - posting type';
        PostedPostingTypeTxt: Label 'Posted %1', Comment = '%1 - posting type';
#pragma warning disable AA0470
        ProcessingItemsTxt: Label 'Processing items  #1##########';
#pragma warning restore AA0470
        ItemNoLongerExistTxt: Label 'The item no. no longer exists.';
#pragma warning disable AA0470
        ProcessingProdOrdersTxt: Label 'Processing production order  #1##########';
#pragma warning restore AA0470
        Item: Record Item;
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        TempInvtPostBuf: Record "Invt. Posting Buffer" temporary;
        TempCapValueEntry: Record "Value Entry" temporary;
        TempValueEntry: Record "Value Entry" temporary;
        ItemValueEntry: Record "Value Entry";
        CapValueEntry: Record "Value Entry";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLineReq: Record "Gen. Journal Line";
        InvtPostToGL: Codeunit "Inventory Posting To G/L";
        Window: Dialog;
        GenPostingSetupTxt: Text[250];
        ValueEntryFilter: Text;
        DimText: Text[250];
        COGSAmt: Decimal;
        InvtAdjmtAmt: Decimal;
        DirCostAmt: Decimal;
        OvhdCostAmt: Decimal;
        VarPurchCostAmt: Decimal;
        VarMfgDirCostAmt: Decimal;
        VarMfgOvhdAmt: Decimal;
        WIPInvtAmt: Decimal;
        InvtAmt: Decimal;
        TotalCOGSAmt: Decimal;
        TotalInvtAdjmtAmt: Decimal;
        TotalDirCostAmt: Decimal;
        TotalOvhdCostAmt: Decimal;
        TotalVarPurchCostAmt: Decimal;
        TotalVarMfgDirCostAmt: Decimal;
        TotalVarMfgOvhdCostAmt: Decimal;
        TotalWIPInvtAmt: Decimal;
        TotalInvtAmt: Decimal;
        CostAmt: Decimal;
        PostingTypeTxt: Label 'per Posting Group,per Entry';
        PostMethodInt: Integer;
        PageNoCaptionLbl: Label 'Page';
        PostInvCosttoGLCaptionLbl: Label 'Post Inventory Cost to G/L';
        TestReportnotpostedCaptionLbl: Label 'Test Report (Not Posted)';
        DocNoCaptionLbl: Label 'Document No.';
        EntryNoCaptionLbl: Label 'Entry No.';
        ItemLedgerEntryTypeCaptionLbl: Label 'Item Ledger Entry Type';
        SourceNoCaptionLbl: Label 'Source No.';
        InvPostingGroupCaptionLbl: Label 'Inventory Posting Group';
        PostingDateCaptionLbl: Label 'Posting Date';
        COGSCaptionLbl: Label 'COGS', Comment = 'Cost of goods sold';
        InventoryAdjustmentCaptionLbl: Label 'Inventory Adjustment';
        DirectCostAppliedCaptionLbl: Label 'Direct Cost Applied';
        OverheadAppliedCaptionLbl: Label 'Overhead Applied';
        PurchaseVarianceCaptionLbl: Label 'Purchase Variance';
        VarMfgDirectCostAppliedCaptionLbl: Label 'Mfg. Direct Cost Variance';
        MfgOvhdVarianceCaptionLbl: Label 'Manufacturing Ovhd Variance';
        WIPInventoryCaptionLbl: Label 'WIP Inventory';
        InventoryCaptionLbl: Label 'Inventory';
        ExpectedCostCaptionLbl: Label 'Expected Cost';
        InventoryCostPostedtoGLCaptionLbl: Label 'Inventory Cost Posted to G/L';
        ItemCaptionLbl: Label 'Item';
        EntryTypeCaptionLbl: Label 'Entry Type';
        DimTextCaptionLbl: Label 'Line Dimensions';
        GenPostingSetupTxtCaptionLbl: Label 'General Posting Setup';
        TotalCaptionLbl: Label 'Total';
        InvtPostBufAmountCaptionLbl: Label 'Amount';
        CostAmtCaptionLbl: Label 'Cost Amount';
        ExpectedCost_SkippedValueEntryCaptionLbl: Label 'Skipped Value Entries';
        SkippedItemsCaptionLbl: Label 'Skipped Items';
        PrevCapValueEntryOrderNo: Code[20];
        TotalValueEntriesPostedToGL: Integer;
        IsJournalTemplNameMandatory: Boolean;
#pragma warning disable AA0470
        StatisticsMsg: Label '%1 value entries have been posted to the general ledger.', Comment = '10 value entries have been posted to the general ledger.';
#pragma warning restore AA0470
        NothingToPostMsg: Label 'There is nothing to post to the general ledger.';
        MissingJournalFieldErr: Label 'Please enter a %1 when posting inventory cost to G/L.', Comment = '%1 - field caption';

    protected var
        DocNo: Code[20];
        Post: Boolean;
        PostMethod: Option "per Posting Group","per Entry";

    procedure InitializeRequest(NewPostMethod: Option; NewDocNo: Code[20]; NewPost: Boolean)
    begin
        PostMethod := NewPostMethod;
        DocNo := NewDocNo;
        Post := NewPost;
    end;

    procedure SetGenJnlBatch(NewJnlTemplName: Code[10]; NewJnlBatchName: Code[10])
    begin
        GenJnlLineReq."Journal Template Name" := NewJnlTemplName;
        GenJnlLineReq."Journal Batch Name" := NewJnlBatchName;
    end;

    procedure GetParameters(var NewPostMethod: Option; var NewDocNo: Code[20]; var NewPost: Boolean)
    begin
        NewPostMethod := PostMethod;
        NewDocNo := DocNo;
        NewPost := Post;
    end;

    local procedure GetItemValueEntry(EntryNo: Integer)
    begin
        ItemValueEntry.Get(EntryNo);
        OnAfterGetItemValueEntry(ItemValueEntry);
    end;

    local procedure GetDimText(var DimSetEntry: Record "Dimension Set Entry")
    var
        OldDimText: Text[250];
    begin
        DimText := '';

        if DimSetEntry.FindSet() then
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
                    exit;
                end;
            until DimSetEntry.Next() = 0;
    end;

    local procedure PostEntryToGL(ValueEntry: Record "Value Entry")
    begin
        InvtPostToGL.Initialize(PostMethod = PostMethod::"per Posting Group");
        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then
            InvtPostToGL.SetGenJnlBatch(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
        InvtPostToGL.Run(ValueEntry);
        TotalValueEntriesPostedToGL += 1;
    end;

    local procedure UpdateAmounts()
    begin
        OnBeforeUpdateAmounts(ItemValueEntry);
        InvtPostToGL.GetAmtToPost(
          COGSAmt, InvtAdjmtAmt, DirCostAmt,
          OvhdCostAmt, VarPurchCostAmt, VarMfgDirCostAmt, VarMfgOvhdAmt,
          WIPInvtAmt, InvtAmt, false);

        InvtPostToGL.GetAmtToPost(
          TotalCOGSAmt, TotalInvtAdjmtAmt, TotalDirCostAmt,
          TotalOvhdCostAmt, TotalVarPurchCostAmt, TotalVarMfgDirCostAmt, TotalVarMfgOvhdCostAmt,
          TotalWIPInvtAmt, TotalInvtAmt, true);
    end;

    local procedure InsertValueEntryNoBuf(ValueEntry: Record "Value Entry")
    begin
        TempValueEntry.Init();
        TempValueEntry := ValueEntry;
        TempValueEntry.Insert();
        OnAfterInsertValueEntryNoBuf(ValueEntry, TempValueEntry);
    end;

    local procedure DisplayStatistics(NotSimulation: Boolean)
    begin
        if GuiAllowed and NotSimulation then
            if TotalValueEntriesPostedToGL > 0 then
                Message(StatisticsMsg, TotalValueEntriesPostedToGL)
            else
                Message(NothingToPostMsg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemValueEntry(var ItemValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertValueEntryNoBuf(ValueEntry: Record "Value Entry"; var TempValueEntry: Record "Value Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItem(var PostValueEntryToGL: Record "Post Value Entry to G/L"; CompanyName: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePreReport(var Item: Record Item; var ItemValueEntry: Record "Value Entry"; var PostValueEntryToGL: Record "Post Value Entry to G/L"; Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmounts(var ItemValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterSetDocNo(var DocNo: Code[20]; Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSkippedvalueEntryOnOfterGetRecordOnBeforeSkip(ValueEntry: Record "Value Entry"; var ShouldSkip: Boolean)
    begin
    end;
}

