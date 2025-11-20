namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Service.Archive;
using Microsoft.Service.Pricing;
using Microsoft.Service.Comment;
using Microsoft.Service.History;
using Microsoft.Service.Document;
using Microsoft.Service.Email;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Setup;
using Microsoft.Service.Posting;

permissionsetextension 5918 "SERV D365PREM SMG VIEW" extends "D365PREM SMG, VIEW"
{
    Permissions = tabledata "Contract/Service Discount" = RM,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "Filed Service Contract Header" = RM,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Serv. Price Adjustment Detail" = RM,
                  tabledata "Serv. Price Group Setup" = RM,
                  tabledata "Service Comment Line" = RM,
                  tabledata "Service Comment Line Archive" = RM,
                  tabledata "Service Contract Account Group" = RM,
                  tabledata "Service Contract Header" = RM,
                  tabledata "Service Contract Line" = RM,
                  tabledata "Service Contract Template" = RM,
                  tabledata "Service Cost" = RM,
                  tabledata "Service Cr.Memo Header" = RM,
                  tabledata "Service Cr.Memo Line" = RM,
                  tabledata "Service Document Log" = RM,
                  tabledata "Service Document Register" = RM,
                  tabledata "Service Email Queue" = RM,
                  tabledata "Service Header" = RM,
                  tabledata "Service Header Archive" = RM,
                  tabledata "Service Hour" = RM,
                  tabledata "Service Invoice Header" = RM,
                  tabledata "Service Invoice Line" = RM,
                  tabledata "Service Item" = RM,
                  tabledata "Service Item Component" = RM,
                  tabledata "Service Item Group" = RM,
                  tabledata "Service Item Line" = RM,
                  tabledata "Service Item Line Archive" = RM,
                  tabledata "Service Item Log" = RM,
                  tabledata "Service Ledger Entry" = Rm,
                  tabledata "Service Line" = RM,
                  tabledata "Service Line Archive" = RM,
                  tabledata "Service Line Price Adjmt." = RM,
                  tabledata "Service Mgt. Setup" = RM,
                  tabledata "Service Order Allocation" = RM,
                  tabledata "Service Order Allocat. Archive" = RM,
                  tabledata "Service Order Posting Buffer" = RM,
                  tabledata "Service Order Type" = RM,
                  tabledata "Service Price Adjustment Group" = RM,
                  tabledata "Service Price Group" = RM,
                  tabledata "Service Register" = RM,
                  tabledata "Service Shelf" = RM,
                  tabledata "Service Shipment Header" = RM,
                  tabledata "Service Shipment Item Line" = RM,
                  tabledata "Service Shipment Line" = RM,
                  tabledata "Service Status Priority Setup" = RM,
                  tabledata "Service Zone" = RM;
}
