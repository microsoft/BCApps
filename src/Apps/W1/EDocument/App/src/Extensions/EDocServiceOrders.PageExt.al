// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.eServices.EDocument;

pageextension 6122 "E-Doc. Service Orders" extends "Service Orders"
{
    layout
    {
        addlast(Control1)
        {
            field(EDocumentStatus; EDocumentStatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Status';
                ToolTip = 'Specifies the status of the latest electronic document linked to this record. Hidden by default; add it via Personalize to make it visible.';
                Visible = false;
                Editable = false;
            }
        }
    }

    trigger OnOpenPage()
    var
        EDocument: Record "E-Document";
    begin
        HasAnyEDocument := GuiAllowed() and EDocument.HasEDocument();
    end;

    trigger OnAfterGetRecord()
    var
        EDocumentLookup: Record "E-Document";
    begin
        EDocumentStatusText := '';
        if HasAnyEDocument then
            EDocumentStatusText := EDocumentLookup.GetLatestStatus(Rec.RecordId());
    end;

    var
        HasAnyEDocument: Boolean;
        EDocumentStatusText: Text;
}
