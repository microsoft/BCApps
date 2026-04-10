namespace System.Security.AccessControl;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;

permissionset 8783 "Dataverse - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'MS DATAVERSE Integration';

    Permissions = tabledata "CDS Company" = R,
                  tabledata "CDS Connection Setup" = R,
                  tabledata "CDS Coupled Business Unit" = R,
                  tabledata "CDS Environment" = R,
                  tabledata "CDS Solution" = R,
                  tabledata "CDS Teamroles" = R,
                  tabledata "Dataverse Entity Change" = Rd,
                  tabledata "CRM Account" = R,
                  tabledata "CRM Businessunit" = R,
                  tabledata "CRM Contact" = R,
                  tabledata "CRM Customeraddress" = R,
                  tabledata "CRM Freight Terms" = R,
                  tabledata "CRM Organization" = R,
                  tabledata "CRM Payment Terms" = R,
                  tabledata "CRM Role" = R,
                  tabledata "CRM Shipping Method" = R,
                  tabledata "CRM Systemuser" = R,
                  tabledata "CRM Systemuserroles" = R,
                  tabledata "CDS Field Security Profile" = R,
                  tabledata "CDS System User Profiles" = R,
                  tabledata "CRM Team" = R,
                  tabledata "CRM Transactioncurrency" = R;
}
