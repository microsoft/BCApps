// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

table 142 "Dispute Status"
{
    Caption = 'Dispute Status';
    DataCaptionFields = "Code", "Description";
    LookupPageID = "Dispute Status";

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a dispute status code that you can select.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies an explanation of the dispute status.';
        }
        field(10; "Overwrite on hold"; Boolean)
        {
            Caption = 'Overwrite on hold';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies if this dispute status should update the on hold value on the corresponding customer ledger entry.';
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
}
