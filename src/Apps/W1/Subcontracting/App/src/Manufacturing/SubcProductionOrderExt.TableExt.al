// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

tableextension 99001505 "Subc. Production Order Ext." extends "Production Order"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001552; "Created from Purch. Order"; Boolean)
        {
            Caption = 'Created from Purchase Order';
            DataClassification = CustomerContent;
            Description = 'For internal use only';
        }
    }
}