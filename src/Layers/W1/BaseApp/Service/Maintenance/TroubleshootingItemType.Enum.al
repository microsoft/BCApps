// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

enum 5946 "Troubleshooting Item Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Service Item Group") { Caption = 'Service Item Group'; }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Service Item") { Caption = 'Service Item'; }
}
