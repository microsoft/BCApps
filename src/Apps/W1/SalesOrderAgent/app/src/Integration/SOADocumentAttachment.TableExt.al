// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.Foundation.Attachment;

tableextension 4590 "SOA Document Attachment" extends "Document Attachment"
{
    fields
    {
        field(4590; "SOA Task Attachment ID"; Guid)
        {
            Caption = 'SOA Task Attachment ID', Locked = true;
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(SOATaskAttachment; "SOA Task Attachment ID")
        {
        }
    }
}
