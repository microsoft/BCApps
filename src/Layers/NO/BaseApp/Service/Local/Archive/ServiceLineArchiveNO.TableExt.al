// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

tableextension 10601 "Service Line Archive NO" extends "Service Line Archive"
{
    fields
    {
        field(10600; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the account code of the customer.';
        }
    }
}