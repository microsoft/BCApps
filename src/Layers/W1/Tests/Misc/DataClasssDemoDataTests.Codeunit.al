codeunit 135153 "Data Classs Demo Data Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Classification]
    end;

    var
        Assert: Codeunit Assert;
        UnclassifiedFieldsErr: Label 'The following tables have fields with Data Sensitivity Unclassified. Classify them (e.g. via Codeunit "Data Classification Eval. Data" or a subscriber to OnCreateEvaluationDataOnAfterClassifyTablesToNormal), or add the owning app to GetAppsPendingDataClassification:\%1', Comment = '%1 = a multi-line list of tables and their unclassified fields';
        TableLineTxt: Label 'Table %1 "%2": %3 unclassified field(s): %4', Comment = '%1 = table no., %2 = table name, %3 = count of unclassified fields, %4 = comma-separated list of field numbers';
        MoreFieldsTxt: Label '%1, (+%2 more)', Comment = '%1 = the first field numbers, %2 = count of remaining unclassified fields not listed';
        MoreTablesTxt: Label '...and %1 more table(s).', Comment = '%1 = count of remaining unclassified tables not listed';
        MaxTablesInMessage: Integer;
        MaxFieldsPerTable: Integer;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDataSensitivities()
    var
        Company: Record Company;
        DataSensitivity: Record "Data Sensitivity";
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
        AppsPendingDataClassification: List of [Guid];
        UnclassifiedTablesMessage: Text;
    begin
        MaxTablesInMessage := 100;
        MaxFieldsPerTable := 20;

        // [SCENARIO] All shipped fields should have a classification
        // [SCENARIO] EUII EUPI fields are classified as Personal
        // [SCENARIO] Master Tables contain Personal fields
        // [SCENARIO] Documents and Document Lines Contain Personal Fields
        // If this test fails, you should make sure that your fields are correctly classified in <App\Layers\W1\BaseApp\DataClassificationEvalData.Codeunit.al>.
        // [GIVEN] DataSensitivity Table is empty
        DataSensitivity.DeleteAll();

        Company.Get(CompanyName);
        Company."Evaluation Company" := true;
        Company.Modify();

        // [WHEN] The evaluation data are created
        DataClassificationEvalData.CreateEvaluationData();

        // [THEN] All shipped fields should have a classification
        // Apps listed in GetAppsPendingDataClassification are temporarily exempted while their
        // fields are being classified. New apps/tables not on that list are still enforced.
        // All offending tables/fields are collected and reported together so a single run lists
        // everything that needs classifying, instead of failing on the first field.
        GetAppsPendingDataClassification(AppsPendingDataClassification);
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        DataSensitivity.SetFilter("Table No", '..101000|150000..160799|160803..');
        CollectUnclassifiedFields(DataSensitivity, AppsPendingDataClassification, UnclassifiedTablesMessage);
        if UnclassifiedTablesMessage <> '' then
            Error(UnclassifiedFieldsErr, UnclassifiedTablesMessage);

        // [THEN] EUII EUPI fields are classified as Personal
        DataSensitivity.SetFilter("Data Classification", StrSubstNo('%1|%2',
            DataSensitivity."Data Classification"::EndUserIdentifiableInformation,
            DataSensitivity."Data Classification"::EndUserPseudonymousIdentifiers));
        DataSensitivity.SetFilter("Data Sensitivity", StrSubstNo('<>%1', DataSensitivity."Data Sensitivity"::Personal));
        Assert.RecordIsEmpty(DataSensitivity);

        // [THEN] Master Tables contain Personal fields
        // [THEN] Documents and Document Lines Contain Personal Fields
        VerifySensitivitiesForMasterTablesAndDocuments();
    end;

    local procedure CollectUnclassifiedFields(var DataSensitivity: Record "Data Sensitivity"; AppsPendingDataClassification: List of [Guid]; var Message: Text)
    var
        TableMetadata: Record "Table Metadata";
        FieldsForTable: Text;
        FieldCount: Integer;
        TableCount: Integer;
        LastTableNo: Integer;
        CurrentTableName: Text;
        Reporting: Boolean;
    begin
        // Walk the (already ordered by Table No, Field No) unclassified rows, grouping by table.
        // For each offending table we emit one line listing its unclassified field numbers, so a
        // single run reports every table/field that still needs classifying. Each table is only
        // evaluated once (when its first row is seen), not per field.
        if not DataSensitivity.FindSet() then
            exit;

        repeat
            if DataSensitivity."Table No" <> LastTableNo then begin
                // Table boundary: flush the previous table, then decide whether to report the new one.
                if Reporting then
                    AppendTableLine(Message, TableCount, LastTableNo, CurrentTableName, FieldsForTable, FieldCount);

                LastTableNo := DataSensitivity."Table No";
                FieldsForTable := '';
                FieldCount := 0;
                Reporting :=
                    TableMetadata.Get(DataSensitivity."Table No") and
                    (TableMetadata.TableType <> TableMetadata.TableType::Temporary) and
                    (not IsTablePendingDataClassification(DataSensitivity."Table No", AppsPendingDataClassification));
                if Reporting then
                    CurrentTableName := TableMetadata.Name;
            end;

            if Reporting then begin
                FieldCount += 1;
                if FieldCount <= MaxFieldsPerTable then
                    if FieldsForTable = '' then
                        FieldsForTable := StrSubstNo('field %1', DataSensitivity."Field No")
                    else
                        FieldsForTable += StrSubstNo(', field %1', DataSensitivity."Field No");
            end;
        until DataSensitivity.Next() = 0;

        // Flush the final table.
        if Reporting then
            AppendTableLine(Message, TableCount, LastTableNo, CurrentTableName, FieldsForTable, FieldCount);

        if TableCount > MaxTablesInMessage then
            Message += '\' + StrSubstNo(MoreTablesTxt, TableCount - MaxTablesInMessage);
    end;

    local procedure AppendTableLine(var Message: Text; var TableCount: Integer; TableNo: Integer; TableName: Text; FieldsForTable: Text; FieldCount: Integer)
    var
        FieldsText: Text;
    begin
        TableCount += 1;
        if TableCount > MaxTablesInMessage then
            exit;

        FieldsText := FieldsForTable;
        if FieldCount > MaxFieldsPerTable then
            FieldsText := StrSubstNo(MoreFieldsTxt, FieldsForTable, FieldCount - MaxFieldsPerTable);

        if Message <> '' then
            Message += '\';
        Message += StrSubstNo(TableLineTxt, TableNo, TableName, FieldCount, FieldsText);
    end;

    local procedure IsTablePendingDataClassification(TableNo: Integer; AppsPendingDataClassification: List of [Guid]): Boolean
    var
        AllObj: Record AllObj;
        NAVAppInstalledApp: Record "NAV App Installed App";
    begin
        // Resolve the app that owns the table and check whether that app is temporarily
        // exempted from the classification check while its fields are being classified.
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableNo);
        if not AllObj.FindFirst() then
            exit(false);
        if IsNullGuid(AllObj."App Package ID") then
            exit(false);
        NAVAppInstalledApp.SetRange("Package ID", AllObj."App Package ID");
        if not NAVAppInstalledApp.FindFirst() then
            exit(false);
        exit(AppsPendingDataClassification.Contains(NAVAppInstalledApp."App ID"));
    end;

    local procedure GetAppsPendingDataClassification(var AppIds: List of [Guid])
    begin
        // These apps ship fields whose Data Sensitivity is still Unclassified. Each app must
        // classify its fields (subscribe to Codeunit "Data Classification Eval. Data".
        // OnCreateEvaluationDataOnAfterClassifyTablesToNormal, or classify via the country
        // codeunit) and then be removed from this list, which must eventually reach zero.
        AppIds.Add('7a129d06-5fd6-4fb6-b82b-0bf539c779d0'); // _Exclude_Bank Deposits
        AppIds.Add('114e4e19-182b-42e2-b5a9-91d8b8ee8ce1'); // _Exclude_Email Logging Using Graph API
        AppIds.Add('a01864f8-9c3f-42f6-8328-8d7be1ce3e20'); // _Exclude_Master_Data_Management
        AppIds.Add('00155c68-8cdd-4d60-a451-2034ad094223'); // Agent Design Experience
        AppIds.Add('16319982-4995-4fb1-8fb2-2b1e13773e3b'); // AMC Banking 365 Fundamentals
        AppIds.Add('a41b0c3e-bf1c-4c97-ad1b-b430a3933ada'); // Audit File Export
        AppIds.Add('639580c8-7356-11ed-a1eb-0242ac120002'); // Automatic Account Codes
        AppIds.Add('63c9fbe6-d4f3-458c-8c25-644c90a0874a'); // Bank Account Reconciliation With AI
        AppIds.Add('f4e3d2c1-b0a9-4867-8765-432109876543'); // Business Central 14 Historical Data
        AppIds.Add('3d5b2137-eeeb-4014-8489-41d37f8fd4c3'); // C5 2012 Data Migration
        AppIds.Add('972624b9-849a-40cd-98b1-fd0924b0defe'); // Calculate Sustainability Emission with Copilot
        AppIds.Add('30828ce4-53e3-407f-ba80-13ce8d79d110'); // Ceridian Payroll
        AppIds.Add('c512d720-63b9-4b26-b062-a0c09b4ed322'); // Company Hub
        AppIds.Add('5a0b41e9-7a42-4123-d521-2265186cfb31'); // Contoso Coffee Demo Dataset
        AppIds.Add('7819d79d-feea-4f09-bbed-5bbaca4bf323'); // Data Archive
        AppIds.Add('ac14293f-1eb7-4a7b-9936-b280da31970b'); // Data Search
        AppIds.Add('2363a2b7-1018-4976-a32a-c77338dc9f16'); // Dynamics 365 Business Central v14 Reimplementation
        AppIds.Add('cc11c22e-5ca3-423f-8804-88cac6d91983'); // Dynamics BC Excel Reports
        AppIds.Add('7c7d97ca-3598-40f5-b263-f713f49bd2a5'); // Dynamics GP Historical Data
        AppIds.Add('feeb3504-556e-4790-b28d-a2b9ce302d81'); // Dynamics GP Intelligent Cloud
        AppIds.Add('abe5dab1-9b38-44fc-a5f2-747ca8f4551e'); // Dynamics GP Intelligent Cloud - US
        AppIds.Add('4f3fe3fd-bdc4-4371-8579-d53820b93575'); // Dynamics SL Historical Data
        AppIds.Add('237981b4-9e3c-437c-9b92-988aae978e8f'); // Dynamics SL Migration
        AppIds.Add('40f34440-fcff-4601-a664-69ad316f4324'); // Dynamics SL Migration - US
        AppIds.Add('e1d97edc-c239-46b4-8d84-6368bdf67c8b'); // E-Document Core
        AppIds.Add('de0dddf3-9917-430d-8d20-6e7679a08500'); // E-Document Core Demo Data
        AppIds.Add('e6328152-bb29-4664-9dae-3bc7eaae1fd8'); // Email - Outlook REST API
        AppIds.Add('68e13fa3-217a-4be0-9141-99e5bf0ca818'); // Email - SMTP Connector
        AppIds.Add('e2ae191d-8829-44c3-a373-3749a2742d4e'); // Enforced Digital Vouchers
        AppIds.Add('e2743298-9ccb-49cd-9d8e-4b2d1ab91d36'); // Envestnet Yodlee Bank Feeds
        AppIds.Add('2a89f298-7ffd-44a5-a7ce-e08dac98abce'); // Essential Business Headlines
        AppIds.Add('a7bd3b4e-5469-4185-88b5-06745dd4c153'); // Excise Taxes
        AppIds.Add('c9ce86fe-cb70-4b79-be03-d21856b1a4ca'); // External File Storage - Azure Blob Service Connector
        AppIds.Add('79447b11-8301-4d02-a546-2261eb811296'); // External File Storage - Azure File Service Connector
        AppIds.Add('e0df20ef-75a2-4fae-8e3a-88140ab29507'); // External File Storage - SFTP Connector
        AppIds.Add('34bfcef7-f8ed-449f-94be-74024cadba3b'); // External File Storage - SharePoint Connector
        AppIds.Add('5f2e93a0-6083-4718-b05a-7ac89be5644d'); // External Storage - Document Attachments
        AppIds.Add('e868ad92-21b8-4e08-af2b-8975a8b06e04'); // Image Analyzer
        AppIds.Add('58623bfa-0559-4bc2-ae1c-0979c29fd9e0'); // Intelligent Cloud Base
        AppIds.Add('70912191-3c4c-49fc-a1de-bc6ea1ac9da6'); // Intrastat Core
        AppIds.Add('bf7682b0-67b3-44de-a1e6-676ceb3b05ca'); // IRS 1096
        AppIds.Add('b696b4c9-637c-49d1-a806-763ff8f0a20e'); // IRS Forms
        AppIds.Add('3d5b2137-efeb-4014-8489-41d37f8fd4c3'); // Late Payment Prediction
        AppIds.Add('1b80b577-772f-4e0f-bc13-50214fb3da6e'); // Migration of QuickBooks Data
        AppIds.Add('d09fa965-9a2a-424d-b704-69f3b54ed0ce'); // Payment Links to PayPal
        AppIds.Add('64977288-facd-4b48-aaaa-bb0e288edfb3'); // Payment Practices
        AppIds.Add('e4e86220-cac0-4ec3-b853-7c2fa610399d'); // Power BI Report embeddings for Dynamics 365 Business Central
        AppIds.Add('bc7b3891-f61b-4883-bbb3-384cdef88bec'); // Quality Management
        AppIds.Add('87990153-0e35-4e5d-ba61-2e93077d1699'); // Review General Ledger Entries
        AppIds.Add('4ce93371-6bd6-4027-a78f-021064ad250e'); // SAF-T
        AppIds.Add('c526b3e9-b8ca-4683-81ba-fcd5f6b1472a'); // Sales and Inventory Forecast
        AppIds.Add('dd3f226b-40bf-4b3c-9988-9b1e0f74edd8'); // Sales Lines Suggestions
        AppIds.Add('8c972578-fe72-4aa5-ae51-cc5575fef2ea'); // Send To Email Printer
        AppIds.Add('e2ae191d-8829-44c3-a373-3749a2742d4d'); // Service Declaration
        AppIds.Add('ec255f57-31d0-4ca2-b751-f2fa7c745abb'); // Shopify Connector
        AppIds.Add('a98932e6-0fbc-4f74-a39b-f159b068d424'); // Standard Import Export (SIE)
        AppIds.Add('ea130081-c669-460f-a5f4-5dde14f03131'); // Statistical Accounts
        AppIds.Add('3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c'); // Subscription Billing
        AppIds.Add('8a3db2bc-9378-4d0f-b89a-a7dea0555449'); // Subscription Billing Demo Data
        AppIds.Add('b3780cd9-f8f8-4a83-a4d5-0c2ad87b28af'); // Sustainability
        AppIds.Add('7961e9dc-a8e5-49b1-839b-3a78803a4cb8'); // Troubleshoot FA Ledger Entries
        AppIds.Add('2654d7e7-9afd-4947-9e02-6bb8f3e0cd04'); // Universal Print Integration
        AppIds.Add('c50a4bf0-db51-4ad2-88d5-fe2287da0eb8'); // VAT Group Management
        AppIds.Add('c31ee575-3fc7-4388-98ee-d75aa2fc5f87'); // Withholding Tax
    end;

    local procedure VerifySensitivitiesForMasterTablesAndDocuments()
    var
        DataSensitivity: Record "Data Sensitivity";
    begin
        DataSensitivity.SetRange("Company Name", CompanyName);
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Personal);
        DataSensitivity.SetRange("Table No", DATABASE::Customer);
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::Vendor);
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::User);
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::Resource);
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Salesperson/Purchaser");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::Contact);
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::Employee);
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Reminder Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Issued Reminder Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Finance Charge Memo Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Issued Fin. Charge Memo Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Salesperson/Purchaser");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purchase Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Shipment Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Invoice Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Cr.Memo Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purch. Rcpt. Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purch. Inv. Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purch. Cr. Memo Hdr.");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Header Archive");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purchase Header Archive");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Shipment Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Invoice Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Cr.Memo Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Return Shipment Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Return Receipt Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Filed Service Contract Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"IC Outbox Sales Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Handled IC Outbox Sales Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"IC Inbox Sales Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Contract Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Header Archive");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"IC Outbox Purchase Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Handled IC Outbox Purch. Hdr");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"IC Inbox Purchase Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Handled IC Inbox Purch. Header");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Invoice Entity Aggregate");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Order Entity Buffer");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purch. Inv. Entity Aggregate");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Shipment Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Invoice Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Cr.Memo Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purch. Rcpt. Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purch. Inv. Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purch. Cr. Memo Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Sales Line Archive");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Purchase Line Archive");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Shipment Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Invoice Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Cr.Memo Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Service Line Archive");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Return Shipment Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Return Receipt Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Segment Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Bank Acc. Reconciliation Line");
        Assert.RecordIsNotEmpty(DataSensitivity);

        DataSensitivity.SetRange("Table No", DATABASE::"Posted Payment Recon. Line");
        Assert.RecordIsNotEmpty(DataSensitivity);
    end;
}

