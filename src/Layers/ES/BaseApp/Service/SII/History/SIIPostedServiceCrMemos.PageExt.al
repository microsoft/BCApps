// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Service.History;

#pragma warning disable AS0088
pageextension 7000086 "SII Posted Service Cr. Memos" extends "Posted Service Credit Memos"
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
