// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using Microsoft.Manufacturing.ProductionBOM;

pageextension 99000861 "Mfg. Data Administration" extends "Data Administration"
{
    actions
    {
        addafter(DeletePhysicalInventoryLedger)
        {
            action(DeleteExpiredComponents)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Delete Expired Components';
                ToolTip = 'Delete Expired Components';
                RunObject = report "Delete Expired Components";
                Ellipsis = true;
            }
        }
    }
}