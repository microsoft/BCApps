// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

tableextension 6172 "E-Doc. Sales Header" extends "Sales Header"
{
    fields
    {
        field(6102; "E-Document Link"; Guid)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
    keys
    {
        key(EDocKey1; "E-Document Link")
        {
        }
    }
}
