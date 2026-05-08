// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.Sales.History;

/// <summary>
/// Extends the Posted Sales Credit Memo page to display the Avalara Document ID when available.
/// </summary>
pageextension 6377 "Avalara Posted Sales Cr.Memo" extends "Posted Sales Credit Memo"
{
    layout
    {
        addafter("Applies-to Doc. No.")
        {
            field("Avalara Doc. ID"; Rec."Avalara Doc. ID")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the value of the Avalara Doc. ID field.';
                Visible = AvalaraDocIdVisible;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        AvalaraDocIdVisible := Rec."Avalara Doc. ID" <> '';
    end;

    var
        AvalaraDocIdVisible: Boolean;
}
