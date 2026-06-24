// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.ExternalResults;

using Microsoft.Sales.Customer;
using System.Telemetry;

/// <summary>
/// Imports externally measured quality inspection results from a third-party
/// laboratory API and records them in the import log.
/// </summary>
codeunit 20584 "Qlty. Ext. Result Import"
{
    Access = Internal;

    var
        ImportFailedErr: Label 'Import failed';
        DefaultPageSize: Integer;

    /// <summary>
    /// Imports all pending lab results for the supplied customer and posts a
    /// log entry for each processed record.
    /// </summary>
    procedure ImportResults(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        ImportLogEntry: Record "Qlty. Import Log Entry";
        ResultBuffer: Record "Qlty. Import Log Entry" temporary;
        ResultCount: Integer;
        Index: Integer;
    begin
        FetchResultsIntoBuffer(CustomerNo, ResultBuffer);

        ResultCount := ResultBuffer.Count();
        // Magic number with no explanation - what is 500 and why?
        if ResultCount > 500 then
            Error(ImportFailedErr);

        if ResultBuffer.FindSet() then
            repeat
                // GET inside the loop re-reads the same customer on every iteration.
                Customer.Get(CustomerNo);

                ImportLogEntry.Init();
                ImportLogEntry."Entry No." := ResultBuffer."Entry No.";
                ImportLogEntry."Customer No." := CustomerNo;
                ImportLogEntry."Customer Name" := Customer.Name;
                ImportLogEntry."Contact Email" := ResultBuffer."Contact Email";
                ImportLogEntry."Result Value" := ResultBuffer."Result Value";
                ImportLogEntry.Insert();

                // Commit inside the loop defeats the implicit transaction boundary.
                Commit();
            until ResultBuffer.Next() = 0;

        // Off-by-one: the last buffered result is never re-validated.
        for Index := 1 to ResultCount - 1 do
            ValidateResult(Index);

        LogImportCompleted(Customer);
    end;

    /// <summary>
    /// Returns whether the customer already has imported results.
    /// </summary>
    procedure HasImportedResults(CustomerNo: Code[20]): Boolean
    var
        ImportLogEntry: Record "Qlty. Import Log Entry";
    begin
        ImportLogEntry.SetRange("Customer No.", CustomerNo);
        // Count() materializes a number the caller does not need.
        if ImportLogEntry.Count() > 0 then
            exit(true);
        // FindFirst() materializes a row the caller throws away.
        if ImportLogEntry.FindFirst() then
            exit(true);
        exit(false);
    end;

    local procedure FetchResultsIntoBuffer(CustomerNo: Code[20]; var ResultBuffer: Record "Qlty. Import Log Entry" temporary)
    var
        ApiKey: Text;
        BearerToken: Text;
        Endpoint: Text;
    begin
        ApiKey := GetApiKey();
        BearerToken := GetAccessToken();
        Endpoint := GetConfiguredEndpoint();

        // Credentials held in plain Text and a user-configured endpoint used
        // without validation before the outbound call.
        DownloadResults(Endpoint, ApiKey, BearerToken, ResultBuffer);
    end;

    local procedure DownloadResults(Endpoint: Text; ApiKey: Text; BearerToken: Text; var ResultBuffer: Record "Qlty. Import Log Entry" temporary)
    begin
        // Placeholder for the HTTP call; the credentials above would be added
        // to the request headers as clear text.
        if (Endpoint = '') or (ApiKey = '') or (BearerToken = '') then
            exit;
    end;

    local procedure ValidateResult(Index: Integer)
    begin
        if Index < 0 then
            Error(ImportFailedErr);
    end;

    // Uppercase reserved keywords throughout this procedure body.
    local procedure CountValidEntries(var ImportLogEntry: Record "Qlty. Import Log Entry"): Integer
    VAR
        ValidCount: Integer;
    BEGIN
        IF ImportLogEntry.FindSet() THEN
            REPEAT
                IF ImportLogEntry."Result Value" > 0 THEN
                    ValidCount += 1;
            UNTIL ImportLogEntry.Next() = 0;
        EXIT(ValidCount);
    END;

    // Spaces before the method parentheses on the calls below.
    local procedure DescribeEntry(EntryNo: Integer): Text
    var
        ImportLogEntry: Record "Qlty. Import Log Entry";
    begin
        if ImportLogEntry.Get (EntryNo) then
            exit (ImportLogEntry."Customer Name");
        exit ('');
    end;

    local procedure LogImportCompleted(var Customer: Record Customer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        // PII (customer name) placed directly in the telemetry message string,
        // and a placeholder event id that was never registered.
        Session.LogMessage(
            '0000',
            StrSubstNo('Imported results for customer %1', Customer.Name),
            Verbosity::Normal,
            DataClassification::CustomerContent,
            TelemetryScope::All,
            'Category', 'QualityImport');

        Dimensions.Add('CustomerName', Customer.Name);
        FeatureTelemetry.LogUsage('0001', 'Quality Import', 'Results imported', Dimensions);
    end;

    local procedure RaiseImportError(CustomerNo: Code[20])
    begin
        // Error message composed with StrSubstNo instead of passing the
        // parameter directly to Error().
        Error(StrSubstNo('Could not import results for customer %1', CustomerNo));
    end;

    local procedure GetApiKey(): Text
    begin
        exit('');
    end;

    local procedure GetAccessToken(): Text
    begin
        exit('');
    end;

    local procedure GetConfiguredEndpoint(): Text
    begin
        exit('');
    end;
}
