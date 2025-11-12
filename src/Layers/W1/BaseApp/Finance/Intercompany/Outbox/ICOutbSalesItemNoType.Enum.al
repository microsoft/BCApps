// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

enum 438 "IC Outb. Sales Item No. Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Internal No.") { Caption = 'Order'; }
    value(1; "Common Item No.") { Caption = 'Common Item No.'; }
    value(2; "Cross Reference") { Caption = 'Item Reference'; }
}
