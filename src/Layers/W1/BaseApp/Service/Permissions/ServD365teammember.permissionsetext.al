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

permissionsetextension 5913 "SERV D365 TEAM MEMBER" extends "D365 TEAM MEMBER"
{
    Permissions =
                  tabledata "Contract Change Log" = RM,
                  tabledata "Contract Gain/Loss Entry" = RM,
                  tabledata "Contract Group" = RM,
                  tabledata "Contract Trend Buffer" = RIMD,
                  tabledata "Fault Area" = RM,
                  tabledata "Fault Area/Symptom Code" = RM,
                  tabledata "Fault Code" = RM,
                  tabledata "Fault Reason Code" = RM,
                  tabledata "Fault/Resol. Cod. Relationship" = RM,
                  tabledata "Filed Contract Line" = RM,
                  tabledata Loaner = RM,
                  tabledata "Loaner Entry" = RM,
                  tabledata "Repair Status" = RM,
                  tabledata "Resolution Code" = RM,
                  tabledata "Resource Location" = RM,
                  tabledata "Resource Service Zone" = RM,
                  tabledata "Resource Skill" = RM,
                  tabledata "Service Cue" = RM,
                  tabledata "Service Item Trend Buffer" = RIMD,
                  tabledata "Service Shipment Buffer" = Rm,
                  tabledata "Skill Code" = RM,
                  tabledata "Standard Service Code" = RM,
                  tabledata "Standard Service Item Gr. Code" = RM,
                  tabledata "Standard Service Line" = RM,
                  tabledata "Symptom Code" = RM,
                  tabledata "Troubleshooting Header" = RM,
                  tabledata "Troubleshooting Line" = RM,
                  tabledata "Troubleshooting Setup" = RM,
                  tabledata "Warranty Ledger Entry" = RM,
                  tabledata "Work-Hour Template" = RM;
}