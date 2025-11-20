namespace System.Security.AccessControl;

using Microsoft.Foundation.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Profiling;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Foundation.Shipping;

permissionset 4970 "Customer - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read customers and entries';

    Permissions = tabledata "Comment Line" = R,
                  tabledata Contact = R,
                  tabledata "Contact Profile Answer" = R,
                  tabledata Currency = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "Item Reference" = R,
                  tabledata Location = R,
                  tabledata "My Customer" = Rimd,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata "Reminder/Fin. Charge Entry" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Ship-to Address" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R;
}
