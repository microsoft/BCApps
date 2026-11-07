namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;

permissionsetextension 5905 "SERV D365 BASIC ISV" extends "D365 BASIC ISV"
{
    Permissions =
                  tabledata "Contract Change Log" = RIMD,
                  tabledata "Contract Gain/Loss Entry" = RIMD,
                  tabledata "Contract Group" = RIMD,
                  tabledata "Contract Trend Buffer" = RIMD,
                  tabledata "Fault Area" = RIMD,
                  tabledata "Fault Code" = RIMD,
                  tabledata "Fault Reason Code" = RIMD,
                  tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata "Filed Contract Line" = RIMD,
                  tabledata "Filed Serv. Contract Cmt. Line" = RIMD,
                  tabledata Loaner = RIMD,
                  tabledata "Loaner Entry" = RIMD,
                  tabledata "Repair Status" = RIMD,
                  tabledata "Resolution Code" = RIMD,
                  tabledata "Resource Location" = RIMD,
                  tabledata "Resource Service Zone" = RIMD,
                  tabledata "Resource Skill" = RIMD,
                  tabledata "Service Item Trend Buffer" = RIMD,
                  tabledata "Service Mgt. Setup" = Ri,
                  tabledata "Skill Code" = RIMD,
                  tabledata "Symptom Code" = RIMD,
                  tabledata "Troubleshooting Header" = RIMD,
                  tabledata "Troubleshooting Line" = RIMD,
                  tabledata "Troubleshooting Setup" = RIMD,
                  tabledata "Warranty Ledger Entry" = RIMD,
                  tabledata "Work-Hour Template" = RIMD;
}