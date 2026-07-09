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
        AppIds.Add('7819d79d-feea-4f09-bbed-5bbaca4bf323'); // Data Archive
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

