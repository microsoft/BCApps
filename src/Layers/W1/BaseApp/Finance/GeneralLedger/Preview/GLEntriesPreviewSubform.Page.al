// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Security.User;

page 1571 "G/L Entries Preview Subform"
{
    PageType = ListPart;
    Editable = false;
    SourceTable = "G/L Entry Posting Preview";
    SourceTableTemporary = true;
    Caption = 'G/L Entries';

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
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field("G/L Account Name"; Rec."G/L Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the account that the entry has been posted to.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry or record.';
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Document Type that the entry belongs to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s Document No.';
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Amount of the entry.';
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger entry that is posted if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been part of a reverse transaction (correction) made by the Reverse function.';
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the correcting entry. If the field Specifies a number, the entry cannot be reversed again.';
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
                    Visible = false;
                }
                field("FA Entry Type"; Rec."FA Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the fixed asset entry.';
                    Visible = false;
                }
                field("FA Entry No."; Rec."FA Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the fixed asset entry.';
                    Visible = false;
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim2Visible;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim8Visible;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                Enabled = ShowDimensionEnabled;

                trigger OnAction()
                begin
                    GenJnlPostPreview.ShowDimensions(DATABASE::"G/L Entry", Rec."G/L Entry No.", Rec."Dimension Set ID");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        Emphasize := Rec.Indentation = 0;
        ShowDimensionEnabled := Rec."G/L Entry No." <> 0;

        if Rec."G/L Entry No." <> 0 then
            TempGLEntry.Get(Rec."G/L Entry No.")
        else begin
            TempGLEntry.Init();
            TempGLEntry."G/L Account No." := Rec."G/L Account No.";
            TempGLEntry.Description := Rec.Description;
            TempGLEntry.Amount := Rec.Amount;
        end;
    end;

    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ShowDimensionEnabled: Boolean;

    protected var
        TempGLEntry: Record "G/L Entry" temporary;
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;
        Emphasize: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

    procedure Set(PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    var
        TempGLEntryPostingPreview: Record "G/L Entry Posting Preview" temporary;
        RecRef: RecordRef;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        TempGLEntryPostingPreview.Reset();
        TempGLEntryPostingPreview.DeleteAll();
        TempGLEntry.Reset();
        TempGLEntry.DeleteAll();

        PostingPreviewEventHandler.GetEntries(Database::"G/L Entry", RecRef);

        LoadBufferAsHierarchicalView(RecRef, TempGLEntryPostingPreview);

        Rec.Copy(TempGLEntryPostingPreview, true);
    end;

    local procedure LoadBufferAsHierarchicalView(var RecRef: RecordRef; var TempGLEntryPostingPreview: Record "G/L Entry Posting Preview" temporary)
    var
        GLAccount: Record "G/L Account";
        TempGLAccount: Record "G/L Account" temporary;
        EntryNo: Integer;
    begin
        if RecRef.FindSet() then
            repeat
                RecRef.SetTable(TempGLEntry);
                TempGLEntry.Insert();

                if not TempGLAccount.Get(TempGLEntry."G/L Account No.") then begin
                    GLAccount.Get(TempGLEntry."G/L Account No.");
                    TempGLAccount."No." := TempGLEntry."G/L Account No.";
                    TempGLAccount.Name := GLAccount.Name;
                    TempGLAccount.Insert();
                end;
            until RecRef.Next() = 0;

        EntryNo := 1;
        if TempGLAccount.FindSet() then
            repeat
                TempGLEntry.SetRange("G/L Account No.", TempGLAccount."No.");
                TempGLEntry.CalcSums(Amount);
                TempGLEntryPostingPreview.Init();
                TempGLEntryPostingPreview."Entry No." := EntryNo;
                TempGLEntryPostingPreview."G/L Account No." := TempGLAccount."No.";
                TempGLEntryPostingPreview.Description := TempGLAccount.Name;
                TempGLEntryPostingPreview.Amount := TempGLEntry.Amount;
                TempGLEntryPostingPreview.Indentation := 0;
                OnLoadBufferAsHierarchicalViewOnBeforeInsertGroupEntry(TempGLEntryPostingPreview, TempGLEntry);
                TempGLEntryPostingPreview.Insert();
                EntryNo += 1;

                if TempGLEntry.FindSet() then
                    repeat
                        TempGLEntryPostingPreview.Init();
                        TempGLEntryPostingPreview.TransferFields(TempGLEntry);
                        TempGLEntryPostingPreview."G/L Entry No." := TempGLEntry."Entry No.";
                        TempGLEntryPostingPreview."Entry No." := EntryNo;
                        TempGLEntryPostingPreview.Indentation := 1;
                        OnLoadBufferAsHierarchicalViewOnBeforeInsertEntry(TempGLEntryPostingPreview, TempGLEntry);
                        TempGLEntryPostingPreview.Insert();
                        EntryNo += 1;
                    until TempGLEntry.Next() = 0;
            until TempGLAccount.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadBufferAsHierarchicalViewOnBeforeInsertGroupEntry(var TempGLEntryPostingPreview: Record "G/L Entry Posting Preview" temporary; var TempGLEntry: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadBufferAsHierarchicalViewOnBeforeInsertEntry(var TempGLEntryPostingPreview: Record "G/L Entry Posting Preview" temporary; var TempGLEntry: Record "G/L Entry" temporary)
    begin
    end;
}
