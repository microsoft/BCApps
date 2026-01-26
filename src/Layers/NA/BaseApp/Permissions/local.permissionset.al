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

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Account Identifier" = RIMD,
                  tabledata "ACH Cecoban Detail" = RIMD,
                  tabledata "ACH Cecoban Footer" = RIMD,
                  tabledata "ACH Cecoban Header" = RIMD,
                  tabledata "ACH RB Detail" = RIMD,
                  tabledata "ACH RB Footer" = RIMD,
                  tabledata "ACH RB Header" = RIMD,
                  tabledata "ACH US Detail" = RIMD,
                  tabledata "ACH US Footer" = RIMD,
                  tabledata "ACH US Header" = RIMD,
                  tabledata "B10 Adjustment" = RIMD,
                  tabledata "Bank Comment Line" = RIMD,
                  tabledata "CFDI Cancellation Reason" = RIMD,
                  tabledata "CFDI Export Code" = RIMD,
                  tabledata "CFDI Subject to Tax" = RIMD,
                  tabledata "CFDI Documents" = RIMD,
                  tabledata "CFDI Relation Document" = RIMD,
                  tabledata "CFDI Transport Operator" = RIMD,
                  tabledata "Credit Manager Cue" = RIMD,
                  tabledata "Data Dictionary Info" = RIMD,
                  tabledata "Document Header" = RIMD,
                  tabledata "Document Line" = RIMD,
                  tabledata "EFT Export" = RIMD,
                  tabledata "EFT Export Workset" = RIMD,
                  tabledata "GIFI Code" = RIMD,
                  tabledata "Item Location Variant Buffer" = RIMD,
                  tabledata "MX Electronic Invoicing Setup" = RIMD,
                  tabledata "PAC Web Service" = RIMD,
                  tabledata "PAC Web Service Detail" = RIMD,
                  tabledata "Posted Bank Rec. Header" = Rimd,
                  tabledata "Posted Bank Rec. Line" = Rimd,
                  tabledata "Posted Deposit Header" = Rimd,
                  tabledata "Posted Deposit Line" = Rimd,
                  tabledata "Sales Tax Amount Difference" = RIMD,
                  tabledata "Sales Tax Amount Line" = RIMD,
                  tabledata "Sales Tax Setup Wizard" = RIMD,
                  tabledata "SAT Account Code" = RIMD,
                  tabledata "SAT Classification" = RIMD,
                  tabledata "SAT Country Code" = RIMD,
                  tabledata "SAT Address" = RIMD,
                  tabledata "SAT MX Resources" = RIMD,
                  tabledata "SAT Payment Method" = RIMD,
                  tabledata "SAT Payment Method Code" = RIMD,
                  tabledata "SAT Payment Term" = RIMD,
                  tabledata "SAT Relationship Type" = RIMD,
                  tabledata "SAT Tax Scheme" = RIMD,
                  tabledata "SAT Unit of Measure" = RIMD,
                  tabledata "SAT Use Code" = RIMD,
                  tabledata "SAT Weight Unit of Measure" = RIMD,
                  tabledata "SAT Federal Motor Transport" = RIMD,
                  tabledata "SAT Trailer Type" = RIMD,
                  tabledata "SAT Permission Type" = RIMD,
                  tabledata "SAT Hazardous Material" = RIMD,
                  tabledata "SAT Packaging Type" = RIMD,
                  tabledata "SAT State" = RIMD,
                  tabledata "SAT Municipality" = RIMD,
                  tabledata "SAT Locality" = RIMD,
                  tabledata "SAT Suburb" = RIMD,
                  tabledata "SAT International Trade Term" = RIMD,
                  tabledata "SAT Customs Unit" = RIMD,
                  tabledata "SAT Transfer Reason" = RIMD,
                  tabledata "SAT Material Type" = RIMD,
                  tabledata "SAT Customs Regime" = RIMD,
                  tabledata "SAT Customs Document Type" = RIMD,
                  tabledata "Vendor Location" = RIMD;
}