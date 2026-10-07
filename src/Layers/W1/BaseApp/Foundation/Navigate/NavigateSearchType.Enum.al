// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

enum 345 "Navigate Search Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Document") { Caption = 'Search for documents'; }
    value(1; "Business Contact") { Caption = 'Search for business contacts'; }
    value(2; "Item Reference") { Caption = 'Search for item references'; }
}
