// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Manufacturing.Forecast;

pageextension 99000798 "DF Purchasing Manager RC" extends "Purchasing Manager Role Center"
{
    actions
    {
        addafter("Vendors1")
        {
            action("Production Forecasts")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Demand Forecasts';
                RunObject = page "Demand Forecast Names";
            }
        }
    }
}