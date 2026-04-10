// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.EServices.EDocument;


#pragma warning disable AL0659
enum 135 "Attachment Entity Buffer Document Type" implements IPdfDocumentHandler
#pragma warning restore AL0659
{
    Extensible = true;
    DefaultImplementation = IPdfDocumentHandler = "Default PDF Doc.Handler";

    value(0; " ") { Caption = ' '; }
    value(1; "Journal") { Caption = 'Journal'; }
    value(9; "Employee") { Caption = 'Employee'; }
    value(11; "Item") { Caption = 'Item'; }
    value(12; "Customer") { Caption = 'Customer'; }
    value(13; "Vendor") { Caption = 'Vendor'; }
}
