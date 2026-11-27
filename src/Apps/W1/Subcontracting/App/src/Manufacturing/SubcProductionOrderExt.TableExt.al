// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

tableextension 20505 "Subc. Production Order Ext." extends "Production Order"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(20580; "Subc. WIP Cohort"; Enum "Subc. WIP Cohort")
        {
            Caption = 'WIP Cohort';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20581; "Subc. WIP Lineage ID"; Guid)
        {
            Caption = 'WIP Lineage ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20582; "Subc. WIP Version"; Integer)
        {
            Caption = 'WIP Version';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20583; "Subc. Continuation Token"; Guid)
        {
            Caption = 'WIP Continuation Token';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20552; "Created from Purch. Order"; Boolean)
        {
            Caption = 'Created from Purchase Order';
            DataClassification = CustomerContent;
            Description = 'For internal use only';
        }
    }
}
