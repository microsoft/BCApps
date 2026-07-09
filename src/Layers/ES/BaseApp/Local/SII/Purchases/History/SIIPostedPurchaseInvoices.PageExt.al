// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.EServices.EDocument;


pageextension 7000143 "SII Posted Purchase Invoices" extends "Posted Purchase Invoices"
{
    layout
    {
        addafter("No. Printed")
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
                    SIIDocUploadState.SetRange("Document Source", SIIDocUploadState."Document Source"::"Vendor Ledger");
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
    var
        SIIManagement: Codeunit "SII Management";
    begin
        StyleText := SIIManagement.GetSIIStyle(Rec."SII Status".AsInteger());
    end;

    trigger OnOpenPage()
    var
        SIISetup: Record "SII Setup";
    begin
        SIIStateVisible := SIISetup.IsEnabled();
    end;

    var
        StyleText: Text;
        SIIStateVisible: Boolean;
}