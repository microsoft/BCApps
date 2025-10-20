// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.eServices.EDocument;
using Microsoft.EServices.EDocument.Processing.Import.Purchase;

pageextension 6153 "E-Doc. Info" extends "Inbound E-Documents"
{
    actions
    {
        addafter(DownloadFile)
        {
            group("E-Document")
            {
                action(EDocPurchaseLineHistory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'EDocPurchaseLineHistory';
                    Tooltip = 'EDocPurchaseLineHistory';
                    RunObject = page "E-Doc. Purchase Line History";
                    Image = History;
                    RunPageLink = "Entry No." = field("Entry No");
                }
            }
        }
    }
}
