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

permissionsetextension 5912 "SERV D365 READ" extends "D365 READ"
{
    Permissions =
                  tabledata "Contract Change Log" = R,
                  tabledata "Contract Gain/Loss Entry" = R,
                  tabledata "Contract Group" = R,
                  tabledata "Contract Trend Buffer" = R,
                  tabledata "Contract/Service Discount" = R,
                  tabledata "Fault Area" = R,
                  tabledata "Fault Area/Symptom Code" = R,
                  tabledata "Fault Code" = R,
                  tabledata "Fault Reason Code" = R,
                  tabledata "Fault/Resol. Cod. Relationship" = R,
                  tabledata "Filed Service Contract Header" = R,
                  tabledata "Filed Contract Line" = R,
                  tabledata "Filed Serv. Contract Cmt. Line" = R,
                  tabledata "Filed Contract Service Hour" = R,
                  tabledata "Filed Contract/Serv. Discount" = R,
                  tabledata Loaner = R,
                  tabledata "Loaner Entry" = R,
                  tabledata "Repair Status" = R,
                  tabledata "Resolution Code" = R,
                  tabledata "Resource Location" = R,
                  tabledata "Resource Service Zone" = R,
                  tabledata "Resource Skill" = R,
                  tabledata "Serv. Price Adjustment Detail" = R,
                  tabledata "Serv. Price Group Setup" = R,
                  tabledata "Service Comment Line" = R,
                  tabledata "Service Comment Line Archive" = R,
                  tabledata "Service Contract Account Group" = R,
                  tabledata "Service Contract Header" = R,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Contract Template" = R,
                  tabledata "Service Cost" = R,
                  tabledata "Service Cr.Memo Header" = R,
                  tabledata "Service Cr.Memo Line" = R,
                  tabledata "Service Cue" = R,
                  tabledata "Service Document Log" = R,
                  tabledata "Service Document Register" = R,
                  tabledata "Service Email Queue" = R,
                  tabledata "Service Header" = R,
                  tabledata "Service Header Archive" = R,
                  tabledata "Service Hour" = R,
                  tabledata "Service Invoice Header" = R,
                  tabledata "Service Invoice Line" = R,
                  tabledata "Service Item" = R,
                  tabledata "Service Item Component" = R,
                  tabledata "Service Item Group" = R,
                  tabledata "Service Item Line" = R,
                  tabledata "Service Item Line Archive" = R,
                  tabledata "Service Item Log" = R,
                  tabledata "Service Item Trend Buffer" = R,
                  tabledata "Service Ledger Entry" = R,
                  tabledata "Service Line" = R,
                  tabledata "Service Line Archive" = R,
                  tabledata "Service Line Price Adjmt." = R,
                  tabledata "Service Mgt. Setup" = R,
                  tabledata "Service Order Allocation" = R,
                  tabledata "Service Order Allocat. Archive" = R,
                  tabledata "Service Order Posting Buffer" = R,
                  tabledata "Service Order Type" = R,
                  tabledata "Service Price Adjustment Group" = R,
                  tabledata "Service Price Group" = R,
                  tabledata "Service Register" = R,
                  tabledata "Service Shelf" = R,
                  tabledata "Service Shipment Buffer" = R,
                  tabledata "Service Shipment Header" = R,
                  tabledata "Service Shipment Item Line" = R,
                  tabledata "Service Shipment Line" = R,
                  tabledata "Service Status Priority Setup" = R,
                  tabledata "Service Zone" = R,
                  tabledata "Skill Code" = R,
                  tabledata "Standard Service Code" = R,
                  tabledata "Standard Service Item Gr. Code" = R,
                  tabledata "Standard Service Line" = R,
                  tabledata "Symptom Code" = R,
                  tabledata "Troubleshooting Header" = R,
                  tabledata "Troubleshooting Line" = R,
                  tabledata "Troubleshooting Setup" = R,
                  tabledata "Warranty Ledger Entry" = R,
                  tabledata "Work-Hour Template" = R;
}