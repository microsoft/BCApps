namespace Microsoft.SubscriptionBilling;

interface "Usage Data Processing"
{
    /// <summary>
    /// Import usage data into the connector-specific staging table (e.g. via Data Exchange Definition or API).
    /// </summary>
    /// <param name="UsageDataImport">Usage Data Import for which the import is executed</param>
    procedure ImportUsageData(var UsageDataImport: Record "Usage Data Import")

    /// <summary>
    /// Process imported records in the connector-specific staging table:
    /// 1. Create Usage Data Supp. Customers if they do not exist.
    /// 2. Create Usage Data Supp. Subscriptions if they do not exist.
    /// 3. Validate Subscription Lines and check their dates.
    /// 4. Assign the Subscription to the staging table record if possible.
    /// </summary>
    /// <param name="UsageDataImport">Usage Data Import for which the processing is executed</param>
    procedure ProcessUsageData(var UsageDataImport: Record "Usage Data Import")

    /// <summary>
    /// Validate that imported staging data exists before Usage Data Billing creation.
    /// Set an error on the Usage Data Import if no staging data is found.
    /// </summary>
    /// <param name="UsageDataImport">Usage Data Import to validate</param>
    procedure ValidateImportedData(var UsageDataImport: Record "Usage Data Import");

    /// <summary>
    /// Create Usage Data Billing records from the connector-specific staging table.
    /// Handle retry logic for previously failed staging records.
    /// </summary>
    /// <param name="UsageDataImport">Usage Data Import for which billing records are created</param>
    procedure CreateBillingData(var UsageDataImport: Record "Usage Data Import");

    /// <summary>
    /// Check the connector-specific staging table for errors after billing creation
    /// and set the Usage Data Import status accordingly.
    /// </summary>
    /// <param name="UsageDataImport">Usage Data Import to update with error status</param>
    procedure UpdateImportStatus(var UsageDataImport: Record "Usage Data Import");

    /// <summary>
    /// Delete all connector-specific staging table records for a given Usage Data Import.
    /// Called when the Usage Data Import is deleted or reset.
    /// </summary>
    /// <param name="UsageDataImport">Usage Data Import whose staging data should be deleted</param>
    procedure DeleteImportedData(var UsageDataImport: Record "Usage Data Import");

    /// <summary>
    /// Update the Subscription Header No. in the connector-specific staging table
    /// when a Supplier Subscription is connected to a Subscription.
    /// </summary>
    /// <param name="SupplierReference">Supplier Reference identifying the subscription in the staging table</param>
    /// <param name="SubscriptionHeaderNo">Subscription Header No. to assign to matching staging records</param>
    procedure UpdateSubscriptionHeaderNo(SupplierReference: Text[80]; SubscriptionHeaderNo: Code[20]);
}
