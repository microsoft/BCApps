// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using Microsoft.RoleCenters;
using Microsoft.Service.Setup;

pageextension 6470 "Serv. Administrator Main RC" extends "Administrator Main Role Center"
{
    actions
    {
        addafter("Report Selection Sales")
        {
            action("Report Selection Service")
            {
                ApplicationArea = Service;
                Caption = 'Report Selections Service';
                RunObject = page "Report Selection - Service";
            }
        }
    }
}
