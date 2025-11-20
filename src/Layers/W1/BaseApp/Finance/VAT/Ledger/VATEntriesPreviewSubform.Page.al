// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.VAT.Setup;

page 1572 "VAT Entries Preview Subform"
{
    PageType = ListPart;
    SourceTable = "VAT Entry Posting Preview";
    SourceTableTemporary = true;
    Editable = false;
    Caption = 'VAT Entries';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Indentation;
                ShowCaption = false;
                TreeInitialState = CollapseAll;
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = Emphasize;
                    Style = Strong;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = Emphasize;
                    Style = Strong;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = Emphasize;
                    Style = Strong;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = Emphasize;
                    Style = Strong;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Additional-Currency Base"; Rec."Additional-Currency Base")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Add.-Curr. VAT Difference"; Rec."Add.-Curr. VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Ship-to/Order Address Code"; Rec."Ship-to/Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Suite;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Closed by Entry No."; Rec."Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Internal Ref. No."; Rec."Internal Ref. No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Emphasize := Rec.Indentation = 0;
    end;

    protected var
        Emphasize: Boolean;

    procedure Set(PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    var
        TempVATEntryPostingPreview: Record "VAT Entry Posting Preview" temporary;
        RecRef: RecordRef;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        TempVATEntryPostingPreview.Reset();
        TempVATEntryPostingPreview.DeleteAll();

        PostingPreviewEventHandler.GetEntries(Database::"VAT Entry", RecRef);

        LoadBufferAsHierarchicalView(RecRef, TempVATEntryPostingPreview);

        Rec.Copy(TempVATEntryPostingPreview, true);
    end;

    local procedure LoadBufferAsHierarchicalView(var RecRef: RecordRef; var TempVATEntryPostingPreview: Record "VAT Entry Posting Preview" temporary)
    var
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        EntryNo: Integer;
    begin
        if RecRef.FindSet() then
            repeat
                RecRef.SetTable(TempVATEntry);
                TempVATEntry.Insert();

                if not TempVATPostingSetup.Get(TempVATEntry."VAT Bus. Posting Group", TempVATEntry."VAT Prod. Posting Group") then begin
                    TempVATPostingSetup."VAT Bus. Posting Group" := TempVATEntry."VAT Bus. Posting Group";
                    TempVATPostingSetup."VAT Prod. Posting Group" := TempVATEntry."VAT Prod. Posting Group";
                    TempVATPostingSetup.Insert();
                end;
            until RecRef.Next() = 0;

        EntryNo := 1;
        if TempVATPostingSetup.FindSet() then
            repeat
                TempVATEntry.SetRange("VAT Bus. Posting Group", TempVATPostingSetup."VAT Bus. Posting Group");
                TempVATEntry.SetRange("VAT Prod. Posting Group", TempVATPostingSetup."VAT Prod. Posting Group");
                TempVATEntry.CalcSums(Base, Amount);
                TempVATEntryPostingPreview.Init();
                TempVATEntryPostingPreview."Entry No." := EntryNo;
                TempVATEntryPostingPreview."VAT Bus. Posting Group" := TempVATPostingSetup."VAT Bus. Posting Group";
                TempVATEntryPostingPreview."VAT Prod. Posting Group" := TempVATPostingSetup."VAT Prod. Posting Group";
                TempVATEntryPostingPreview.Base := TempVATEntry.Base;
                TempVATEntryPostingPreview.Amount := TempVATEntry.Amount;
                TempVATEntryPostingPreview.Indentation := 0;
                OnLoadBufferAsHierarchicalViewOnBeforeInsertGroupEntry(TempVATEntryPostingPreview, TempVATEntry);
                TempVATEntryPostingPreview.Insert();
                EntryNo += 1;

                if TempVATEntry.FindSet() then
                    repeat
                        TempVATEntryPostingPreview.Init();
                        TempVATEntryPostingPreview.TransferFields(TempVATEntry);
                        TempVATEntryPostingPreview."VAT Entry No." := TempVATEntry."Entry No.";
                        TempVATEntryPostingPreview."Entry No." := EntryNo;
                        TempVATEntryPostingPreview.Indentation := 1;
                        OnLoadBufferAsHierarchicalViewOnBeforeInsertEntry(TempVATEntryPostingPreview, TempVATEntry);
                        TempVATEntryPostingPreview.Insert();
                        EntryNo += 1;
                    until TempVATEntry.Next() = 0;
            until TempVATPostingSetup.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadBufferAsHierarchicalViewOnBeforeInsertGroupEntry(var TempVATEntryPostingPreview: Record "VAT Entry Posting Preview" temporary; var TempVATEntry: Record "VAT Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadBufferAsHierarchicalViewOnBeforeInsertEntry(var TempVATEntryPostingPreview: Record "VAT Entry Posting Preview" temporary; var TempVATEntry: Record "VAT Entry" temporary)
    begin
    end;
}
