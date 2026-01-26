// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using System.Text;

pageextension 28041 "Serv.ServiceMgrRoleCenter APAC" extends "Service Manager Role Center"
{
    actions
    {
        addafter("Service Item Line Labels")
        {
            action("BarCode Checking")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'BarCode Checking';
                RunObject = Report "BarCode Checking";
            }
            action("BarCode Batch Job")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'BarCode Batch Job';
                RunObject = Report "BarCode Batch Job";
            }
        }
    }
}
