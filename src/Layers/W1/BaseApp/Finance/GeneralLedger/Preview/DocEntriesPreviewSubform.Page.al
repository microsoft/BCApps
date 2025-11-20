// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Navigate;

page 1573 "Doc. Entries Preview Subform"
{
    PageType = ListPart;
    SourceTable = "Document Entry";
    SourceTableTemporary = true;
    Editable = false;
    Caption = 'Related Entries';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Related Entries';
                    ToolTip = 'Specifies the name of the table where the Navigate facility has found entries with the selected document number and/or posting date.';
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Entries';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of documents that the Navigate facility has found in the table with the selected entries.';

                    trigger OnDrillDown()
                    begin
                        PostingPreviewEventHandler.ShowEntries(Rec."Table ID");
                    end;
                }
            }
        }
    }

    var
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";

    procedure Set(var TempDocumentEntry: Record "Document Entry" temporary; NewPostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
        PostingPreviewEventHandler := NewPostingPreviewEventHandler;
        TempDocumentEntry.SetFilter("Table ID", '<>%1&<>%2', Database::"G/L Entry", Database::"VAT Entry");
        if TempDocumentEntry.FindSet() then
            repeat
                Rec := TempDocumentEntry;
                Rec.Insert();
            until TempDocumentEntry.Next() = 0;
    end;
}
