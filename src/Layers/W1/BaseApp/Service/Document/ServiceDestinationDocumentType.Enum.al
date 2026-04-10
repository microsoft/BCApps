// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

#pragma warning disable AL0659
enum 5937 "Service Destination Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Invoice") { Caption = 'Invoice'; }
    value(1; "Credit Memo") { Caption = 'Credit Memo'; }
    value(2; "Posted Invoice") { Caption = 'Posted Invoice'; }
    value(3; "Posted Credit Memo") { Caption = 'Posted Credit Memo'; }
}
