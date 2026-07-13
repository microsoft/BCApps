// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Document;

tableextension 5005282 DRPurchSetup extends "Purchases & Payables Setup"
{
    fields
    {
        field(5005270; "Delivery Reminder Nos."; Code[20])
        {
            Caption = 'Delivery Reminder Nos.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(5005271; "Issued Delivery Reminder Nos."; Code[20])
        {
            Caption = 'Issued Delivery Reminder Nos.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(5005272; "Default Del. Rem. Date Field"; Enum "Delivery Reminder Date Type")
        {
            Caption = 'Default Del. Rem. Date Field';
            DataClassification = CustomerContent;
        }
    }
}
