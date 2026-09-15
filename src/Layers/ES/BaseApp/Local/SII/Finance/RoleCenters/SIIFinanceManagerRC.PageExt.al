// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.EServices.EDocument;

pageextension 7000140 "SII Finance Manager RC" extends "Finance Manager Role Center"
{
    actions
    {
        addafter("Make 340 Declaration")
        {
            action("SII Requests History")
            {
                ApplicationArea = All;
                Caption = 'SII History';
                RunObject = page "SII History";
                ToolTip = 'View the history of SII requests and responses.';
            }
        }
        addafter("No. Series")
        {
            action("SII VAT Setup")
            {
                ApplicationArea = All;
                Caption = 'SII Setup';
                RunObject = page "SII Setup";
                ToolTip = 'Configure the SII settings.';
            }
        }
    }
}