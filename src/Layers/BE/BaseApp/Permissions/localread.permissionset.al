namespace System.Security.AccessControl;

using Microsoft.Bank.CODA;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Review;
using Microsoft.Finance.VAT.Reporting;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "CODA Statement" = R,
                  tabledata "CODA Statement Line" = R,
                  tabledata "CODA Statement Source Line" = R,
                  tabledata "Domiciliation Journal Batch" = R,
                  tabledata "Domiciliation Journal Line" = R,
                  tabledata "Domiciliation Journal Template" = R,
                  tabledata "Electronic Banking Setup" = R,
                  tabledata "Export Check Error Log" = R,
                  tabledata "Export Protocol" = R,
                  tabledata "G/L Entry Application Buffer" = R,
                  tabledata "IBLC/BLWI Transaction Code" = R,
                  tabledata "Manual VAT Correction" = R,
                  tabledata "Paym. Journal Batch" = R,
                  tabledata "Payment Journal Line" = R,
                  tabledata "Payment Journal Template" = R,
                  tabledata Representative = R,
                  tabledata "Transaction Coding" = R,
                  tabledata "VAT Summary Buffer" = R,
                  tabledata "VAT VIES Correction" = R;
}
