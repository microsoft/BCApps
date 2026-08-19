namespace System.Security.AccessControl;

using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Email;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Service.Resources;
using Microsoft.Service.RoleCenters;
using Microsoft.Service.Setup;

permissionsetextension 5901 "SERV D365 AUTOMATION" extends "D365 AUTOMATION"
{
    Permissions =
                  tabledata "Contract Change Log" = RIMD,
                  tabledata "Contract Gain/Loss Entry" = RIMD,
                  tabledata "Contract Group" = RIMD,
                  tabledata "Contract Trend Buffer" = RIMD,
                  tabledata "Contract/Service Discount" = RIMD,
                  tabledata "Fault Area" = RIMD,
                  tabledata "Fault Area/Symptom Code" = RIMD,
                  tabledata "Fault Code" = RIMD,
                  tabledata "Fault Reason Code" = RIMD,
                  tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata "Filed Service Contract Header" = RIMD,
                  tabledata "Filed Contract Line" = RIMD,
                  tabledata "Filed Serv. Contract Cmt. Line" = RIMD,
                  tabledata "Filed Contract Service Hour" = RIMD,
                  tabledata "Filed Contract/Serv. Discount" = RIMD,
                  tabledata Loaner = RIMD,
                  tabledata "Loaner Entry" = RIMD,
                  tabledata "Repair Status" = RIMD,
                  tabledata "Resolution Code" = RIMD,
                  tabledata "Resource Location" = RIMD,
                  tabledata "Resource Service Zone" = RIMD,
                  tabledata "Resource Skill" = RIMD,
                  tabledata "Serv. Price Adjustment Detail" = RIMD,
                  tabledata "Serv. Price Group Setup" = RIMD,
                  tabledata "Service Comment Line" = RIMD,
                  tabledata "Service Comment Line Archive" = RIMD,
                  tabledata "Service Contract Account Group" = RIMD,
                  tabledata "Service Contract Header" = RIMD,
                  tabledata "Service Contract Line" = RIMD,
                  tabledata "Service Contract Template" = RIMD,
                  tabledata "Service Cost" = RIMD,
                  tabledata "Service Cr.Memo Header" = RIMD,
                  tabledata "Service Cr.Memo Line" = RIMD,
                  tabledata "Service Cue" = RIMD,
                  tabledata "Service Document Log" = RIMD,
                  tabledata "Service Document Register" = RIMD,
                  tabledata "Service Email Queue" = RIMD,
                  tabledata "Service Header" = RIMD,
                  tabledata "Service Header Archive" = RIMD,
                  tabledata "Service Hour" = RIMD,
                  tabledata "Service Invoice Header" = RIMD,
                  tabledata "Service Invoice Line" = RIMD,
                  tabledata "Service Item" = RIMD,
                  tabledata "Service Item Component" = RIMD,
                  tabledata "Service Item Group" = RIMD,
                  tabledata "Service Item Line" = RIMD,
                  tabledata "Service Item Line Archive" = RIMD,
                  tabledata "Service Item Log" = RIMD,
                  tabledata "Service Item Trend Buffer" = RIMD,
                  tabledata "Service Ledger Entry" = Rimd,
                  tabledata "Service Line" = RIMD,
                  tabledata "Service Line Archive" = RIMD,
                  tabledata "Service Line Price Adjmt." = RIMD,
                  tabledata "Service Mgt. Setup" = RIMD,
                  tabledata "Service Order Allocation" = RIMD,
                  tabledata "Service Order Allocat. Archive" = RIMD,
                  tabledata "Service Order Posting Buffer" = RIMD,
                  tabledata "Service Order Type" = RIMD,
                  tabledata "Service Price Adjustment Group" = RIMD,
                  tabledata "Service Price Group" = RIMD,
                  tabledata "Service Register" = RIMD,
                  tabledata "Service Shelf" = RIMD,
                  tabledata "Service Shipment Buffer" = RimD,
                  tabledata "Service Shipment Header" = RIMD,
                  tabledata "Service Shipment Item Line" = RIMD,
                  tabledata "Service Shipment Line" = RIMD,
                  tabledata "Service Status Priority Setup" = RIMD,
                  tabledata "Service Zone" = RIMD,
                  tabledata "Skill Code" = RIMD,
                  tabledata "Standard Service Code" = RIMD,
                  tabledata "Standard Service Item Gr. Code" = RIMD,
                  tabledata "Standard Service Line" = RIMD,
                  tabledata "Symptom Code" = RIMD,
                  tabledata "Troubleshooting Header" = RIMD,
                  tabledata "Troubleshooting Line" = RIMD,
                  tabledata "Troubleshooting Setup" = RIMD,
                  tabledata "Warranty Ledger Entry" = RIMD,
                  tabledata "Work-Hour Template" = RIMD;
}