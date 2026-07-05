namespace System.Security.AccessControl;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;

permissionset 2393 "Dynamics CRM - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Setup Dynamics CRM Int.';

    Permissions = tabledata "CDS Solution" = RIMD,
                  tabledata "CDS Teammembership" = RIMD,
                  tabledata "CDS Teamroles" = RIMD,
                  tabledata "Coupling Record Buffer" = RIMD,
                  tabledata "Dataverse Entity Change" = RID,
                  tabledata "CRM Account" = RIMD,
                  tabledata "CRM Account Statistics" = RIMD,
                  tabledata "CRM Annotation" = RIMD,
                  tabledata "CRM Annotation Buffer" = RIMD,
                  tabledata "CRM Annotation Coupling" = RIMD,
                  tabledata "CRM Appmodule" = RIMD,
                  tabledata "CRM Businessunit" = RIMD,
                  tabledata "CRM Connection Setup" = RIMD,
                  tabledata "CRM Contact" = RIMD,
                  tabledata "CRM Contract" = RIMD,
                  tabledata "CRM Customeraddress" = RIMD,
                  tabledata "CRM Discount" = RIMD,
                  tabledata "CRM Discounttype" = RIMD,
                  tabledata "CRM Freight Terms" = R,
                  tabledata "CRM Full Synch. Review Line" = RIMD,
                  tabledata "CRM Incident" = RIMD,
                  tabledata "CRM Incidentresolution" = RIMD,
                  tabledata "CRM Integration Record" = RIMD,
                  tabledata "CRM Invoice" = RIMD,
                  tabledata "CRM Invoicedetail" = RIMD,
                  tabledata "CRM NAV Connection" = RIMD,
                  tabledata "CRM Opportunity" = RIMD,
                  tabledata "CRM Option Mapping" = RIMD,
                  tabledata "CRM Organization" = RIMD,
                  tabledata "CRM Payment Terms" = R,
                  tabledata "CRM Post" = RIMD,
                  tabledata "CRM Post Buffer" = RIMD,
                  tabledata "CRM Post Configuration" = RIMD,
                  tabledata "CRM Pricelevel" = RIMD,
                  tabledata "CRM Product" = RIMD,
                  tabledata "CRM Productpricelevel" = RIMD,
                  tabledata "CRM Quote" = RIMD,
                  tabledata "CRM Quotedetail" = RIMD,
                  tabledata "CRM Redirect" = R,
                  tabledata "CRM Role" = RIMD,
                  tabledata "CRM Salesorder" = RIMD,
                  tabledata "CRM Salesorderdetail" = RIMD,
                  tabledata "CRM Shipping Method" = R,
                  tabledata "CRM Synch. Conflict Buffer" = RIMD,
                  tabledata "CRM Synch. Job Status Cue" = RIMD,
                  tabledata "CRM Systemuser" = RIMD,
                  tabledata "CRM Systemuserroles" = RIMD,
                  tabledata "CDS Field Security Profile" = RIMD,
                  tabledata "CDS System User Profiles" = RIMD,
                  tabledata "CRM Team" = RIMD,
                  tabledata "CRM Transactioncurrency" = RIMD,
                  tabledata "CRM Uom" = RIMD,
                  tabledata "CRM Uomschedule" = RIMD,
                  tabledata "Integration Field Mapping" = RIMD,
                  tabledata "Integration Synch. Job" = RIMD,
                  tabledata "Integration Synch. Job Errors" = RIMD,
                  tabledata "Integration Table Mapping" = RIMD,
                  tabledata "Man. Integration Table Mapping" = RIMD,
                  tabledata "Temp Integration Field Mapping" = RIMD,
                  tabledata "Man. Int. Field Mapping" = RIMD;
}