// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

#pragma warning disable AL0659
enum 7158 "Sales Analysis Matrix Dimensions"
#pragma warning restore AL0659
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Period") { Caption = 'Period'; }
    value(2; "Location") { Caption = 'Location'; }
    value(3; "Dimension 1") { Caption = 'Dimension 1'; }
    value(4; "Dimension 2") { Caption = 'Dimension 2'; }
    value(5; "Dimension 3") { Caption = 'Dimension 3'; }
    value(99; "Undefined") { Caption = 'Undefined'; }
}
