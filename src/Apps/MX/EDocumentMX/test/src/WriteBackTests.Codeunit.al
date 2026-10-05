// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;
using Microsoft.Sales.Customer;

codeunit 148753 "CFDI Write Back Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        CFDIWriteBack: Codeunit "CFDI Write-Back MX";

    [Test]
    procedure GetUUIDForUnstampedRecordReturnsEmptyValue()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] An unstamped record has no CFDI UUID
        Initialize();

        // [GIVEN] A record that is not an E-Document
        Customer.Insert(true);

        // [WHEN] The UUID is requested
        // [THEN] No UUID is returned
        Assert.AreEqual('', CFDIWriteBack.GetUUIDForDocument(Customer.RecordId()), 'An UUID was returned for an unstamped record.');
    end;

    [Test]
    procedure IsDocumentStampedReturnsFalseForUnstampedRecord()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] An unstamped record is not reported as stamped
        Initialize();

        // [GIVEN] A record that is not an E-Document
        Customer.Insert(true);

        // [WHEN] The stamped state is requested
        // [THEN] The record is not stamped
        Assert.IsFalse(CFDIWriteBack.IsDocumentStamped(Customer.RecordId()), 'An unstamped record was reported as stamped.');
    end;

    local procedure Initialize()
    begin
    end;
}
