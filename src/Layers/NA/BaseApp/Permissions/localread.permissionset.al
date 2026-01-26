namespace System.Security.AccessControl;

using Microsoft;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Deposit;
using Microsoft.Bank.ElectronicFundsTransfer;
using Microsoft.Bank.Reconciliation;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reports;
using Microsoft.Sales.RoleCenters;
using Microsoft.Utilities;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access';

    Permissions = tabledata "Account Identifier" = R,
                  tabledata "ACH Cecoban Detail" = R,
                  tabledata "ACH Cecoban Footer" = R,
                  tabledata "ACH Cecoban Header" = R,
                  tabledata "ACH RB Detail" = R,
                  tabledata "ACH RB Footer" = R,
                  tabledata "ACH RB Header" = R,
                  tabledata "ACH US Detail" = R,
                  tabledata "ACH US Footer" = R,
                  tabledata "ACH US Header" = R,
                  tabledata "B10 Adjustment" = R,
                  tabledata "Bank Comment Line" = R,
                  tabledata "CFDI Documents" = R,
                  tabledata "CFDI Relation Document" = R,
                  tabledata "Credit Manager Cue" = R,
                  tabledata "Data Dictionary Info" = R,
                  tabledata "Document Header" = R,
                  tabledata "Document Line" = R,
                  tabledata "EFT Export" = R,
                  tabledata "EFT Export Workset" = R,
                  tabledata "GIFI Code" = R,
                  tabledata "Item Location Variant Buffer" = R,
                  tabledata "MX Electronic Invoicing Setup" = R,
                  tabledata "PAC Web Service" = R,
                  tabledata "PAC Web Service Detail" = R,
                  tabledata "Posted Bank Rec. Header" = R,
                  tabledata "Posted Bank Rec. Line" = R,
                  tabledata "Posted Deposit Header" = R,
                  tabledata "Posted Deposit Line" = R,
                  tabledata "Sales Tax Amount Difference" = R,
                  tabledata "Sales Tax Amount Line" = R,
                  tabledata "Sales Tax Setup Wizard" = R,
                  tabledata "SAT Account Code" = R,
                  tabledata "SAT Classification" = R,
                  tabledata "SAT Country Code" = R,
                  tabledata "SAT MX Resources" = R,
                  tabledata "SAT Payment Method" = R,
                  tabledata "SAT Payment Method Code" = R,
                  tabledata "SAT Payment Term" = R,
                  tabledata "SAT Relationship Type" = R,
                  tabledata "SAT Tax Scheme" = R,
                  tabledata "SAT Unit of Measure" = R,
                  tabledata "SAT Use Code" = R,
                  tabledata "Vendor Location" = R;
}