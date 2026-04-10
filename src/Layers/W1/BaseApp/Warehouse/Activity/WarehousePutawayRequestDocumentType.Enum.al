// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

#pragma warning disable AL0659
enum 7324 "Warehouse Put-away Request Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Receipt") { Caption = 'Receipt'; }
    value(1; "Internal Put-away") { Caption = 'Internal Put-away'; }
}
