// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.RoleCenters;

using Microsoft.Manufacturing.Forecast;

pageextension 99000777 "DF Sales Marketing Mgr. RC" extends "Sales & Marketing Manager RC"
{
    actions
    {
        addafter("Sales Analysis by Dimensions")
        {
            action("Forecast")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Demand Forecast';
                RunObject = page "Demand Forecast Names";
            }
        }
    }
}