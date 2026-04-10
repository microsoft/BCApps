// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

enum 5938 "Service Source Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Order") { Caption = 'Order'; }
    value(1; "Contract") { Caption = 'Contract'; }
}
