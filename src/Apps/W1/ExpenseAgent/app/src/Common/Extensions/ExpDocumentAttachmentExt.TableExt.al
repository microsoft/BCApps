// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;

tableextension 6902 "Exp. Document Attachment Ext" extends "Document Attachment"
{
    fields
    {
        field(6900; "Content Hash"; Text[64])
        {
            Caption = 'Content Hash';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
    keys
    {
        key(ContentHashKey; "Content Hash")
        {
        }
    }
}
