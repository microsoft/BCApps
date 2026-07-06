// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

pageextension 11031 "Intrastat Report Setup DE" extends "Intrastat Report Setup"
{
    layout
    {
        addlast(General)
        {
            field("Default Submission Channel"; Rec."Default Submission Channel")
            {
                ApplicationArea = BasicEU;
                Caption = 'Default Submission Channel';
                ToolTip = 'Specifies the submission channel that is suggested on new Intrastat reports. Choose eSTATISTIK.CORE to export the clean format that does not use the Material No., or IDEV to keep the Material No. (Company No.) in the message ID. You can still change the channel on each individual Intrastat report.';
            }
        }
    }
}
