// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Import;

pageextension 11036 "E-Doc. Readable Purch. Doc. DE" extends "E-Doc. Readable Purchase Doc."
{
    layout
    {
        addafter("Purchase Order No.")
        {
            field("Buyer Reference DE"; Rec."Buyer Reference DE")
            {
                Caption = 'Buyer Reference';
                ToolTip = 'Specifies the buyer reference that the vendor stated on the document, such as the Leitweg-ID.';
            }
        }
    }
}
