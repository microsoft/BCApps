namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Service.RoleCenters;
using Microsoft.Service.Setup;

permissionsetextension 5906 "SERV D365 BUS FULL ACCESS" extends "D365 BUS FULL ACCESS"
{
    Permissions =
                  tabledata "Contract Change Log" = RIMD,
                  tabledata "Contract Gain/Loss Entry" = RIM,
                  tabledata "Contract Group" = RIMD,
                  tabledata "Contract Trend Buffer" = RIMD,
                  tabledata "Fault Area" = RIMD,
                  tabledata "Fault Area/Symptom Code" = RIMD,
                  tabledata "Fault Code" = RIMD,
                  tabledata "Fault Reason Code" = RIMD,
                  tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata "Filed Service Contract Header" = rm,
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
                  tabledata "Service Cue" = RIMD,
                  tabledata "Service Item Trend Buffer" = RIMD,
                  tabledata "Service Mgt. Setup" = RI,
                  tabledata "Service Shipment Buffer" = RimD,
                  tabledata "Skill Code" = RIMD,
                  tabledata "Standard Service Code" = RIMD,
                  tabledata "Standard Service Item Gr. Code" = RIMD,
                  tabledata "Standard Service Line" = RIMD,
                  tabledata "Symptom Code" = RIMD,
                  tabledata "Troubleshooting Header" = RIMD,
                  tabledata "Troubleshooting Line" = RIMD,
                  tabledata "Warranty Ledger Entry" = ID,
                  tabledata "Work-Hour Template" = RIMD;
}