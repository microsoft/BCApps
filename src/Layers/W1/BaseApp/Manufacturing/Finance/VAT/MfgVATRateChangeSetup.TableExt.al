// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

tableextension 99000785 "Mfg. VAT Rate Change Setup" extends "VAT Rate Change Setup"
{
    fields
    {
        field(60; "Update Production Orders"; Option)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Update Production Orders';
            DataClassification = CustomerContent;
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        field(62; "Update Work Centers"; Option)
        {
            AccessByPermission = TableData "Work Center" = R;
            Caption = 'Update Work Centers';
            DataClassification = CustomerContent;
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        field(64; "Update Machine Centers"; Option)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Update Machine Centers';
            DataClassification = CustomerContent;
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
    }
}
