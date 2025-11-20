// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Navigate;

page 1570 "Extended G/L Posting Preview"
{
    PageType = Card;
    Caption = 'Posting Preview';
    SaveValues = true;
    DataCaptionExpression = PostingPreviewTxt;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(ShowHierarchicalViewControl; ShowHierarchicalView)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Hierarchical View';
                    ToolTip = 'Specifies how to arrange G/L entries and VAT entries in the posting preview. Turn off the toggle to display entries in a list. Turn it on to group G/L entries by their G/L account number in ascending order, and VAT entries by their VAT business posting group and VAT product posting group.';

                    trigger OnValidate()
                    begin
                        UpdateGLAndVATEntries();
                        CurrPage.Update();
                    end;
                }
            }
            part(GLEntriesPreviewFlat; "G/L Entries Preview Flat Subf.")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                Visible = not ShowHierarchicalView;
            }
            part(GLEntriesPreviewHierarchical; "G/L Entries Preview Subform")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                Visible = ShowHierarchicalView;
            }
            part(VATEntriesPreviewFlat; "VAT Entries Preview Flat Subf.")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                Visible = not ShowHierarchicalView;
            }
            part(VATEntriesPreviewHierarchical; "VAT Entries Preview Subform")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                Visible = ShowHierarchicalView;
            }
            part(DocEntriesPreviewSubform; "Doc. Entries Preview Subform")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if not PostingPreviewEventHandler.IsTransactionConsistent() then
            SendInconsistencyNotification();
        UpdateGLAndVATEntries();
        CurrPage.DocEntriesPreviewSubform.Page.Set(TempDocumentEntry, PostingPreviewEventHandler);
    end;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        InconsistenceTxt: Label 'The transaction will cause G/L entries to be inconsistent. Typical causes for this are mismatched amounts, including amounts in additional currencies, and posting dates.';
        PostingPreviewTxt: Label 'Posting Preview';

    protected var
        ShowHierarchicalView: Boolean;

    local procedure SendInconsistencyNotification()
    var
        InconsistencyNotification: Notification;
    begin
        InconsistencyNotification.Message := InconsistenceTxt;
        InconsistencyNotification.Send();
    end;

    procedure Set(var NewTempDocumentEntry: Record "Document Entry" temporary; NewPostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
        PostingPreviewEventHandler := NewPostingPreviewEventHandler;
        TempDocumentEntry.Copy(NewTempDocumentEntry, true);
    end;

    local procedure UpdateGLAndVATEntries()
    begin
        if ShowHierarchicalView then begin
            CurrPage.GLEntriesPreviewHierarchical.Page.Set(PostingPreviewEventHandler);
            CurrPage.VATEntriesPreviewHierarchical.Page.Set(PostingPreviewEventHandler);
        end else begin
            CurrPage.GLEntriesPreviewFlat.Page.Set(PostingPreviewEventHandler);
            CurrPage.VATEntriesPreviewFlat.Page.Set(PostingPreviewEventHandler);
        end;
    end;
}
