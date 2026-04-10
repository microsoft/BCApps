// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Integration.Graph;

enumextension 5052 "Project Att.Ent.Buf.Doc.Type" extends "Attachment Entity Buffer Document Type"
{
    value(10; "Job") { Caption = 'Project'; Implementation = IPdfDocumentHandler = "Project PDF Doc.Handler"; }
}
