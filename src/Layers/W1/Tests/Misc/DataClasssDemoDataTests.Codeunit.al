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
        UnclassifiedFieldsErr: Label 'Field %1 of Table %2 has Data Sensitivity Unclassified';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDataSensitivities()
    var
        Company: Record Company;
        DataSensitivity: Record "Data Sensitivity";
        TableMetadata: Record "Table Metadata";
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
        AppsPendingDataClassification: List of [Guid];
    begin
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
        GetAppsPendingDataClassification(AppsPendingDataClassification);
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        DataSensitivity.SetFilter("Table No", '..101000|150000..160799|160803..');
        // Assert.RecordIsEmpty is not giving a helpful message
        if DataSensitivity.FindSet() then
            repeat
                TableMetadata.Get(DataSensitivity."Table No");
                if (TableMetadata.TableType <> TableMetadata.TableType::Temporary) then
                    if not IsTablePendingDataClassification(DataSensitivity."Table No", AppsPendingDataClassification) then
                        Error(UnclassifiedFieldsErr, DataSensitivity."Field No", DataSensitivity."Table No");
            until DataSensitivity.Next() = 0;

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
        AppIds.Add('d6636d6f-155e-4490-9979-ec323a6b7c81'); // Advance Payments Localization for Czech
        AppIds.Add('f12846ee-be97-4316-a5b3-ba789471687a'); // Advanced Localization Pack for Czech
        AppIds.Add('00155c68-8cdd-4d60-a451-2034ad094223'); // Agent Design Experience
        AppIds.Add('16319982-4995-4fb1-8fb2-2b1e13773e3b'); // AMC Banking 365 Fundamentals
        AppIds.Add('a41b0c3e-bf1c-4c97-ad1b-b430a3933ada'); // Audit File Export
        AppIds.Add('63c9fbe6-d4f3-458c-8c25-644c90a0874a'); // Bank Account Reconciliation With AI
        AppIds.Add('7a129d06-5fd6-4fb6-b82b-0bf539c779d0'); // Bank Deposits
        AppIds.Add('8730dafb-13cd-42c9-987c-decb6354269d'); // Banking Documents Localization for Czech
        AppIds.Add('f4e3d2c1-b0a9-4867-8765-432109876543'); // Business Central 14 Historical Data
        AppIds.Add('6992416f-3f39-4d3c-8242-3fff61350bea'); // Business Central Cloud Migration - Previous Release
        AppIds.Add('972624b9-849a-40cd-98b1-fd0924b0defe'); // Calculate Sustainability Emission with Copilot
        AppIds.Add('bc0899d1-2cc9-4091-93f8-032538dbb70f'); // Cash Desk Localization for Czech
        AppIds.Add('30828ce4-53e3-407f-ba80-13ce8d79d110'); // Ceridian Payroll
        AppIds.Add('8acb7e50-e2cb-4461-a546-6ca1100306f1'); // Charge Group Base
        AppIds.Add('c512d720-63b9-4b26-b062-a0c09b4ed322'); // Company Hub
        AppIds.Add('2078250c-40a0-40da-812a-8d635104dc80'); // Compensation Localization for Czech
        AppIds.Add('267b59d3-7302-44c5-ba77-c87000380514'); // Core Localization Pack for Czech
        AppIds.Add('daf22d93-ac7e-4a55-a3fc-fa6f5e8e7261'); // Customs Declaration Tracking for Russia
        AppIds.Add('7819d79d-feea-4f09-bbed-5bbaca4bf323'); // Data Archive
        AppIds.Add('ac14293f-1eb7-4a7b-9936-b280da31970b'); // Data Search
        AppIds.Add('adc18994-073b-4840-a144-2a5e3a0d9d1e'); // DIOT - Localization for Mexico
        AppIds.Add('73c6e046-a89d-484b-993b-5417088e42b9'); // Document Registration in Spain
        AppIds.Add('2363a2b7-1018-4976-a32a-c77338dc9f16'); // Dynamics 365 Business Central v14 Reimplementation
        AppIds.Add('cc11c22e-5ca3-423f-8804-88cac6d91983'); // Dynamics BC Excel Reports
        AppIds.Add('7c7d97ca-3598-40f5-b263-f713f49bd2a5'); // Dynamics GP Historical Data
        AppIds.Add('feeb3504-556e-4790-b28d-a2b9ce302d81'); // Dynamics GP Intelligent Cloud
        AppIds.Add('abe5dab1-9b38-44fc-a5f2-747ca8f4551e'); // Dynamics GP Intelligent Cloud - US
        AppIds.Add('4f3fe3fd-bdc4-4371-8579-d53820b93575'); // Dynamics SL Historical Data
        AppIds.Add('237981b4-9e3c-437c-9b92-988aae978e8f'); // Dynamics SL Migration
        AppIds.Add('40f34440-fcff-4601-a664-69ad316f4324'); // Dynamics SL Migration - US
        AppIds.Add('f35c56a6-7c5f-4dbe-89c4-fef5145d00f4'); // E-Document Connector - Avalara
        AppIds.Add('b4305a63-f987-425b-8520-ca9ccf7b22b6'); // E-Document Connector - B2Brouter
        AppIds.Add('31ef535a-1182-4354-98e8-e0e66a587055'); // E-Document Connector - Continia
        AppIds.Add('0addc017-80c4-40ad-bac6-5852f4fc4c55'); // E-Document Connector - FORNAV
        AppIds.Add('f4a198ad-cd8c-44bb-aff1-814e0e28ab79'); // E-Document Connector - Logiq
        AppIds.Add('d852a468-263e-49e5-bfda-f09e33342b89'); // E-Document Connector - Pagero
        AppIds.Add('b56171bd-9a8e-47ad-a527-99f476d5af83'); // E-Document Connector - SignUp
        AppIds.Add('de0dddf3-9917-430d-8d20-6e7679a08500'); // E-Document Core Demo Data
        AppIds.Add('64977288-facd-4b48-abaa-bb0e288edfb3'); // Electronic VAT Declaration for Denmark
        AppIds.Add('b0c41a2d-9ebe-4773-a22f-86bd69e75949'); // ELSTER VAT Localization for Germany
        AppIds.Add('e6328152-bb29-4664-9dae-3bc7eaae1fd8'); // Email - Outlook REST API
        AppIds.Add('68e13fa3-217a-4be0-9141-99e5bf0ca818'); // Email - SMTP Connector
        AppIds.Add('114e4e19-182b-42e2-b5a9-91d8b8ee8ce1'); // Email Logging Using Graph API
        AppIds.Add('e2ae191d-8829-44c3-a373-3749a2742d4e'); // Enforced Digital Vouchers
        AppIds.Add('e2743298-9ccb-49cd-9d8e-4b2d1ab91d36'); // Envestnet Yodlee Bank Feeds
        AppIds.Add('2a89f298-7ffd-44a5-a7ce-e08dac98abce'); // Essential Business Headlines
        AppIds.Add('a7bd3b4e-5469-4185-88b5-06745dd4c153'); // Excise Taxes
        AppIds.Add('c9ce86fe-cb70-4b79-be03-d21856b1a4ca'); // External File Storage - Azure Blob Service Connector
        AppIds.Add('79447b11-8301-4d02-a546-2261eb811296'); // External File Storage - Azure File Service Connector
        AppIds.Add('e0df20ef-75a2-4fae-8e3a-88140ab29507'); // External File Storage - SFTP Connector
        AppIds.Add('34bfcef7-f8ed-449f-94be-74024cadba3b'); // External File Storage - SharePoint Connector
        AppIds.Add('5f2e93a0-6083-4718-b05a-7ac89be5644d'); // External Storage - Document Attachments
        AppIds.Add('1150dd8d-51da-485a-bd4a-1ee98d78c21a'); // Fixed Asset Depreciation for India
        AppIds.Add('ef5dfe8c-ba1c-4271-8a86-95d5abdc6fe9'); // Fixed Asset Localization for Czech
        AppIds.Add('80672d74-d90a-4eb0-8f90-5b9bcea58dca'); // GovTalk
        AppIds.Add('e3cf5645-b42c-412a-ac9d-bd85793266e5'); // GST Base
        AppIds.Add('fbc443fd-02a7-4e4e-a697-883efe7bc33b'); // GST Distribution
        AppIds.Add('02256837-7459-45d9-8ff6-66cf4f517a0e'); // GST on Payments
        AppIds.Add('6f9d2a17-ea47-4289-8a4a-aa9551792530'); // GST Reconcilation
        AppIds.Add('1774437c-9f8f-4007-8ade-3459cead7e14'); // GST Return and Settlement
        AppIds.Add('1a03de13-ff11-4546-bdce-cde54edc82fe'); // GST Service Transfer
        AppIds.Add('dc030b4e-79f1-4b79-b694-556900859881'); // GST Stock Transfer
        AppIds.Add('55bb842b-34ef-48fe-9234-f39d858a3adb'); // GSTSubcontracting
        AppIds.Add('c62d3f56-16a4-484f-878a-330583985eeb'); // IdealPostcodes
        AppIds.Add('417e3995-43e5-46bd-ab72-1ca13df0658d'); // India Data Migration
        AppIds.Add('2dc39818-e0f0-42b6-99eb-ba29dc5f4102'); // India Gate Entry
        AppIds.Add('58623bfa-0559-4bc2-ae1c-0979c29fd9e0'); // Intelligent Cloud Base
        AppIds.Add('70912191-3c4c-49fc-a1de-bc6ea1ac9da6'); // Intrastat Core
        AppIds.Add('6cdf570a-47f0-4ee3-80b5-ae08e9e840e8'); // Intrastat CZ
        AppIds.Add('b696b4c9-637c-49d1-a806-763ff8f0a20e'); // IRS Forms
        AppIds.Add('cd6afb88-73aa-406f-a087-50a6149d5779'); // IS Core
        AppIds.Add('3d5b2137-efeb-4014-8489-41d37f8fd4c3'); // Late Payment Prediction
        AppIds.Add('38fa97fa-ebd1-4862-af24-77c4cee2c6ca'); // Making Tax Digital Localization for United Kingdom
        AppIds.Add('1b80b577-772f-4e0f-bc13-50214fb3da6e'); // Migration of QuickBooks Data
        AppIds.Add('d09fa965-9a2a-424d-b704-69f3b54ed0ce'); // Payment Links to PayPal
        AppIds.Add('24f54185-e697-4e03-bae0-f134f2d69673'); // Payment Management FR
        AppIds.Add('64977288-facd-4b48-aaaa-bb0e288edfb3'); // Payment Practices
        AppIds.Add('5f92e0d5-a60e-435f-ae85-71ec28dd3e41'); // PlanConfiguration
        AppIds.Add('e4e86220-cac0-4ec3-b853-7c2fa610399d'); // Power BI Report embeddings for Dynamics 365 Business Central
        AppIds.Add('98860128-1333-4598-a3da-0590804648b7'); // QR-Bill Management for Switzerland
        AppIds.Add('bc7b3891-f61b-4883-bbb3-384cdef88bec'); // Quality Management
        AppIds.Add('87990153-0e35-4e5d-ba61-2e93077d1699'); // Review General Ledger Entries
        AppIds.Add('4ce93371-6bd6-4027-a78f-021064ad250e'); // SAF-T
        AppIds.Add('fed2a629-3c57-4250-b2b7-f3c7a9c53cd5'); // SAF-T Modification DK
        AppIds.Add('c526b3e9-b8ca-4683-81ba-fcd5f6b1472a'); // Sales and Inventory Forecast
        AppIds.Add('8c972578-fe72-4aa5-ae51-cc5575fef2ea'); // Send To Email Printer
        AppIds.Add('ec255f57-31d0-4ca2-b751-f2fa7c745abb'); // Shopify Connector
        AppIds.Add('3d5fd255-4fb4-464b-9362-44cd85a883e7'); // Standard Audit File - Tax Localization for Norway
        AppIds.Add('ea130081-c669-460f-a5f4-5dde14f03131'); // Statistical Accounts
        AppIds.Add('1f32a50d-0057-4b95-b5df-cc04d7e89470'); // Subcontracting
        AppIds.Add('3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c'); // Subscription Billing
        AppIds.Add('8a3db2bc-9378-4d0f-b89a-a7dea0555449'); // Subscription Billing Demo Data
        AppIds.Add('b3780cd9-f8f8-4a83-a4d5-0c2ad87b28af'); // Sustainability
        AppIds.Add('fbb56a54-4f3b-4d2f-9330-ed8921ec4ec7'); // SyncBaseApp
        AppIds.Add('52cd6cb4-0433-4e94-8e62-9d12fff1a02b'); // Tax Engine Core
        AppIds.Add('d400443e-5a25-4eae-95dd-7891e382e068'); // Tax Engine Posting Handler
        AppIds.Add('0382879d-7e2a-46fd-bfd6-2672e3b9add4'); // Tax Engine Script Handler
        AppIds.Add('6557efcc-709a-40d9-bb71-526f2ba1a1e9'); // Tax Engine Tax Type Handler
        AppIds.Add('968ef3c8-1bbd-4cd1-83da-099bd66f11c5'); // Tax Engine Use Case Builder
        AppIds.Add('a34a9295-94ef-4c4c-b175-367e76e5dd99'); // TCS Base
        AppIds.Add('fa63fcf1-bc0a-42a5-8c87-92b63a81b6d4'); // TCS Return and Settlement
        AppIds.Add('c529ebd1-996f-4f1d-b0a4-f3e53256d5ad'); // TDS Base
        AppIds.Add('3147530a-3d75-43c7-b5e9-b28f0faa5a3a'); // TDS For Customer
        AppIds.Add('2ccd4f40-5cc3-495a-b7d5-1c3ca1448066'); // TDS Return and Settlement
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

