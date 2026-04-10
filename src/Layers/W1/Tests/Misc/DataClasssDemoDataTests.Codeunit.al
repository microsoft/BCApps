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
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        DataSensitivity.SetFilter("Table No", '..101000|150000..160799|160803..');
        // Assert.RecordIsEmpty is not giving a helpful message
        if DataSensitivity.FindSet() then
            repeat
                TableMetadata.Get(DataSensitivity."Table No");
                if (TableMetadata.TableType <> TableMetadata.TableType::Temporary) then
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

