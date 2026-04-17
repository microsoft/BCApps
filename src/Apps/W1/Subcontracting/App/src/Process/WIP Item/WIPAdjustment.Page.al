// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;

page 99001561 "WIP Adjustment"
{
    ApplicationArea = Manufacturing;
    Caption = 'WIP Adjustment';
    PageType = StandardDialog;
    SourceTable = "Subcontractor WIP Ledger Entry";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    DataCaptionExpression = CreatePageCaption();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Adjustment)
            {
                Caption = 'Adjustment';
                field("Document Type"; DocumentType)
                {
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the document type applied to all created adjustment entries.';
                    Editable = false;
                }
                field("Document No."; DocumentNo)
                {
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number applied to all created adjustment entries.';
                }
            }
            group("Production Order")
            {
                Caption = 'Production Order';
                Visible = LineCount = 1;
                field("Prod. Order Status"; Rec."Prod. Order Status")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Prod. Order Line No."; Rec."Prod. Order Line No.")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    Editable = false;
                }
                field("Routing Reference No."; Rec."Routing Reference No.")
                {
                    Editable = false;
                }
                field("Operation No."; Rec."Operation No.")
                {
                    Editable = false;
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    Editable = false;
                }
            }
            group(General)
            {
                Caption = 'General';
                Visible = LineCount = 1;
                field("Location Code"; Rec."Location Code")
                {
                    Editable = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    Editable = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Editable = false;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                }
                field("Description 2"; Rec."Description 2")
                {
                    Visible = false;
                }
                field("Current Quantity (Base)"; Rec."Quantity (Base)")
                {
                    Caption = 'Current Quantity (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the current WIP quantity base for this operation and location.';
                }
                field("New Quantity (Base)"; NewQuantityBase)
                {
                    AutoFormatType = 0;
                    Caption = 'New Quantity (Base)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the new target WIP quantity base after adjustment.';

                    trigger OnValidate()
                    begin
                        NewQuantities.Set(Rec."Entry No.", NewQuantityBase);
                        UpdateQuantityStyle();
                    end;
                }
                field("Quantity to Adjust (Base)"; QuantityToAdjustBase)
                {
                    AutoFormatType = 0;
                    Caption = 'Quantity to Adjust (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    StyleExpr = QuantityStyle;
                    ToolTip = 'Specifies the quantity that will be adjusted (New Quantity (Base) minus Current Quantity (Base)).';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    Editable = false;
                    Caption = 'Base Unit of Measure';
                }
            }
            repeater(Lines)
            {
                Caption = 'Lines';
                Visible = LineCount > 1;
                field("Prod. Order Status Line"; Rec."Prod. Order Status")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Prod. Order No. Line"; Rec."Prod. Order No.")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Prod. Order Line No. Line"; Rec."Prod. Order Line No.")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Routing No. Line"; Rec."Routing No.")
                {
                    Editable = false;
                }
                field("Routing Reference No. Line"; Rec."Routing Reference No.")
                {
                    Editable = false;
                }
                field("Operation No. Line"; Rec."Operation No.")
                {
                    Editable = false;
                }
                field("Work Center No. Line"; Rec."Work Center No.")
                {
                    Editable = false;
                }
                field("Item No. Line"; Rec."Item No.")
                {
                    Editable = false;
                }
                field("Variant Code Line"; Rec."Variant Code")
                {
                    Editable = false;
                    Visible = false;
                }
                field(DescriptionLine; Rec.Description)
                {
                }
                field("Description 2 Line"; Rec."Description 2")
                {
                    Visible = false;
                }
                field("Location Code Line"; Rec."Location Code")
                {
                    Caption = 'Location Code';
                    Editable = false;
                }
                field("Current Quantity Line"; Rec."Quantity (Base)")
                {
                    Caption = 'Current Quantity (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                }
                field("New Quantity Line"; NewQuantityBase)
                {
                    AutoFormatType = 0;
                    Caption = 'New Quantity (Base)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the new target WIP quantity after adjustment.';

                    trigger OnValidate()
                    begin
                        NewQuantities.Set(Rec."Entry No.", NewQuantityBase);
                        UpdateQuantityStyle();
                    end;
                }
                field("Quantity to Adjust Line"; QuantityToAdjustBase)
                {
                    AutoFormatType = 0;
                    Caption = 'Qty. to Adjust (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    StyleExpr = QuantityStyle;
                    ToolTip = 'Specifies the quantity that will be adjusted (New Quantity minus Current Quantity).';
                }
                field("Unit of Measure Code Line"; Rec."Unit of Measure Code")
                {
                    Caption = 'Base Unit of Measure';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NewQuantities.Get(Rec."Entry No.", NewQuantityBase);
        UpdateQuantityStyle();
    end;

    trigger OnOpenPage()
    begin
        PostingDate := WorkDate();
        DocumentType := DocumentType::"Adjustment (Manual)";

        if not Rec.FindFirst() then
            Error(NothingToAdjustErr);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            CreateAdjustmentEntries();
        exit(true);
    end;

    var
        Item: Record Item;
        NewQuantities: Dictionary of [BigInteger, Decimal];
        PostingDate: Date;
        DocumentType: Enum "WIP Document Type";
        DocumentNo: Code[20];
        NewQuantityBase: Decimal;
        QuantityToAdjustBase: Decimal;
        QuantityStyle: Text;
        LineCount: Integer;
        CaptionLbl: Label 'Production Order %1 %2', Comment = '%1=Prod. Order Status,%2=Prod. Order Number';
        NothingToAdjustErr: Label 'There are no WIP quantities to adjust, because there are no existing ledger entries for the specified source.';

    /// <summary>
    /// Populates the page source table with one row per (Routing Reference No., Operation No., Location Code)
    /// combination, aggregating the current WIP quantity from the supplied ledger entries.
    /// Must be called before running the page.
    /// </summary>
    procedure SetWIPLedgerEntry(var WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry")
    var
        EntrySeq: BigInteger;
    begin
        EntrySeq := 1;

        if not Rec.IsEmpty() then
            Rec.DeleteAll();

        if not WIPLedgerEntry.FindSet() then
            Error(NothingToAdjustErr);

        repeat
            Rec.SetRange("Prod. Order Status", WIPLedgerEntry."Prod. Order Status");
            Rec.SetRange("Prod. Order No.", WIPLedgerEntry."Prod. Order No.");
            Rec.SetRange("Prod. Order Line No.", WIPLedgerEntry."Prod. Order Line No.");
            Rec.SetRange("Routing Reference No.", WIPLedgerEntry."Routing Reference No.");
            Rec.SetRange("Routing No.", WIPLedgerEntry."Routing No.");
            Rec.SetRange("Operation No.", WIPLedgerEntry."Operation No.");
            Rec.SetRange("Location Code", WIPLedgerEntry."Location Code");
            if Rec.FindFirst() then begin
                Rec."Quantity (Base)" += WIPLedgerEntry."Quantity (Base)";
                Rec.Modify();
                NewQuantities.Set(Rec."Entry No.", Rec."Quantity (Base)");
            end else begin
                Rec.Init();
                Rec.TransferFields(WIPLedgerEntry);
                Rec."Entry No." := EntrySeq;
                Rec."Document Line No." := 0;
                Rec."In Transit" := WIPLedgerEntry."In Transit";
                Rec."Quantity (Base)" := WIPLedgerEntry."Quantity (Base)";
                Rec."Unit of Measure Code" := GetItemBaseUnitOfMeasure(WIPLedgerEntry."Item No.");
                Rec.Insert();
                NewQuantities.Add(Rec."Entry No.", Rec."Quantity (Base)");
                EntrySeq += 1;
            end;
        until WIPLedgerEntry.Next() = 0;

        LineCount := Rec.Count();
        if Rec.FindFirst() then;
    end;

    procedure SetDocumentNo(DocNo: Code[20])
    begin
        DocumentNo := DocNo;
    end;

    local procedure CreateAdjustmentEntries()
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TempWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry" temporary;
        AdjEntryType: Enum "WIP Ledger Entry Type";
        TargetQty: Decimal;
    begin
        TempWIPLedgerEntry.Copy(Rec, true);

        TempWIPLedgerEntry.FindSet();

        repeat
            NewQuantities.Get(TempWIPLedgerEntry."Entry No.", TargetQty);
            if TargetQty <> TempWIPLedgerEntry."Quantity (Base)" then begin
                WIPLedgerEntry.Init();
                WIPLedgerEntry.TransferFields(TempWIPLedgerEntry);
                WIPLedgerEntry."Entry No." := WIPLedgerEntry.GetNextEntryNo();
                WIPLedgerEntry."Posting Date" := PostingDate;
                WIPLedgerEntry."Document Type" := DocumentType;
                WIPLedgerEntry."Document No." := DocumentNo;

                WIPLedgerEntry."Quantity (Base)" := TargetQty - TempWIPLedgerEntry."Quantity (Base)";
                if WIPLedgerEntry."Quantity (Base)" >= 0 then
                    WIPLedgerEntry."Entry Type" := AdjEntryType::"Positive Adjustment"
                else
                    WIPLedgerEntry."Entry Type" := AdjEntryType::"Negative Adjustment";
                WIPLedgerEntry.Insert(true);
            end;
        until TempWIPLedgerEntry.Next() = 0;
    end;

    local procedure UpdateQuantityStyle()
    begin
        QuantityToAdjustBase := NewQuantityBase - Rec."Quantity (Base)";
        if QuantityToAdjustBase >= 0 then
            QuantityStyle := Format(PageStyle::Strong)
        else
            QuantityStyle := Format(PageStyle::Unfavorable);
    end;

    local procedure CreatePageCaption(): Text
    begin
        exit(StrSubstNo(CaptionLbl, Rec."Prod. Order Status", Rec."Prod. Order No."));
    end;

    local procedure GetItemBaseUnitOfMeasure(ItemNo: Code[20]): Code[10]
    begin
        Item.SetLoadFields("Base Unit of Measure");
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
        exit(Item."Base Unit of Measure");
    end;
}