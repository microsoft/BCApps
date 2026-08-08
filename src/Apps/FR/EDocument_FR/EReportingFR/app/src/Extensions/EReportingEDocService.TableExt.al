// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

tableextension 10977 "E-Reporting E-Doc. Service" extends "E-Document Service"
{
    fields
    {
        field(10970; "FR Sender Platform ID"; Text[50])
        {
            Caption = 'FR Sender Platform ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the identifier of the French approved platform that sends lifecycle messages.';
        }
        field(10971; "FR Sender Platform Scheme"; Code[4])
        {
            Caption = 'FR Sender Platform Scheme';
            DataClassification = CustomerContent;
            InitValue = '0238';
            ToolTip = 'Specifies the identifier scheme of the French approved platform.';
        }
        field(10972; "FR Sender Platform Name"; Text[100])
        {
            Caption = 'FR Sender Platform Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the name of the French approved platform that sends lifecycle messages.';
        }
    }
}