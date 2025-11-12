// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using Microsoft.Service.Document;
using Microsoft.Service.Email;
using Microsoft.Service.Item;

pageextension 6461 "Serv. Data Administration" extends "Data Administration"
{
    actions
    {
        addafter(DeleteInvoicedPurchaseReturnOrders)
        {
            action(DeleteInvoicedServiceOrders)
            {
                ApplicationArea = Service;
                Caption = 'Delete Service Orders';
                ToolTip = 'Delete Service Orders';
                RunObject = Report "Delete Invoiced Service Orders";
                Ellipsis = true;
            }
        }
        addafter(DeletePhysicalInventoryLedger)
        {
            action(ServiceEmailQueue)
            {
                ApplicationArea = Service;
                Caption = 'Delete Service Email Queue';
                ToolTip = 'Delete Service Email Queue';

                RunObject = report "Delete Service Email Queue";
                Ellipsis = true;
            }
            action(DeleteServiceDocumentLog)
            {
                ApplicationArea = Service;
                Caption = 'Delete Service Document Log';
                ToolTip = 'Delete Service Document Log';

                RunObject = report "Delete Service Document Log";
                Ellipsis = true;
            }
            action(DeleteServiceItemLog)
            {
                ApplicationArea = Service;
                Caption = 'Delete Service Item Log';
                ToolTip = 'Delete Service Item Log';

                RunObject = report "Delete Service Item Log";
                Ellipsis = true;
            }
        }
    }
}
