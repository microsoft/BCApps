// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50178 "Filename Permission Tests"
{
    // Runs as a user who holds no permission set from this app: D365 BUS FULL ACCESS and nothing of
    // ours. Microsoft's Permissions Mock narrows the test session to exactly that set, which is how
    // Microsoft's own tests run as a restricted user. A second real user was the first choice, and
    // could not be made: the container's user commands refuse this machine's account.
    //
    // Filename Proof Seed Perm leaves the pattern behind first, as the administrator it takes.
    //
    // Every user who prints a report runs this feature's code, because the naming happens inside
    // the print. Only people who set up patterns hold Report Filename Mgr. So an ordinary user must be
    // named by a pattern without being able to read the patterns table, and must never get a
    // permission error out of a print.
    //
    // Nothing here writes: the user could not, and a write would change what is being measured.
    // A failure is an error, so Run-TestsInBcContainer reports it.

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
        NoRecord: RecordRef;
        Payload: JsonObject;
        Filename: Text;
        Expected: Text;
        Success: Boolean;
        ProbeInstalled: Boolean;
    begin
        // Read before the session is narrowed, which may take away the right to read it.
        ProbeInstalled := IsPermissionSetInstalled(ProbeSetTok);
        PermissionsMock.Set(OrdinaryUserSetTok);
        // Where the diagnostic probe is installed beside this app, it listens to the same naming
        // event, writing to its own log. It is not part of the deliverable, and without its set the
        // first run of this test failed inside the probe - before this feature's code was reached -
        // which measured nothing about this feature. Its set covers only the probe's own objects.
        // Where the probe is not installed there is no such set, and nothing to assign.
        if ProbeInstalled then
            PermissionsMock.Assign(ProbeSetTok);

        // The control. If this user can read the patterns table directly, the test proves nothing
        // about a user who cannot.
        if Pattern.ReadPermission() then
            Error(UserCanReadPatternsErr, UserId());

        SalesInvoiceHeader.SetFilter("Bill-to Customer No.", '<>%1', '');
        SalesInvoiceHeader.FindFirst();

        Payload.ReadFrom(StrSubstNo(PayloadTok, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader)));

        // The platform's own naming hook, raised exactly as a print raises it.
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionTok, Payload, PdfExtensionTok, NoRecord, Filename, Success);

        Expected := InvoicePrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok;
        if not Success then
            Error(NotNamedErr, UserId(), SalesInvoiceHeader."No.");
        if Filename <> Expected then
            Error(WrongNameErr, Expected, Filename);
    end;

    /// <summary>
    /// The other half: somebody who manages file names holds Report Filename Mgr. beside their
    /// ordinary set, and nothing more - not SUPER, which every check in a client made by the person
    /// who installed the app would otherwise run as. Each page is opened the way an administrator
    /// opens it, by its action or its lookup, so a page, table or codeunit missing from the set
    /// stops the test where the administrator would be stopped.
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
        PatternsList: TestPage "Report Filename Patterns";
        Setup: TestPage "Report Filename Setup";
        PatternCard: TestPage "Report Filename Pattern Card";
        SecondCard: TestPage "Report Filename Pattern Card";
        ProbeInstalled: Boolean;
    begin
        // Prepared as the administrator who runs the suite, before the session is narrowed.
        FilenameProofGuard.AssertSafeEnvironment();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());
        FilenameProofGuard.SwitchFeatureOn();
        FilenameProofGuard.ClearPatterns();
        SalesInvoiceHeader.SetFilter("No.", '<>%1', '');
        SalesInvoiceHeader.FindFirst();
        TestedInvoiceNo := SalesInvoiceHeader."No.";
        ProbeInstalled := IsPermissionSetInstalled(ProbeSetTok);

        PermissionsMock.Set(OrdinaryUserSetTok);
        PermissionsMock.Assign(ManagerSetTok);
        if ProbeInstalled then
            PermissionsMock.Assign(ProbeSetTok);

        // The control: the narrowed session holds this set. Without it, as the test above shows,
        // the patterns cannot even be read.
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
    begin
        ReportLookup.Filter.SetFilter(Caption, InvoiceCaptionTok);
        if not ReportLookup.First() then
            Error(InvoiceReportNotListedErr, InvoiceCaptionTok);
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
        // A named placeholder, not whichever sorts first: once the computed values were renamed,
        // the first became [Kind of Document], which declines here because the language field
        // this test picks (the last one offered) does not hold the invoice's language.
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
        // Print, because Test Pattern starts on the pattern's first route, and the name it shows
        // is then this pattern's.
        RoutesPage.First();
        RoutesPage.Selected.SetValue(true);
        RoutesPage.OK().Invoke();
    end;

    /// <summary>
    /// Whether a permission set by this name is installed, from any app.
    /// </summary>
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
        InvoiceReportNotListedErr: Label 'The report lookup lists no report captioned %1 for this user, so no pattern could be set up on it.', Comment = '%1 the report caption';
        ManagerCannotWriteErr: Label 'User %1, narrowed to D365 BUS FULL ACCESS and Report Filename Mgr., cannot write patterns, so the set was not applied and this test proves nothing.', Comment = '%1 the user';
        ManagerRouteNotSetErr: Label 'With only Report Filename Mgr. beside D365 BUS FULL ACCESS, ticking the first route should set the card''s Output Route Filter to %1, but it reads "%2".', Comment = '%1 expected, %2 what the card shows';
        ManagerTestPatternEmptyErr: Label 'With only Report Filename Mgr. beside D365 BUS FULL ACCESS, Test Pattern on invoice %1 showed no file name.', Comment = '%1 the invoice';
        PlaceholderNotOfferedErr: Label 'Available Placeholders on the invoice pattern does not offer [%1] to a manager.', Comment = '%1 the placeholder';
        ManagerTestPatternWrongErr: Label 'With only Report Filename Mgr. beside D365 BUS FULL ACCESS, Test Pattern on invoice %1 showed "%2", which does not carry the invoice number. The pattern was %3; Test Pattern gave the reason: %4', Comment = '%1 the invoice, %2 the file name shown, %3 the file name pattern, %4 the reason Test Pattern gave';
        OrdinaryUserSetTok: Label 'D365 BUS FULL ACCESS', Locked = true;
        ProbeSetTok: Label 'Report Naming Probe', Locked = true;
        PayloadTok: Label '{"filterviews":%1,"intent":"Print"}', Comment = '%1 the filterviews array', Locked = true;
        InvoiceCaptionTok: Label 'Sales - Invoice', Locked = true;
        InvoicePrefixTok: Label 'Invoice-', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        UserCanReadPatternsErr: Label 'User %1 can read the patterns table directly, so this test cannot show what happens to a user who cannot. Run it as a user without Filename Manager.', Comment = '%1 the user';
        NotNamedErr: Label 'User %1 printed invoice %2 and the pattern did not name it.', Comment = '%1 the user, %2 the invoice';
        WrongNameErr: Label 'Expected the file to be called %1 but it was called %2.', Comment = '%1 expected, %2 actual';
}
