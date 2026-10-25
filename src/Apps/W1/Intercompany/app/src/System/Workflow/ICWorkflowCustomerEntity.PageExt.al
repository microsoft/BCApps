// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

pageextension 8554 "IC Workflow Customer Entity" extends "Workflow - Customer Entity"
{
    layout
    {
        addafter(pmtToleranceLcy)
        {
            field(icPartnerCode; Rec."IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'IC Partner Code', Locked = true;
            }
        }
    }
}
