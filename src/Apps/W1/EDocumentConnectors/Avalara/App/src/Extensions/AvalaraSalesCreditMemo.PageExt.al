// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.Sales.Document;

/// <summary>
/// Extends the Sales Credit Memo page to display the Avalara Document ID field when an Avalara service is active.
/// </summary>
pageextension 6380 "Avalara Sales Credit Memo" extends "Sales Credit Memo"
{
    layout
    {
        addafter("Applies-to ID")
        {
            field("Avalara Doc. ID"; Rec."Avalara Doc. ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Avalara Doc. ID field.';
                Visible = AvalaraDocIdVisible;
            }
        }
    }

    trigger OnOpenPage()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        AvalaraDocIdVisible := AvalaraFunctions.IsAvalaraActive();
    end;

    var
        AvalaraDocIdVisible: Boolean;
}
