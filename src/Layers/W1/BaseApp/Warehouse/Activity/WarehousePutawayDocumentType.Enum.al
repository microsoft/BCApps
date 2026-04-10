// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

#pragma warning disable AL0659
enum 7352 "Warehouse Putaway Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Receipt") { Caption = 'Receipt'; }
    value(3; "Internal Put-away") { Caption = 'Internal Put-away'; }
    value(5; "Production") { Caption = 'Production'; }
}
