// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

enum 138 "Attachment Entity Buffer Type"
{
    Extensible = false;

    value(0; "Incoming Document") { Caption = 'Incoming Document'; }
    value(1; "Document Attachment") { Caption = 'Document Attachment'; }
}