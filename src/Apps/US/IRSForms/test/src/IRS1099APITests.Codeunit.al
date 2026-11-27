// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Purchases.Vendor;

codeunit 148018 "IRS 1099 API Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        TempOwnedDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempOwnedReportingPeriod: Record "IRS Reporting Period" temporary;
        TempOwnedVendor: Record Vendor temporary;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        OriginalWorkDate: Date;
        IsInitialized: Boolean;
        IRS1099DocumentsServiceNameLbl: Label 'irs1099documents';

    [Test]
    procedure IRS1099DocumentsAPISunshine()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormReport: Record "IRS 1099 Form Report";
        ResponseSucceeded: Boolean;
        ResponseError: Text;
    begin
        // [SCENARIO 497835]
        Initialize();
        Commit();
        CreateAPIDocument(OtherIRS1099FormDocHeader);
        CreateAPIDocument(IRS1099FormDocHeader);
        // [GIVEN]
        MockIRS1099FormDocWithLineAndFormReport(IRS1099FormDocHeader, IRS1099FormDocLine, IRS1099FormReport);
        Commit();
        // [WHEN] Call the API
        ResponseSucceeded := TryGetAndVerifyAPIResponse(IRS1099FormDocHeader, IRS1099FormDocLine, IRS1099FormReport);
        ResponseError := GetLastErrorText();
        // [THEN] The response contains the header, line and form report
        Cleanup();
        Commit();
        Assert.IsTrue(ResponseSucceeded, ResponseError);
    end;

    local procedure Initialize()
    begin
        Cleanup();
        OriginalWorkDate := WorkDate();
        SetLicenseSafeWorkDate();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS 1099 API Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS 1099 API Tests");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IRS 1099 API Tests");
    end;

    local procedure AppendQueryParameterToTargetURL(TargetURL: Text; QueryParameter: Text): Text
    begin
        if StrPos(TargetURL, '?') = 0 then
            exit(TargetURL + '?' + QueryParameter);

        exit(TargetURL + '&' + QueryParameter);
    end;

    local procedure Cleanup()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ReportingPeriod: Record "IRS Reporting Period";
        Vendor: Record Vendor;
    begin
        if TempOwnedDocHeader.FindSet() then
            repeat
                if IRS1099FormDocHeader.Get(TempOwnedDocHeader.ID) then begin
                    Assert.AreEqual(TempOwnedDocHeader.SystemId, IRS1099FormDocHeader.SystemId, 'The test document ID now belongs to a different document.');
                    IRS1099FormDocHeader.Delete(true);
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
    end;

    local procedure CreateAPIDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        Vendor: Record Vendor;
        PeriodNo: Code[20];
    begin
        // API test documents must not replace another codeunit's reporting setup or consume number series.
        PeriodNo := LibraryIRSReportingPeriod.CreateAvailableAnnualReportingPeriod(2026);
        ReportingPeriod.Get(PeriodNo);
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
        IRS1099FormDocHeader.Init();
        IRS1099FormDocHeader.ID := LibraryUtility.GetNewRecNo(IRS1099FormDocHeader, IRS1099FormDocHeader.FieldNo(ID));
        IRS1099FormDocHeader."Period No." := ReportingPeriod."No.";
        IRS1099FormDocHeader."Vendor No." := Vendor."No.";
        IRS1099FormDocHeader."Form No." := Form."No.";
        IRS1099FormDocHeader.Insert(true);
        TempOwnedDocHeader := IRS1099FormDocHeader;
        TempOwnedDocHeader.Insert(false, true);
    end;

    local procedure GetIRS1099DocumentAPIWithExpands(DocHeader: Record "IRS 1099 Form Doc. Header") Url: Text
    begin
        Url := LibraryGraphMgt.CreateTargetURL(Format(DocHeader.SystemId), Page::"IRS 1099 Documents API", IRS1099DocumentsServiceNameLbl);
        Url := AppendQueryParameterToTargetURL(Url, '$expand=irs1099documentlines,irs1099formreports');
        exit(Url);
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

    local procedure SetLicenseSafeWorkDate()
    begin
        WorkDate := DMY2Date(15, 11, Date2DMY(Today, 3));
    end;

    [TryFunction]
    local procedure TryGetAndVerifyAPIResponse(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; IRS1099FormReport: Record "IRS 1099 Form Report")
    var
        ResponseText: Text;
    begin
        LibraryGraphMgt.GetFromWebService(ResponseText, GetIRS1099DocumentAPIWithExpands(IRS1099FormDocHeader));
        VerifyResponseSunshine(ResponseText, IRS1099FormDocHeader, IRS1099FormDocLine, IRS1099FormReport);
    end;

    local procedure VerifyResponseSunshine(ResponseText: Text; IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; IRS1099FormReport: Record "IRS 1099 Form Report")
    var
        IRS1099FormHeaderJson, IRS1099DocumentLinesSet, IRS1099FormReportsSet : Text;
    begin
        IRS1099FormHeaderJson := ResponseText;
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
