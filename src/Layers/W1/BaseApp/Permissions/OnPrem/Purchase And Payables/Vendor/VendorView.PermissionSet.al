namespace System.Security.AccessControl;

using Microsoft.Foundation.Comment;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Payables;
using Microsoft.HumanResources.Payables;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Remittance;

permissionset 5600 "Vendor - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read vendors and entries';

    Permissions = tabledata "Comment Line" = R,
                  tabledata Contact = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Detailed Vendor Ledg. Entry" = R,
                  tabledata "Employee Ledger Entry" = R,
                  tabledata "Item Reference" = R,
                  tabledata Location = R,
                  tabledata "My Vendor" = Rimd,
                  tabledata "Order Address" = R,
                  tabledata "Remit Address" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Ledger Entry" = R;
}
