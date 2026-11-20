// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Purchases.Vendor;

codeunit 148018 "IRS 1099 API Tests"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = Uncategorized;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        TempOwnedDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempOwnedReportingPeriod: Record "IRS Reporting Period" temporary;
        TempOwnedVendor: Record Vendor temporary;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryIRS1099Document: Codeunit "Library IRS 1099 Document";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        OriginalWorkDate: Date;
        IsInitialized: Boolean;
        IRS1099DocumentsServiceNameLbl: Label 'irs1099documents';
        SupplementalServiceNameLbl: Label 'irs1099documentsupplementallines', Locked = true;

    [Test]
    procedure SupplementalAPIExposesExcludedStoredValuesAndNavigation()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OtherDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        ResponseText: Text;
        DocumentJson: Text;
        LineJson: Text;
        Url: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Stored excluded disclosures are separate from financial income and scoped to their document.
        Initialize();

        // [GIVEN] D has excluded income 500, stored tips 100 and text codes; another document has no disclosures.
        CreateSupplementalAPIFixture(DocHeader, ParentDocLine, TipsSupplLine, CodesSupplLine, 100);
        CreateAPIDocument(OtherDocHeader);
        Commit();

        // [WHEN] D is expanded and its child navigation is read.
        Url := LibraryGraphMgt.CreateTargetURL(Format(DocHeader.SystemId), Page::"IRS 1099 Documents API", IRS1099DocumentsServiceNameLbl);
        LibraryGraphMgt.GetFromWebService(ResponseText,
            LibraryGraphMgt.AppendQueryParameterToTargetURL(Url, '$expand=irs1099documentlines,irs1099documentsupplementallines'));

        // [THEN] Financial income remains 500, and excluded supplemental values retain their types.
        DocumentJson := ResponseText;
        Assert.IsTrue(LibraryGraphMgt.GetObjectFromJSONResponseByName(DocumentJson, 'irs1099documentlines', LineJson, 1), 'Financial line is missing.');
        LibraryGraphMgt.VerifyPropertyInJSON(LineJson, 'amount', '500');
        LibraryGraphMgt.VerifyPropertyInJSON(LineJson, 'includeIn1099', 'False');
        VerifySupplementalCollection(ResponseText, DocHeader.ID, TipsSupplLine, CodesSupplLine, true);
        Clear(ResponseText);
        LibraryGraphMgt.GetFromWebService(ResponseText, LibraryGraphMgt.AppendPathToTargetURL(Url, '/' + SupplementalServiceNameLbl));
        VerifySupplementalCollection(ResponseText, DocHeader.ID, TipsSupplLine, CodesSupplLine, false);
        Url := LibraryGraphMgt.CreateTargetURL(Format(OtherDocHeader.SystemId), Page::"IRS 1099 Documents API", IRS1099DocumentsServiceNameLbl);
        Clear(ResponseText);
        LibraryGraphMgt.GetFromWebService(ResponseText, LibraryGraphMgt.AppendPathToTargetURL(Url, '/' + SupplementalServiceNameLbl));
        VerifyEmptyCollection(ResponseText);
        ParentDocLine.SetRange("Document ID", DocHeader.ID);
        Assert.RecordCount(ParentDocLine, 1);
        Cleanup();
    end;

    [Test]
    procedure SupplementalAPIRetainsZeroTipCodes()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        ResponseText: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Zero-tip codes remain stored API data, not a transmitted-value projection.
        Initialize();

        // [GIVEN] D retains occupation codes after its tips are cleared.
        CreateSupplementalAPIFixture(DocHeader, ParentDocLine, TipsSupplLine, CodesSupplLine, 0);
        Commit();

        // [WHEN] The code row is read directly using SystemId.
        LibraryGraphMgt.GetFromWebService(ResponseText,
            LibraryGraphMgt.CreateTargetURL(Format(CodesSupplLine.SystemId), Page::"IRS 1099 Doc. Suppl. API", SupplementalServiceNameLbl));

        // [THEN] Both text codes, including 000, are returned without reporting filtering.
        VerifySupplementalValue(ResponseText, CodesSupplLine);
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplLine), 'Stored API codes must not imply reportability.');
        Cleanup();
    end;

    [Test]
    procedure SupplementalAPIPreservesFractionalAmountsAfterStatement()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        StatementLine: Record "IRS 1099 Form Statement Line";
        Lines: JsonArray;
        ResponseText: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Statement-only cent projection never changes fractional amounts or code text exposed by the API.
        Initialize();

        // [GIVEN] D has eligible fractional tips and an explicit tip/code statement selection.
        CreateSupplementalAPIFixture(DocHeader, ParentDocLine, TipsSupplLine, CodesSupplLine, 0.004);
        ParentDocLine.Validate(Amount, 5000);
        ParentDocLine.Modify(true);
        StatementLine."Period No." := DocHeader."Period No.";
        StatementLine."Form No." := DocHeader."Form No.";
        StatementLine."Line No." := 10000;
        StatementLine."Value Source" := StatementLine."Value Source"::"Supplemental Line";
        StatementLine.Validate("Supplemental Box No.", 'NEC-01B');
        StatementLine.Insert(true);
        StatementLine."Line No." := 20000;
        StatementLine.Validate("Supplemental Box No.", 'NEC-01C');
        StatementLine.Insert(true);

        // [WHEN] The statement projection is generated and the stored tip row is read through the API.
        Lines := LibraryIRS1099Document.GetStatementDataset(DocHeader);
        Commit();
        LibraryGraphMgt.GetFromWebService(ResponseText,
            LibraryGraphMgt.CreateTargetURL(Format(TipsSupplLine.SystemId), Page::"IRS 1099 Doc. Suppl. API", SupplementalServiceNameLbl));

        // [THEN] Only the amount is projected into the statement, but the API retains the raw decimal.
        Assert.AreEqual(1, Lines.Count(), 'Rounded-zero tips suppress the statement codes, not the positive raw amount row.');
        VerifySupplementalValue(ResponseText, TipsSupplLine);
        TipsSupplLine.Get(DocHeader.ID, 'NEC-01B');
        Assert.AreEqual(0.004, TipsSupplLine.Amount, 'Statement rendering must preserve stored/API precision.');
        Clear(ResponseText);
        LibraryGraphMgt.GetFromWebService(ResponseText,
            LibraryGraphMgt.CreateTargetURL(Format(CodesSupplLine.SystemId), Page::"IRS 1099 Doc. Suppl. API", SupplementalServiceNameLbl));
        VerifySupplementalValue(ResponseText, CodesSupplLine);
        Cleanup();
    end;

    [Test]
    procedure SupplementalAPIRejectsAllWrites()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        ResponseText: Text;
        Url: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Supplemental API writes cannot bypass document validation even while Open.
        Initialize();

        // [GIVEN] An Open document D with saved disclosures.
        CreateSupplementalAPIFixture(DocHeader, ParentDocLine, TipsSupplLine, CodesSupplLine, 100);
        Commit();
        Url := LibraryGraphMgt.CreateTargetURL(Format(TipsSupplLine.SystemId), Page::"IRS 1099 Doc. Suppl. API", SupplementalServiceNameLbl);

        // [WHEN] POST, PATCH and DELETE are attempted.
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            LibraryGraphMgt.CreateTargetURL('', Page::"IRS 1099 Doc. Suppl. API", SupplementalServiceNameLbl),
            '{"amount":50}', ResponseText, 405);
        Assert.ExpectedError('405 (MethodNotAllowed).');
        Assert.ExpectedError('Entity does not support insert.');
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(Url, '{"amount":50}', ResponseText, 405);
        Assert.ExpectedError('405 (MethodNotAllowed).');
        Assert.ExpectedError('Entity does not support modifying data.');
        asserterror LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(Url, '', ResponseText, 400);
        Assert.ExpectedError('400 (BadRequest).');
        Assert.ExpectedError('Entity does not support delete.');

        // [THEN] Neither the stored amounts nor the row count changed.
        TipsSupplLine.Get(DocHeader.ID, 'NEC-01B');
        Assert.AreEqual(100, TipsSupplLine.Amount, 'Rejected writes changed stored tips.');
        TipsSupplLine.SetRange("Document ID", DocHeader.ID);
        Assert.RecordCount(TipsSupplLine, 2);
        Cleanup();
    end;

    [Test]
    procedure IRS1099DocumentsAPISunshine()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormReport: Record "IRS 1099 Form Report";
        ResponseText: Text;
    begin
        // [SCENARIO 497835] 
        Initialize();
        CreateAPIDocument(IRS1099FormDocHeader);
        // [GIVEN]
        MockIRS1099FormDocWithLineAndFormReport(IRS1099FormDocHeader, IRS1099FormDocLine, IRS1099FormReport);
        Commit();
        // [WHEN] Call the API
        LibraryGraphMgt.GetFromWebService(ResponseText, GetIRS1099DocumentAPIWithExpands(IRS1099FormDocHeader));
        // [THEN] The response contains the header, line and form report
        VerifyResponseSunshine(ResponseText, IRS1099FormDocHeader, IRS1099FormDocLine, IRS1099FormReport);
        Cleanup();
    end;

    local procedure Initialize()
    begin
        Cleanup();
        OriginalWorkDate := WorkDate();
        LibraryGraphMgt.SetLicenseSafeWorkDate();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS 1099 API Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS 1099 API Tests");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IRS 1099 API Tests");
    end;

    local procedure CreateAPIDocument(var DocHeader: Record "IRS 1099 Form Doc. Header")
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        Vendor: Record Vendor;
    begin
        // API projection fixtures must not replace another codeunit's reporting setup or consume number series.
        ReportingPeriod."No." := LibraryUtility.GenerateGUID();
        ReportingPeriod."Starting Date" := DMY2Date(1, 1, 2026);
        ReportingPeriod."Ending Date" := DMY2Date(31, 12, 2026);
        ReportingPeriod.Insert(true);
        TempOwnedReportingPeriod := ReportingPeriod;
        TempOwnedReportingPeriod.Insert();
        Form."Period No." := ReportingPeriod."No.";
        Form."No." := 'NEC';
        Form.Insert(true);
        FormBox."Period No." := ReportingPeriod."No.";
        FormBox."Form No." := Form."No.";
        FormBox."No." := 'NEC-01';
        FormBox.Insert(true);
        Vendor."No." := LibraryUtility.GenerateGUID();
        Vendor.Name := Vendor."No.";
        Vendor.Insert();
        TempOwnedVendor := Vendor;
        TempOwnedVendor.Insert();
        DocHeader.Init();
        DocHeader.ID := LibraryUtility.GetNewRecNo(DocHeader, DocHeader.FieldNo(ID));
        DocHeader."Period No." := ReportingPeriod."No.";
        DocHeader."Vendor No." := Vendor."No.";
        DocHeader."Form No." := Form."No.";
        DocHeader.Insert(true);
        TempOwnedDocHeader := DocHeader;
        TempOwnedDocHeader.Insert(false, true);
    end;

    local procedure Cleanup()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ReportingPeriod: Record "IRS Reporting Period";
        Vendor: Record Vendor;
    begin
        if TempOwnedDocHeader.FindSet() then
            repeat
                if DocHeader.Get(TempOwnedDocHeader.ID) then begin
                    Assert.AreEqual(TempOwnedDocHeader.SystemId, DocHeader.SystemId, 'API fixture ownership changed.');
                    DocHeader.Delete(true);
                end;
            until TempOwnedDocHeader.Next() = 0;
        TempOwnedDocHeader.DeleteAll();
        if TempOwnedReportingPeriod.FindSet() then
            repeat
                if ReportingPeriod.Get(TempOwnedReportingPeriod."No.") then
                    ReportingPeriod.Delete(true);
            until TempOwnedReportingPeriod.Next() = 0;
        TempOwnedReportingPeriod.DeleteAll();
        if TempOwnedVendor.FindSet() then
            repeat
                if Vendor.Get(TempOwnedVendor."No.") then
                    Vendor.Delete();
            until TempOwnedVendor.Next() = 0;
        TempOwnedVendor.DeleteAll();
        if OriginalWorkDate <> 0D then begin
            WorkDate(OriginalWorkDate);
            Clear(OriginalWorkDate);
        end;
        Commit();
    end;

    local procedure CreateSupplementalAPIFixture(var DocHeader: Record "IRS 1099 Form Doc. Header"; var ParentDocLine: Record "IRS 1099 Form Doc. Line"; var TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line"; var CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line"; TipsAmount: Decimal)
    begin
        CreateAPIDocument(DocHeader);
        LibraryIRS1099Document.CreateSupplementalDefinition(DocHeader."Period No.", DocHeader."Form No.", 'NEC-01B');
        LibraryIRS1099Document.CreateSupplementalDefinition(DocHeader."Period No.", DocHeader."Form No.", 'NEC-01C');
        ParentDocLine."Document ID" := DocHeader.ID;
        ParentDocLine."Period No." := DocHeader."Period No.";
        ParentDocLine."Vendor No." := DocHeader."Vendor No.";
        ParentDocLine."Form No." := DocHeader."Form No.";
        ParentDocLine."Form Box No." := 'NEC-01';
        ParentDocLine."Line No." := 1;
        ParentDocLine.Insert(true);
        ParentDocLine.SetRange("Document ID", DocHeader.ID);
        ParentDocLine.FindFirst();
        ParentDocLine."Minimum Reportable Amount" := 2000;
        ParentDocLine.Validate(Amount, 500);
        ParentDocLine.Modify(true);
        TipsSupplLine."Document ID" := DocHeader.ID;
        TipsSupplLine.Validate("Supplemental Box No.", 'NEC-01B');
        TipsSupplLine.Validate(Amount, TipsAmount);
        TipsSupplLine.Insert(true);
        CodesSupplLine."Document ID" := DocHeader.ID;
        CodesSupplLine.Validate("Supplemental Box No.", 'NEC-01C');
        CodesSupplLine.Validate("Occupation Code 1", '101');
        CodesSupplLine.Validate("Occupation Code 2", '000');
        CodesSupplLine.Insert(true);
    end;

    local procedure VerifySupplementalCollection(ResponseText: Text; DocumentID: Integer; TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line"; CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line"; Expanded: Boolean)
    var
        Response: JsonObject;
        Document: JsonToken;
        Collection: JsonToken;
        Value: JsonToken;
    begin
        Response.ReadFrom(ResponseText);
        if Expanded then
            Response.Get(SupplementalServiceNameLbl, Collection)
        else
            Response.Get('value', Collection);
        Assert.AreEqual(2, Collection.AsArray().Count(), 'Navigation must include only this document''s stored disclosures.');
        Collection.AsArray().Get(0, Document);
        Document.AsObject().Get('documentId', Value);
        Assert.AreEqual(DocumentID, Value.AsValue().AsInteger(), 'Stored document ID must be numeric.');
        VerifySupplementalValue(GetSupplementalResponse(TipsSupplLine.SystemId), TipsSupplLine);
        VerifySupplementalValue(GetSupplementalResponse(CodesSupplLine.SystemId), CodesSupplLine);
    end;

    local procedure GetSupplementalResponse(SystemID: Guid) ResponseText: Text
    begin
        LibraryGraphMgt.GetFromWebService(ResponseText,
            LibraryGraphMgt.CreateTargetURL(Format(SystemID), Page::"IRS 1099 Doc. Suppl. API", SupplementalServiceNameLbl));
    end;

    local procedure VerifySupplementalValue(ResponseText: Text; SupplLine: Record "IRS 1099 Doc. Suppl. Line")
    var
        Response: JsonObject;
        Value: JsonToken;
        SystemID: Guid;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get('id', Value);
        Evaluate(SystemID, Value.AsValue().AsText());
        Assert.AreEqual(SupplLine.SystemId, SystemID, 'The API key must be SystemId.');
        Response.Get('documentId', Value);
        Assert.AreEqual(SupplLine."Document ID", Value.AsValue().AsInteger(), 'Document ID changed.');
        Response.Get('supplementalBoxNo', Value);
        Assert.AreEqual(SupplLine."Supplemental Box No.", Value.AsValue().AsText(), 'Supplemental box changed.');
        Response.Get('parentFormBoxNo', Value);
        Assert.AreEqual(SupplLine."Parent Form Box No.", Value.AsValue().AsText(), 'Saved parent changed.');
        Response.Get('valueType', Value);
        case SupplLine."Value Type" of
            SupplLine."Value Type"::Amount:
                Assert.AreEqual('Amount', Value.AsValue().AsText(), 'Amount value kind changed.');
            SupplLine."Value Type"::"Occupation Codes":
                Assert.AreEqual('Occupation_x0020_Codes', Value.AsValue().AsText(), 'Occupation-code value kind changed.');
        end;
        Response.Get('amount', Value);
        Assert.AreEqual(SupplLine.Amount, Value.AsValue().AsDecimal(), 'Stored amount must remain numeric.');
        Response.Get('occupationCode1', Value);
        Assert.AreEqual(SupplLine."Occupation Code 1", Value.AsValue().AsText(), 'First code must remain text.');
        Response.Get('occupationCode2', Value);
        Assert.AreEqual(SupplLine."Occupation Code 2", Value.AsValue().AsText(), 'Second code must retain leading zeros.');
    end;

    local procedure VerifyEmptyCollection(ResponseText: Text)
    var
        Response: JsonObject;
        Collection: JsonToken;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get('value', Collection);
        Assert.AreEqual(0, Collection.AsArray().Count(), 'Another document must not inherit disclosures.');
    end;

    local procedure MockIRS1099FormDocWithLineAndFormReport(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; var IRS1099FormReport: Record "IRS 1099 Form Report")
    begin
        IRS1099FormDocHeader."Receiving 1099 E-Form Consent" := true;
        IRS1099FormDocHeader."Vendor E-Mail" := 'mymail@microsoft.com';
        IRS1099FormDocHeader.Modify();
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Period No." := IRS1099FormDocHeader."Period No.";
        IRS1099FormDocLine."Vendor No." := IRS1099FormDocHeader."Vendor No.";
        IRS1099FormDocLine."Form No." := IRS1099FormDocHeader."Form No.";
        IRS1099FormDocLine."Form Box No." := 'NEC-01';
        IRS1099FormDocLine."Manually Changed" := true;
        IRS1099FormDocLine."Include In 1099" := true;
        IRS1099FormDocLine.Amount := 100;
        IRS1099FormDocLine."Minimum Reportable Amount" := 50;
        IRS1099FormDocLine.Insert();
        IRS1099FormReport."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormReport."Report Type" := IRS1099FormReport."Report Type"::"Copy B";
        IRS1099FormReport.Insert();
    end;

    local procedure GetIRS1099DocumentAPIWithExpands(DocHeader: Record "IRS 1099 Form Doc. Header") Url: Text
    begin
        Url := LibraryGraphMgt.CreateTargetURL('', Page::"IRS 1099 Documents API", IRS1099DocumentsServiceNameLbl);
        Url := LibraryGraphMgt.AppendQueryParameterToTargetURL(Url, '$filter=id eq ' + Format(DocHeader.SystemId, 0, 4));
        Url := LibraryGraphMgt.AppendQueryParameterToTargetURL(Url, '$expand=irs1099documentlines,irs1099formreports');
        exit(Url);
    end;

    local procedure VerifyResponseSunshine(ResponseText: Text; IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; IRS1099FormReport: Record "IRS 1099 Form Report")
    var
        IRS1099FormHeaderJson, IRS1099DocumentLinesSet, IRS1099FormReportsSet : Text;
    begin
        Assert.IsTrue(
            LibraryGraphMgt.GetObjectFromJSONResponse(ResponseText, IRS1099FormHeaderJson, 1), 'No Json response from IRS1099FormDocHeader.SystemId');
        LibraryGraphMgt.VerifyIDInJson(IRS1099FormHeaderJson);
        LibraryGraphMgt.VerifyPropertyInJSON(IRS1099FormHeaderJson, 'vendorNo', IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocHeader.CalcFields("Vendor Name");
        LibraryGraphMgt.VerifyPropertyInJSON(IRS1099FormHeaderJson, 'vendorName', IRS1099FormDocHeader."Vendor Name");
        LibraryGraphMgt.VerifyPropertyInJSON(IRS1099FormHeaderJson, 'docId', Format(IRS1099FormDocHeader.ID));
        LibraryGraphMgt.VerifyPropertyInJSON(IRS1099FormHeaderJson, 'formNo', IRS1099FormDocHeader."Form No.");
        LibraryGraphMgt.VerifyPropertyInJSON(IRS1099FormHeaderJson, 'receivingConsent', 'True');
        LibraryGraphMgt.VerifyPropertyInJSON(IRS1099FormHeaderJson, 'vendorEmail', IRS1099FormDocHeader."Vendor E-Mail");
        Assert.IsTrue(
            LibraryGraphMgt.GetObjectFromJSONResponseByName(IRS1099FormHeaderJson, 'irs1099documentlines', IRS1099DocumentLinesSet, 1), 'irs1099documentlines does not exist in the response');
        VerifyIRS1099DocumentLineResponse(IRS1099DocumentLinesSet, IRS1099FormDocLine);
        Assert.IsTrue(
            LibraryGraphMgt.GetObjectFromJSONResponseByName(IRS1099FormHeaderJson, 'irs1099formreports', IRS1099FormReportsSet, 1), 'irs1099formreports does not exist in the response');
        VerifyIRS1099FormReportResponse(IRS1099FormReportsSet, IRS1099FormReport);
    end;

    local procedure VerifyIRS1099DocumentLineResponse(ResponseJson: Text; IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line")
    begin
        LibraryGraphMgt.VerifyIDInJson(ResponseJson);
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseJson, 'formBoxNo', IRS1099FormDocLine."Form Box No.");
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseJson, 'manuallyChanged', 'True');
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseJson, 'includeIn1099', 'True');
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseJson, 'amount', IRS1099FormDocLine.Amount.ToText());
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseJson, 'minimumReportableAmount', IRS1099FormDocLine."Minimum Reportable Amount".ToText());
    end;

    local procedure VerifyIRS1099FormReportResponse(ResponseJson: Text; IRS1099FormReport: Record "IRS 1099 Form Report")
    begin
        LibraryGraphMgt.VerifyIDInJson(ResponseJson);
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseJson, 'reportType', Format(IRS1099FormReport."Report Type").Replace(' ', '_'));
    end;
}
