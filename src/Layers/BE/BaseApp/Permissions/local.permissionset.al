namespace System.Security.AccessControl;

using Microsoft.Bank.CODA;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Review;
using Microsoft.Finance.VAT.Reporting;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "CODA Statement" = RIMD,
                  tabledata "CODA Statement Line" = RIMD,
                  tabledata "CODA Statement Source Line" = RIMD,
                  tabledata "Domiciliation Journal Batch" = RIMD,
                  tabledata "Domiciliation Journal Line" = RIMD,
                  tabledata "Domiciliation Journal Template" = RIMD,
                  tabledata "Electronic Banking Setup" = RIMD,
                  tabledata "Export Check Error Log" = RIMD,
                  tabledata "Export Protocol" = RIMD,
                  tabledata "G/L Entry Application Buffer" = RIMD,
                  tabledata "IBLC/BLWI Transaction Code" = RIMD,
                  tabledata "Manual VAT Correction" = RIMD,
                  tabledata "Paym. Journal Batch" = RIMD,
                  tabledata "Payment Journal Line" = RIMD,
                  tabledata "Payment Journal Template" = RIMD,
                  tabledata Representative = RIMD,
                  tabledata "Transaction Coding" = RIMD,
                  tabledata "VAT Summary Buffer" = RIMD,
                  tabledata "VAT VIES Correction" = RIMD;
}
