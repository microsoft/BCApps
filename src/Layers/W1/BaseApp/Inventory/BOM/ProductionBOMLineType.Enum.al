// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

enum 99000772 "Production BOM Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Production BOM") { Caption = 'Production BOM'; }
}
