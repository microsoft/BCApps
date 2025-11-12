namespace System.Security.AccessControl;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
#if not CLEAN25
using Microsoft.Integration.FieldService;
#endif
using Microsoft.Sales.Customer;
using Microsoft.Integration.SyncEngine;
using Microsoft.CRM.Interaction;
using Microsoft.Purchases.Vendor;

permissionset 617 "D365 DYN CRM MGT"
{
    Assignable = true;
    IncludedPermissionSets = "D365 DYN CRM READ";

    Caption = 'Dynamics 365 Sales Integration - Mgt.';
    Permissions = tabledata "CDS Available Virtual Table" = IMD,
                  tabledata "CDS BC Table Relation" = IMD,
                  tabledata "CDS Company" = IMD,
                  tabledata "CDS Connection Setup" = IMD,
                  tabledata "CDS Coupled Business Unit" = IMD,
                  tabledata "CDS Environment" = IMD,
                  tabledata "CDS Solution" = IMD,
                  tabledata "CDS Teammembership" = IMD,
                  tabledata "CDS Teamroles" = IMD,
                  tabledata "Coupling Record Buffer" = IMD,
                  tabledata "Dataverse Entity Change" = ID,
                  tabledata "CRM Account" = IMD,
                  tabledata "CRM Account Statistics" = IMD,
                  tabledata "CRM Annotation" = IMD,
                  tabledata "CRM Annotation Buffer" = IMD,
                  tabledata "CRM Annotation Coupling" = IMD,
                  tabledata "CRM Appmodule" = IMD,
                  tabledata "CRM BC Virtual Table Config." = IMD,
                  tabledata "CRM Businessunit" = IMD,
                  tabledata "CRM Company" = IMD,
                  tabledata "CRM Contact" = IMD,
                  tabledata "CRM Contract" = IMD,
                  tabledata "CRM Connection Setup" = IMD,
                  tabledata "CRM Customeraddress" = IMD,
                  tabledata "CRM Discount" = IMD,
                  tabledata "CRM Discounttype" = IMD,
                  tabledata "CRM Full Synch. Review Line" = IMD,
                  tabledata "CRM Incident" = IMD,
                  tabledata "CRM Incidentresolution" = IMD,
                  tabledata "CRM Integration Record" = IMD,
                  tabledata "CRM Invoice" = IMD,
                  tabledata "CRM Invoicedetail" = IMD,
                  tabledata "CRM NAV Connection" = IMD,
                  tabledata "CRM Opportunity" = IMD,
                  tabledata "CRM Option Mapping" = IMD,
                  tabledata "CRM Organization" = IMD,
                  tabledata "CRM Post" = IMD,
                  tabledata "CRM Post Buffer" = IMD,
                  tabledata "CRM Post Configuration" = IMD,
                  tabledata "CRM Pricelevel" = IMD,
                  tabledata "CRM Product" = IMD,
                  tabledata "CRM Productpricelevel" = IMD,
                  tabledata "CRM Quote" = IMD,
                  tabledata "CRM Quotedetail" = IMD,
                  tabledata "CRM Role" = IMD,
                  tabledata "CRM Salesorder" = IMD,
                  tabledata "CRM Salesorderdetail" = IMD,
                  tabledata "CRM Synch Status" = IMD,
                  tabledata "CRM Synch. Conflict Buffer" = IMD,
                  tabledata "CRM Synch. Job Status Cue" = IMD,
                  tabledata "CRM Systemuser" = IMD,
                  tabledata "CRM Systemuserroles" = IMD,
                  tabledata "CDS Field Security Profile" = IMD,
                  tabledata "CDS System User Profiles" = IMD,
                  tabledata "CRM Team" = IMD,
                  tabledata "CRM Transactioncurrency" = IMD,
                  tabledata "CRM Uom" = IMD,
                  tabledata "CRM Uomschedule" = IMD,
#if not CLEAN25
                  tabledata "FS Connection Setup" = IMD,
                  tabledata "FS Bookable Resource" = IMD,
                  tabledata "FS Bookable Resource Booking" = IMD,
                  tabledata "FS BookableResourceBookingHdr" = IMD,
                  tabledata "FS Customer Asset" = IMD,
                  tabledata "FS Customer Asset Category" = IMD,
                  tabledata "FS Project Task" = IMD,
                  tabledata "FS Resource Pay Type" = IMD,
                  tabledata "FS Work Order" = IMD,
                  tabledata "FS Work Order Incident" = IMD,
                  tabledata "FS Work Order Product" = IMD,
                  tabledata "FS Work Order Service" = IMD,
                  tabledata "FS Work Order Substatus" = IMD,
                  tabledata "FS Work Order Type" = IMD,
#endif
                  tabledata "Customer Templ." = IMD,
                  tabledata "Vendor Templ." = IMD,
                  tabledata "Int. Table Config Template" = IMD,
                  tabledata "Integration Field Mapping" = IMD,
                  tabledata "Integration Synch. Job" = IMD,
                  tabledata "Integration Synch. Job Errors" = IMD,
                  tabledata "Integration Table Mapping" = IMD,
                  tabledata "Interaction Template" = imd,
                  tabledata "Man. Integration Table Mapping" = IMD,
                  tabledata "Temp Integration Field Mapping" = IMD,
                  tabledata "Man. Int. Field Mapping" = IMD,
                  tabledata "Table Config Template" = IMD;
}