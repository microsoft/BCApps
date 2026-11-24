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
        field(6901; "No Receipt Declaration"; Boolean)
        {
            Access = Internal;
            Caption = 'No Receipt Declaration';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6902; "System Generated"; Boolean)
        {
            Access = Internal;
            Caption = 'System Generated';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        // Fingerprint of the card receipt data that attached this receipt to a corporate card expense. A receipt with a
        // fingerprint is locked: it cannot be deleted or replaced, and only an identical retry is accepted.
        field(6903; "Card Receipt Data Hash"; Text[64])
        {
            Access = Internal;
            Caption = 'Card Receipt Data Hash';
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
