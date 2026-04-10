namespace Microsoft.API.Upgrade;

codeunit 5523 "API Fix Document Shortcut Dim."
{
    trigger OnRun()
    begin
        UpgradeSalesInvoiceShortcutDimension();
        UpgradePurchInvoiceShortcutDimension();
        UpgradePurchaseOrderShortcutDimension();
        UpgradeSalesOrderShortcutDimension();
        UpgradeSalesQuoteShortcutDimension();
        UpgradeSalesCrMemoShortcutDimension();
    end;

    var
        APIDataUpgrade: Codeunit "API Data Upgrade";

    procedure UpgradeSalesInvoiceShortcutDimension()
    begin
        APIDataUpgrade.UpgradeSalesInvoiceShortcutDimension(false);
    end;

    procedure UpgradePurchInvoiceShortcutDimension()
    begin
        APIDataUpgrade.UpgradePurchInvoiceShortcutDimension(false);
    end;

    procedure UpgradePurchaseOrderShortcutDimension()
    begin
        APIDataUpgrade.UpgradePurchaseOrderShortcutDimension(false);
    end;

    procedure UpgradeSalesOrderShortcutDimension()
    begin
        APIDataUpgrade.UpgradeSalesOrderShortcutDimension(false);
    end;

    procedure UpgradeSalesQuoteShortcutDimension()
    begin
        APIDataUpgrade.UpgradeSalesQuoteShortcutDimension(false);
    end;

    procedure UpgradeSalesCrMemoShortcutDimension()
    begin
        APIDataUpgrade.UpgradeSalesCrMemoShortcutDimension(false);
    end;
}