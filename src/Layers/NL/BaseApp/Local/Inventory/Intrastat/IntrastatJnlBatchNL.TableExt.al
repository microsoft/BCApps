#if not CLEANSCHEMA25
#pragma warning disable AL0520
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

tableextension 11409 "Intrastat Jnl. Batch NL" extends "Intrastat Jnl. Batch"
{
    fields
    {
        field(11400; "Export Date"; Date)
        {
            Caption = 'Export Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11401; "Export Time"; Time)
        {
            Caption = 'Export Time';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
#pragma warning restore AL0520
#endif
