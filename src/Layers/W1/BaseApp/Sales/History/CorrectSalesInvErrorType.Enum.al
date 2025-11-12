// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

enum 1303 "Correct Sales Inv. Error Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "IsPaid") { }
    value(1; "CustomerBlocked") { }
    value(2; "ItemBlocked") { }
    value(3; "AccountBlocked") { }
    value(4; "IsCorrected") { }
    value(5; "IsCorrective") { }
    value(6; "SerieNumInv") { }
    value(7; "SerieNumCM") { }
    value(8; "SerieNumPostCM") { }
    value(9; "ItemIsReturned") { }
    value(10; "FromOrder") { }
    value(11; "PostingNotAllowed") { }
    value(12; "LineFromOrder") { }
    value(13; "WrongItemType") { }
    value(14; "LineFromJob") { }
    value(15; "DimErr") { }
    value(16; "DimCombErr") { }
    value(17; "DimCombHeaderErr") { }
    value(18; "ExtDocErr") { }
    value(19; "InventoryPostClosed") { }
    value(20; "ItemVariantBlocked") { }
}
