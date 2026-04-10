// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

#pragma warning disable AL0659
enum 5943 "Replaced Service Item Component Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Service Item") { Caption = 'Service Item'; }
    value(2; "Item") { Caption = 'Item'; }
}
