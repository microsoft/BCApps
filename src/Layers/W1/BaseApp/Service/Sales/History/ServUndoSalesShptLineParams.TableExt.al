// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

tableextension 5825 "Serv. UndoSalesShptLineParams" extends "Undo Sales Shpt. Line Params"
{
    fields
    {
        field(5900; "Delete Service Items"; Boolean)
        {
            Caption = 'Delete Service Items';
            DataClassification = SystemMetadata;
        }
    }
}
