namespace System.Security.AccessControl;

using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Email;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;

permissionsetextension 5917 "SERV D365PREM SMG EDIT" extends "D365PREM SMG, EDIT"
{
    Permissions = tabledata "Contract/Service Discount" = ID,
                  tabledata "Filed Service Contract Header" = ID,
                  tabledata "Serv. Price Adjustment Detail" = ID,
                  tabledata "Serv. Price Group Setup" = ID,
                  tabledata "Service Comment Line" = ID,
                  tabledata "Service Comment Line Archive" = ID,
                  tabledata "Service Contract Account Group" = ID,
                  tabledata "Service Contract Header" = ID,
                  tabledata "Service Contract Line" = ID,
                  tabledata "Service Contract Template" = ID,
                  tabledata "Service Cost" = ID,
                  tabledata "Service Cr.Memo Header" = ID,
                  tabledata "Service Cr.Memo Line" = ID,
                  tabledata "Service Document Log" = ID,
                  tabledata "Service Document Register" = ID,
                  tabledata "Service Email Queue" = ID,
                  tabledata "Service Header" = ID,
                  tabledata "Service Header Archive" = ID,
                  tabledata "Service Hour" = ID,
                  tabledata "Service Invoice Header" = ID,
                  tabledata "Service Invoice Line" = ID,
                  tabledata "Service Item" = ID,
                  tabledata "Service Item Component" = ID,
                  tabledata "Service Item Group" = ID,
                  tabledata "Service Item Line" = ID,
                  tabledata "Service Item Line Archive" = ID,
                  tabledata "Service Item Log" = ID,
                  tabledata "Service Ledger Entry" = id,
                  tabledata "Service Line" = ID,
                  tabledata "Service Line Archive" = ID,
                  tabledata "Service Line Price Adjmt." = ID,
                  tabledata "Service Mgt. Setup" = ID,
                  tabledata "Service Order Allocation" = ID,
                  tabledata "Service Order Allocat. Archive" = ID,
                  tabledata "Service Order Posting Buffer" = ID,
                  tabledata "Service Order Type" = ID,
                  tabledata "Service Price Adjustment Group" = ID,
                  tabledata "Service Price Group" = ID,
                  tabledata "Service Register" = ID,
                  tabledata "Service Shelf" = ID,
                  tabledata "Service Shipment Header" = ID,
                  tabledata "Service Shipment Item Line" = ID,
                  tabledata "Service Shipment Line" = ID,
                  tabledata "Service Status Priority Setup" = ID,
                  tabledata "Service Zone" = ID;
}
