// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument.Service.Participant;

tableextension 10974 "FR Service Participant" extends "Service Participant"
{
    fields
    {
        field(10970; "FR Identifier Scheme"; Enum "Electronic Address Scheme")
        {
            Caption = 'French Identifier Scheme';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the electronic address scheme used for French electronic invoicing.';
        }
    }
}