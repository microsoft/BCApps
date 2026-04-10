// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using Microsoft.Service.Document;

tableextension 6478 "Serv. VAT Rate Change Setup" extends "VAT Rate Change Setup"
{
    fields
    {
        field(41; "Update Service Docs."; Option)
        {
            AccessByPermission = TableData "Service Header" = R;
            Caption = 'Update Service Docs.';
            DataClassification = CustomerContent;
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(43; "Update Serv. Price Adj. Detail"; Option)
        {
            AccessByPermission = TableData "Service Header" = R;
            Caption = 'Update Serv. Price Adj. Detail';
            DataClassification = CustomerContent;
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        field(103; "Ignore Status on Service Docs."; Boolean)
        {
            Caption = 'Ignore Status on Service Docs.';
            DataClassification = CustomerContent;
            InitValue = true;
        }

    }
}
