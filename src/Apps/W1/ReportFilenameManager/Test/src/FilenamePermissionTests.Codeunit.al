// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using System.Environment;
using System.Reflection;
using System.Security.AccessControl;
using System.TestLibraries.Security.AccessControl;

codeunit 149528 "Filename Permission Tests"
{
    // Every user who prints runs the naming code, but Report Filename Mgr. is meant for pattern
    // administrators only: an ordinary user must be named by a pattern without reading the patterns
    // table. Each test sets up as the administrator, then narrows the session with Permissions Mock.

    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AnOrdinaryUserIsNamedByThePattern()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ProofSupport: Codeunit "Filename Proof Support";
        ReportingTriggers: Codeunit "Reporting Triggers";
        PermissionsMock: Codeunit "Permissions Mock";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        TestData: Codeunit "Filename Test Data";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Filename: Text;
        Expected: Text;
        Success: Boolean;
        ProbeInstalled: Boolean;
    begin
        FilenameProofGuard.ClearPatterns();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", InvoicePatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        TestData.PostNewInvoice(SalesInvoiceHeader);
        // Read before the session is narrowed, so the narrowed set's rights do not matter.
        ProbeInstalled := IsPermissionSetInstalled(ProbeSetTok);
        PermissionsMock.Set(OrdinaryUserSetTok);
        // A diagnostic probe app, where installed, also subscribes to OnGetFilename and writes its
        // own log, which fails without its set; that set covers only the probe's own objects.
        if ProbeInstalled then
            PermissionsMock.Assign(ProbeSetTok);

        // Control: a user who can read the patterns table proves nothing about one who cannot.
        if Pattern.ReadPermission() then
            Error(UserCanReadPatternsErr, UserId());

        Payload.ReadFrom(StrSubstNo(PayloadTok, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader)));

        // Raised as a print raises it.
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionTok, Payload, PdfExtensionTok, NoRecord, Filename, Success);

        Expected := InvoicePrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok;
        if not Success then
            Error(NotNamedErr, UserId(), SalesInvoiceHeader."No.");
        if Filename <> Expected then
            Error(WrongNameErr, Expected, Filename);
    end;

    /// <summary>
    /// Report Filename Mgr. beside the ordinary set (not SUPER) is enough to manage patterns: the
    /// pages and the card's lookups are opened as a manager would, so a right missing for any of
    /// them stops the test.
    /// </summary>
    [Test]
    [HandlerFunctions('PickInvoiceReportHandler,PickLastFieldHandler,AppendFirstPlaceholderHandler,TestPatternOnInvoiceHandler,ChooseInvoiceHandler,PickFirstTableHandler,TickPrintRouteHandler')]
    procedure AManagerWithThisSetCanSetUpAndTestAPattern()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        PermissionsMock: Codeunit "Permissions Mock";
        TestData: Codeunit "Filename Test Data";
        PatternsList: TestPage "Report Filename Patterns";
        Setup: TestPage "Report Filename Setup";
        PatternCard: TestPage "Report Filename Pattern Card";
        SecondCard: TestPage "Report Filename Pattern Card";
        ProbeInstalled: Boolean;
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());
        FilenameProofGuard.SwitchFeatureOn();
        FilenameProofGuard.ClearPatterns();
        TestData.PostNewInvoice(SalesInvoiceHeader);
        TestedInvoiceNo := SalesInvoiceHeader."No.";
        ProbeInstalled := IsPermissionSetInstalled(ProbeSetTok);

        PermissionsMock.Set(OrdinaryUserSetTok);
        PermissionsMock.Assign(ManagerSetTok);
        if ProbeInstalled then
            PermissionsMock.Assign(ProbeSetTok);

        // Control: the narrowed session holds this set.
        if not Pattern.WritePermission() then
            Error(ManagerCannotWriteErr, UserId());

        PatternsList.OpenView();
        PatternsList.Close();

        Setup.OpenEdit();
        Setup."Max. File Name Length".SetValue(100);
        Setup.Close();

        PatternCard.OpenNew();
        PatternCard.ReportName.AssistEdit();
        PatternCard.LanguageCodeField.AssistEdit();
        PatternCard.RouteFilterText.AssistEdit();
        if PatternCard.RouteFilterText.Value() <> Format(Enum::"Report Filename Output Route"::Print) then
            Error(ManagerRouteNotSetErr, Format(Enum::"Report Filename Output Route"::Print), PatternCard.RouteFilterText.Value());
        PatternCard."File Name Pattern".SetValue(ManagerPatternTok);
        PatternCard.AvailablePlaceholders.Invoke();
        PatternCard.Enabled.SetValue(true);
        PatternCard.TestPattern.Invoke();
        PatternCard.Close();

        // The Tables lookup, on a card with no report: choosing a report fixes the table.
        SecondCard.OpenNew();
        SecondCard.TableCaption.AssistEdit();
        SecondCard.Close();

        if TestedName = '' then
            Error(ManagerTestPatternEmptyErr, TestedInvoiceNo);
        if StrPos(TestedName, TestedInvoiceNo) = 0 then
            Error(ManagerTestPatternWrongErr, TestedInvoiceNo, TestedName, TestedPattern, TestedReason);
    end;

    [ModalPageHandler]
    procedure PickInvoiceReportHandler(var ReportLookup: TestPage "Report Filename Report Lookup")
    var
        ReportMetadata: Record "Report Metadata";
    begin
        ReportMetadata.Get(Report::"Standard Sales - Invoice");
        ReportLookup.GoToRecord(ReportMetadata);
        ReportLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PickLastFieldHandler(var FieldLookup: TestPage "Report Filename Field Lookup")
    begin
        FieldLookup.Last();
        FieldLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AppendFirstPlaceholderHandler(var Placeholders: TestPage "Report Filename Placeholders")
    var
        CompanyPlaceholder: Interface "Report Filename Placeholder";
    begin
        // A named placeholder, not whichever sorts first, which could be one that can decline (such
        // as [Kind of Document] on a language mismatch).
        CompanyPlaceholder := Enum::"Report Filename Placeholder"::CompanyPrefix;
        Placeholders.Filter.SetFilter(Placeholder, '[' + CompanyPlaceholder.DisplayName() + ']');
        if not Placeholders.First() then
            Error(PlaceholderNotOfferedErr, CompanyPlaceholder.DisplayName());
        Placeholders.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TestPatternOnInvoiceHandler(var TestPatternPage: TestPage "Report Filename Test")
    begin
        TestPatternPage.RunScope.SetValue(Enum::"Report Filename Run Scope"::"One Record");
        TestPatternPage.RunTargetText.AssistEdit();
        TestedName := TestPatternPage.ResultingFileName.Value();
        TestedReason := TestPatternPage.WhyNotThisPattern.Value();
        TestedPattern := TestPatternPage.PatternText.Value();
    end;

    [ModalPageHandler]
    procedure ChooseInvoiceHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    begin
        PostedSalesInvoices.Filter.SetFilter("No.", TestedInvoiceNo);
        PostedSalesInvoices.First();
        PostedSalesInvoices.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PickFirstTableHandler(var TableLookup: TestPage "Report Filename Table Lookup")
    begin
        TableLookup.First();
        TableLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TickPrintRouteHandler(var RoutesPage: TestPage "Report Filename Routes")
    begin
        // Print: Test Pattern starts on the pattern's first route.
        RoutesPage.First();
        RoutesPage.Selected.SetValue(true);
        RoutesPage.OK().Invoke();
    end;

    local procedure IsPermissionSetInstalled(RoleId: Text): Boolean
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange("Role ID", RoleId);
        exit(not AggregatePermissionSet.IsEmpty());
    end;

    var
        TestedInvoiceNo: Code[20];
        TestedName: Text;
        TestedReason: Text;
        TestedPattern: Text;
        ManagerSetTok: Label 'Report Filename Mgr.', Locked = true;
        ManagerPatternTok: Label 'Managed-[No.]', Locked = true;
        ManagerCannotWriteErr: Label 'User %1, narrowed to D365 BUS FULL ACCESS and Report Filename Mgr., cannot write patterns, so the set was not applied and this test proves nothing.', Comment = '%1 the user';
        ManagerRouteNotSetErr: Label 'With only Report Filename Mgr. beside D365 BUS FULL ACCESS, ticking the first route should set the card''s Output Route Filter to %1, but it reads "%2".', Comment = '%1 expected, %2 what the card shows';
        ManagerTestPatternEmptyErr: Label 'With only Report Filename Mgr. beside D365 BUS FULL ACCESS, Test Pattern on invoice %1 showed no file name.', Comment = '%1 the invoice';
        PlaceholderNotOfferedErr: Label 'Available Placeholders on the invoice pattern does not offer [%1] to a manager.', Comment = '%1 the placeholder';
        ManagerTestPatternWrongErr: Label 'With only Report Filename Mgr. beside D365 BUS FULL ACCESS, Test Pattern on invoice %1 showed "%2", which does not carry the invoice number. The pattern was %3; Test Pattern gave the reason: %4', Comment = '%1 the invoice, %2 the file name shown, %3 the file name pattern, %4 the reason Test Pattern gave';
        OrdinaryUserSetTok: Label 'D365 BUS FULL ACCESS', Locked = true;
        ProbeSetTok: Label 'Report Naming Probe', Locked = true;
        PayloadTok: Label '{"filterviews":%1,"intent":"Print"}', Comment = '%1 the filterviews array', Locked = true;
        InvoiceCaptionTok: Label 'Sales - Invoice', Locked = true;
        InvoicePatternTok: Label 'Invoice-[No.]', Locked = true;
        InvoicePrefixTok: Label 'Invoice-', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        UserCanReadPatternsErr: Label 'User %1 can read the patterns table directly, so this test cannot show what happens to a user who cannot. Run it as a user without Filename Manager.', Comment = '%1 the user';
        NotNamedErr: Label 'User %1 printed invoice %2 and the pattern did not name it.', Comment = '%1 the user, %2 the invoice';
        WrongNameErr: Label 'Expected the file to be called %1 but it was called %2.', Comment = '%1 expected, %2 actual';
}
