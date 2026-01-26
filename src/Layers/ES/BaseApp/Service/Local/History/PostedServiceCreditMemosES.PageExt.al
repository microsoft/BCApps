// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;

pageextension 10731 "Posted Service Credit Memos ES" extends "Posted Service Credit Memos"
{
    layout
    {
        addafter("Posting Date")
        {
            field("SII Status"; Rec."SII Status")
            {
                ApplicationArea = Basic, Suite;
                StyleExpr = StyleText;
                ToolTip = 'Specifies the document''s status with regard to tax declaration, the Immediate Information Supply requirement. ';
                Visible = SIIStateVisible;

                trigger OnDrillDown()
                var
                    SIIDocUploadState: Record "SII Doc. Upload State";
                    SIIManagement: Codeunit "SII Management";
                begin
                    SIIDocUploadState.SetRange("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
                    SIIDocUploadState.SetRange("Document Type", SIIDocUploadState."Document Type"::Invoice);
                    SIIDocUploadState.SetRange("Document No.", Rec."No.");
                    SIIManagement.SIIStateDrilldown(SIIDocUploadState);
                end;
            }
            field("Do Not Send To SII"; Rec."Do Not Send To SII")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the document must not be sent to SII.';
            }
            field("Sent to SII"; Rec."Sent to SII")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies that the document has been sent to the Immediate Information Supply system.';
                Visible = SIIStateVisible;
            }
        }
    }
    actions
    {
        addafter(ActivityLog)
        {
            action("Update Document")
            {
                ApplicationArea = Service;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedServCrMemoUpdate: Page "Posted Serv. Cr. Memo - Update";
                begin
                    PostedServCrMemoUpdate.LookupMode := true;
                    PostedServCrMemoUpdate.SetRec(Rec);
                    PostedServCrMemoUpdate.RunModal();
                end;
            }
        }
        addbefore(Category_CategoryPrint)
        {
            actionref("Update Document_Promoted"; "Update Document")
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleText := SIIManagement.GetSIIStyle(Rec."SII Status".AsInteger());
    end;

    trigger OnOpenPage()
    begin
        SIIStateVisible := SIISetup.IsEnabled();
    end;

    var
        SIISetup: Record "SII Setup";
        SIIManagement: Codeunit "SII Management";
        StyleText: Text;
        SIIStateVisible: Boolean;
}