// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Posting;

using Microsoft.Assembly.Comment;
using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.TimeSheet;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Tracking;
using System.Utilities;

codeunit 900 "Assembly-Post"
{
    Permissions = TableData "Posted Assembly Header" = rim,
                  TableData "Posted Assembly Line" = rim,
                  TableData "Item Entry Relation" = ri,
                  TableData "G/L Entry" = r;

    TableNo = "Assembly Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        AssemblyHeader: Record "Assembly Header";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        SavedSuppressCommit: Boolean;
        SavedPreviewMode: Boolean;
    begin
        OnBeforeOnRun(Rec, SuppressCommit);

        // Replace posting date if called from batch posting
        ValidatePostingDate(Rec);

        SavedSuppressCommit := SuppressCommit;
        SavedPreviewMode := PreviewMode;
        ClearAll();
        SuppressCommit := SavedSuppressCommit;
        PreviewMode := SavedPreviewMode;
        SequenceNoMgt.SetPreviewMode(PreviewMode);

        AssemblyHeader := Rec;

        if Rec.IsAsmToOrder() then
            Rec.TestField("Assemble to Order", false);

        OpenWindow(Rec."Document Type");
        Window.Update(1, StrSubstNo('%1 %2', Rec."Document Type", Rec."No."));

        InitPost(AssemblyHeader);
        Clear(PostponedValueEntries);
        BindSubscription(this); // To collect value entries for GLPosting
        Post(AssemblyHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine, false);
        UnBindSubscription(this);
        ItemJnlPostLine.PostDeferredValueEntriesToGL(PostponedValueEntries);
        FinalizePost(AssemblyHeader);
        if not (SuppressCommit or PreviewMode) then
            Commit();

        Window.Close();
        Rec := AssemblyHeader;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        OnAfterOnRun(AssemblyHeader, SuppressCommit);
    end;

    var
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
        AssembledItem: Record Item;
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        Window: Dialog;
        PostponedValueEntries: List of [Integer];
        ItemsToAdjust: List of [Code[20]];
        PostingDate: Date;
        SourceCode: Code[10];
        PostingDateExists: Boolean;
        ReplacePostingDate: Boolean;
#pragma warning disable AA0074
        Text001: Label 'is not within your range of allowed posting dates.', Comment = 'starts with "Posting Date"';
#pragma warning disable AA0470
        Text002: Label 'The combination of dimensions used in %1 %2 is blocked. %3.', Comment = '%1 = Document Type, %2 = Document No.';
        Text003: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked. %4.', Comment = '%1 = Document Type, %2 = Document No.';
        Text004: Label 'The dimensions that are used in %1 %2 are not valid. %3.', Comment = '%1 = Document Type, %2 = Document No.';
        Text005: Label 'The dimensions that are used in %1 %2, line no. %3, are not valid. %4.', Comment = '%1 = Document Type, %2 = Document No.';
        Text007: Label 'Posting lines              #2######';
        Text008: Label 'Posting %1';
        Text009: Label '%1 should be blank for comment text: %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ShowProgress: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text010: Label 'Undoing %1';
#pragma warning restore AA0470
        Text011: Label 'Posted assembly order %1 cannot be restored because the number of lines in assembly order %2 has changed.', Comment = '%1=Posted Assembly Order No. field value,%2=Assembly Header Document No field value';
#pragma warning restore AA0074
        SuppressCommit: Boolean;
        PreviewMode: Boolean;

    local procedure InitPost(var AssemblyHeader: Record "Assembly Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        NoSeries: Codeunit "No. Series";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        OnBeforeInitPost(AssemblyHeader, SuppressCommit, GenJnlPostPreview, PostingDate, PostingDateExists, ReplacePostingDate);

        AssemblyHeader.TestField("Document Type");
        AssemblyHeader.TestField("Posting Date");
        PostingDate := AssemblyHeader."Posting Date";
        if GenJnlCheckLine.DateNotAllowed(AssemblyHeader."Posting Date") then
            AssemblyHeader.FieldError("Posting Date", Text001);
        AssemblyHeader.TestField("Item No.");
        CheckDim(AssemblyHeader);
        if not IsOrderPostable(AssemblyHeader) then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        if AssemblyHeader."Posting No." = '' then
            if AssemblyHeader."Document Type" = AssemblyHeader."Document Type"::Order then begin
                AssemblyHeader.TestField("Posting No. Series");
                AssemblyHeader."Posting No." := NoSeries.GetNextNo(AssemblyHeader."Posting No. Series", AssemblyHeader."Posting Date");
                AssemblyHeader.Modify();
                if not GenJnlPostPreview.IsActive() and not (SuppressCommit or PreviewMode) then
                    Commit();
            end;

        if AssemblyHeader.Status = AssemblyHeader.Status::Open then begin
            CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
            AssemblyHeader.TestField(Status, AssemblyHeader.Status::Released);
            AssemblyHeader.Status := AssemblyHeader.Status::Open;
            if not GenJnlPostPreview.IsActive() then begin
                AssemblyHeader.Modify();
                if not (SuppressCommit or PreviewMode) then
                    Commit();
            end;
            AssemblyHeader.Status := AssemblyHeader.Status::Released;
        end;

        GetSourceCode(AssemblyHeader.IsAsmToOrder());

        OnAfterInitPost(AssemblyHeader, SuppressCommit);
    end;

    local procedure Post(var AssemblyHeader: Record "Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; NeedUpdateUnitCost: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        AssemblySetup: Record "Assembly Setup";
        AssemblyCommentLine: Record "Assembly Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        OnBeforePost(AssemblyHeader);

        AssemblyHeader.SuspendStatusCheck(true);
        LockTables(AssemblyLine, AssemblyHeader);

        // Insert posted assembly header
        if AssemblyHeader."Document Type" = AssemblyHeader."Document Type"::Order then begin
            PostedAssemblyHeader.Init();
            PostedAssemblyHeader.TransferFields(AssemblyHeader);

            PostedAssemblyHeader."No." := AssemblyHeader."Posting No.";
            PostedAssemblyHeader."Order No. Series" := AssemblyHeader."No. Series";
            PostedAssemblyHeader."Order No." := AssemblyHeader."No.";
            PostedAssemblyHeader."Source Code" := SourceCode;
            PostedAssemblyHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(PostedAssemblyHeader."User ID"));
            OnPostOnBeforePostedAssemblyHeaderInsert(AssemblyHeader, PostedAssemblyHeader);
            PostedAssemblyHeader.Insert();
            OnPostOnAfterPostedAssemblyHeaderInsert(AssemblyHeader, PostedAssemblyHeader);

            AssemblySetup.Get();
            if AssemblySetup."Copy Comments when Posting" then begin
                CopyCommentLines(
                    AssemblyHeader."Document Type", AssemblyCommentLine."Document Type"::"Posted Assembly",
                    AssemblyHeader."No.", PostedAssemblyHeader."No.");
                RecordLinkManagement.CopyLinks(AssemblyHeader, PostedAssemblyHeader);
                OnPostOnAfterCopyComments(AssemblyHeader, PostedAssemblyHeader);
            end;
        end;

        AssembledItem.Get(AssemblyHeader."Item No.");
        AssemblyHeader.TestField(AssemblyHeader."Document Type", AssemblyHeader."Document Type"::Order);
        PostLines(AssemblyHeader, AssemblyLine, PostedAssemblyHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
        PostHeader(AssemblyHeader, PostedAssemblyHeader, ItemJnlPostLine, WhseJnlRegisterLine, NeedUpdateUnitCost);

        OnAfterPost(AssemblyHeader, AssemblyLine, PostedAssemblyHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
    end;

    local procedure FinalizePost(AssemblyHeader: Record "Assembly Header")
    begin
        OnBeforeFinalizePost(AssemblyHeader);

        MakeInventoryAdjustment(AssemblyHeader);

        if not PreviewMode then
            DeleteAssemblyDocument(AssemblyHeader);

        OnAfterFinalizePost(AssemblyHeader);
    end;

    local procedure DeleteAssemblyDocument(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyCommentLine: Record "Assembly Comment Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteAssemblyDocument(AssemblyHeader, IsHandled);
        if not IsHandled then begin
            // Delete header and lines
            AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
            AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
            if AssemblyHeader."Remaining Quantity (Base)" = 0 then begin
                if AssemblyHeader.HasLinks then
                    AssemblyHeader.DeleteLinks();
                DeleteWhseRequest(AssemblyHeader);
                OnDeleteAssemblyDocumentOnBeforeDeleteAssemblyHeader(AssemblyHeader, AssemblyLine);
                AssemblyHeader.Delete();
                OnDeleteAssemblyDocumentOnAfterDeleteAssemblyHeader(AssemblyHeader, AssemblyLine);
                if AssemblyLine.Find('-') then
                    repeat
                        if AssemblyLine.HasLinks() then
                            AssemblyHeader.DeleteLinks();
                        AssemblyLineReserve.SetDeleteItemTracking(true);
                        AssemblyLineReserve.DeleteLine(AssemblyLine);
                    until AssemblyLine.Next() = 0;
                OnDeleteAssemblyDocumentOnBeforeDeleteAssemblyLines(AssemblyHeader, AssemblyLine);
                AssemblyLine.DeleteAll();
                AssemblyCommentLine.SetCurrentKey("Document Type", "Document No.");
                AssemblyCommentLine.SetRange("Document Type", AssemblyHeader."Document Type");
                AssemblyCommentLine.SetRange("Document No.", AssemblyHeader."No.");
                if not AssemblyCommentLine.IsEmpty() then
                    AssemblyCommentLine.DeleteAll();
            end;
        end;

        OnAfterDeleteAssemblyDocument(AssemblyHeader);
    end;

    local procedure OpenWindow(DocType: Enum "Assembly Document Type")
    var
        AsmHeader: Record "Assembly Header";
    begin
        AsmHeader."Document Type" := DocType;
        if AsmHeader."Document Type" = AsmHeader."Document Type"::Order then
            Window.Open(
              '#1#################################\\' +
              Text007 + '\\' +
              StrSubstNo(Text008, AsmHeader."Document Type"));
        ShowProgress := true;
    end;

    procedure SetPostingDate(NewReplacePostingDate: Boolean; NewPostingDate: Date)
    begin
        PostingDateExists := true;
        ReplacePostingDate := NewReplacePostingDate;
        PostingDate := NewPostingDate;
    end;

    local procedure ValidatePostingDate(var AssemblyHeader: Record "Assembly Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        if not PostingDateExists then
            PostingDateExists :=
              BatchProcessingMgt.GetBooleanParameter(
                AssemblyHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate) and
              BatchProcessingMgt.GetDateParameter(
                  AssemblyHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Posting Date", PostingDate);

        if PostingDateExists and (ReplacePostingDate or (AssemblyHeader."Posting Date" = 0D)) then
            AssemblyHeader."Posting Date" := PostingDate;

        OnAfterValidatePostingDate(AssemblyHeader, PostingDateExists, ReplacePostingDate);
    end;

    local procedure CheckDim(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine."Line No." := 0;
        CheckDimValuePosting(AssemblyHeader, AssemblyLine);
        CheckDimComb(AssemblyHeader, AssemblyLine);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetFilter(Type, '<>%1', AssemblyLine.Type::" ");
        if AssemblyLine.Find('-') then
            repeat
                if AssemblyHeader."Quantity to Assemble" <> 0 then begin
                    CheckDimComb(AssemblyHeader, AssemblyLine);
                    CheckDimValuePosting(AssemblyHeader, AssemblyLine);
                end;
            until AssemblyLine.Next() = 0;
    end;

    local procedure CheckDimComb(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line")
    begin
        if AssemblyLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(AssemblyHeader."Dimension Set ID") then
                Error(Text002, AssemblyHeader."Document Type", AssemblyHeader."No.", DimMgt.GetDimCombErr());

        if AssemblyLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(AssemblyLine."Dimension Set ID") then
                Error(Text003, AssemblyHeader."Document Type", AssemblyHeader."No.", AssemblyLine."Line No.", DimMgt.GetDimCombErr());
    end;

    local procedure CheckDimValuePosting(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        if AssemblyLine."Line No." = 0 then begin
            TableIDArr[1] := DATABASE::Item;
            NumberArr[1] := AssemblyHeader."Item No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, AssemblyHeader."Dimension Set ID") then
                Error(
                  Text004,
                  AssemblyHeader."Document Type", AssemblyHeader."No.", DimMgt.GetDimValuePostingErr());
        end else begin
            TableIDArr[1] := DimMgt.TypeToTableID4(AssemblyLine.Type.AsInteger());
            NumberArr[1] := AssemblyLine."No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, AssemblyLine."Dimension Set ID") then
                Error(
                  Text005,
                  AssemblyHeader."Document Type", AssemblyHeader."No.", AssemblyLine."Line No.", DimMgt.GetDimValuePostingErr());
        end;
    end;

    local procedure IsOrderPostable(AssemblyHeader: Record "Assembly Header"): Boolean
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if AssemblyHeader."Document Type" <> AssemblyHeader."Document Type"::Order then
            exit(false);

        if AssemblyHeader."Quantity to Assemble" = 0 then
            exit(false);

        AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");

        AssemblyLine.SetFilter(Type, '<>%1', AssemblyLine.Type::" ");
        if AssemblyLine.IsEmpty() then
            exit(false);

        AssemblyLine.SetFilter("Quantity to Consume", '<>0');
        exit(not AssemblyLine.IsEmpty);
    end;

    local procedure LockTables(var AssemblyLine: Record "Assembly Line"; var AssemblyHeader: Record "Assembly Header")
    var
        InvSetup: Record "Inventory Setup";
    begin
        AssemblyLine.LockTable();
        AssemblyHeader.LockTable();
        if InvSetup.UseLegacyPosting() and not InvSetup.OptimGLEntLockForMultiuserEnv() then begin
            GLEntry.LockTable();
            GLEntry.GetLastEntryNo();
        end;
    end;

    local procedure CopyCommentLines(FromDocumentType: Enum "Assembly Comment Document Type"; ToDocumentType: Enum "Assembly Comment Document Type"; FromNumber: Code[20]; ToNumber: Code[20])
    var
        AssemblyCommentLine: Record "Assembly Comment Line";
        AssemblyCommentLine2: Record "Assembly Comment Line";
    begin
        AssemblyCommentLine.SetRange("Document Type", FromDocumentType);
        AssemblyCommentLine.SetRange("Document No.", FromNumber);
        if AssemblyCommentLine.Find('-') then
            repeat
                AssemblyCommentLine2 := AssemblyCommentLine;
                AssemblyCommentLine2."Document Type" := ToDocumentType;
                AssemblyCommentLine2."Document No." := ToNumber;
                AssemblyCommentLine2.Insert();
            until AssemblyCommentLine.Next() = 0;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure SortLines(var AssemblyLine: Record "Assembly Line")
    var
        InvSetup: Record "Inventory Setup";
    begin
        if InvSetup.OptimGLEntLockForMultiuserEnv() then
            AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type, "No.")
        else
            AssemblyLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
    end;

    local procedure SortPostedLines(var PostedAsmLine: Record "Posted Assembly Line")
    var
        InvSetup: Record "Inventory Setup";
    begin
        if InvSetup.OptimGLEntLockForMultiuserEnv() then
            PostedAsmLine.SetCurrentKey(Type, "No.")
        else
            PostedAsmLine.SetCurrentKey("Document No.", "Line No.");
    end;

    local procedure GetLineQtys(var LineQty: Decimal; var LineQtyBase: Decimal; AssemblyLine: Record "Assembly Line")
    begin
        LineQty := RoundQuantity(AssemblyLine."Quantity to Consume", AssemblyLine."Qty. Rounding Precision");
        LineQtyBase := RoundQuantity(AssemblyLine."Quantity to Consume (Base)", AssemblyLine."Qty. Rounding Precision (Base)");
    end;

    local procedure GetHeaderQtys(var HeaderQty: Decimal; var HeaderQtyBase: Decimal; AssemblyHeader: Record "Assembly Header")
    begin
        HeaderQty := RoundQuantity(AssemblyHeader."Quantity to Assemble", AssemblyHeader."Qty. Rounding Precision");
        HeaderQtyBase := RoundQuantity(AssemblyHeader."Quantity to Assemble (Base)", AssemblyHeader."Qty. Rounding Precision (Base)");
    end;

    local procedure RoundQuantity(Qty: Decimal; QtyRoundingPrecision: Decimal): Decimal
    begin
        if QtyRoundingPrecision = 0 then
            QtyRoundingPrecision := UOMMgt.QtyRndPrecision();

        exit(Round(Qty, QtyRoundingPrecision))
    end;

    local procedure PostLines(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedAssemblyLine: Record "Posted Assembly Line";
        LineCounter: Integer;
        QtyToConsume: Decimal;
        QtyToConsumeBase: Decimal;
        ItemLedgEntryNo: Integer;
    begin
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        SortLines(AssemblyLine);

        LineCounter := 0;
        if AssemblyLine.FindSet() then
            repeat
                if (AssemblyLine."No." = '') and
                    (AssemblyLine.Description <> '') and
                    (AssemblyLine.Type <> AssemblyLine.Type::" ")
                then
                    Error(Text009, AssemblyLine.FieldCaption(Type), AssemblyLine.Description);

                LineCounter := LineCounter + 1;
                if ShowProgress then
                    Window.Update(2, LineCounter);

                GetLineQtys(QtyToConsume, QtyToConsumeBase, AssemblyLine);
                OnPostLinesOnAfterGetLineQtys(QtyToConsume, QtyToConsumeBase, AssemblyLine);

                ItemLedgEntryNo := 0;
                if QtyToConsumeBase <> 0 then begin
                    case AssemblyLine.Type of
                        AssemblyLine.Type::Item:
                            ItemLedgEntryNo :=
                                PostItemConsumption(
                                AssemblyHeader,
                                AssemblyLine,
                                AssemblyHeader."Posting No. Series",
                                QtyToConsume,
                                QtyToConsumeBase, ItemJnlPostLine, WhseJnlRegisterLine, AssemblyHeader."Posting No.", false, 0);
                        AssemblyLine.Type::Resource:
                            PostResourceConsumption(
                                AssemblyHeader,
                                AssemblyLine,
                                AssemblyHeader."Posting No. Series",
                                QtyToConsume,
                                QtyToConsumeBase, ResJnlPostLine, ItemJnlPostLine, AssemblyHeader."Posting No.", false);
                    end;

                    // modify the lines
                    AssemblyLine."Consumed Quantity" := AssemblyLine."Consumed Quantity" + QtyToConsume;
                    AssemblyLine."Consumed Quantity (Base)" := AssemblyLine."Consumed Quantity (Base)" + QtyToConsumeBase;
                    //// Update Qty. Pick for location with optional warehouse pick.
                    UpdateQtyPickedForOptionalWhsePick(AssemblyLine, AssemblyLine."Consumed Quantity");
                    AssemblyLine.InitRemainingQty();
                    AssemblyLine.InitQtyToConsume();
                    OnBeforeAssemblyLineModify(AssemblyLine, QtyToConsumeBase);
                    AssemblyLine.Modify();
                end;

                // Insert posted assembly lines
                PostedAssemblyLine.Init();
                PostedAssemblyLine.TransferFields(AssemblyLine);
                PostedAssemblyLine."Document No." := PostedAssemblyHeader."No.";
                PostedAssemblyLine.Quantity := QtyToConsume;
                PostedAssemblyLine."Quantity (Base)" := QtyToConsumeBase;
                PostedAssemblyLine."Cost Amount" := Round(PostedAssemblyLine.Quantity * AssemblyLine."Unit Cost");
                PostedAssemblyLine."Order No." := AssemblyLine."Document No.";
                PostedAssemblyLine."Order Line No." := AssemblyLine."Line No.";
                InsertLineItemEntryRelation(PostedAssemblyLine, ItemJnlPostLine, ItemLedgEntryNo);
                OnBeforePostedAssemblyLineInsert(PostedAssemblyLine, AssemblyLine);
                PostedAssemblyLine.Insert();
                OnAfterPostedAssemblyLineInsert(PostedAssemblyLine, AssemblyLine);
            until AssemblyLine.Next() = 0;
    end;

    local procedure PostHeader(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; NeedUpdateUnitCost: Boolean)
    var
        WhseAssemblyRelease: Codeunit "Whse.-Assembly Release";
        ItemLedgEntryNo: Integer;
        QtyToOutput: Decimal;
        QtyToOutputBase: Decimal;
    begin
        GetHeaderQtys(QtyToOutput, QtyToOutputBase, AssemblyHeader);
        if NeedUpdateUnitCost then
            if not AssemblyHeader.IsStandardCostItem() then
                AssemblyHeader.UpdateUnitCost();

        OnPostHeaderOnBeforePostItemOutput(AssemblyHeader, QtyToOutput, QtyToOutputBase);
        ItemLedgEntryNo :=
            PostItemOutput(
            AssemblyHeader, AssemblyHeader."Posting No. Series",
            QtyToOutput, QtyToOutputBase,
            ItemJnlPostLine, WhseJnlRegisterLine, AssemblyHeader."Posting No.", false, 0);
        OnPostHeaderOnAfterPostItemOutput(AssemblyHeader, QtyToOutput, QtyToOutputBase);

        // modify the header
        AssemblyHeader."Assembled Quantity" := AssemblyHeader."Assembled Quantity" + QtyToOutput;
        AssemblyHeader."Assembled Quantity (Base)" := AssemblyHeader."Assembled Quantity (Base)" + QtyToOutputBase;
        AssemblyHeader.InitRemainingQty();
        AssemblyHeader.InitQtyToAssemble();
        AssemblyHeader.Validate("Quantity to Assemble");
        AssemblyHeader."Posting No." := '';
        AssemblyHeader.Modify();

        WhseAssemblyRelease.Release(AssemblyHeader);

        // modify the posted assembly header
        PostedAssemblyHeader.Quantity := QtyToOutput;
        PostedAssemblyHeader."Quantity (Base)" := QtyToOutputBase;
        PostedAssemblyHeader."Cost Amount" := Round(PostedAssemblyHeader.Quantity * AssemblyHeader."Unit Cost");

        InsertHeaderItemEntryRelation(PostedAssemblyHeader, ItemJnlPostLine, ItemLedgEntryNo);
        PostedAssemblyHeader.Modify();
        OnAfterPostedAssemblyHeaderModify(PostedAssemblyHeader, AssemblyHeader, ItemLedgEntryNo);
    end;

    local procedure PostItemConsumption(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostingNoSeries: Code[20]; QtyToConsume: Decimal; QtyToConsumeBase: Decimal; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; DocumentNo: Code[20]; IsCorrection: Boolean; ApplyToEntryNo: Integer) Result: Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemConsumptionProcedure(
            AssemblyHeader, AssemblyLine, PostingNoSeries, QtyToConsume, QtyToConsumeBase, ItemJnlPostLine,
            WhseJnlRegisterLine, DocumentNo, IsCorrection, ApplyToEntryNo, Result, IsHandled);
        if IsHandled then
            exit;

        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);

        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Assembly Consumption";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Posted Assembly";
        ItemJnlLine."Document No." := DocumentNo;
        ItemJnlLine."Document Date" := PostingDate;
        ItemJnlLine."Document Line No." := AssemblyLine."Line No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Assembly;
        ItemJnlLine."Order No." := AssemblyLine."Document No.";
        ItemJnlLine."Order Line No." := AssemblyLine."Line No.";
        ItemJnlLine."Shortcut Dimension 1 Code" := AssemblyLine."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := AssemblyLine."Shortcut Dimension 2 Code";
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
        ItemJnlLine."Source No." := AssembledItem."No.";

        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Posting No. Series" := PostingNoSeries;
        ItemJnlLine.Type := ItemJnlLine.Type::" ";
        ItemJnlLine."Item No." := AssemblyLine."No.";
        ItemJnlLine."Gen. Bus. Posting Group" := AssemblyLine."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := AssemblyLine."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := AssemblyLine."Inventory Posting Group";

        ItemJnlLine."Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
        ItemJnlLine."Qty. Rounding Precision" := AssemblyLine."Qty. Rounding Precision";
        ItemJnlLine."Qty. Rounding Precision (Base)" := AssemblyLine."Qty. Rounding Precision (Base)";
        ItemJnlLine.Quantity := QtyToConsume;
        ItemJnlLine."Quantity (Base)" := QtyToConsumeBase;
        ItemJnlLine."Variant Code" := AssemblyLine."Variant Code";
        ItemJnlLine.Description := AssemblyLine.Description;
        ItemJnlLine.Validate("Location Code", AssemblyLine."Location Code");
        ItemJnlLine.Validate("Dimension Set ID", AssemblyLine."Dimension Set ID");
        ItemJnlLine."Bin Code" := AssemblyLine."Bin Code";
        ItemJnlLine."Unit Cost" := AssemblyLine."Unit Cost";
        ItemJnlLine.Correction := IsCorrection;
        ItemJnlLine."Applies-to Entry" := AssemblyLine."Appl.-to Item Entry";
        UpdateItemCategoryAndGroupCode(ItemJnlLine);

        OnBeforePostItemConsumption(AssemblyHeader, AssemblyLine, ItemJnlLine);

        if IsCorrection then
            PostCorrectionItemJnLine(
              ItemJnlLine, AssemblyHeader, ItemJnlPostLine, WhseJnlRegisterLine, DATABASE::"Posted Assembly Line", ApplyToEntryNo)
        else begin
            AssemblyLineReserve.TransferAsmLineToItemJnlLine(AssemblyLine, ItemJnlLine, ItemJnlLine."Quantity (Base)", false);
            PostItemJnlLine(ItemJnlLine, ItemJnlPostLine);
            OnPostItemConsumptionOnAfterPostItemJnlLine(ItemJnlPostLine, AssemblyLine);
            AssemblyLineReserve.UpdateItemTrackingAfterPosting(AssemblyLine);
            PostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
        end;
        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostItemOutput(var AssemblyHeader: Record "Assembly Header"; PostingNoSeries: Code[20]; QtyToOutput: Decimal; QtyToOutputBase: Decimal; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; DocumentNo: Code[20]; IsCorrection: Boolean; ApplyToEntryNo: Integer) Result: Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemOutputProcedure(
            AssemblyHeader, PostingNoSeries, QtyToOutput, QtyToOutputBase, ItemJnlPostLine,
            WhseJnlRegisterLine, DocumentNo, IsCorrection, ApplyToEntryNo, Result, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Assembly Output";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Posted Assembly";
        ItemJnlLine."Document No." := DocumentNo;
        ItemJnlLine."Document Date" := PostingDate;
        ItemJnlLine."Document Line No." := 0;
        ItemJnlLine."Order No." := AssemblyHeader."No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Assembly;
        ItemJnlLine."Shortcut Dimension 1 Code" := AssemblyHeader."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := AssemblyHeader."Shortcut Dimension 2 Code";
        ItemJnlLine."Order Line No." := 0;
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
        ItemJnlLine."Source No." := AssembledItem."No.";

        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Posting No. Series" := PostingNoSeries;
        ItemJnlLine.Type := ItemJnlLine.Type::" ";
        ItemJnlLine."Item No." := AssemblyHeader."Item No.";
        ItemJnlLine."Gen. Bus. Posting Group" := AssemblyHeader."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := AssemblyHeader."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := AssemblyHeader."Inventory Posting Group";

        ItemJnlLine."Unit of Measure Code" := AssemblyHeader."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := AssemblyHeader."Qty. per Unit of Measure";
        ItemJnlLine."Qty. Rounding Precision" := AssemblyHeader."Qty. Rounding Precision";
        ItemJnlLine."Qty. Rounding Precision (Base)" := AssemblyHeader."Qty. Rounding Precision (Base)";
        ItemJnlLine.Quantity := QtyToOutput;
        ItemJnlLine."Invoiced Quantity" := QtyToOutput;
        ItemJnlLine."Quantity (Base)" := QtyToOutputBase;
        ItemJnlLine."Invoiced Qty. (Base)" := QtyToOutputBase;
        ItemJnlLine."Variant Code" := AssemblyHeader."Variant Code";
        ItemJnlLine.Description := AssemblyHeader.Description;
        ItemJnlLine.Validate("Location Code", AssemblyHeader."Location Code");
        ItemJnlLine.Validate("Dimension Set ID", AssemblyHeader."Dimension Set ID");
        ItemJnlLine."Bin Code" := AssemblyHeader."Bin Code";
        ItemJnlLine."Indirect Cost %" := AssemblyHeader."Indirect Cost %";
        ItemJnlLine."Overhead Rate" := AssemblyHeader."Overhead Rate";
        ItemJnlLine."Unit Cost" := AssemblyHeader."Unit Cost";
        ItemJnlLine.Validate("Unit Amount",
            Round((AssemblyHeader."Unit Cost" - AssemblyHeader."Overhead Rate") / (1 + AssemblyHeader."Indirect Cost %" / 100),
            GLSetup."Unit-Amount Rounding Precision"));
        ItemJnlLine.Correction := IsCorrection;
        UpdateItemCategoryAndGroupCode(ItemJnlLine);
        OnAfterCreateItemJnlLineFromAssemblyHeader(ItemJnlLine, AssemblyHeader);

        if IsCorrection then
            PostCorrectionItemJnLine(
              ItemJnlLine, AssemblyHeader, ItemJnlPostLine, WhseJnlRegisterLine, DATABASE::"Posted Assembly Header", ApplyToEntryNo)
        else begin
            AssemblyHeaderReserve.TransferAsmHeaderToItemJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlLine."Quantity (Base)", false);
            PostItemJnlLine(ItemJnlLine, ItemJnlPostLine);
            AssemblyHeaderReserve.UpdateItemTrackingAfterPosting(AssemblyHeader);
            PostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
        end;
        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    var
        OrigItemJnlLine: Record "Item Journal Line";
        ItemShptEntry: Integer;
    begin
        OrigItemJnlLine := ItemJnlLine;
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        ItemShptEntry := ItemJnlLine."Item Shpt. Entry No.";
        ItemJnlLine := OrigItemJnlLine;
        ItemJnlLine."Item Shpt. Entry No." := ItemShptEntry;
    end;

    local procedure PostCorrectionItemJnLine(var ItemJnlLine: Record "Item Journal Line"; AssemblyHeader: Record "Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; SourceType: Integer; ApplyToEntry: Integer)
    var
        TempItemLedgEntry2: Record "Item Ledger Entry" temporary;
        ATOLink: Record "Assemble-to-Order Link";
        TempItemLedgEntryInChain: Record "Item Ledger Entry" temporary;
        ItemApplnEntry: Record "Item Application Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        EntriesExist: Boolean;
    begin
        UndoPostingMgt.CollectItemLedgEntries(
          TempItemLedgEntry2, SourceType, ItemJnlLine."Document No.", ItemJnlLine."Document Line No.",
          Abs(ItemJnlLine."Quantity (Base)"), ApplyToEntry);

        if TempItemLedgEntry2.FindSet() then
            repeat
                TempItemLedgEntry2."Expiration Date" :=
                  ItemTrackingMgt.ExistingExpirationDate(TempItemLedgEntry2, false, EntriesExist);
                TempItemLedgEntry := TempItemLedgEntry2;
                TempItemLedgEntry.Insert();

                if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Assembly Consumption" then begin
                    ItemJnlLine.Quantity :=
                      Round(TempItemLedgEntry.Quantity * TempItemLedgEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    ItemJnlLine."Quantity (Base)" := TempItemLedgEntry.Quantity;

                    ItemJnlLine."Applies-from Entry" := TempItemLedgEntry."Entry No.";
                end else begin
                    ItemJnlLine.Quantity :=
                      -Round(TempItemLedgEntry.Quantity * TempItemLedgEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    ItemJnlLine."Quantity (Base)" := -TempItemLedgEntry.Quantity;

                    if (ItemJnlLine."Order Type" = ItemJnlLine."Order Type"::Assembly) and
                       ATOLink.Get(ATOLink."Assembly Document Type"::Order, ItemJnlLine."Order No.")
                    then begin
                        TempItemLedgEntryInChain.Reset();
                        TempItemLedgEntryInChain.DeleteAll();
                        ItemApplnEntry.GetVisitedEntries(TempItemLedgEntry, TempItemLedgEntryInChain, true);

                        ItemJnlLine."Applies-to Entry" := FindAppliesToATOUndoEntry(TempItemLedgEntryInChain);
                    end else
                        ItemJnlLine."Applies-to Entry" := TempItemLedgEntry."Entry No.";
                end;
                ItemJnlLine."Invoiced Quantity" := ItemJnlLine.Quantity;
                ItemJnlLine."Invoiced Qty. (Base)" := ItemJnlLine."Quantity (Base)";

                ItemJnlLine.CopyTrackingFromItemLedgEntry(TempItemLedgEntry);
                ItemJnlLine."Warranty Date" := TempItemLedgEntry."Warranty Date";
                ItemJnlLine."Item Expiration Date" := TempItemLedgEntry."Expiration Date";
                ItemJnlLine."Item Shpt. Entry No." := 0;

                OnBeforePostCorrectionItemJnLine(ItemJnlLine, TempItemLedgEntry);

                ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                PostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
            until TempItemLedgEntry2.Next() = 0;
    end;

    local procedure FindAppliesToATOUndoEntry(var ItemLedgEntryInChain: Record "Item Ledger Entry"): Integer
    begin
        ItemLedgEntryInChain.Reset();
        ItemLedgEntryInChain.SetCurrentKey("Item No.", Positive);
        ItemLedgEntryInChain.SetRange(Positive, true);
        ItemLedgEntryInChain.SetRange(Open, true);
        ItemLedgEntryInChain.FindFirst();
        exit(ItemLedgEntryInChain."Entry No.");
    end;

    local procedure GetLocation(LocationCode: Code[10]; var Location: Record Location)
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure UpdateQtyPickedForOptionalWhsePick(var AssemblyLine: Record "Assembly Line"; QtyPosted: Decimal)
    var
        Location: Record Location;
    begin
        GetLocation(AssemblyLine."Location Code", Location);
        if Location."Asm. Consump. Whse. Handling" <> Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)" then
            if AssemblyLine."Qty. Picked" < QtyPosted then
                AssemblyLine.Validate("Qty. Picked", QtyPosted);
    end;

    local procedure PostWhseJnlLine(AssemblyHeader: Record "Assembly Header"; ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        Location: Record Location;
        Item: Record Item;
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        if Item.Get(ItemJnlLine."Item No.") then
            if Item.IsNonInventoriableType() then
                exit;

        IsHandled := false;
        OnBeforePostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine, Location, SourceCode, IsHandled);
        if IsHandled then
            exit;

        GetLocation(ItemJnlLine."Location Code", Location);
        if not Location."Bin Mandatory" then
            exit;

        IsHandled := false;
        OnPostWhseJnlLineOnBeforeGetWhseItemTrkgSetup(ItemJnlLine, IsHandled);
        if not IsHandled then
            if ItemTrackingMgt.GetWhseItemTrkgSetup(ItemJnlLine."Item No.") then
                if ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification) then
                    if TempTrackingSpecification.FindSet() then
                        repeat
                            case ItemJnlLine."Entry Type" of
                                ItemJnlLine."Entry Type"::"Assembly Consumption":
                                    TempTrackingSpecification."Source Type" := DATABASE::"Assembly Line";
                                ItemJnlLine."Entry Type"::"Assembly Output":
                                    TempTrackingSpecification."Source Type" := DATABASE::"Assembly Header";
                            end;
                            TempTrackingSpecification."Source Subtype" := AssemblyHeader."Document Type".AsInteger();
                            TempTrackingSpecification."Source ID" := AssemblyHeader."No.";
                            TempTrackingSpecification."Source Batch Name" := '';
                            TempTrackingSpecification."Source Prod. Order Line" := 0;
                            TempTrackingSpecification."Source Ref. No." := ItemJnlLine."Order Line No.";
                            TempTrackingSpecification.Modify();
                        until TempTrackingSpecification.Next() = 0;

        CreateWhseJnlLine(Location, TempWhseJnlLine, AssemblyHeader, ItemJnlLine);
        ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, false);
        if TempWhseJnlLine2.FindSet() then
            repeat
                WhseJnlRegisterLine.Run(TempWhseJnlLine2);
            until TempWhseJnlLine2.Next() = 0;
    end;

    local procedure CreateWhseJnlLine(Location: Record Location; var WhseJnlLine: Record "Warehouse Journal Line"; AssemblyHeader: Record "Assembly Header"; ItemJnlLine: Record "Item Journal Line")
    var
        WMSManagement: Codeunit "WMS Management";
        WhseMgt: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseJnlLine(Location, WhseJnlLine, AssemblyHeader, ItemJnlLine, IsHandled);
        if not IsHandled then begin
            case ItemJnlLine."Entry Type" of
                ItemJnlLine."Entry Type"::"Assembly Consumption":
                    WMSManagement.CheckAdjmtBin(Location, ItemJnlLine.Quantity, true);
                ItemJnlLine."Entry Type"::"Assembly Output":
                    WMSManagement.CheckAdjmtBin(Location, ItemJnlLine.Quantity, false);
            end;

            WMSManagement.CreateWhseJnlLine(ItemJnlLine, 0, WhseJnlLine, false);

            case ItemJnlLine."Entry Type" of
                ItemJnlLine."Entry Type"::"Assembly Consumption":
                    WhseJnlLine."Source Type" := DATABASE::"Assembly Line";
                ItemJnlLine."Entry Type"::"Assembly Output":
                    WhseJnlLine."Source Type" := DATABASE::"Assembly Header";
            end;
            WhseJnlLine."Source Subtype" := AssemblyHeader."Document Type".AsInteger();
            WhseJnlLine."Source Code" := SourceCode;
            WhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
            ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Assembly);
            WhseJnlLine."Source No." := ItemJnlLine."Order No.";
            WhseJnlLine."Source Line No." := ItemJnlLine."Order Line No.";
            WhseJnlLine."Reason Code" := ItemJnlLine."Reason Code";
            WhseJnlLine."Registering No. Series" := ItemJnlLine."Posting No. Series";
            WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::Assembly;
            WhseJnlLine."Whse. Document No." := ItemJnlLine."Order No.";
            WhseJnlLine."Whse. Document Line No." := ItemJnlLine."Order Line No.";
            WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::Assembly;
            WhseJnlLine."Reference No." := ItemJnlLine."Document No.";
            if Location."Directed Put-away and Pick" then
                WMSManagement.CalcCubageAndWeight(
                    ItemJnlLine."Item No.", ItemJnlLine."Unit of Measure Code", WhseJnlLine."Qty. (Absolute)",
                    WhseJnlLine.Cubage, WhseJnlLine.Weight);
        end;

        OnAfterCreateWhseJnlLineFromItemJnlLine(WhseJnlLine, ItemJnlLine);
        CheckWhseJnlLine(WhseJnlLine, ItemJnlLine);
    end;

    local procedure CheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; ItemJnlLine: Record "Item Journal Line")
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseJnlLine(WhseJnlLine, ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        WMSManagement.CheckWhseJnlLine(WhseJnlLine, 0, 0, false);
    end;

    local procedure PostResourceConsumption(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostingNoSeries: Code[20]; QtyToConsume: Decimal; QtyToConsumeBase: Decimal; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; DocumentNo: Code[20]; IsCorrection: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
        ResJnlLine: Record "Res. Journal Line";
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        AssemblyLine.TestField(Type, AssemblyLine.Type::Resource);
        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Assembly Output";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Posted Assembly";
        ItemJnlLine."Document No." := DocumentNo;
        ItemJnlLine."Document Date" := PostingDate;
        ItemJnlLine."Document Line No." := AssemblyLine."Line No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Assembly;
        ItemJnlLine."Order No." := AssemblyLine."Document No.";
        ItemJnlLine."Order Line No." := AssemblyLine."Line No.";
        ItemJnlLine."Dimension Set ID" := AssemblyLine."Dimension Set ID";
        ItemJnlLine."Shortcut Dimension 1 Code" := AssemblyLine."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := AssemblyLine."Shortcut Dimension 2 Code";
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
        ItemJnlLine."Source No." := AssemblyHeader."Item No.";

        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Posting No. Series" := PostingNoSeries;
        ItemJnlLine.Type := ItemJnlLine.Type::Resource;
        ItemJnlLine."No." := AssemblyLine."No.";
        ItemJnlLine."Item No." := AssemblyHeader."Item No.";
        ItemJnlLine."Unit of Measure Code" := AssemblyHeader."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := AssemblyHeader."Qty. per Unit of Measure";

        ItemJnlLine.Validate("Location Code", AssemblyLine."Location Code");
        ItemJnlLine."Gen. Bus. Posting Group" := AssemblyLine."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := AssemblyLine."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := AssemblyLine."Inventory Posting Group";
        ItemJnlLine."Unit Cost" := AssemblyLine."Unit Cost";
        ItemJnlLine."Qty. per Cap. Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
        ItemJnlLine."Cap. Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
        ItemJnlLine."Variant Code" := AssemblyHeader."Variant Code";
        ItemJnlLine.Description := AssemblyLine.Description;
        ItemJnlLine.Quantity := QtyToConsume;
        ItemJnlLine."Quantity (Base)" := QtyToConsumeBase;
        ItemJnlLine.Correction := IsCorrection;
        OnAfterCreateItemJnlLineFromAssemblyLine(ItemJnlLine, AssemblyLine);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        ResJnlLine.Init();
        ResJnlLine."Posting Date" := ItemJnlLine."Posting Date";
        ResJnlLine."Document Date" := ItemJnlLine."Document Date";
        ResJnlLine."Reason Code" := ItemJnlLine."Reason Code";
        ResJnlLine."System-Created Entry" := true;
        ResJnlLine.Validate("Resource No.", ItemJnlLine."No.");
        ResJnlLine.Description := ItemJnlLine.Description;
        ResJnlLine."Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
        ResJnlLine."Shortcut Dimension 1 Code" := ItemJnlLine."Shortcut Dimension 1 Code";
        ResJnlLine."Shortcut Dimension 2 Code" := ItemJnlLine."Shortcut Dimension 2 Code";
        ResJnlLine."Dimension Set ID" := ItemJnlLine."Dimension Set ID";
        ResJnlLine."Gen. Bus. Posting Group" := ItemJnlLine."Gen. Bus. Posting Group";
        ResJnlLine."Gen. Prod. Posting Group" := ItemJnlLine."Gen. Prod. Posting Group";
        ResJnlLine."Entry Type" := ResJnlLine."Entry Type"::Usage;
        ResJnlLine."Document No." := ItemJnlLine."Document No.";
        ResJnlLine."Order Type" := ResJnlLine."Order Type"::Assembly;
        ResJnlLine."Order No." := ItemJnlLine."Order No.";
        ResJnlLine."Order Line No." := ItemJnlLine."Order Line No.";
        ResJnlLine."Line No." := ItemJnlLine."Document Line No.";
        ResJnlLine."External Document No." := ItemJnlLine."External Document No.";
        ResJnlLine.Quantity := QtyToConsume;
        ResJnlLine."Unit Cost" := AssemblyLine."Unit Cost";
        ResJnlLine."Total Cost" := AssemblyLine."Unit Cost" * ResJnlLine.Quantity;
        ResJnlLine."Source Code" := ItemJnlLine."Source Code";
        ResJnlLine."Posting No. Series" := ItemJnlLine."Posting No. Series";
        ResJnlLine."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
        OnAfterCreateResJnlLineFromItemJnlLine(ResJnlLine, ItemJnlLine, AssemblyLine);
        ResJnlPostLine.RunWithCheck(ResJnlLine);

        TimeSheetMgt.CreateTSLineFromAssemblyLine(AssemblyHeader, AssemblyLine, QtyToConsumeBase);
    end;

    local procedure InsertLineItemEntryRelation(var PostedAssemblyLine: Record "Posted Assembly Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; ItemLedgEntryNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
    begin
        if ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    ItemEntryRelation.TransferFieldsPostedAsmLine(PostedAssemblyLine);
                    ItemEntryRelation.Insert();
                until TempItemEntryRelation.Next() = 0;
        end else
            PostedAssemblyLine."Item Shpt. Entry No." := ItemLedgEntryNo;
    end;

    local procedure InsertHeaderItemEntryRelation(var PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; ItemLedgEntryNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
    begin
        if ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    ItemEntryRelation.TransferFieldsPostedAsmHeader(PostedAssemblyHeader);
                    ItemEntryRelation.Insert();
                    OnInsertHeaderItemEntryRelationOnAfterInsertItemEntryRelation(ItemEntryRelation, PostedAssemblyHeader);
                until TempItemEntryRelation.Next() = 0;
        end else
            PostedAssemblyHeader."Item Rcpt. Entry No." := ItemLedgEntryNo;
    end;

    procedure Undo(var PostedAsmHeader: Record "Posted Assembly Header"; RecreateAsmOrder: Boolean)
    var
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        SavedSuppressCommit: Boolean;
        SavedPreviewMode: Boolean;
    begin
        SavedSuppressCommit := SuppressCommit;
        SavedPreviewMode := PreviewMode;
        ClearAll();
        SuppressCommit := SavedSuppressCommit;
        PreviewMode := SavedPreviewMode;

        Window.Open(
          '#1#################################\\' +
          Text007 + '\\' +
          StrSubstNo(Text010, PostedAsmHeader."No."));

        ShowProgress := true;
        Window.Update(1, StrSubstNo('%1 %2', PostedAsmHeader.TableCaption(), PostedAsmHeader."No."));

        PostedAsmHeader.CheckIsNotAsmToOrder();

        UndoInitPost(PostedAsmHeader);
        UndoPost(PostedAsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
        UndoFinalizePost(PostedAsmHeader, RecreateAsmOrder);

        if not (SuppressCommit or PreviewMode) then
            Commit();

        Window.Close();
    end;

    local procedure UndoInitPost(var PostedAsmHeader: Record "Posted Assembly Header")
    begin
        PostingDate := PostedAsmHeader."Posting Date";

        CheckPossibleToUndo(PostedAsmHeader);

        GetSourceCode(PostedAsmHeader.IsAsmToOrder());

        TempItemLedgEntry.Reset();
        TempItemLedgEntry.DeleteAll();

        OnAfterUndoInitPost(PostedAsmHeader, PostingDate);
    end;

    local procedure UndoFinalizePost(var PostedAsmHeader: Record "Posted Assembly Header"; RecreateAsmOrder: Boolean)
    var
        AsmHeader: Record "Assembly Header";
    begin
        MakeInventoryAdjustment();

        if AsmHeader.Get(AsmHeader."Document Type"::Order, PostedAsmHeader."Order No.") then
            UpdateAsmOrderWithUndo(PostedAsmHeader)
        else
            if RecreateAsmOrder then
                RecreateAsmOrderWithUndo(PostedAsmHeader);
    end;

    local procedure UndoPost(var PostedAsmHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        AssembledItem.Get(PostedAsmHeader."Item No.");
        UndoPostHeader(PostedAsmHeader, ItemJnlPostLine, WhseJnlRegisterLine);
        UndoPostLines(PostedAsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);

        OnAfterUndoPost(PostedAsmHeader, SuppressCommit);
    end;

    local procedure UndoPostLines(PostedAsmHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedAsmLine: Record "Posted Assembly Line";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        LineCounter: Integer;
    begin
        AsmHeader.TransferFields(PostedAsmHeader);
        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader."No." := PostedAsmHeader."Order No.";

        PostedAsmLine.Reset();
        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
        OnUndoPostLinesOnBeforeSortPostedLines(PostedAsmHeader, PostedAsmLine);
        SortPostedLines(PostedAsmLine);

        LineCounter := 0;
        if PostedAsmLine.FindSet() then
            repeat
                AsmLine.TransferFields(PostedAsmLine);
                OnUndoPostLinesOnAfterTransferFields(AsmLine, AsmHeader, PostedAsmHeader);
                AsmLine."Document Type" := AsmHeader."Document Type"::Order;
                AsmLine."Document No." := PostedAsmHeader."Order No.";

                LineCounter := LineCounter + 1;
                if ShowProgress then
                    Window.Update(2, LineCounter);

                if PostedAsmLine."Quantity (Base)" <> 0 then begin
                    case PostedAsmLine.Type of
                        PostedAsmLine.Type::Item:
                            PostItemConsumption(
                                AsmHeader,
                                AsmLine,
                                PostedAsmHeader."No. Series",
                                -PostedAsmLine.Quantity,
                                -PostedAsmLine."Quantity (Base)", ItemJnlPostLine, WhseJnlRegisterLine, PostedAsmLine."Document No.", true, PostedAsmLine."Item Shpt. Entry No.");
                        PostedAsmLine.Type::Resource:
                            PostResourceConsumption(
                                AsmHeader,
                                AsmLine,
                                PostedAsmHeader."No. Series",
                                -PostedAsmLine.Quantity,
                                -PostedAsmLine."Quantity (Base)",
                                ResJnlPostLine, ItemJnlPostLine, PostedAsmLine."Document No.", true);
                    end;
                    InsertLineItemEntryRelation(PostedAsmLine, ItemJnlPostLine, 0);

                    PostedAsmLine.Modify();
                end;
            until PostedAsmLine.Next() = 0;
    end;

    local procedure UndoPostHeader(var PostedAsmHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        AsmHeader: Record "Assembly Header";
    begin
        AsmHeader.TransferFields(PostedAsmHeader);
        OnUndoPostHeaderOnAfterTransferFields(AsmHeader, PostedAsmHeader);
        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader."No." := PostedAsmHeader."Order No.";

        PostItemOutput(
            AsmHeader, PostedAsmHeader."No. Series", -PostedAsmHeader.Quantity, -PostedAsmHeader."Quantity (Base)",
            ItemJnlPostLine, WhseJnlRegisterLine, PostedAsmHeader."No.", true, PostedAsmHeader."Item Rcpt. Entry No.");
        InsertHeaderItemEntryRelation(PostedAsmHeader, ItemJnlPostLine, 0);

        PostedAsmHeader.Reversed := true;
        PostedAsmHeader.Modify();
    end;

    local procedure SumCapQtyPosted(OrderNo: Code[20]; OrderLineNo: Integer): Decimal
    var
        CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
    begin
        CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Assembly);
        CapLedgEntry.SetRange("Order No.", OrderNo);
        CapLedgEntry.SetRange("Order Line No.", OrderLineNo);
        CapLedgEntry.CalcSums(Quantity);
        exit(CapLedgEntry.Quantity);
    end;

    local procedure SumItemQtyPosted(OrderNo: Code[20]; OrderLineNo: Integer): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Assembly);
        ItemLedgEntry.SetRange("Order No.", OrderNo);
        ItemLedgEntry.SetRange("Order Line No.", OrderLineNo);
        ItemLedgEntry.CalcSums(Quantity);
        exit(ItemLedgEntry.Quantity);
    end;

    local procedure UpdateAsmOrderWithUndo(var PostedAsmHeader: Record "Posted Assembly Header")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        PostedAsmLine: Record "Posted Assembly Line";
    begin
        AsmHeader.Get(AsmHeader."Document Type"::Order, PostedAsmHeader."Order No.");
        AsmHeader."Assembled Quantity" -= PostedAsmHeader.Quantity;
        AsmHeader."Assembled Quantity (Base)" -= PostedAsmHeader."Quantity (Base)";
        AsmHeader.InitRemainingQty();
        AsmHeader.InitQtyToAssemble();
        AsmHeader.Modify();

        RestoreItemTracking(TempItemLedgEntry, AsmHeader."No.", 0, DATABASE::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."Due Date", 0D);
        VerifyAsmHeaderReservAfterUndo(AsmHeader);

        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
        PostedAsmLine.SetFilter("Quantity (Base)", '<>0');
        if PostedAsmLine.FindSet() then
            repeat
                AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", PostedAsmLine."Line No.");
                AsmLine."Consumed Quantity" -= PostedAsmLine.Quantity;
                AsmLine."Consumed Quantity (Base)" -= PostedAsmLine."Quantity (Base)";
                if AsmLine."Qty. Picked (Base)" <> 0 then begin
                    AsmLine."Qty. Picked" -= PostedAsmLine.Quantity;
                    AsmLine."Qty. Picked (Base)" -= PostedAsmLine."Quantity (Base)";
                end;

                AsmLine.InitRemainingQty();
                AsmLine.InitQtyToConsume();
                AsmLine.Modify();

                if not FindItemLedgerEntryAndWhseItemTrackingLine(AsmLine, PostedAsmLine) then
                    RestoreItemTracking(TempItemLedgEntry, AsmLine."Document No.", AsmLine."Line No.", DATABASE::"Assembly Line", AsmLine."Document Type".AsInteger(), 0D, AsmLine."Due Date");
                VerifyAsmLineReservAfterUndo(AsmLine);
            until PostedAsmLine.Next() = 0;

        OnAfterUpdateAsmOrderWithUndo(PostedAsmHeader, AsmHeader);
    end;

    local procedure RecreateAsmOrderWithUndo(var PostedAsmHeader: Record "Posted Assembly Header")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        PostedAsmLine: Record "Posted Assembly Line";
        AsmCommentLine: Record "Assembly Comment Line";
    begin
        AsmHeader.Init();
        AsmHeader.TransferFields(PostedAsmHeader);
        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader."No." := PostedAsmHeader."Order No.";

        AsmHeader."Assembled Quantity (Base)" := SumItemQtyPosted(AsmHeader."No.", 0);
        AsmHeader."Assembled Quantity" := Round(AsmHeader."Assembled Quantity (Base)" / AsmHeader."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        AsmHeader.Quantity := PostedAsmHeader.Quantity + AsmHeader."Assembled Quantity";
        AsmHeader."Quantity (Base)" := PostedAsmHeader."Quantity (Base)" + AsmHeader."Assembled Quantity (Base)";
        AsmHeader.InitRemainingQty();
        AsmHeader.InitQtyToAssemble();

        OnBeforeRecreatedAsmHeaderInsert(AsmHeader, PostedAsmHeader);
        AsmHeader.Insert();

        CopyCommentLines(
            AsmCommentLine."Document Type"::"Posted Assembly", AsmHeader."Document Type",
            PostedAsmHeader."No.", AsmHeader."No.");

        RestoreItemTracking(
            TempItemLedgEntry, AsmHeader."No.", 0, DATABASE::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."Due Date", 0D);
        VerifyAsmHeaderReservAfterUndo(AsmHeader);

        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
        if PostedAsmLine.FindSet() then
            repeat
                AsmLine.Init();
                AsmLine.TransferFields(PostedAsmLine);
                AsmLine."Document Type" := AsmLine."Document Type"::Order;
                AsmLine."Document No." := PostedAsmLine."Order No.";
                AsmLine."Line No." := PostedAsmLine."Order Line No.";

                if PostedAsmLine."Quantity (Base)" <> 0 then begin
                    if AsmLine.Type = AsmLine.Type::Item then
                        AsmLine."Consumed Quantity (Base)" := -SumItemQtyPosted(AsmLine."Document No.", AsmLine."Line No.")
                    else
                        AsmLine."Consumed Quantity (Base)" := SumCapQtyPosted(AsmLine."Document No.", AsmLine."Line No.");

                    AsmLine."Consumed Quantity" := Round(AsmLine."Consumed Quantity (Base)" / AsmLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    AsmLine.Quantity := PostedAsmLine.Quantity + AsmLine."Consumed Quantity";
                    AsmLine."Quantity (Base)" := PostedAsmLine."Quantity (Base)" + AsmLine."Consumed Quantity (Base)";
                    AsmLine."Cost Amount" := AsmLine.CalcCostAmount(AsmLine.Quantity, AsmLine."Unit Cost");
                    if AsmLine.Type = AsmLine.Type::Item then begin
                        AsmLine."Qty. Picked" := AsmLine."Consumed Quantity";
                        AsmLine."Qty. Picked (Base)" := AsmLine."Consumed Quantity (Base)";
                    end;
                    AsmLine.InitRemainingQty();
                    AsmLine.InitQtyToConsume();
                end;
                AsmLine.Insert();

                RestoreItemTracking(
                    TempItemLedgEntry,
                    AsmLine."Document No.", AsmLine."Line No.", DATABASE::"Assembly Line", AsmLine."Document Type".AsInteger(), 0D, AsmLine."Due Date");
                VerifyAsmLineReservAfterUndo(AsmLine);
            until PostedAsmLine.Next() = 0;

        OnAfterRecreateAsmOrderWithUndo(PostedAsmHeader, AsmHeader);
    end;

    local procedure VerifyAsmHeaderReservAfterUndo(var AsmHeader: Record "Assembly Header")
    var
        xAsmHeader: Record "Assembly Header";
        AsmHeaderReserve: Codeunit "Assembly Header-Reserve";
    begin
        xAsmHeader := AsmHeader;
        xAsmHeader."Quantity (Base)" := 0;
        AsmHeaderReserve.VerifyQuantity(AsmHeader, xAsmHeader);
    end;

    local procedure VerifyAsmLineReservAfterUndo(var AsmLine: Record "Assembly Line")
    var
        xAsmLine: Record "Assembly Line";
        AsmLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        xAsmLine := AsmLine;
        xAsmLine."Quantity (Base)" := 0;
        AsmLineReserve.VerifyQuantity(AsmLine, xAsmLine);
    end;

    local procedure GetSourceCode(IsATO: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if IsATO then
            SourceCode := SourceCodeSetup.Sales
        else
            SourceCode := SourceCodeSetup.Assembly;
    end;

    local procedure CheckPossibleToUndo(PostedAsmHeader: Record "Posted Assembly Header"): Boolean
    var
        AsmHeader: Record "Assembly Header";
        PostedAsmLine: Record "Posted Assembly Line";
        AsmLine: Record "Assembly Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPossibleToUndo(PostedAsmHeader, IsHandled);
        if IsHandled then
            exit;

        PostedAsmHeader.TestField(Reversed, false);
        UndoPostingMgt.TestAsmHeader(PostedAsmHeader);
        UndoPostingMgt.CollectItemLedgEntries(
            TempItemLedgEntry, DATABASE::"Posted Assembly Header", PostedAsmHeader."No.", 0, PostedAsmHeader."Quantity (Base)", PostedAsmHeader."Item Rcpt. Entry No.");
        UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, 0);

        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
        repeat
            if (PostedAsmLine.Type = PostedAsmLine.Type::Item) and (PostedAsmLine."Item Shpt. Entry No." <> 0) then begin
                UndoPostingMgt.TestAsmLine(PostedAsmLine);
                UndoPostingMgt.CollectItemLedgEntries(
                    TempItemLedgEntry, DATABASE::"Posted Assembly Line", PostedAsmLine."Document No.", PostedAsmLine."Line No.",
                    PostedAsmLine."Quantity (Base)", PostedAsmLine."Item Shpt. Entry No.");
                UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, PostedAsmLine."Line No.");
            end;
        until PostedAsmLine.Next() = 0;

        if not AsmHeader.Get(AsmHeader."Document Type"::Order, PostedAsmHeader."Order No.") then
            exit(true);

        AsmHeader.TestField("Variant Code", PostedAsmHeader."Variant Code");
        AsmHeader.TestField("Location Code", PostedAsmHeader."Location Code");
        AsmHeader.TestField("Bin Code", PostedAsmHeader."Bin Code");

        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        if PostedAsmLine.Count() <> AsmLine.Count() then
            Error(Text011, PostedAsmHeader."No.", AsmHeader."No.");

        AsmLine.FindSet();
        PostedAsmLine.FindSet();
        repeat
            AsmLine.TestField(Type, PostedAsmLine.Type);
            AsmLine.TestField("No.", PostedAsmLine."No.");
            AsmLine.TestField("Variant Code", PostedAsmLine."Variant Code");
            AsmLine.TestField("Location Code", PostedAsmLine."Location Code");
            AsmLine.TestField("Bin Code", PostedAsmLine."Bin Code");
        until (PostedAsmLine.Next() = 0) and (AsmLine.Next() = 0);
    end;

    local procedure RestoreItemTracking(var ItemLedgEntry: Record "Item Ledger Entry"; OrderNo: Code[20]; OrderLineNo: Integer; SourceType: Integer; DocType: Option; RcptDate: Date; ShptDate: Date)
    var
        AsmHeader: Record "Assembly Header";
        ReservEntry: Record "Reservation Entry";
        ATOLink: Record "Assemble-to-Order Link";
        SalesLine: Record "Sales Line";
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsATOHeader: Boolean;
        ReservStatus: Enum "Reservation Status";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRestoreItemTracking(ItemLedgEntry, OrderNo, OrderLineNo, SourceType, DocType, RcptDate, ShptDate, IsHandled);
        if not IsHandled then begin
            AsmHeader.Get(AsmHeader."Document Type"::Order, OrderNo);
            IsATOHeader := (OrderLineNo = 0) and AsmHeader.IsAsmToOrder();

            ItemLedgEntry.Reset();
            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Assembly);
            ItemLedgEntry.SetRange("Order No.", OrderNo);
            ItemLedgEntry.SetRange("Order Line No.", OrderLineNo);
            if ItemLedgEntry.FindSet() then
                repeat
                    if ItemLedgEntry.TrackingExists() then begin
                        CreateReservEntry.SetDates(ItemLedgEntry."Warranty Date", ItemLedgEntry."Expiration Date");
                        CreateReservEntry.SetQtyToHandleAndInvoice(ItemLedgEntry.Quantity, ItemLedgEntry.Quantity);
                        CreateReservEntry.SetItemLedgEntryNo(ItemLedgEntry."Entry No.");
                        ReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                        CreateReservEntry.CreateReservEntryFor(
                            SourceType, DocType, ItemLedgEntry."Order No.", '', 0, ItemLedgEntry."Order Line No.",
                            ItemLedgEntry."Qty. per Unit of Measure", 0, Abs(ItemLedgEntry.Quantity), ReservEntry);

                        if IsATOHeader then begin
                            ATOLink.Get(AsmHeader."Document Type", AsmHeader."No.");
                            IsHandled := false;
                            OnBeforeRestoreItemTrackingOnBeforeCreateSalesAssemblyReservationEntry(ItemLedgEntry, AsmHeader, ATOLink, CreateReservEntry, FromTrackingSpecification, ReservStatus, IsHandled);
                            if not IsHandled then begin
                                ATOLink.TestField(Type, ATOLink.Type::Sale);
                                SalesLine.Get(ATOLink."Document Type", ATOLink."Document No.", ATOLink."Document Line No.");

                                CreateReservEntry.SetDisallowCancellation(true);
                                CreateReservEntry.SetBinding("Reservation Binding"::"Order-to-Order");

                                SalesLineReserve.InitFromSalesLine(FromTrackingSpecification, SalesLine);
                                FromTrackingSpecification."Qty. per Unit of Measure" := ItemLedgEntry."Qty. per Unit of Measure";
                                FromTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                                CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
                                ReservStatus := ReservStatus::Reservation;
                            end;
                        end else
                            ReservStatus := ReservStatus::Surplus;
                        CreateReservEntry.CreateEntry(
                            ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code", ItemLedgEntry."Location Code", '', RcptDate, ShptDate, 0, ReservStatus);
                    end;
                until ItemLedgEntry.Next() = 0;
            ItemLedgEntry.DeleteAll();
        end;
    end;

    procedure InitPostATO(var AssemblyHeader: Record "Assembly Header")
    begin
        if AssemblyHeader.IsAsmToOrder() then
            InitPost(AssemblyHeader);
    end;

    procedure PostATO(var AssemblyHeader: Record "Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        if AssemblyHeader.IsAsmToOrder() then
            Post(AssemblyHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine, true);
    end;

    procedure FinalizePostATO(var AssemblyHeader: Record "Assembly Header")
    begin
        if AssemblyHeader.IsAsmToOrder() then
            FinalizePost(AssemblyHeader);
    end;

    procedure UndoInitPostATO(var PostedAsmHeader: Record "Posted Assembly Header")
    begin
        if PostedAsmHeader.IsAsmToOrder() then
            UndoInitPost(PostedAsmHeader);
    end;

    procedure UndoPostATO(var PostedAsmHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        if PostedAsmHeader.IsAsmToOrder() then
            UndoPost(PostedAsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
    end;

    procedure UndoFinalizePostATO(var PostedAsmHeader: Record "Posted Assembly Header")
    begin
        if PostedAsmHeader.IsAsmToOrder() then
            UndoFinalizePost(PostedAsmHeader, false);
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtAdjmtHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust);
    end;

    local procedure MakeInventoryAdjustment(AssemblyHeader: Record "Assembly Header")
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Assembly);
        InventoryAdjmtEntryOrder.SetRange("Order No.", AssemblyHeader."No.");
        InvtAdjmtHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust, InventoryAdjmtEntryOrder);
    end;

    local procedure DeleteWhseRequest(AssemblyHeader: Record "Assembly Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetRange("Source Type", DATABASE::"Assembly Line");
        WarehouseRequest.SetRange("Source Subtype", AssemblyHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", AssemblyHeader."No.");
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.DeleteAll(true);
    end;

    procedure UpdateBlanketATO(xBlanketOrderSalesLine: Record "Sales Line"; BlanketOrderSalesLine: Record "Sales Line")
    var
        AsmHeader: Record "Assembly Header";
        QuantityDiff: Decimal;
        QuantityDiffBase: Decimal;
    begin
        if BlanketOrderSalesLine.AsmToOrderExists(AsmHeader) then begin
            QuantityDiff := BlanketOrderSalesLine."Quantity Shipped" - xBlanketOrderSalesLine."Quantity Shipped";
            QuantityDiffBase := BlanketOrderSalesLine."Qty. Shipped (Base)" - xBlanketOrderSalesLine."Qty. Shipped (Base)";

            AsmHeader."Assembled Quantity" += QuantityDiff;
            AsmHeader."Assembled Quantity (Base)" += QuantityDiffBase;
            AsmHeader.InitRemainingQty();
            AsmHeader.InitQtyToAssemble();
            AsmHeader.Modify(true);
            UpdateBlanketATOLines(AsmHeader, QuantityDiff);
        end;
    end;

    local procedure UpdateBlanketATOLines(AsmHeader: Record "Assembly Header"; QuantityDiff: Decimal)
    var
        AsmLine: Record "Assembly Line";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        if AsmLine.FindSet() then
            repeat
                AsmLine."Consumed Quantity" += UOMMgt.RoundQty(QuantityDiff * AsmLine."Quantity per");
                AsmLine."Consumed Quantity (Base)" +=
                    UOMMgt.CalcBaseQty(
                    AsmLine."No.", AsmLine."Variant Code", AsmLine."Unit of Measure Code",
                    QuantityDiff * AsmLine."Quantity per", AsmLine."Qty. per Unit of Measure");
                AsmLine.InitRemainingQty();
                AsmLine.InitQtyToConsume();
                AsmLine.Modify(true);
            until AsmLine.Next() = 0;
    end;

    local procedure UpdateItemCategoryAndGroupCode(var ItemJnlLine: Record "Item Journal Line")
    var
        Item: Record Item;
    begin
        Item.Get(ItemJnlLine."Item No.");
        ItemJnlLine."Item Category Code" := Item."Item Category Code";
    end;

    local procedure FindItemLedgerEntryAndWhseItemTrackingLine(AssemblyLine: Record "Assembly Line"; PostedAssemblyLine: Record "Posted Assembly Line"): Boolean
    var
        Item: Record Item;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        WhseItemTrackingLineIsDeleted: Boolean;
    begin
        PostedAssemblyHeader.SetLoadFields("Item No.");
        PostedAssemblyHeader.Get(PostedAssemblyLine."Document No.");

        Item.SetLoadFields("Assembly Policy");
        Item.Get(PostedAssemblyHeader."Item No.");
        if not (Item."Assembly Policy" = Item."Assembly Policy"::"Assemble-to-Order") then
            exit(false);

        ItemTrackingDocManagement.RetrieveEntriesFromShptRcpt(TempItemLedgerEntry, Database::"Posted Assembly Line", 0, PostedAssemblyLine."Document No.", '', 0, PostedAssemblyLine."Line No.");
        if TempItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry.Get(TempItemLedgerEntry."Entry No.");
                WhseItemTrackingLineIsDeleted := FindandDeleteWhseItemTrackingLinesforAssembly(AssemblyLine, ItemLedgerEntry);
            until TempItemLedgerEntry.Next() = 0;

        exit(WhseItemTrackingLineIsDeleted);
    end;

    local procedure FindandDeleteWhseItemTrackingLinesforAssembly(AssemblyLine: Record "Assembly Line"; ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetSourceFilter(
            Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(),
            AssemblyLine."Document No.", AssemblyLine."Line No.", true);
        WhseItemTrackingLine.SetRange("Quantity Handled (Base)", Abs(ItemLedgerEntry.Quantity));
        WhseItemTrackingLine.SetTrackingFilterFromItemLedgerEntry(ItemLedgerEntry);
        if WhseItemTrackingLine.FindFirst() then begin
            WhseItemTrackingLine.Delete();
            exit(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforePostValueEntryToGL', '', false, false)]
    local procedure OnBeforePostValueEntryToGL(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if InventorySetup.UseLegacyPosting() then
            exit;
        PostponedValueEntries.Add(ValueEntry."Entry No.");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem', '', false, false)]
    local procedure OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem(var Item2: Record Item)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if InventorySetup.UseLegacyPosting() then
            exit;

        if not ItemsToAdjust.Contains(Item2."No.") then
            ItemsToAdjust.Add(Item2."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLineFromAssemblyHeader(var ItemJournalLine: Record "Item Journal Line"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLineFromAssemblyLine(var ItemJournalLine: Record "Item Journal Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateResJnlLineFromItemJnlLine(var ResJournalLine: Record "Res. Journal Line"; ItemJournalLine: Record "Item Journal Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLineFromItemJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAssemblyDocument(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePost(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPost(var AssemblyHeader: Record "Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var AssemblyHeader: Record "Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedAssemblyLineInsert(var PostedAssemblyLine: Record "Posted Assembly Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedAssemblyHeaderModify(var PostedAssemblyHeader: Record "Posted Assembly Header"; AssemblyHeader: Record "Assembly Header"; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateAsmOrderWithUndo(var PostedAssemblyHeader: Record "Posted Assembly Header"; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostingDate(var AssemblyHeader: Record "Assembly Header"; PostingDateExists: Boolean; ReplacePostingDate: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoInitPost(var PostedAssemblyHeader: Record "Posted Assembly Header"; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoPost(var PostedAssemblyHeader: Record "Posted Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAsmOrderWithUndo(var PostedAssemblyHeader: Record "Posted Assembly Header"; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssemblyLineModify(var AssemblyLine: Record "Assembly Line"; QtyToConsumeBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAssemblyDocument(AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizePost(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPost(var AssemblyHeader: Record "Assembly Header"; SuppressCommit: Boolean; var GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview"; var PostingDate: Date; PostingDateExists: Boolean; ReplacePostingDate: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnRun(var AssemblyHeader: Record "Assembly Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCorrectionItemJnLine(var ItemJournalLine: Record "Item Journal Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemConsumption(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(AssemblyHeader: Record "Assembly Header"; ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; Location: Record Location; SourceCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedAssemblyLineInsert(var PostedAssemblyLine: Record "Posted Assembly Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemConsumptionProcedure(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostingNoSeries: Code[20]; QtyToConsume: Decimal; QtyToConsumeBase: Decimal; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; DocumentNo: Code[20]; IsCorrection: Boolean; ApplyToEntryNo: Integer; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemOutputProcedure(AssemblyHeader: Record "Assembly Header"; PostingNoSeries: Code[20]; QtyToOutput: Decimal; QtyToOutputBase: Decimal; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; DocumentNo: Code[20]; IsCorrection: Boolean; ApplyToEntryNo: Integer; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreatedAsmHeaderInsert(var AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAssemblyDocumentOnBeforeDeleteAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAssemblyDocumentOnAfterDeleteAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAssemblyDocumentOnBeforeDeleteAssemblyLines(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertHeaderItemEntryRelationOnAfterInsertItemEntryRelation(var ItemEntryRelation: Record "Item Entry Relation"; var PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostHeaderOnAfterPostItemOutput(var AssemblyHeader: Record "Assembly Header"; var HeaderQty: Decimal; var HeaderQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostHeaderOnBeforePostItemOutput(var AssemblyHeader: Record "Assembly Header"; var HeaderQty: Decimal; var HeaderQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemConsumptionOnAfterPostItemJnlLine(var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOnAfterPostedAssemblyHeaderInsert(AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOnAfterCopyComments(AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOnBeforePostedAssemblyHeaderInsert(AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGetLineQtys(var LineQty: Decimal; var LineQtyBase: Decimal; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnBeforeGetWhseItemTrkgSetup(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoPostHeaderOnAfterTransferFields(var AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoPostLinesOnAfterTransferFields(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoPostLinesOnBeforeSortPostedLines(PostedAssemblyHeader: Record "Posted Assembly Header"; var PostedAssemblyLine: Record "Posted Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRestoreItemTracking(var ItemLedgerEntry: Record "Item Ledger Entry"; OrderNo: Code[20]; OrderLineNo: Integer; SourceType: Integer; DocType: Option; RcptDate: Date; ShptDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseJnlLine(Location: Record Location; var WarehouseJournalLine: Record "Warehouse Journal Line"; AssemblyHeader: Record "Assembly Header"; ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPossibleToUndo(PostedAssemblyHeader: Record "Posted Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRestoreItemTrackingOnBeforeCreateSalesAssemblyReservationEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; AssemblyHeader: Record "Assembly Header"; var ATOLink: Record "Assemble-to-Order Link"; var CreateReservEntry: Codeunit "Create Reserv. Entry"; var FromTrackingSpecification: Record "Tracking Specification"; var ReservStatus: Enum "Reservation Status"; var IsHandled: Boolean)
    begin
    end;
}

