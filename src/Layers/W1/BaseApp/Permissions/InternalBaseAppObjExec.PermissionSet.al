namespace System.Security.AccessControl;

using Microsoft;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.D365Sales;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Analysis;
using Microsoft.Warehouse.Availability;
using Microsoft.Utilities;
using System.AI;
using System.Email;
using System.Integration;
using System.Environment.Configuration;
using System.DataAdministration;
using System.Telemetry;
using System.Environment;
using System.Threading;
using System.Diagnostics;

permissionset 23 "Internal BaseApp Obj. - Exec"
{
    Access = Public;
    Assignable = false;
    Caption = 'Internal BaseApp Obj. - Exec';

    permissions = Table "CDS Coupled Business Unit" = X,
                  Table "CDS Environment" = X,
                  Table "CRM BC Virtual Table Config." = X,
                  Table "CRM Freight Terms" = X,
                  Table "CRM Payment Terms" = X,
                  Table "CRM Shipping Method" = X,
                  Table "Email Item" = X,
                  Table "OData Initialized Status" = X,
                  Table "Permission Conflicts" = X,
                  Table "Permission Conflicts Overview" = X,
                  Codeunit "Application Area Cache" = X,
                  Codeunit "Base Application Logs Delete" = X,
                  Codeunit "CDS Environment" = X,
                  Codeunit "Company Setup Notification" = X,
                  Codeunit "Contact Business Relation" = X,
                  Codeunit "Data Admin. Page Notification" = X,
                  Codeunit "Email Address Lookup Subs" = X,
                  codeunit "Emit Database Wait Statistics" = X,
                  Codeunit "Environment Cleanup Subs" = X,
                  Codeunit "Lookup State Manager" = X,
                  Codeunit "Map Email Source" = X,
                  Codeunit "OData Initializer" = X,
                  Codeunit "Reten. Pol. Doc. Arch. Fltrng." = X,
                  Codeunit "Reten. Pol. Install - BaseApp" = X,
                  Codeunit "Reten. Pol. Upgrade - BaseApp" = X,
                  Codeunit "Retention Policy JQ" = X,
                  Codeunit "Retention Policy Scheduler" = X,
                  Codeunit "Advanced Settings Ext. Impl." = X,
                  Codeunit "Azure AI Usage Impl." = X,
                  Codeunit "BOM Tree Impl." = X,
                  Codeunit "BOM Tree Node" = X,
                  Codeunit "BOM Tree Node Dictionary Impl." = X,
                  Codeunit "BOM Tree Nodes Bucket" = X,
                  Codeunit "Global Admin Notifier" = X,
                  Codeunit "Job Queue Start Report" = X,
                  codeunit "Monitored Field Notification" = X,
                  Codeunit "Scheduled Tasks" = X,
                  Query CalcRsvQtyOnPicksShipsWithIT = X,
                  Query "Calculate Actual Material Cost" = X,
                  Query "Sales by Cust. Grp. Chart Mgt." = X;
}