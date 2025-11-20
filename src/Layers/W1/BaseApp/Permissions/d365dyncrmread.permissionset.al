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

permissionset 618 "D365 DYN CRM READ"
{
    Assignable = true;

    Caption = 'Dynamics 365 Sales Integration - Read';
    Permissions = tabledata "CDS Available Virtual Table" = R,
                  tabledata "CDS BC Table Relation" = R,
                  tabledata "CDS Company" = R,
                  tabledata "CDS Connection Setup" = R,
                  tabledata "CDS Coupled Business Unit" = R,
                  tabledata "CDS Environment" = R,
                  tabledata "CDS Solution" = R,
                  tabledata "CDS Teammembership" = R,
                  tabledata "CDS Teamroles" = R,
                  tabledata "Coupling Record Buffer" = R,
                  tabledata "Dataverse Entity Change" = R,
                  tabledata "CRM Account" = R,
                  tabledata "CRM Account Statistics" = R,
                  tabledata "CRM Annotation" = R,
                  tabledata "CRM Annotation Buffer" = R,
                  tabledata "CRM Annotation Coupling" = R,
                  tabledata "CRM Appmodule" = R,
                  tabledata "CRM BC Virtual Table Config." = R,
                  tabledata "CRM Businessunit" = R,
                  tabledata "CRM Company" = R,
                  tabledata "CRM Contact" = R,
                  tabledata "CRM Contract" = R,
                  tabledata "CRM Connection Setup" = R,
                  tabledata "CRM Customeraddress" = R,
                  tabledata "CRM Discount" = R,
                  tabledata "CRM Discounttype" = R,
                  tabledata "CRM Freight Terms" = R,
                  tabledata "CRM Full Synch. Review Line" = R,
                  tabledata "CRM Incident" = R,
                  tabledata "CRM Incidentresolution" = R,
                  tabledata "CRM Integration Record" = R,
                  tabledata "CRM Invoice" = R,
                  tabledata "CRM Invoicedetail" = R,
                  tabledata "CRM NAV Connection" = R,
                  tabledata "CRM Opportunity" = R,
                  tabledata "CRM Option Mapping" = R,
                  tabledata "CRM Organization" = R,
                  tabledata "CRM Payment Terms" = R,
                  tabledata "CRM Post" = R,
                  tabledata "CRM Post Buffer" = R,
                  tabledata "CRM Post Configuration" = R,
                  tabledata "CRM Pricelevel" = R,
                  tabledata "CRM Product" = R,
                  tabledata "CRM Productpricelevel" = R,
                  tabledata "CRM Quote" = R,
                  tabledata "CRM Quotedetail" = R,
                  tabledata "CRM Redirect" = R,
                  tabledata "CRM Role" = R,
                  tabledata "CRM Salesorder" = R,
                  tabledata "CRM Salesorderdetail" = R,
                  tabledata "CRM Shipping Method" = R,
                  tabledata "CRM Synch Status" = R,
                  tabledata "CRM Synch. Conflict Buffer" = R,
                  tabledata "CRM Synch. Job Status Cue" = R,
                  tabledata "CRM Systemuser" = R,
                  tabledata "CRM Systemuserroles" = R,
                  tabledata "CDS Field Security Profile" = R,
                  tabledata "CDS System User Profiles" = R,
                  tabledata "CRM Team" = R,
                  tabledata "CRM Transactioncurrency" = R,
                  tabledata "CRM Uom" = R,
                  tabledata "CRM Uomschedule" = R,
#if not CLEAN25
                  tabledata "FS Connection Setup" = R,
                  tabledata "FS Bookable Resource" = R,
                  tabledata "FS Bookable Resource Booking" = R,
                  tabledata "FS BookableResourceBookingHdr" = R,
                  tabledata "FS Customer Asset" = R,
                  tabledata "FS Customer Asset Category" = R,
                  tabledata "FS Project Task" = R,
                  tabledata "FS Resource Pay Type" = R,
                  tabledata "FS Work Order" = R,
                  tabledata "FS Work Order Incident" = R,
                  tabledata "FS Work Order Product" = R,
                  tabledata "FS Work Order Service" = R,
                  tabledata "FS Work Order Substatus" = R,
                  tabledata "FS Work Order Type" = R,
#endif
                  tabledata "Customer Templ." = R,
                  tabledata "Vendor Templ." = R,
                  tabledata "Int. Table Config Template" = R,
                  tabledata "Integration Field Mapping" = R,
                  tabledata "Integration Synch. Job" = R,
                  tabledata "Integration Synch. Job Errors" = R,
                  tabledata "Integration Table Mapping" = R,
                  tabledata "Interaction Template" = R,
                  tabledata "Man. Integration Table Mapping" = R,
                  tabledata "Temp Integration Field Mapping" = R,
                  tabledata "Man. Int. Field Mapping" = R,
                  tabledata "Table Config Template" = R;
}