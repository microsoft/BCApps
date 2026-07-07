// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Purchases.History;
using System.Utilities;

/// <summary>
/// Factbox that previews the inbound PDF for a posted purchase invoice (Purch. Inv. Header).
/// Sourced on the host table and driven by SubPageLink so the preview refreshes reliably as the
/// selected document changes (including on list pages).
/// </summary>
page 6131 "E-Doc. Posted Purch. Preview"
{
    PageType = CardPart;
    SourceTable = "Purch. Inv. Header";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;

    layout
    {
        area(content)
        {
            field(Picture; TempMediaRepository.Image)
            {
                ApplicationArea = Basic, Suite;
                ShowCaption = false;
                ExtendedDatatype = Document;
                ToolTip = 'Specifies a preview of the PDF that this purchase invoice was created from.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EDocumentHelper.RenderInboundPdfPreview(Rec.RecordId(), TempMediaRepository);
    end;

    var
        TempMediaRepository: Record "Media Repository" temporary;
        EDocumentHelper: Codeunit "E-Document Helper";
}
