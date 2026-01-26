// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

tableextension 10611 "Service Mgt. Setup NO" extends "Service Mgt. Setup"
{
    fields
    {
        field(10600; "E-Invoice Service Invoice Path"; Text[250])
        {
            Caption = 'E-Invoice Service Invoice Path';
            DataClassification = CustomerContent;
        }
        field(10601; "E-Invoice Serv. Cr. Memo Path"; Text[250])
        {
            Caption = 'E-Invoice Serv. Cr. Memo Path';
            DataClassification = CustomerContent;
        }
    }
}