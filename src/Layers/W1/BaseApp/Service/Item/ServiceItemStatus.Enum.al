// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

enum 5940 "Service Item Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Own Service Item") { Caption = 'Own Service Item'; }
    value(2; Installed) { Caption = 'Installed'; }
    value(3; "Temporarily Installed") { Caption = 'Temporarily Installed'; }
    value(4; "Defective") { Caption = 'Defective'; }

}
