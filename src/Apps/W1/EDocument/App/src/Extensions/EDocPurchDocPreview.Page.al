// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Purchases.Document;
using System.Utilities;

/// <summary>
/// Factbox that previews the inbound PDF for an open purchase document (Purchase Header).
/// Sourced on the host table and driven by SubPageLink so the preview refreshes reliably as the
/// selected document changes (including on list pages).
/// </summary>
page 6117 "E-Doc. Purch. Doc. Preview"
{
    PageType = CardPart;
    SourceTable = "Purchase Header";
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
                ToolTip = 'Specifies a preview of the PDF that this purchase document was created from.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EDocumentHelper.RenderInboundPdfPreview(Rec.RecordId(), Rec."E-Document Link", TempMediaRepository);
    end;

    var
        TempMediaRepository: Record "Media Repository" temporary;
        EDocumentHelper: Codeunit "E-Document Helper";
}
