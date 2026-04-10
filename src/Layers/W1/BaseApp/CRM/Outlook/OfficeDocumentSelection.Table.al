// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.EServices.EDocument;

table 1620 "Office Document Selection"
{
    Caption = 'Office Document Selection';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Series; Option)
        {
            Caption = 'Series';
            ToolTip = 'Specifies the series of the involved document, such as Purchasing or Sales.';
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
        }
        field(2; "Document Type"; Enum "Incoming Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type that the entry belongs to.';
            Description = 'Type of the referenced document.';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the involved document.';
            Description = 'No. of the referenced document.';
        }
        field(4; Posted; Boolean)
        {
            Caption = 'Posted';
            ToolTip = 'Specifies whether the involved document has been posted.';
        }
        field(5; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';
        }
    }

    keys
    {
        key(Key1; Series, "Document Type", "Document No.", Posted)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

