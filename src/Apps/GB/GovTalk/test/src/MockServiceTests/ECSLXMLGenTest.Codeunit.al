// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System;
using System.TestLibraries.Environment;
using System.Xml;

codeunit 144029 "ECSL XML Gen. Test"
{
    // // [FEATURE] [Record Link]

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        RegressionCountryCode: Code[10];
        RegressionReportVersion: Code[10];
#if not CLEAN27
        GovTalkFeatureEnabled: Boolean;
#endif
        MonthsTok: Label 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

    [Test]
    [Scope('OnPrem')]
    procedure ECSLXMLGenerateAllNodesQuarterly()
    var
        VATEntry: Record "VAT Entry";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        VATReportHeader: Record "VAT Report Header";
        ECSalesListPopulateXML: Codeunit "EC Sales List XML";
        ECSalesListSuggestLines: Codeunit "EC Sales List Suggest Lines";
        GovTalkRequestXMLNode: DotNet XmlNode;
        StartDate: Date;
        EndDate: Date;
        VATRegNo: Text[20];
        DummyGuid: Guid;
    begin
        // [Scenario] generating full XML for a quarter
        VATRegNo := '100001';
        StartDate := DMY2Date(1, 1, 2017);
        EndDate := DMY2Date(31, 3, 2017);
        InitPrerequisites();
        // [Given] VAT report header
        InitReportHeader(VATReportHeader, StartDate, EndDate);
        VATReportHeader."Period Type" := VATReportHeader."Period Type"::Quarter;
        VATReportHeader."Period No." := 1;
        VATReportHeader.Modify();

        // [Given] 1 B2B Goods, 1 B2B Services and 1 EU 3-Party Trade  Vat Entry
        VATEntry.DeleteAll();
        InitVatEntry(VATEntry, VATRegNo, StartDate);

        InitVatEntry(VATEntry, VATRegNo, StartDate);
        VATEntry."EU 3-Party Trade" := true;
        VATEntry.Modify();

        InitVatEntry(VATEntry, VATRegNo, EndDate);
        VATEntry."EU Service" := true;
        VATEntry.Modify();

        // [When] Generate the XML
        ECSalesListSuggestLines.Run(VATReportHeader);
        ECSalesListPopulateXML.GetECSLDeclarationRequestMessage(GovTalkRequestXMLNode, VATReportHeader, DummyGuid);

        // [THEN] XML has all the expected values and elements
        AssertXML(VATReportHeader, GovTalkRequestXMLNode);

        // Teardown
        ECSLVATReportLine.DeleteAll();
        VATReportHeader.DeleteAll();
        VATEntry.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ECSLXMLGenerateAllNodesMonthly()
    var
        VATEntry: Record "VAT Entry";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        VATReportHeader: Record "VAT Report Header";
        ECSalesListPopulateXML: Codeunit "EC Sales List XML";
        ECSalesListSuggestLines: Codeunit "EC Sales List Suggest Lines";
        GovTalkRequestXMLNode: DotNet XmlNode;
        StartDate: Date;
        EndDate: Date;
        VATRegNo: Text[20];
        DummyGuid: Guid;
    begin
        // [Scenario] generating full XML for a quarter
        VATRegNo := '100001';
        StartDate := DMY2Date(1, 1, 2017);
        EndDate := DMY2Date(31, 1, 2017);
        InitPrerequisites();

        // [Given] VAT report header
        InitReportHeader(VATReportHeader, StartDate, EndDate);

        // [Given] 1 B2B Goods, 1 B2B Services and 1 EU 3-Party Trade  Vat Entry
        VATEntry.DeleteAll();
        InitVatEntry(VATEntry, VATRegNo, StartDate);

        InitVatEntry(VATEntry, VATRegNo, StartDate);
        VATEntry."EU 3-Party Trade" := true;
        VATEntry.Modify();

        InitVatEntry(VATEntry, VATRegNo, EndDate);
        VATEntry."EU Service" := true;
        VATEntry.Modify();

        // [When] Generate the XML
        ECSalesListSuggestLines.Run(VATReportHeader);
        ECSalesListPopulateXML.GetECSLDeclarationRequestMessage(GovTalkRequestXMLNode, VATReportHeader, DummyGuid);

        // [Given] 1 B2B Goods, 1 B2B Services and 1 EU 3-Party Trade  Vat Entry
        AssertXML(VATReportHeader, GovTalkRequestXMLNode);

        // Teardown
        ECSLVATReportLine.DeleteAll();
        VATReportHeader.DeleteAll();
        VATEntry.DeleteAll();
    end;

#if not CLEAN27
    [Test]
    procedure ECSLSuggestLinesCountsEntryOnceWithoutGovTalk()
    var
        VATEntry: Record "VAT Entry";
        OtherVATEntry: Record "VAT Entry";
        VATReportHeader: Record "VAT Report Header";
        ECSalesListSuggestLines: Codeunit "EC Sales List Suggest Lines";
        ExpectedTotalValue: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653360] With GovTalk disabled, repeated query rows contribute each VAT entry once and rounding applies to the group.
        Initialize();

        // [GIVEN] GovTalk is disabled and two entries for customer "C" have a combined fractional base.
        GovTalkFeatureEnabled := false;
        ExpectedTotalValue := CreateGroupedRegressionVATEntries(VATEntry, OtherVATEntry);

        // [GIVEN] Entry "A" has relations to two rejected reports and report "R" has no lines.
        CreatePriorECSLRelation(VATEntry, true);
        CreatePriorECSLRelation(VATEntry, true);
        CreateRegressionReport(VATReportHeader);

        // [WHEN] Suggest lines for report "R".
        ECSalesListSuggestLines.Run(VATReportHeader);

        // [THEN] One grouped line contains each entry once and is rounded after aggregation.
        VerifyRegressionLine(VATReportHeader, VATEntry, ExpectedTotalValue, 2);
        VerifyRegressionRelation(VATReportHeader, OtherVATEntry);
        UnbindSubscription(this);
    end;
#endif

    [Test]
    procedure ECSLSuggestLinesIncludesRejectedVATEntry()
    var
        VATEntry: Record "VAT Entry";
        VATReportHeader: Record "VAT Report Header";
        ECSalesListSuggestLines: Codeunit "EC Sales List Suggest Lines";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653360] With GovTalk enabled, an entry related only to rejected reports can be reported again.
        Initialize();

        // [GIVEN] Entry "A" for customer "C" has relations to two rejected reports.
        CreateRegressionVATEntry(VATEntry, LibraryUtility.GenerateGUID(), -125);
        CreatePriorECSLRelation(VATEntry, true);
        CreatePriorECSLRelation(VATEntry, true);
        CreateRegressionReport(VATReportHeader);

        // [WHEN] Suggest lines for report "R".
        ECSalesListSuggestLines.Run(VATReportHeader);

        // [THEN] The entry contributes once and has exactly one new relation.
        VerifyRegressionLine(VATReportHeader, VATEntry, 125, 1);
        UnbindSubscription(this);
    end;

    [Test]
    procedure ECSLSuggestLinesExcludesAcceptedVATEntry()
    var
        VATEntry: Record "VAT Entry";
        VATReportHeader: Record "VAT Report Header";
        ECSalesListSuggestLines: Codeunit "EC Sales List Suggest Lines";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653360] With GovTalk enabled, any accepted prior report excludes an entry even when another prior report was rejected.
        Initialize();

        // [GIVEN] Entry "A" for customer "C" has relations to a rejected and an accepted report.
        CreateRegressionVATEntry(VATEntry, LibraryUtility.GenerateGUID(), -125);
        CreatePriorECSLRelation(VATEntry, true);
        CreatePriorECSLRelation(VATEntry, false);
        CreateRegressionReport(VATReportHeader);

        // [WHEN] Suggest lines for report "R".
        ECSalesListSuggestLines.Run(VATReportHeader);

        // [THEN] Neither a line nor a relation is created for the entry.
        VerifyRegressionReportIsEmpty(VATReportHeader);
        UnbindSubscription(this);
    end;

    local procedure Initialize()
    var
        CountryRegion: Record "Country/Region";
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        if UnbindSubscription(this) then;

        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", 'DE');
        CountryRegion.Modify(true);
        RegressionCountryCode := CountryRegion.Code;

        VATReportsConfiguration.Init();
        VATReportsConfiguration."VAT Report Type" := VATReportsConfiguration."VAT Report Type"::"EC Sales List";
        VATReportsConfiguration."VAT Report Version" := LibraryUtility.GenerateGUID();
        VATReportsConfiguration.Validate("Suggest Lines Codeunit ID", Codeunit::"EC Sales List Suggest Lines");
        VATReportsConfiguration.Insert(true);
        RegressionReportVersion := VATReportsConfiguration."VAT Report Version";
#if not CLEAN27
        GovTalkFeatureEnabled := true;
#endif
        BindSubscription(this);
    end;

    local procedure CreateRegressionReport(var VATReportHeader: Record "VAT Report Header")
    begin
        InitReportHeader(VATReportHeader, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        VATReportHeader.Validate("VAT Report Version", RegressionReportVersion);
        VATReportHeader.Modify(true);
    end;

    local procedure CreateRegressionVATEntry(var VATEntry: Record "VAT Entry"; VATRegistrationNo: Text[20]; BaseAmount: Decimal)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry.Validate("Country/Region Code", RegressionCountryCode);
        VATEntry.Validate("VAT Registration No.", VATRegistrationNo);
        VATEntry.Base := BaseAmount;
        VATEntry.Insert(true);
    end;

#if not CLEAN27
    local procedure CreateGroupedRegressionVATEntries(var VATEntry: Record "VAT Entry"; var OtherVATEntry: Record "VAT Entry"): Decimal
    begin
        // These bases round to 301 together, but to 300 when rounded separately.
        CreateRegressionVATEntry(VATEntry, LibraryUtility.GenerateGUID(), -100.4);
        CreateRegressionVATEntry(OtherVATEntry, VATEntry."VAT Registration No.", -200.4);
        exit(301);
    end;
#endif

    local procedure CreatePriorECSLRelation(VATEntry: Record "VAT Entry"; Rejected: Boolean)
    var
        VATReportHeader: Record "VAT Report Header";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        GovTalkMessagePart: Record "GovTalk Msg. Parts";
    begin
        CreateRegressionReport(VATReportHeader);
        GovTalkMessagePart.Init();
        GovTalkMessagePart."Part Id" := CreateGuid();
        GovTalkMessagePart.Validate("Report No.", VATReportHeader."No.");
        GovTalkMessagePart.Validate("VAT Report Config. Code", GovTalkMessagePart."VAT Report Config. Code"::"EC Sales List");
        GovTalkMessagePart.Status := GovTalkMessagePart.Status::Rejected;
        VATReportHeader.Status := VATReportHeader.Status::Rejected;
        if not Rejected then begin
            GovTalkMessagePart.Status := GovTalkMessagePart.Status::Accepted;
            VATReportHeader.Status := VATReportHeader.Status::Accepted;
        end;
        GovTalkMessagePart.Insert(true);
        VATReportHeader.Modify(true);

        ECSLVATReportLine.Init();
        ECSLVATReportLine.Validate("Report No.", VATReportHeader."No.");
        ECSLVATReportLine."Line No." := 1;
        ECSLVATReportLine."Country Code" := VATEntry."Country/Region Code";
        ECSLVATReportLine."Customer VAT Reg. No." := VATEntry."VAT Registration No.";
        ECSLVATReportLine."Total Value Of Supplies" := -VATEntry.Base;
        ECSLVATReportLine."XML Part Id GB" := GovTalkMessagePart."Part Id";
#if not CLEAN27
        SetLegacyRegressionLineStatus(ECSLVATReportLine, GovTalkMessagePart);
#endif
        ECSLVATReportLine.Insert(true);

        ECSLVATReportLineRelation.Init();
        ECSLVATReportLineRelation."VAT Entry No." := VATEntry."Entry No.";
        ECSLVATReportLineRelation."ECSL Report No." := ECSLVATReportLine."Report No.";
        ECSLVATReportLineRelation."ECSL Line No." := ECSLVATReportLine."Line No.";
        ECSLVATReportLineRelation.Insert(true);
    end;

#if not CLEAN27
#pragma warning disable AL0432
    local procedure SetLegacyRegressionLineStatus(var ECSLVATReportLine: Record "ECSL VAT Report Line"; GovTalkMessagePart: Record "GovTalk Msg. Parts")
    var
        GovTalkMessageParts: Record "GovTalk Message Parts";
    begin
        // Non-CLEAN BaseApp still checks the legacy status before the GovTalk subscriber.
        GovTalkMessageParts.Init();
        GovTalkMessageParts."Part Id" := GovTalkMessagePart."Part Id";
        GovTalkMessageParts.Validate("Report No.", GovTalkMessagePart."Report No.");
        GovTalkMessageParts.Validate("VAT Report Config. Code", GovTalkMessageParts."VAT Report Config. Code"::"EC Sales List");
        GovTalkMessageParts.Status := GovTalkMessagePart.Status;
        GovTalkMessageParts.Insert(true);
        ECSLVATReportLine."XML Part Id" := GovTalkMessagePart."Part Id";
    end;
#pragma warning restore AL0432
#endif

    local procedure VerifyRegressionLine(VATReportHeader: Record "VAT Report Header"; VATEntry: Record "VAT Entry"; ExpectedTotalValue: Decimal; ExpectedRelationCount: Integer)
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        Assert.RecordCount(ECSLVATReportLine, 1);
        ECSLVATReportLine.FindFirst();
        Assert.AreEqual(VATEntry."Country/Region Code", ECSLVATReportLine."Country Code", 'Unexpected ECSL country.');
        Assert.AreEqual(VATEntry."VAT Registration No.", ECSLVATReportLine."Customer VAT Reg. No.", 'Unexpected ECSL customer.');
        Assert.AreEqual(ECSLVATReportLine."Transaction Indicator"::"B2B Goods", ECSLVATReportLine."Transaction Indicator", 'Unexpected ECSL transaction indicator.');
        Assert.AreEqual(ExpectedTotalValue, ECSLVATReportLine."Total Value Of Supplies", 'Each VAT entry must contribute once before group rounding.');
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", VATReportHeader."No.");
        Assert.RecordCount(ECSLVATReportLineRelation, ExpectedRelationCount);
        VerifyRegressionRelation(VATReportHeader, VATEntry);
    end;

    local procedure VerifyRegressionRelation(VATReportHeader: Record "VAT Report Header"; VATEntry: Record "VAT Entry")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", VATReportHeader."No.");
        ECSLVATReportLineRelation.SetRange("VAT Entry No.", VATEntry."Entry No.");
        Assert.RecordCount(ECSLVATReportLineRelation, 1);
        ECSLVATReportLineRelation.FindFirst();
        ECSLVATReportLine.Get(ECSLVATReportLineRelation."ECSL Report No.", ECSLVATReportLineRelation."ECSL Line No.");
        Assert.AreEqual(VATEntry."VAT Registration No.", ECSLVATReportLine."Customer VAT Reg. No.", 'The relation must reference the generated customer line.');
    end;

    local procedure VerifyRegressionReportIsEmpty(VATReportHeader: Record "VAT Report Header")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        Assert.RecordIsEmpty(ECSLVATReportLine);
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", VATReportHeader."No.");
        Assert.RecordIsEmpty(ECSLVATReportLineRelation);
    end;

    local procedure InitReportHeader(var VATReportHeader: Record "VAT Report Header"; StartDate: Date; EndDate: Date)
    begin
        VATReportHeader.Init();
        VATReportHeader."Start Date" := StartDate;
        VATReportHeader."End Date" := EndDate;
        VATReportHeader."No." := CopyStr(CreateGuid(), 2, 20);

        VATReportHeader."Period Type" := VATReportHeader."Period Type"::Month;
        VATReportHeader."Period No." := Date2DMY(StartDate, 2);
        VATReportHeader."Period Year" := Date2DMY(StartDate, 3);

        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"EC Sales List";
        VATReportHeader.Insert();
    end;

    local procedure InitVatEntry(var VATEntry: Record "VAT Entry"; VatRegNo: Text[20]; PostingDate: Date)
    var
        LastId: Integer;
    begin
        if VATEntry.FindLast() then
            LastId := VATEntry."Entry No.";

        VATEntry.Init();
        VATEntry."Entry No." := LastId + 1;
        VATEntry.Base := -1.7;
        VATEntry."Posting Date" := PostingDate;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."EU 3-Party Trade" := false;
        VATEntry."VAT Registration No." := VatRegNo;
        VATEntry."EU Service" := false;
        VATEntry."Country/Region Code" := 'DE';
        VATEntry.Insert();
    end;

    local procedure AssertXML(VATReportHeader: Record "VAT Report Header"; GovTalkRequestXMLNode: DotNet XmlNode)
    var
        CompanyInformation: Record "Company Information";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        XMLDOMManagement: Codeunit "XML DOM Management";
        DummyXMLNodeList: DotNet XmlNodeList;
        XPathNavigator: DotNet XPathNavigator;
        XPathExpression: DotNet XPathExpression;
        TotalStr: Text;
        TotalInt: Integer;
    begin
        CompanyInformation.Get();
        Assert.AreEqual(CompanyInformation."Contact Person", XMLDOMManagement.FindNodeText(
            GovTalkRequestXMLNode, GetSalesReqHeaderXpath('[name()=''VATCore:SubmittersContactName'']')), '');

        GeneralLedgerSetup.Get();
        Assert.AreEqual(GeneralLedgerSetup."LCY Code", XMLDOMManagement.FindNodeText(GovTalkRequestXMLNode,
            GetSalesReqHeaderXpath('[name()=''VATCore:CurrencyCode'']')), '');
        Assert.AreEqual('true', XMLDOMManagement.FindNodeText(GovTalkRequestXMLNode,
            GetSalesReqHeaderXpath('[name()=''VATCore:ApplyStrictEuropeanSaleValidation'']')), '');

        if VATReportHeader."Period Type" = VATReportHeader."Period Type"::Month then begin
            Assert.AreEqual(GetMonthCode(VATReportHeader."Period No."), XMLDOMManagement.FindNodeText(GovTalkRequestXMLNode,
                GetSalesReqHeaderXpath('[name()=''VATCore:TaxMonthlyPeriod'']/*[name()=''VATCore:TaxMonth'']')),
              'Expected that the Month value are the same');

            Assert.AreEqual(Format(VATReportHeader."Period Year"), XMLDOMManagement.FindNodeText(GovTalkRequestXMLNode,
                GetSalesReqHeaderXpath('[name()=''VATCore:TaxMonthlyPeriod'']/*[name()=''VATCore:TaxMonthPeriodYear'']')),
              'Expected that the Years are the same');
        end else begin
            Assert.AreEqual(Format(VATReportHeader."Period No."), XMLDOMManagement.FindNodeText(GovTalkRequestXMLNode,
                GetSalesReqHeaderXpath('[name()=''VATCore:TaxQuarter'']/*[name()=''VATCore:TaxQuarterNumber'']')),
              'Expected that the Quarter value are the same');
            Assert.AreEqual(Format(VATReportHeader."Period Year"), XMLDOMManagement.FindNodeText(
                GovTalkRequestXMLNode, GetSalesReqHeaderXpath('[name()=''VATCore:TaxQuarter'']/*[name()=''VATCore:TaxQuarterYear'']')),
              'Expected that the Years are the same');
        end;

        ECSLVATReportLine.SetFilter("Report No.", VATReportHeader."No.");
        Assert.IsTrue(XMLDOMManagement.FindNodes(GovTalkRequestXMLNode,
            GetSalesReqBodyXpath('[name()=''EuropeanSale'']/*[name()=''VATCore:TotalValueOfSupplies'']'),
            DummyXMLNodeList), 'Expected to get nodes back');
        Assert.AreEqual(ECSLVATReportLine.Count, DummyXMLNodeList.Count, 'Expected to have a node per record');

        XPathNavigator := GovTalkRequestXMLNode.CreateNavigator();
        XPathExpression := XPathNavigator.Compile(
            'sum(' + GetSalesReqBodyXpath('[name()=''EuropeanSale'']/*[name()=''VATCore:TotalValueOfSupplies'']') + ')');
        TotalStr := Format(XPathNavigator.Evaluate(XPathExpression));
        Evaluate(TotalInt, TotalStr);
        Assert.AreEqual(GetReportTotalValue(VATReportHeader), TotalInt, '');
    end;

    local procedure GetReportTotalValue(VATReportHeader: Record "VAT Report Header"): Integer
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetCurrentKey("Report No.");
        ECSLVATReportLine.CalcSums("Total Value Of Supplies");
        exit(ECSLVATReportLine."Total Value Of Supplies");
    end;

    local procedure GetSalesReqHeaderXpath(xpath: Text): Text
    begin
        exit('//*[name()=''EuropeanSalesDeclarationRequest'']/*[name()=''Header'']/*' + xpath);
    end;

    local procedure GetSalesReqBodyXpath(xpath: Text): Text
    begin
        exit('//*[name()=''EuropeanSalesDeclarationRequest'']/*[name()=''Body'']/*' + xpath);
    end;

    local procedure GetMonthCode(MonthNo: Integer): Text
    begin
        exit(SelectStr(MonthNo, MonthsTok));
    end;

    local procedure InitPrerequisites()
    var
        CompanyInformation: Record "Company Information";
        GovTalkSetup: Record "Gov Talk Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := '7777777';
        CompanyInformation."Branch Number GB" := '000';
        CompanyInformation."Post Code" := '12345';
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        CompanyInformation.Modify();

        if not GovTalkSetup.Get() then
            GovTalkSetup.Insert();
        GovTalkSetup.Username := 'DummyUserName';
        GovTalkSetup.Password := CreateGuid();
        GovTalkSetup.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EC Sales List Suggest Lines", 'OnPopulateVatEntryLinesOnAfterEUVATEntriesSetFilters', '', false, false)]
    local procedure FilterRegressionVATEntries(var VATReportHeader: Record "VAT Report Header"; EUVATEntries: Query "EU VAT Entries")
    begin
        // Limit this instance to its own country without deleting or changing posted demo entries.
        EUVATEntries.SetRange(CountryCode, RegressionCountryCode);
    end;

#if not CLEAN27
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GovTalk, OnAfterCheckFeatureEnabled, '', false, false)]
    local procedure SetGovTalkFeatureEnabled(var IsEnabled: Boolean)
    begin
        IsEnabled := GovTalkFeatureEnabled;
    end;
#endif
}
