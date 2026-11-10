// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Assembly.History;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.EMail;
using System.Environment;
using System.Globalization;
using System.Reflection;

codeunit 149517 "Filename Proof Run"
{
    // Proves a name is derived from a report run, whose selection may cover none, one or many
    // records, not from a single document.

    Access = Internal;

    /// <summary>
    /// A run over many records keeps its whole selection, whether it arrives as a payload filter or as
    /// a filtered record reference.
    /// </summary>
    procedure ProveARunKeepsItsWholeSelection()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        InvoiceFilter: Text;
        FromFilter: Text;
        FromReference: Text;
        Numbers: List of [Text];
        Expected: Text;
    begin
        ClearPatterns();

        ThreeInvoices(SalesInvoiceHeader, InvoiceFilter, Numbers);

        SetPattern('Invoices-[No.]');

        FromFilter := NameWith(Report::"Standard Sales - Invoice", Channel::Preview,
            SourceRecRef, ProofSupport.InvoiceFilterViewsFor(InvoiceFilter));

        SalesInvoiceHeader.SetFilter("No.", InvoiceFilter);
        SourceRecRef.GetTable(SalesInvoiceHeader);
        FromReference := NameWith(Report::"Standard Sales - Invoice", Channel::Email, SourceRecRef, '');

        Expected := StrSubstNo(RangeLbl, FirstOf(Numbers), LastOf(Numbers));

        ProofSupport.LogLine('17 Invoices in the run', Format(Numbers.Count()));
        ProofSupport.LogLine('17 Named from the payload filter', FromFilter);
        ProofSupport.LogLine('17 Named from the record reference', FromReference);
        ProofSupport.LogLine('17 Expected', Expected);

        if (FromFilter = Expected) and (FromReference = Expected) then
            ProofSupport.LogLine('RESULT a run keeps its whole selection', StrSubstNo(PassCollapsedMsg, Expected))
        else
            ProofSupport.LogLine('RESULT a run keeps its whole selection',
                StrSubstNo(FailCollapsedMsg, Expected, FromFilter, FromReference));

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A run that narrowed nothing can still be named. Called with no filter views and no record, so the
    /// manager falls back to the whole table.
    /// </summary>
    procedure ProveAnUnfilteredRunIsStillNamed()
    var
        GLAccount: Record "G/L Account";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Name: Text;
        Expected: Text;
        WithFieldPlaceholder: Text;
        ExpectedWholeTable: Text;
    begin
        ClearPatterns();

        if GLAccount.IsEmpty() then begin
            ProofSupport.LogLine('RESULT an unfiltered run is still named', StrSubstNo(SkippedMsg, NoAccountsMsg));
            Done();
            exit;
        end;

        SetPatternFor(Report::"Chart of Accounts", Database::"G/L Account", 'Chart of Accounts-[Your Company Name]');

        // No reference and no payload: the manager falls back to the whole table.
        Name := NameWith(Report::"Chart of Accounts", Channel::Preview, EmptyRecRef, '');

        // Sanitised: a company name ending in a period cannot end a Windows file name.
        Expected := ReportFilenameMgt.Sanitise('Chart of Accounts-' + CompanyDisplayName());

        ProofSupport.LogLine('18 Accounts in the whole table', Format(GLAccount.Count()));
        ProofSupport.LogLine('18 Name for a run that narrowed nothing', Name);
        ProofSupport.LogLine('18 Expected', Expected);

        if Name = Expected then
            ProofSupport.LogLine('RESULT an unfiltered run is still named', StrSubstNo(PassNamedMsg, Name))
        else
            ProofSupport.LogLine('RESULT an unfiltered run is still named',
                StrSubstNo(FailNamedMsg, Expected, Name));

        // Field values come from the records, not the filter, so a whole-table run is named after the
        // first and last account, as a run filtered to that range is.
        ClearPatterns();
        SetPatternFor(Report::"Chart of Accounts", Database::"G/L Account", 'Accounts-[No.]');
        WithFieldPlaceholder := NameWith(Report::"Chart of Accounts", Channel::Preview, EmptyRecRef, '');
        ExpectedWholeTable := StrSubstNo(AccountRangeLbl, FirstAccountNo(), LastAccountNo());

        ProofSupport.LogLine('18 A field placeholder over a run covering every account',
            StrSubstNo(ProducedLbl, WithFieldPlaceholder));
        ProofSupport.LogLine('18 Expected', ExpectedWholeTable);

        if WithFieldPlaceholder = ExpectedWholeTable then
            ProofSupport.LogLine('RESULT a field placeholder names a run that narrowed nothing',
                StrSubstNo(PassWholeTableMsg, WithFieldPlaceholder))
        else
            ProofSupport.LogLine('RESULT a field placeholder names a run that narrowed nothing',
                StrSubstNo(FailWholeTableMsg, ExpectedWholeTable, WithFieldPlaceholder));

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A pattern conditioned on one record does not claim a run that also contains others: the condition
    /// must hold for every record. The single-record run is checked too, so broken conditions cannot pass.
    /// </summary>
    procedure ProveAConditionMustHoldForTheWholeRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        InvoiceFilter: Text;
        Numbers: List of [Text];
        OneInvoice: Text;
        NamedAlone: Text;
        NamedInABatch: Text;
    begin
        ClearPatterns();

        ThreeInvoices(SalesInvoiceHeader, InvoiceFilter, Numbers);
        OneInvoice := FirstOf(Numbers);

        SetConditionedPattern('Just-This-One', OneInvoice);

        NamedAlone := NameWith(Report::"Standard Sales - Invoice", Channel::Preview,
            SourceRecRef, ProofSupport.InvoiceFilterViewsFor(OneInvoice));

        NamedInABatch := NameWith(Report::"Standard Sales - Invoice", Channel::Preview,
            SourceRecRef, ProofSupport.InvoiceFilterViewsFor(InvoiceFilter));

        ProofSupport.LogLine('19 Condition names invoice', OneInvoice);
        ProofSupport.LogLine('19 Run covering only that invoice', NamedAlone);
        ProofSupport.LogLine('19 Run covering it and two others', NamedInABatch);

        case true of
            NamedAlone <> 'Just-This-One':
                ProofSupport.LogLine('RESULT a condition must hold for the whole run',
                    StrSubstNo(FailConditionLostMsg, NamedAlone));
            NamedInABatch = 'Just-This-One':
                ProofSupport.LogLine('RESULT a condition must hold for the whole run',
                    StrSubstNo(FailConditionClaimedMsg, Numbers.Count()));
            else
                ProofSupport.LogLine('RESULT a condition must hold for the whole run',
                    StrSubstNo(PassConditionMsg, OneInvoice, Numbers.Count()));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A run whose records disagree about their language is not named in one of them.
    /// Uses the test app's own report, because report 1306's caption is the same in every language in W1.
    /// </summary>
    procedure ProveARunWithTwoLanguagesPicksOne()
    var
        CompanyInformation: Record "Company Information";
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        OriginalCompanyLanguage: Code[10];
        RestoreLanguage: Integer;
        DanishCaption: Text;
        GermanCaption: Text;
        BothDanish: Text;
        Mixed: Text;
        MixedWithDanishDefault: Text;
    begin
        ClearPatterns();
        TestData.EnsureLanguage(ProofSupport.EnglishLanguageCode(), ProofSupport.EnglishLanguageId());
        TestData.EnsureLanguage(ProofSupport.DanishLanguageCode(), ProofSupport.DanishLanguageId());
        TestData.EnsureLanguage(ProofSupport.GermanLanguageCode(), ProofSupport.GermanLanguageId());
        CompanyInformation.Get();
        OriginalCompanyLanguage := CompanyInformation."Default Language Code";
        CompanyInformation."Default Language Code" := ProofSupport.GermanLanguageCode();
        CompanyInformation.Modify(false);

        DanishCaption := ReportFilenameMgt.Sanitise(ProofSupport.ReportCaptionIn(ProofSupport.DanishLanguageId(), Report::"Filename Proof Report"));
        GermanCaption := ReportFilenameMgt.Sanitise(ProofSupport.ReportCaptionIn(ProofSupport.GermanLanguageId(), Report::"Filename Proof Report"));
        ProofSupport.LogLine('20 Proof report caption DAN', DanishCaption);
        ProofSupport.LogLine('20 Proof report caption DEU', GermanCaption);

        WriteLanguageDocument(LanguageDocumentOneTok, ProofSupport.DanishLanguageCode());
        WriteLanguageDocument(LanguageDocumentTwoTok, ProofSupport.DanishLanguageCode());
        SetProofLanguagePattern(Pattern);

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.EnglishLanguageId());
        BothDanish := NameLanguageRun(ProofDocument, SourceRecRef);
        ProofSupport.AssertNameLanguage(Pattern, SourceRecRef, ProofSupport.DanishLanguageCode());
        ProofSupport.AssertSessionLanguage(ProofSupport.EnglishLanguageId());

        // The company default differs from the first document's language.
        WriteLanguageDocument(LanguageDocumentTwoTok, ProofSupport.GermanLanguageCode());
        Mixed := NameLanguageRun(ProofDocument, SourceRecRef);
        ProofSupport.AssertNameLanguage(Pattern, SourceRecRef, ProofSupport.GermanLanguageCode());
        ProofSupport.AssertSessionLanguage(ProofSupport.EnglishLanguageId());

        // A valid fallback may also match the first document and produce the same filename.
        CompanyInformation."Default Language Code" := ProofSupport.DanishLanguageCode();
        CompanyInformation.Modify(false);
        MixedWithDanishDefault := NameLanguageRun(ProofDocument, SourceRecRef);
        ProofSupport.AssertNameLanguage(Pattern, SourceRecRef, ProofSupport.DanishLanguageCode());
        ProofSupport.AssertSessionLanguage(ProofSupport.EnglishLanguageId());
        GlobalLanguage(RestoreLanguage);
        CompanyInformation."Default Language Code" := OriginalCompanyLanguage;
        CompanyInformation.Modify(false);

        ProofSupport.LogLine('20 Two Danish documents, named as one run', BothDanish);
        ProofSupport.LogLine('20 Mixed documents, German company default', Mixed);
        ProofSupport.LogLine('20 Mixed documents, Danish company default', MixedWithDanishDefault);

        case true of
            BothDanish <> DanishCaption:
                ProofSupport.LogLine('RESULT a run in two languages is named in one',
                    StrSubstNo(FailAgreedLanguageMsg, BothDanish));
            Mixed <> GermanCaption:
                ProofSupport.LogLine('RESULT a run in two languages is named in one',
                    StrSubstNo(FailLanguageOutputMsg, GermanCaption, Mixed));
            MixedWithDanishDefault <> DanishCaption:
                ProofSupport.LogLine('RESULT a run in two languages is named in one',
                    StrSubstNo(FailLanguageOutputMsg, DanishCaption, MixedWithDanishDefault));
            else
                ProofSupport.LogLine('RESULT a run in two languages is named in one',
                    StrSubstNo(PassLanguageMsg, BothDanish, Mixed, MixedWithDanishDefault));
        end;

        ForgetLanguageDocuments();
        ClearPatterns();
        Done();
    end;

    local procedure NameLanguageRun(var ProofDocument: Record "Filename Proof Document"; var SourceRecRef: RecordRef): Text
    var
        Channel: Enum "Report Filename Output Route";
    begin
        ProofDocument.Reset();
        ProofDocument.SetFilter("No.", '%1|%2', LanguageDocumentOneTok, LanguageDocumentTwoTok);
        Clear(SourceRecRef);
        SourceRecRef.GetTable(ProofDocument);
        SourceRecRef.SetView(ProofDocument.GetView());

        exit(NameWith(Report::"Filename Proof Report", Channel::Preview, SourceRecRef, ''));
    end;

    local procedure SetProofLanguagePattern(var Pattern: Record "Report Filename Pattern")
    var
        ProofDocument: Record "Filename Proof Document";
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Filename Proof Report");
        Pattern.Validate("Table No.", Database::"Filename Proof Document");
        Pattern.Validate("File Name Pattern", ReportCaptionOnlyTok);
        // Must be a field related to the Language table; others are refused.
        Pattern.Validate("Language Code Field", ProofDocument.FieldNo("Language Code"));
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure WriteLanguageDocument(DocumentNo: Code[20]; DocumentLanguageCode: Code[10])
    var
        ProofDocument: Record "Filename Proof Document";
    begin
        ProofDocument.Reset();
        if not ProofDocument.Get(DocumentNo) then begin
            ProofDocument.Init();
            ProofDocument."No." := DocumentNo;
            ProofDocument.Insert(false);
        end;

        ProofDocument."Customer Name" := LanguageCustomerTok;
        ProofDocument."Language Code" := DocumentLanguageCode;
        ProofDocument."Document Language Code" := DocumentLanguageCode;
        ProofDocument.Modify(false);
    end;

    local procedure ForgetLanguageDocuments()
    var
        ProofDocument: Record "Filename Proof Document";
    begin
        ProofDocument.Reset();
        ProofDocument.SetFilter("No.", '%1|%2', LanguageDocumentOneTok, LanguageDocumentTwoTok);
        if not ProofDocument.IsEmpty() then
            ProofDocument.DeleteAll(false);
    end;

    /// <summary>
    /// A report whose first data item is a virtual table still has a subject table: report 910 has
    /// Integer first and Posted Assembly Header one level in.
    /// </summary>
    procedure ProveAHiddenSubjectIsFound()
    var
        ReportMetadata: Record "Report Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FirstDataItem: Integer;
        Subject: Integer;
    begin
        if not ReportMetadata.Get(Report::"Posted Assembly Order") then begin
            ProofSupport.LogLine('RESULT a hidden subject is found', StrSubstNo(SkippedMsg, NoAssemblyReportMsg));
            Done();
            exit;
        end;

        FirstDataItem := ReportMetadata.FirstDataItemTableID;
        Subject := ReportFilenameMgt.SubjectTableNo(Report::"Posted Assembly Order");

        ProofSupport.LogLine('21 Report', ReportMetadata.Caption);
        ProofSupport.LogLine('21 Its first data item is table', Format(FirstDataItem));
        ProofSupport.LogLine('21 What the run is about', Format(Subject));

        case true of
            ReportFilenameMgt.IsNamableTable(FirstDataItem):
                // The report changed shape, so this proof no longer tests what it claims.
                ProofSupport.LogLine('RESULT a hidden subject is found',
                    StrSubstNo(FailNotHiddenMsg, FirstDataItem));
            Subject <> Database::"Posted Assembly Header":
                ProofSupport.LogLine('RESULT a hidden subject is found',
                    StrSubstNo(FailSubjectMsg, Database::"Posted Assembly Header", Subject));
            else
                ProofSupport.LogLine('RESULT a hidden subject is found',
                    StrSubstNo(PassSubjectMsg, FirstDataItem, Subject));
        end;

        Done();
    end;

    /// <summary>
    /// Test Pattern can test a filter, not only a single record: checks the name, the record count and
    /// which pattern decided it. An empty filter must mean the whole table.
    /// </summary>
    procedure ProveAFilterCanBeTested()
    var
        GLAccount: Record "G/L Account";
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        FilterView: Text;
        AccountFilter: Text;
        Numbers: List of [Text];
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FromThisPattern: Boolean;
        Counted: Integer;
        Expected: Text;
    begin
        ClearPatterns();

        if not ThreeAccounts(AccountFilter, Numbers) then begin
            ProofSupport.LogLine('RESULT a filter can be tested', StrSubstNo(SkippedMsg, NotEnoughAccountsMsg));
            Done();
            exit;
        end;

        SetPatternFor(Report::"Chart of Accounts", Database::"G/L Account", 'Accounts-[No.]');
        Pattern.FindFirst();

        GLAccount.SetFilter("No.", AccountFilter);
        FilterView := GLAccount.GetView(false);

        ReportFilenamePreviewMgt.ExplainNameForRun(
            Pattern, FilterView, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        if not ReportFilenamePreviewMgt.TryCountRun(Database::"G/L Account", FilterView, Counted) then
            Counted := 0;

        // The explain path shows the whole file name, extension included.
        Expected := StrSubstNo(AccountRangeLbl, FirstOf(Numbers), LastOf(Numbers)) + '.pdf';

        ProofSupport.LogLine('22 Accounts the run covers', Format(Counted));
        ProofSupport.LogLine('22 Name that run would produce', Filename);
        ProofSupport.LogLine('22 Name comes from', NameComesFrom);
        ProofSupport.LogLine('22 Expected', Expected);

        case true of
            Counted <> 3:
                ProofSupport.LogLine('RESULT a filter can be tested', StrSubstNo(FailCountMsg, Counted));
            Filename <> Expected:
                ProofSupport.LogLine('RESULT a filter can be tested', StrSubstNo(FailFilterNameMsg, Expected, Filename));
            not FromThisPattern:
                ProofSupport.LogLine('RESULT a filter can be tested', StrSubstNo(FailNotAttributedMsg, NameComesFrom));
            else
                ProofSupport.LogLine('RESULT a filter can be tested',
                    StrSubstNo(PassFilterMsg, Counted, Filename));
        end;

        ReportFilenamePreviewMgt.ExplainNameForRun(
            Pattern, '', Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
        if not ReportFilenamePreviewMgt.TryCountRun(Database::"G/L Account", '', Counted) then
            Counted := 0;

        ProofSupport.LogLine('22 Accounts an unfiltered run covers', Format(Counted));
        ProofSupport.LogLine('22 The selection in words',
            ReportFilenamePreviewMgt.DescribeSelection(Database::"G/L Account", ''));

        if (Counted = GLAccountCount()) and (Counted > 3) then
            ProofSupport.LogLine('RESULT an empty filter means every record',
                StrSubstNo(PassEveryMsg, Counted))
        else
            ProofSupport.LogLine('RESULT an empty filter means every record',
                StrSubstNo(FailEveryMsg, GLAccountCount(), Counted));

        ClearPatterns();
        Done();
    end;

    local procedure GLAccountCount(): Integer
    var
        GLAccount: Record "G/L Account";
    begin
        exit(GLAccount.Count());
    end;

    /// <returns>False when the company has fewer than three G/L accounts.</returns>
    local procedure ThreeAccounts(var AccountFilter: Text; var Numbers: List of [Text]): Boolean
    var
        GLAccount: Record "G/L Account";
        i: Integer;
    begin
        Clear(Numbers);
        AccountFilter := '';

        GLAccount.SetCurrentKey("No.");
        if not GLAccount.FindSet() then
            exit(false);

        for i := 1 to 3 do begin
            Numbers.Add(GLAccount."No.");
            if AccountFilter <> '' then
                AccountFilter += '|';
            AccountFilter += GLAccount."No.";
            if (i < 3) and (GLAccount.Next() = 0) then
                exit(false);
        end;

        exit(Numbers.Count() = 3);
    end;


    /// <summary>
    /// The setup card offers a single-record and a run-of-many example, built from generated shapes
    /// rather than real records (the example must work without data or read permission). A pattern of
    /// computed values only must offer no second example.
    /// </summary>
    procedure ProveTheExampleDoesNotImplyOneRecord()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        SingleRecord: Text;
        OverMany: Text;
        Reason: Text;
        HasSecond: Boolean;
        ComputedOnly: Text;
        ComputedHasSecond: Boolean;
    begin
        ClearPatterns();

        TestData.PostNewInvoice(SalesInvoiceHeader);

        SetPattern('Invoice-[No.]');
        Pattern.FindFirst();

        if not ReportFilenamePreviewMgt.TryPreviewShape(Pattern, SingleRecord, Reason) then begin
            ProofSupport.LogLine('RESULT the example does not imply one record',
                StrSubstNo(FailNoExampleMsg, Reason));
            ClearPatterns();
            Done();
            exit;
        end;

        HasSecond := ReportFilenamePreviewMgt.TryPreviewShapeOverManyRecords(Pattern, OverMany);

        ProofSupport.LogLine('24 Example for a run covering one record', SingleRecord);
        ProofSupport.LogLine('24 Example for a run covering several', OverMany);

        ClearPatterns();

        SetPattern('Chart-[Your Company Name]');
        Pattern.FindFirst();
        ComputedHasSecond := ReportFilenamePreviewMgt.TryPreviewShapeOverManyRecords(Pattern, ComputedOnly);
        ProofSupport.LogLine('24 A pattern of computed values only offers a second example',
            StrSubstNo(YesNoLbl, ComputedHasSecond));

        case true of
            StrPos(SingleRecord, ShapeTok) = 0:
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(FailNotAShapeMsg, ShapeTok, SingleRecord));
            RealInvoiceLeaked(SalesInvoiceHeader."No.", SingleRecord) or RealInvoiceLeaked(SalesInvoiceHeader."No.", OverMany):
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(FailReadARecordMsg, SingleRecord, OverMany));
            not HasSecond:
                ProofSupport.LogLine('RESULT the example does not imply one record', FailNoRunExampleMsg);
            StrPos(OverMany, RangeMarkerTok) = 0:
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(FailNoRangeMsg, OverMany));
            ComputedHasSecond:
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(FailComputedCollapsedMsg, ComputedOnly));
            else
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(PassExampleMsg, SingleRecord, OverMany));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// Checks the proof's own invoice and the first and last posted invoices, which are what a record read would return.
    /// </summary>
    local procedure RealInvoiceLeaked(InvoiceNo: Code[20]; Example: Text): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Example = '' then
            exit(false);
        if StrPos(Example, InvoiceNo) > 0 then
            exit(true);

        SalesInvoiceHeader.SetLoadFields("No.");
        if SalesInvoiceHeader.FindFirst() then
            if StrPos(Example, SalesInvoiceHeader."No.") > 0 then
                exit(true);
        if SalesInvoiceHeader.FindLast() then
            if StrPos(Example, SalesInvoiceHeader."No.") > 0 then
                exit(true);
        exit(false);
    end;


    /// <summary>
    /// Every installed report fits the model. A report fails only if it produces a file and has a subject
    /// table that cannot be set up; processing-only reports and reports about no record are handled.
    /// </summary>
    procedure ProveEveryReportFitsTheModel()
    var
        ReportMetadata: Record "Report Metadata";
        TempTableBuffer: Record "Report Filename Table Buffer" temporary;
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        SubjectTableNo: Integer;
        Total: Integer;
        NoFile: Integer;
        SubjectIsFirst: Integer;
        SubjectIsDeeper: Integer;
        AboutNoRecord: Integer;
        Failures: Integer;
        Listed: Integer;
        Reason: Text;
        FailureList: Text;
    begin
        Total := 0;
        NoFile := 0;
        SubjectIsFirst := 0;
        SubjectIsDeeper := 0;
        AboutNoRecord := 0;
        Failures := 0;
        Listed := 0;

        FilenamePlaceholderMgt.BuildTables(TempTableBuffer);

        if not ReportMetadata.FindSet() then begin
            ProofSupport.LogLine('RESULT every installed report fits the model', StrSubstNo(SkippedMsg, NoReportsMsg));
            Done();
            exit;
        end;

        repeat
            Total += 1;

            if ReportMetadata.ProcessingOnly then
                NoFile += 1
            else begin
                SubjectTableNo := ReportFilenameMgt.SubjectTableNo(ReportMetadata.ID);

                case true of
                    SubjectTableNo = 0:
                        AboutNoRecord += 1;
                    SubjectTableNo = ReportMetadata.FirstDataItemTableID:
                        SubjectIsFirst += 1;
                    else
                        SubjectIsDeeper += 1;
                end;

                if SubjectTableNo <> 0 then
                    if not SubjectCanBeSetUp(SubjectTableNo, TempTableBuffer, Reason) then begin
                        Failures += 1;
                        if Listed < 20 then begin
                            Listed += 1;
                            FailureList += StrSubstNo(FailureLineLbl, ReportMetadata.ID, ReportMetadata.Caption, Reason);
                        end;
                    end;
            end;
        until ReportMetadata.Next() = 0;

        ProofSupport.LogLine('25 Reports installed', Format(Total));
        ProofSupport.LogLine('25 Produce no file at all', Format(NoFile));
        ProofSupport.LogLine('25 Subject is the first data item', Format(SubjectIsFirst));
        ProofSupport.LogLine('25 Subject found by descending', Format(SubjectIsDeeper));
        ProofSupport.LogLine('25 About no record, computed values only', Format(AboutNoRecord));
        ProofSupport.LogLine('25 Tables offered', Format(TempTableBuffer.Count()));
        ProofSupport.LogLine('25 Reports whose subject cannot be set up', Format(Failures));

        if Failures = 0 then
            ProofSupport.LogLine('RESULT every installed report fits the model',
                StrSubstNo(PassFitMsg, Total, NoFile, SubjectIsFirst, SubjectIsDeeper, AboutNoRecord))
        else
            ProofSupport.LogLine('RESULT every installed report fits the model',
                StrSubstNo(FailFitMsg, Failures, FailureList));

        Done();
    end;

    /// <summary>
    /// The setup must be able to name the table, offer it in the table list, and read a field from it.
    /// </summary>
    local procedure SubjectCanBeSetUp(SubjectTableNo: Integer; var TempTableBuffer: Record "Report Filename Table Buffer"; var Reason: Text): Boolean
    var
        TableMetadata: Record "Table Metadata";
        FieldRec: Record Field;
    begin
        Clear(Reason);

        if not TableMetadata.Get(SubjectTableNo) then begin
            Reason := NoTableMetadataMsg;
            exit(false);
        end;
        if TableMetadata.Caption = '' then begin
            Reason := NoCaptionMsg;
            exit(false);
        end;

        if not TempTableBuffer.Get(SubjectTableNo) then begin
            Reason := NotOfferedMsg;
            exit(false);
        end;

        FieldRec.SetRange(TableNo, SubjectTableNo);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        FieldRec.SetRange(Access, FieldRec.Access::Public);
        if FieldRec.IsEmpty() then begin
            Reason := NoFieldsMsg;
            exit(false);
        end;

        exit(true);
    end;


    /// <summary>
    /// Raises Reporting Triggers.GetFilename and lets the whole chain run (codeunit 44's OnGetFilename,
    /// then this app's subscriber), so a subscriber that compiles but never binds is caught.
    /// It does not prove the platform raises the event on any given delivery route; that needs a client.
    /// </summary>
    procedure ProveTheNamingHookNamesTheFile()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportingTriggers: Codeunit "Reporting Triggers";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Filename: Text;
        Expected: Text;
        Success: Boolean;
    begin
        ClearPatterns();

        TestData.PostNewInvoice(SalesInvoiceHeader);

        SetPattern('Invoice-[No.]');

        // Read from text, in the shape the platform sends: filters keyed by table and the delivery intent.
        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader))) then begin
            ProofSupport.LogLine('RESULT the platform naming hook reaches this feature', BadPayloadMsg);
            ClearPatterns();
            Done();
            exit;
        end;

        // No record reference, so the name must come from the payload filter.
        Success := false;
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);

        Expected := 'Invoice-' + SalesInvoiceHeader."No." + PdfExtensionLbl;

        ProofSupport.LogLine('26 Raised', RaisedLbl);
        ProofSupport.LogLine('26 Success came back', Format(Success));
        ProofSupport.LogLine('26 File name came back', Filename);
        ProofSupport.LogLine('26 Expected', Expected);

        case true of
            not Success:
                ProofSupport.LogLine('RESULT the platform naming hook reaches this feature', NotAnsweredMsg);
            Filename <> Expected:
                ProofSupport.LogLine('RESULT the platform naming hook reaches this feature',
                    StrSubstNo(WrongNameMsg, Expected, Filename));
            else
                ProofSupport.LogLine('RESULT the platform naming hook reaches this feature',
                    StrSubstNo(PassHookMsg, Filename));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// The switch in Report Filename Setup turns naming off and on again without touching the patterns.
    /// </summary>
    procedure ProveTheSwitchTurnsNamingOff()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        ReportingTriggers: Codeunit "Reporting Triggers";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Filename: Text;
        Success: Boolean;
    begin
        ClearPatterns();

        TestData.PostNewInvoice(SalesInvoiceHeader);

        SetPattern('Invoice-[No.]');
        Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader)));

        FilenameProofGuard.SwitchFeatureOff();
        Success := false;
        Clear(Filename);
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);
        ProofSupport.LogLine('27 Switched off, Success came back', Format(Success));
        ProofSupport.LogLine('27 Switched off, file name came back', Filename);
        if not Success then
            ProofSupport.LogLine('RESULT switched off, no pattern names a file', PassSwitchedOffMsg)
        else
            ProofSupport.LogLine('RESULT switched off, no pattern names a file', StrSubstNo(SwitchedOffButNamedMsg, Filename));

        FilenameProofGuard.SwitchFeatureOn();
        Success := false;
        Clear(Filename);
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);
        ProofSupport.LogLine('28 Switched on again, file name came back', Filename);
        if Success and (Filename = 'Invoice-' + SalesInvoiceHeader."No." + PdfExtensionLbl) then
            ProofSupport.LogLine('RESULT switched on again, the same pattern names the file', StrSubstNo(PassSwitchedOnMsg, Filename))
        else
            ProofSupport.LogLine('RESULT switched on again, the same pattern names the file',
                StrSubstNo(WrongNameMsg, 'Invoice-' + SalesInvoiceHeader."No." + PdfExtensionLbl, Filename));

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A file already named (Success true) survives the whole chain untouched. This is a property of the
    /// chain, not of this app's guard: codeunit 44 does not raise OnGetFilename when Success is already true.
    /// ProveOurGuardStandsDownForAnotherSubscriber exercises this app's guard.
    /// </summary>
    procedure ProveTheHookLeavesAnAlreadyNamedFileAlone()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportingTriggers: Codeunit "Reporting Triggers";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Filename: Text;
        Success: Boolean;
    begin
        ClearPatterns();

        TestData.PostNewInvoice(SalesInvoiceHeader);

        SetPattern('Invoice-[No.]');

        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader))) then begin
            ProofSupport.LogLine('RESULT a name somebody else set survives the whole chain', BadPayloadMsg);
            ClearPatterns();
            Done();
            exit;
        end;

        // Somebody got there first.
        Filename := AlreadyNamedLbl;
        Success := true;

        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);

        ProofSupport.LogLine('26 Name somebody else had already set', AlreadyNamedLbl);
        ProofSupport.LogLine('26 Name after the hook ran', Filename);

        if Filename = AlreadyNamedLbl then
            ProofSupport.LogLine('RESULT a name somebody else set survives the whole chain',
                StrSubstNo(PassLeftAloneMsg, Filename))
        else
            ProofSupport.LogLine('RESULT a name somebody else set survives the whole chain',
                StrSubstNo(FailOverrodeMsg, AlreadyNamedLbl, Filename));

        ClearPatterns();
        Done();
    end;


    /// <summary>
    /// This app's "if Success then exit" guard stands down for another subscriber, using Base Application's
    /// Reminder Communication as the second subscriber. Each subscriber is first shown to name the file
    /// alone, so a pass cannot come from one of them never being in play. Subscriber order is unspecified,
    /// so the guard is also exercised by calling this app's subscriber directly with a file already named.
    /// </summary>
    procedure ProveOurGuardStandsDownForAnotherSubscriber()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderLevel: Record "Reminder Level";
        PreviousAttachmentTextId: Guid;
        SeededAttachmentTextId: Guid;
        LanguageCode: Code[10];
        NameOursAlone: Text;
        NameAfterSomebodyElse: Text;
        NameTheirsAlone: Text;
        NameBothInPlay: Text;
        ExpectedOurs: Text;
        ExpectedTheirs: Text;
    begin
        ClearPatterns();

        // New terms with no attachment text, so nothing names it until the level gets a file name.
        CreateReminderForTheChain(IssuedReminderHeader, ReminderLevel);

        ProofSupport.LogLine('27 Reminder the chain is raised for', IssuedReminderHeader."No.");
        ProofSupport.LogLine('27 Its reminder terms and level',
            StrSubstNo(TermsAndLevelLbl, IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level"));

        // Raise one: this app alone must name the file, or it is not a competitor.
        SetPatternFor(Report::Reminder, Database::"Issued Reminder Header", OurReminderPatternTok);
        ExpectedOurs := OurReminderPrefixTok + IssuedReminderHeader."No." + PdfExtensionLbl;
        NameOursAlone := RaiseTheRealChain(IssuedReminderHeader);
        ProofSupport.LogLine('27 With only this feature in play', NameOursAlone);

        if NameOursAlone <> ExpectedOurs then begin
            ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailOursDoesNotClaimMsg, ExpectedOurs, NameOursAlone));
            ClearPatterns();
            Done();
            exit;
        end;

        // The guard reached directly: raise three reaches it only if Reminder Communication runs first
        // (otherwise IsNamedByReminderCommunication declines), and subscriber order cannot be forced.
        NameAfterSomebodyElse := CallOurSubscriberAfterSomebodyElse(IssuedReminderHeader);
        ProofSupport.LogLine('27 Handed to this feature already named', NameAfterSomebodyElse);
        if NameAfterSomebodyElse = AlreadyNamedLbl then
            ProofSupport.LogLine(GuardDirectVerdictTok, StrSubstNo(PassLeftAloneDirectMsg, AlreadyNamedLbl, ExpectedOurs))
        else
            ProofSupport.LogLine(GuardDirectVerdictTok, StrSubstNo(FailOverrodeMsg, AlreadyNamedLbl, NameAfterSomebodyElse));

        // Raise two: Reminder Communication alone. Its other conditions come from the raise; the level's
        // file name is seeded here.
        ClearPatterns();

        LanguageCode := AttachmentLanguageCode(IssuedReminderHeader."Customer No.");
        PreviousAttachmentTextId := ReminderLevel."Reminder Attachment Text";
        ProofSupport.LogLine('27 Language its attachment text is read in', LanguageCode);

        if not SeedReminderFileName(ReminderLevel, LanguageCode, SeededAttachmentTextId) then begin
            ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailCouldNotSeedMsg, GetLastErrorText()));
            ClearPatterns();
            Done();
            exit;
        end;

        ExpectedTheirs := TheirFileNameTok + PdfExtensionLbl;
        NameTheirsAlone := RaiseTheRealChain(IssuedReminderHeader);
        ProofSupport.LogLine('27 With only the other subscriber in play', NameTheirsAlone);

        if NameTheirsAlone <> ExpectedTheirs then begin
            ProofSupport.LogLine(GuardVerdictTok,
                StrSubstNo(FailTheirsDidNotNameMsg, ExpectedTheirs, NameTheirsAlone, SuppliedGuardsText(IssuedReminderHeader)));
            RestoreReminderFileName(ReminderLevel, PreviousAttachmentTextId, SeededAttachmentTextId);
            ClearPatterns();
            Done();
            exit;
        end;

        // Raise three: both in play.
        SetPatternFor(Report::Reminder, Database::"Issued Reminder Header", OurReminderPatternTok);
        NameBothInPlay := RaiseTheRealChain(IssuedReminderHeader);
        ProofSupport.LogLine('27 With both in play', NameBothInPlay);
        ProofSupport.LogLine('27 The other subscriber would name it', ExpectedTheirs);
        ProofSupport.LogLine('27 This feature would name it', ExpectedOurs);

        case true of
            NameBothInPlay = ExpectedTheirs:
                ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(PassGuardMsg, ExpectedTheirs, ExpectedOurs));
            NameBothInPlay = ExpectedOurs:
                ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailWeWentFirstMsg, ExpectedOurs, ExpectedTheirs));
            else
                ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailNeitherMsg, NameBothInPlay, ExpectedTheirs, ExpectedOurs));
        end;

        RestoreReminderFileName(ReminderLevel, PreviousAttachmentTextId, SeededAttachmentTextId);
        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A File Name on the reminder level's attachment text means Base Application names the reminder and
    /// this app leaves it alone on every route; without one, the pattern names every route. Reminder
    /// Communication names only on the naming event with the reminder record and on the email attachment,
    /// so the other routes do not depend on subscriber order. Test Pattern must report the same.
    /// </summary>
    procedure ProveAReminderBaseApplicationNamesKeepsItsName()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderLevel: Record "Reminder Level";
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        PreviousAttachmentTextId: Guid;
        SeededAttachmentTextId: Guid;
        Names: array[5] of Text;
        Expected: array[5] of Text;
        ExpectedOurs: Text;
        ExpectedTheirs: Text;
        ShownName: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FromThisPattern: Boolean;
    begin
        ClearPatterns();

        // New terms with no attachment text, so only the File Name seeded below decides.
        CreateReminderForTheChain(IssuedReminderHeader, ReminderLevel);

        ProofSupport.LogLine('29 Reminder', IssuedReminderHeader."No.");
        ProofSupport.LogLine('29 Its reminder terms and level',
            StrSubstNo(TermsAndLevelLbl, IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level"));

        SetPatternFor(Report::Reminder, Database::"Issued Reminder Header", OurReminderPatternTok);
        ExpectedOurs := OurReminderPrefixTok + IssuedReminderHeader."No.";
        ExpectedTheirs := TheirFileNameTok + PdfExtensionLbl;

        // One: no File Name, so the pattern names every route.
        NameOnEveryRoute(IssuedReminderHeader, Names);
        Expected[1] := ExpectedOurs + PdfExtensionLbl;
        Expected[2] := ExpectedOurs + PdfExtensionLbl;
        Expected[3] := ExpectedOurs + PdfExtensionLbl;
        Expected[4] := ExpectedOurs;
        Expected[5] := ExpectedOurs;
        LogRoutes('29 No File Name', Names, Expected);
        if RoutesAgree(Names, Expected) then
            ProofSupport.LogLine(ReminderUnconfiguredVerdictTok, StrSubstNo(PassReminderByPatternMsg, ExpectedOurs))
        else
            ProofSupport.LogLine(ReminderUnconfiguredVerdictTok, StrSubstNo(FailRoutesMsg, RoutesText(Names, Expected)));

        // Two: the level's attachment text carries a File Name.
        PreviousAttachmentTextId := ReminderLevel."Reminder Attachment Text";
        if not SeedReminderFileName(ReminderLevel, AttachmentLanguageCode(IssuedReminderHeader."Customer No."), SeededAttachmentTextId) then begin
            ProofSupport.LogLine(ReminderConfiguredVerdictTok, StrSubstNo(FailCouldNotSeedMsg, GetLastErrorText()));
            ClearPatterns();
            Done();
            exit;
        end;

        // Base Application's name where it names the reminder, its default elsewhere - as without this app.
        NameOnEveryRoute(IssuedReminderHeader, Names);
        Expected[1] := ExpectedTheirs;
        Expected[2] := '';
        Expected[3] := ExpectedTheirs;
        Expected[4] := '';
        Expected[5] := '';
        LogRoutes('29 File Name set', Names, Expected);
        if RoutesAgree(Names, Expected) then
            ProofSupport.LogLine(ReminderConfiguredVerdictTok, StrSubstNo(PassReminderByBaseAppMsg, ExpectedTheirs, ExpectedOurs))
        else
            ProofSupport.LogLine(ReminderConfiguredVerdictTok, StrSubstNo(FailRoutesMsg, RoutesText(Names, Expected)));

        // Three: Test Pattern says so.
        Pattern.FindFirst();
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(Pattern, IssuedReminderHeader.RecordId(), ShownName, NameComesFrom, WhyNotThisPattern, FromThisPattern);
        ProofSupport.LogLine('29 Test Pattern shows', ShownName);
        ProofSupport.LogLine('29 Test Pattern says it comes from', NameComesFrom);
        ProofSupport.LogLine('29 Test Pattern gives as the reason', WhyNotThisPattern);
        if (ShownName <> '') and (ShownName <> ExpectedOurs + PdfExtensionLbl) and (NameComesFrom <> '') and
           (StrPos(WhyNotThisPattern, ExpectedOurs + PdfExtensionLbl) > 0) and not FromThisPattern
        then
            ProofSupport.LogLine(ReminderTestPatternVerdictTok, PassReminderTestPatternMsg)
        else
            ProofSupport.LogLine(ReminderTestPatternVerdictTok,
                StrSubstNo(FailReminderTestPatternMsg, ExpectedOurs + PdfExtensionLbl, ShownName, NameComesFrom, WhyNotThisPattern));

        RestoreReminderFileName(ReminderLevel, PreviousAttachmentTextId, SeededAttachmentTextId);
        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// Names one reminder on each route this proof tells apart:
    ///   1 the platform's naming event with the reminder handed over;
    ///   2 the same event with no record handed over;
    ///   3 the emailed attachment, through Document-Mailing's own GetAttachmentFileName;
    ///   4 Send to Disk and 5 Attach as PDF, through the manager, which is what those subscribers call.
    /// A route that names nothing comes back empty.
    /// </summary>
    local procedure NameOnEveryRoute(var IssuedReminderHeader: Record "Issued Reminder Header"; var Names: array[5] of Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentMailing: Codeunit "Document-Mailing";
        ReminderRecRef: RecordRef;
        AttachmentFileName: Text[250];
    begin
        Clear(Names);
        Names[1] := RaiseTheRealChain(IssuedReminderHeader);
        Names[2] := RaiseTheRealChainWithoutRecord(IssuedReminderHeader);

        // The email subscriber reads the document the render recorded.
        IssuedReminderHeader.SetRecFilter();
        ReminderRecRef.GetTable(IssuedReminderHeader);
        ReportFilenameContext.SetRenderedDocument(ReminderRecRef, Report::Reminder);
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, IssuedReminderHeader."No.", ReminderCaptionLbl, "Report Selection Usage"::Reminder.AsInteger());
        ReportFilenameContext.ClearLastRendered();
        ReportFilenameContext.ClearHeldDocument();
        // Only a pattern's or Reminder Communication's name counts; Business Central's default counts as unnamed.
        if (AttachmentFileName = OurReminderPrefixTok + IssuedReminderHeader."No." + PdfExtensionLbl) or (AttachmentFileName = TheirFileNameTok + PdfExtensionLbl) then
            Names[3] := AttachmentFileName;

        Names[4] := NameWith(Report::Reminder, "Report Filename Output Route"::Disk, ReminderRecRef, '');
        Names[5] := NameWith(Report::Reminder, "Report Filename Output Route"::AttachAsPdf, ReminderRecRef, '');
    end;

    local procedure LogRoutes(Prefix: Text; var Names: array[5] of Text; var Expected: array[5] of Text)
    var
        i: Integer;
    begin
        for i := 1 to 5 do
            ProofSupport.LogLine(Prefix + ', ' + RouteName(i), StrSubstNo(GotAndExpectedLbl, Names[i], Expected[i]));
    end;

    local procedure RoutesAgree(var Names: array[5] of Text; var Expected: array[5] of Text): Boolean
    var
        i: Integer;
    begin
        for i := 1 to 5 do
            if Names[i] <> Expected[i] then
                exit(false);
        exit(true);
    end;

    local procedure RoutesText(var Names: array[5] of Text; var Expected: array[5] of Text) Result: Text
    var
        i: Integer;
    begin
        for i := 1 to 5 do
            if Names[i] <> Expected[i] then
                Result += StrSubstNo(RouteDifferenceLbl, RouteName(i), Expected[i], Names[i]);
    end;

    local procedure RouteName(Route: Integer): Text
    begin
        case Route of
            1:
                exit(RouteRecordHandedOverLbl);
            2:
                exit(RouteNoRecordLbl);
            3:
                exit(RouteEmailLbl);
            4:
                exit(RouteDiskLbl);
            5:
                exit(RouteAttachLbl);
        end;
    end;

    /// <summary>
    /// The naming event with no record. Reminder Communication names a file only when handed the issued
    /// reminder record, so the outcome does not depend on subscriber order.
    /// </summary>
    /// <returns>Empty when nothing named the file.</returns>
    local procedure RaiseTheRealChainWithoutRecord(var IssuedReminderHeader: Record "Issued Reminder Header") Filename: Text
    var
        ReportingTriggers: Codeunit "Reporting Triggers";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Success: Boolean;
    begin
        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.IssuedReminderFilterViews(IssuedReminderHeader))) then
            exit('');

        Filename := IncomingReminderNameTok;
        Success := false;
        ReportingTriggers.GetFilename(
            Report::Reminder, ReminderCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);

        if not Success then
            exit('');
    end;

    /// <summary>
    /// Calls this app's subscriber with a file already named (Success true), shaped as the real raise.
    /// </summary>
    local procedure CallOurSubscriberAfterSomebodyElse(var IssuedReminderHeader: Record "Issued Reminder Header") Filename: Text
    var
        ReportFilenameSubscribers: Codeunit "Report Filename Subscribers";
        ReminderRecRef: RecordRef;
        Payload: JsonObject;
        Success: Boolean;
    begin
        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.IssuedReminderFilterViews(IssuedReminderHeader))) then
            exit('');

        ReminderRecRef.GetTable(IssuedReminderHeader);
        Filename := AlreadyNamedLbl;
        Success := true;
        ReportFilenameSubscribers.NameFromPlatformEvent(Report::Reminder, Payload, PdfExtensionLbl, ReminderRecRef, Filename, Success);
    end;

    /// <summary>
    /// Shaped to meet Reminder Communication's conditions: report 117, a .pdf extension, an incoming name
    /// containing its word for a reminder, and a reference to the issued reminder.
    /// </summary>
    /// <returns>Empty when nothing named the file.</returns>
    local procedure RaiseTheRealChain(var IssuedReminderHeader: Record "Issued Reminder Header") Filename: Text
    var
        ReportingTriggers: Codeunit "Reporting Triggers";
        ReminderRecRef: RecordRef;
        Payload: JsonObject;
        Success: Boolean;
    begin
        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.IssuedReminderFilterViews(IssuedReminderHeader))) then
            exit('');

        ReminderRecRef.GetTable(IssuedReminderHeader);

        Filename := IncomingReminderNameTok;
        Success := false;
        ReportingTriggers.GetFilename(
            Report::Reminder, ReminderCaptionLbl, Payload, PdfExtensionLbl, ReminderRecRef, Filename, Success);

        if not Success then
            exit('');
    end;

    /// <summary>
    /// Lists the conditions supplied, so a failure to reach Reminder Communication can be diagnosed.
    /// </summary>
    local procedure SuppliedGuardsText(var IssuedReminderHeader: Record "Issued Reminder Header"): Text
    begin
        exit(StrSubstNo(SuppliedGuardsLbl, Report::Reminder, PdfExtensionLbl, IncomingReminderNameTok,
            IssuedReminderHeader.TableCaption(), TheirFileNameTok));
    end;

    /// <summary>
    /// Level 1 of new reminder terms, for a new customer, with no attachment text until SeedReminderFileName.
    /// </summary>
    local procedure CreateReminderForTheChain(var IssuedReminderHeader: Record "Issued Reminder Header"; var ReminderLevel: Record "Reminder Level")
    begin
        TestData.CreateIssuedReminder(TestData.CreateCustomer(), TestData.CreateReminderTerms(1), 1, '', IssuedReminderHeader);
        ReminderLevel.Get(IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level");
    end;

    /// <summary>
    /// The language Reminder Communication reads its attachment text in: customer, then user, then application default.
    /// </summary>
    local procedure AttachmentLanguageCode(CustomerNo: Code[20]) LanguageCode: Code[10]
    var
        Customer: Record Customer;
        LanguageMgt: Codeunit Language;
    begin
        if Customer.Get(CustomerNo) then
            LanguageCode := Customer."Language Code";

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetUserLanguageCode();

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetLanguageCode(LanguageMgt.GetDefaultApplicationLanguageId());
    end;

    /// <summary>
    /// The file name has no per-cent sign, because Reminder Communication puts it through StrSubstNo.
    /// </summary>
    /// <param name="ReminderLevel">Modified in place.</param>
    local procedure SeedReminderFileName(var ReminderLevel: Record "Reminder Level"; LanguageCode: Code[10]; var SeededId: Guid): Boolean
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        SeededId := CreateGuid();

        ReminderAttachmentText.Init();
        ReminderAttachmentText.Id := SeededId;
        ReminderAttachmentText."Language Code" := LanguageCode;
        ReminderAttachmentText."File Name" := TheirFileNameTok;
        if not ReminderAttachmentText.Insert(false) then
            exit(false);

        ReminderLevel."Reminder Attachment Text" := SeededId;
        exit(ReminderLevel.Modify(false));
    end;

    local procedure RestoreReminderFileName(var ReminderLevel: Record "Reminder Level"; PreviousId: Guid; SeededId: Guid)
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        ReminderLevel."Reminder Attachment Text" := PreviousId;
        ReminderLevel.Modify(false);

        ReminderAttachmentText.SetRange(Id, SeededId);
        ReminderAttachmentText.DeleteAll(false);
    end;


    /// <summary>
    /// One selection gets one name however its filter is written ("A|B|C" or "A..C"; a closed range,
    /// an open range or no filter), because the name comes from the records, not the filter text.
    /// </summary>
    procedure ProveOneSelectionGetsOneName()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLAccount: Record "G/L Account";
        InvoiceFilter: Text;
        Numbers: List of [Text];
        Listed: Text;
        Ranged: Text;
        ExpectedList: Text;
        Unfiltered: Text;
        ClosedRange: Text;
        OpenRange: Text;
        ExpectedWhole: Text;
    begin
        ClearPatterns();

        // Three named individually: at a lower limit both filters would collapse to a range and agree trivially.
        ThreeInvoices(SalesInvoiceHeader, InvoiceFilter, Numbers);

        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", 'Invoices-[No.]', 3);

        Listed := NameForInvoiceFilter(AlternationOf(Numbers));
        Ranged := NameForInvoiceFilter(FirstOf(Numbers) + RangeTok + LastOf(Numbers));
        ExpectedList := ListedInvoicesLbl + JoinedWithDash(Numbers);

        ProofSupport.LogLine('29 Three invoices listed one by one', Listed);
        ProofSupport.LogLine('29 The same three as a range', Ranged);
        ProofSupport.LogLine('29 Expected', ExpectedList);

        case true of
            Listed <> Ranged:
                ProofSupport.LogLine('RESULT one selection gets one name',
                    StrSubstNo(FailTwoNamesMsg, Listed, Ranged));
            Listed <> ExpectedList:
                ProofSupport.LogLine('RESULT one selection gets one name',
                    StrSubstNo(FailWrongOneNameMsg, ExpectedList, Listed));
            else
                ProofSupport.LogLine('RESULT one selection gets one name',
                    StrSubstNo(PassOneNameMsg, Listed));
        end;

        ClearPatterns();
        if GLAccount.IsEmpty() then begin
            ProofSupport.LogLine('RESULT every way of saying the whole table agrees', StrSubstNo(SkippedMsg, NoAccountsMsg));
            ClearPatterns();
            Done();
            exit;
        end;

        SetPatternNaming(Report::"Chart of Accounts", Database::"G/L Account", 'Accounts-[No.]', 2);

        Unfiltered := NameForAccountFilter('');
        ClosedRange := NameForAccountFilter(FirstAccountNo() + RangeTok + LastAccountNo());
        OpenRange := NameForAccountFilter(FirstAccountNo() + RangeTok);
        ExpectedWhole := StrSubstNo(AccountRangeLbl, FirstAccountNo(), LastAccountNo());

        ProofSupport.LogLine('29 Every account, with no filter', Unfiltered);
        ProofSupport.LogLine('29 Every account, as a closed range', ClosedRange);
        ProofSupport.LogLine('29 Every account, as an open range', OpenRange);
        ProofSupport.LogLine('29 Expected', ExpectedWhole);

        case true of
            (Unfiltered <> ClosedRange) or (ClosedRange <> OpenRange):
                ProofSupport.LogLine('RESULT every way of saying the whole table agrees',
                    StrSubstNo(FailThreeNamesMsg, Unfiltered, ClosedRange, OpenRange));
            Unfiltered <> ExpectedWhole:
                ProofSupport.LogLine('RESULT every way of saying the whole table agrees',
                    StrSubstNo(FailWrongOneNameMsg, ExpectedWhole, Unfiltered));
            else
                ProofSupport.LogLine('RESULT every way of saying the whole table agrees',
                    StrSubstNo(PassThreeNamesMsg, Unfiltered));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// The selection in the payload filter, with no record.
    /// </summary>
    local procedure NameForInvoiceFilter(FilterExpression: Text): Text
    var
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        exit(NameWith(Report::"Standard Sales - Invoice", Channel::Preview, EmptyRecRef,
            ProofSupport.InvoiceFilterViewsFor(FilterExpression)));
    end;

    /// <summary>
    /// An empty expression is a run over every account.
    /// </summary>
    local procedure NameForAccountFilter(FilterExpression: Text): Text
    var
        GLAccount: Record "G/L Account";
        AccountRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if FilterExpression <> '' then
            GLAccount.SetFilter("No.", CopyStr(FilterExpression, 1, 250));
        AccountRecRef.GetTable(GLAccount);

        exit(NameWith(Report::"Chart of Accounts", Channel::Preview, AccountRecRef, ''));
    end;

    local procedure AlternationOf(var Numbers: List of [Text]) Expression: Text
    var
        Number: Text;
    begin
        foreach Number in Numbers do begin
            if Expression <> '' then
                Expression += AlternationTok;
            Expression += Number;
        end;
    end;

    local procedure JoinedWithDash(var Values: List of [Text]) Joined: Text
    var
        Value: Text;
    begin
        foreach Value in Values do begin
            if Joined <> '' then
                Joined += '-';
            Joined += Value;
        end;
    end;

    local procedure FirstAccountNo(): Text
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Reset();
        if GLAccount.FindFirst() then
            exit(GLAccount."No.");
    end;

    local procedure LastAccountNo(): Text
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Reset();
        if GLAccount.FindLast() then
            exit(GLAccount."No.");
    end;

    local procedure SetPatternNaming(ReportId: Integer; TableNo: Integer; PatternText: Text; MaxNamed: Integer)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.Init();
        Pattern."Report ID" := ReportId;
        Pattern.Validate("Table No.", TableNo);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern."Max. Values Named" := MaxNamed;
        Pattern."Separator" := '-';
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    /// <summary>
    /// The example shows both shapes of a run: listed values while they fit Max. Values Named, and
    /// first-to-last beyond. A pattern with Max. Values Named 1 has no listed form and must not offer one.
    /// </summary>
    procedure ProveTheExampleShowsBothShapesOfARun()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        AFewRecords: Text;
        ManyRecords: Text;
        OneNamedFew: Text;
        HasFew: Boolean;
        HasMany: Boolean;
        OneNamedHasFew: Boolean;
    begin
        ClearPatterns();

        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", 'Invoice-[No.]', 3);
        Pattern.FindFirst();

        HasFew := ReportFilenamePreviewMgt.TryPreviewShapeOverAFewRecords(Pattern, AFewRecords);
        HasMany := ReportFilenamePreviewMgt.TryPreviewShapeOverManyRecords(Pattern, ManyRecords);

        ProofSupport.LogLine('30 Naming three individually, a few records', AFewRecords);
        ProofSupport.LogLine('30 Naming three individually, many records', ManyRecords);

        ClearPatterns();
        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", 'Invoice-[No.]', 1);
        Pattern.FindFirst();
        OneNamedHasFew := ReportFilenamePreviewMgt.TryPreviewShapeOverAFewRecords(Pattern, OneNamedFew);
        ProofSupport.LogLine('30 Naming one individually offers a listed example',
            StrSubstNo(YesNoLbl, OneNamedHasFew));

        case true of
            not HasFew:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has', FailNoFewMsg);
            not HasMany:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has', FailNoManyMsg);
            StrPos(AFewRecords, RangeMarkerTok) > 0:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailFewIsARangeMsg, AFewRecords));
            StrPos(ManyRecords, RangeMarkerTok) = 0:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailManyIsNotARangeMsg, ManyRecords));
            AFewRecords = ManyRecords:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailBothSameMsg, AFewRecords));
            not AFewRecords.EndsWith(PdfExtensionForExampleTok):
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailFewWithoutExtensionMsg, AFewRecords));
            OneNamedHasFew:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailOneNamedOfferedFewMsg, OneNamedFew));
            else
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(PassBothShapesMsg, AFewRecords, ManyRecords));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A run whose records point at different related records is named after all of them: same terms
    /// give one description, three different are listed, or collapse to first-to-last. The ends follow
    /// the pointing field's order, not the descriptions' alphabetical order; the test data makes these differ.
    /// </summary>
    procedure ProveARunOverSeveralRelatedRecordsIsNamed()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        Numbers: List of [Text];
        Codes: List of [Text];
        Descriptions: List of [Text];
        InvoiceFilter: Text;
        HopPlaceholder: Text;
        SameTerms: Text;
        Listed: Text;
        Collapsed: Text;
        ExpectedSame: Text;
        ExpectedListed: Text;
        ExpectedCollapsed: Text;
    begin
        ClearPatterns();

        ThreeInvoices(SalesInvoiceHeader, InvoiceFilter, Numbers);
        CreateThreePaymentTerms(Codes, Descriptions);

        HopPlaceholder := ProofSupport.HopPlaceholderIn(
            ProofSupport.EnglishLanguageId(), Database::"Payment Terms", PaymentTerms.FieldNo(Description));
        ProofSupport.LogLine('31 Placeholder being resolved', HopPlaceholder);
        ProofSupport.LogLine('31 Payment terms used', JoinedWithDash(Codes));
        ProofSupport.LogLine('31 Their descriptions, in the order of the code', JoinedWithDash(Descriptions));

        PutSameTermsOnEvery(Numbers, Codes.Get(1));
        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", TermsPatternTok + HopPlaceholder, 3);
        SameTerms := NameForInvoiceFilter(AlternationOf(Numbers));
        ExpectedSame := TermsPrefixTok + Descriptions.Get(1);

        PutADifferentTermOnEach(Numbers, Codes);
        Listed := NameForInvoiceFilter(AlternationOf(Numbers));
        ExpectedListed := TermsPrefixTok + JoinedWithDash(Descriptions);

        ClearPatterns();
        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", TermsPatternTok + HopPlaceholder, 2);
        Collapsed := NameForInvoiceFilter(AlternationOf(Numbers));
        ExpectedCollapsed := TermsPrefixTok + Descriptions.Get(1) + RangeMarkerTok + Descriptions.Get(3);

        ProofSupport.LogLine('31 Every record on the same terms', SameTerms);
        ProofSupport.LogLine('31 Three different, naming three', Listed);
        ProofSupport.LogLine('31 Three different, naming two', Collapsed);

        case true of
            SameTerms <> ExpectedSame:
                ProofSupport.LogLine(HopVerdictTok, StrSubstNo(FailHopSameMsg, ExpectedSame, SameTerms));
            Listed <> ExpectedListed:
                ProofSupport.LogLine(HopVerdictTok, StrSubstNo(FailHopListedMsg, ExpectedListed, Listed));
            Collapsed <> ExpectedCollapsed:
                ProofSupport.LogLine(HopVerdictTok, StrSubstNo(FailHopCollapsedMsg, ExpectedCollapsed, Collapsed));
            else
                ProofSupport.LogLine(HopVerdictTok, StrSubstNo(PassHopMsg, Listed, Collapsed));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// Returned in code order. The descriptions deliberately do not sort in that order.
    /// </summary>
    local procedure CreateThreePaymentTerms(var Codes: List of [Text]; var Descriptions: List of [Text])
    begin
        Clear(Codes);
        Clear(Descriptions);
        AddPaymentTerms(FirstTermsDescriptionTok, Codes, Descriptions);
        AddPaymentTerms(SecondTermsDescriptionTok, Codes, Descriptions);
        AddPaymentTerms(ThirdTermsDescriptionTok, Codes, Descriptions);
    end;

    local procedure AddPaymentTerms(Description: Text[100]; var Codes: List of [Text]; var Descriptions: List of [Text])
    begin
        Codes.Add(TestData.CreatePaymentTerms(Description));
        Descriptions.Add(Description);
    end;

    local procedure PutSameTermsOnEvery(var Numbers: List of [Text]; TermsCode: Text)
    var
        Number: Text;
    begin
        foreach Number in Numbers do
            WritePaymentTerms(Number, TermsCode);
    end;

    local procedure PutADifferentTermOnEach(var Numbers: List of [Text]; var Codes: List of [Text])
    var
        i: Integer;
    begin
        for i := 1 to Numbers.Count() do
            if i <= Codes.Count() then
                WritePaymentTerms(Numbers.Get(i), Codes.Get(i));
    end;

    local procedure WritePaymentTerms(InvoiceNo: Text; TermsCode: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not SalesInvoiceHeader.Get(CopyStr(InvoiceNo, 1, MaxStrLen(SalesInvoiceHeader."No."))) then
            exit;

        SalesInvoiceHeader."Payment Terms Code" := CopyStr(TermsCode, 1, MaxStrLen(SalesInvoiceHeader."Payment Terms Code"));
        SalesInvoiceHeader.Modify(false);
    end;

    /// <summary>
    /// Two financial reports are named after themselves, differently. One report object renders them all,
    /// so the action that starts the render records which one runs. Two are named so a constant cannot pass.
    /// </summary>
    procedure ProveAFinancialReportIsNamedAfterItself()
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FirstName: Text;
        SecondName: Text;
        FirstExpected: Text;
        SecondExpected: Text;
    begin
        ClearPatterns();

        SetPatternFor(Report::"Account Schedule", Database::"Financial Report", FinancialReportPatternTok);

        FinancialReport.Get(TestData.CreateFinancialReport(FirstFinancialReportTok, false));
        FirstExpected := ReportFilenameMgt.Sanitise(FinancialReport.Description);
        FirstName := NameForFinancialReport(FinancialReport);

        FinancialReport.Get(TestData.CreateFinancialReport(SecondFinancialReportTok, false));
        SecondExpected := ReportFilenameMgt.Sanitise(FinancialReport.Description);
        SecondName := NameForFinancialReport(FinancialReport);

        ProofSupport.LogLine('25 First financial report is named', FirstName);
        ProofSupport.LogLine('25 Second financial report is named', SecondName);

        case true of
            FirstName <> FirstExpected:
                ProofSupport.LogLine('RESULT a financial report is named after itself',
                    StrSubstNo(FailFinancialNameMsg, FirstExpected, FirstName));
            SecondName <> SecondExpected:
                ProofSupport.LogLine('RESULT a financial report is named after itself',
                    StrSubstNo(FailFinancialNameMsg, SecondExpected, SecondName));
            FirstName = SecondName:
                ProofSupport.LogLine('RESULT a financial report is named after itself',
                    StrSubstNo(FailFinancialSameMsg, FirstName));
            else
                ProofSupport.LogLine('RESULT a financial report is named after itself',
                    StrSubstNo(PassFinancialNameMsg, FirstName, SecondName));
        end;

        Done();
    end;

    /// <summary>
    /// A financial report run that nothing identified is not named. An unfiltered run otherwise falls back
    /// to the whole table, but report 25 has no data item over Financial Report.
    /// </summary>
    procedure ProveAnUnidentifiedFinancialReportRunIsNotNamed()
    var
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Name: Text;
    begin
        ClearPatterns();

        TestData.CreateFinancialReport(UnidentifiedFinancialReportTok, false);

        SetPatternFor(Report::"Account Schedule", Database::"Financial Report", FinancialReportPatternTok);

        // Nothing recorded, no filter and no record.
        ForgetRunSubject();
        Name := NameWith(Report::"Account Schedule", Channel::Print, SourceRecRef, '');

        ProofSupport.LogLine('26 Name for a run nothing identified', NameOrNone(Name));

        if Name <> '' then
            ProofSupport.LogLine('RESULT an unidentified financial report run is not named',
                StrSubstNo(FailUnidentifiedNamedMsg, Name))
        else
            ProofSupport.LogLine('RESULT an unidentified financial report run is not named', PassUnidentifiedMsg);

        Done();
    end;

    /// <summary>
    /// [Kind of Document] is Business Central's word (GetFullDocumentTypeText) in the document's language,
    /// and a record with no such word is not named. Expected words are read from Base Application;
    /// differing translations are not a prerequisite.
    /// </summary>
    procedure ProveTheKindOfDocumentIsNamedInItsOwnLanguage()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        InDefaultLanguage: Text;
        InDanish: Text;
        DefaultKind: Text;
        DanishKind: Text;
        OnAnAccount: Text;
        OriginalLanguageCode: Code[10];
        InvoiceNo: Code[20];
    begin
        ClearPatterns();

        TestData.PostNewInvoice(SalesInvoiceHeader);
        TestData.EnsureLanguage(ProofSupport.DanishLanguageCode(), ProofSupport.DanishLanguageId());
        InvoiceNo := SalesInvoiceHeader."No.";
        OriginalLanguageCode := SalesInvoiceHeader."Language Code";

        SetPatternFor(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", KindPatternTok);

        SetInvoiceLanguage(InvoiceNo, '');
        InDefaultLanguage := NameForInvoice(InvoiceNo);
        SalesInvoiceHeader.Get(InvoiceNo);
        DefaultKind := ReportDistributionManagement.GetFullDocumentTypeText(SalesInvoiceHeader);

        SetInvoiceLanguage(InvoiceNo, ProofSupport.DanishLanguageCode());
        InDanish := NameForInvoice(InvoiceNo);
        // Re-read so the word is asked for in the language the invoice now carries.
        SalesInvoiceHeader.Get(InvoiceNo);
        DanishKind := ReportDistributionManagement.GetFullDocumentTypeText(SalesInvoiceHeader);

        // Restored before anything is judged, so the invoice is left as it was posted.
        SetInvoiceLanguage(InvoiceNo, OriginalLanguageCode);

        // Business Central has no document word for a G/L account; declining must be clean.
        ClearPatterns();
        SetPatternFor(Report::"Chart of Accounts", Database::"G/L Account", KindPatternTok);
        Clear(SourceRecRef);
        OnAnAccount := NameWith(Report::"Chart of Accounts", Channel::Print, SourceRecRef, '');

        ProofSupport.LogLine('28 Kind of document, no language on the document', InDefaultLanguage);
        ProofSupport.LogLine('28 Kind of document, document in Danish', InDanish);
        ProofSupport.LogLine('28 Business Central''s word for the invoice in Danish', DanishKind);
        ProofSupport.LogLine('28 Kind of document on a chart of accounts', NameOrNone(OnAnAccount));

        case true of
            (DefaultKind = '') or (InDefaultLanguage <> DefaultKind + '-' + InvoiceNo):
                ProofSupport.LogLine('RESULT the kind of document is named in its own language',
                    StrSubstNo(FailKindDefaultMsg, DefaultKind + '-' + InvoiceNo, InDefaultLanguage));
            (DanishKind = '') or (InDanish <> DanishKind + '-' + InvoiceNo):
                ProofSupport.LogLine('RESULT the kind of document is named in its own language',
                    StrSubstNo(FailKindDanishMsg, DanishKind + '-' + InvoiceNo, InDanish));
            OnAnAccount <> '':
                ProofSupport.LogLine('RESULT the kind of document is named in its own language',
                    StrSubstNo(FailKindDeclineMsg, OnAnAccount));
            else
                ProofSupport.LogLine('RESULT the kind of document is named in its own language',
                    StrSubstNo(PassKindMsg, InDefaultLanguage, InDanish));
        end;

        Done();
    end;

    /// <summary>
    /// [Kind of Document] declines when the document's language (used by GetFullDocumentTypeText) differs
    /// from the pattern's language, rather than mixing two languages in one name. Built on the proof
    /// document, which holds the two language codes separately; on Base Application documents
    /// GetDocumentLanguageCode reads the Language Code field. Filename Proof Kind Source supplies the document
    /// language through GetDocumentLanguageCode's event. All three branches are covered.
    /// </summary>
    procedure ProveTheKindOfDocumentDeclinesOnALanguageMismatch()
    var
        CompanyInformation: Record "Company Information";
        ProofDocument: Record "Filename Proof Document";
        OriginalCompanyLanguage: Code[10];
        RestoreLanguage: Integer;
        DanishKind: Text;
        EnglishKind: Text;
        ExpectedName: Text;
        Agreed: Text;
        Silent: Text;
        Mismatched: Text;
    begin
        ClearPatterns();
        TestData.EnsureLanguage(ProofSupport.EnglishLanguageCode(), ProofSupport.EnglishLanguageId());
        TestData.EnsureLanguage(ProofSupport.DanishLanguageCode(), ProofSupport.DanishLanguageId());
        TestData.EnsureLanguage(ProofSupport.GermanLanguageCode(), ProofSupport.GermanLanguageId());
        CompanyInformation.Get();
        OriginalCompanyLanguage := CompanyInformation."Default Language Code";
        CompanyInformation."Default Language Code" := ProofSupport.DanishLanguageCode();
        CompanyInformation.Modify(false);

        DanishKind := ProofSupport.TableCaptionIn(ProofSupport.DanishLanguageId(), Database::"Filename Proof Document");
        EnglishKind := ProofSupport.TableCaptionIn(ProofSupport.EnglishLanguageId(), Database::"Filename Proof Document");
        ExpectedName := DanishKind + '-' + KindMismatchDocumentNoTok;

        SetKindPatternOnProofDocument();

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.GermanLanguageId());
        Agreed := NameProofDocumentByKind(ProofDocument, ProofSupport.DanishLanguageCode(), ProofSupport.DanishLanguageCode());
        ProofSupport.AssertSessionLanguage(ProofSupport.GermanLanguageId());

        // An unspecified document language agrees with the configured company default.
        Silent := NameProofDocumentByKind(ProofDocument, ProofSupport.DanishLanguageCode(), '');
        ProofSupport.AssertSessionLanguage(ProofSupport.GermanLanguageId());

        Mismatched := NameProofDocumentByKind(ProofDocument, ProofSupport.DanishLanguageCode(), ProofSupport.EnglishLanguageCode());
        ProofSupport.AssertSessionLanguage(ProofSupport.GermanLanguageId());
        GlobalLanguage(RestoreLanguage);
        CompanyInformation."Default Language Code" := OriginalCompanyLanguage;
        CompanyInformation.Modify(false);

        // Removed before judging, so a failure cannot leave the document behind.
        ForgetKindMismatchDocument();

        ProofSupport.LogLine('30 Kind of document, both languages Danish', NameOrNone(Agreed));
        ProofSupport.LogLine('30 Kind of document, document names no language', NameOrNone(Silent));
        ProofSupport.LogLine('30 Kind of document, document in English, name in Danish', NameOrNone(Mismatched));
        ProofSupport.LogLine('30 The word a mismatch would otherwise have used', EnglishKind);

        case true of
            Agreed <> ExpectedName:
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(FailKindAgreedMsg, ExpectedName, NameOrNone(Agreed)));
            Silent <> ExpectedName:
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(FailKindSilentMsg, ExpectedName, NameOrNone(Silent)));
            Mismatched <> '':
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(FailKindMismatchMsg, Mismatched, EnglishKind, DanishKind));
            else
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(PassKindMismatchMsg, Agreed, Silent, EnglishKind));
        end;

        Done();
    end;

    /// <summary>
    /// Sets Language Code Field explicitly rather than relying on the suggested field.
    /// </summary>
    local procedure SetKindPatternOnProofDocument()
    var
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
    begin
        Pattern.Init();
        Pattern."Report ID" := Report::"Filename Proof Report";
        Pattern.Validate("Table No.", Database::"Filename Proof Document");
        Pattern.Validate("Language Code Field", ProofDocument.FieldNo("Language Code"));
        Pattern.Validate("File Name Pattern", CopyStr(KindAndNumberPatternTok, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    /// <param name="PatternLanguageCode">Written to the field the pattern reads.</param>
    /// <param name="DocumentLanguageCode">Written to the field handed to GetDocumentLanguageCode's event.</param>
    /// <returns>Empty when nothing named the run.</returns>
    local procedure NameProofDocumentByKind(var ProofDocument: Record "Filename Proof Document"; PatternLanguageCode: Code[10]; DocumentLanguageCode: Code[10]): Text
    var
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        WriteKindMismatchDocument(ProofDocument, PatternLanguageCode, DocumentLanguageCode);

        ProofDocument.SetRecFilter();
        SourceRecRef.GetTable(ProofDocument);
        SourceRecRef.SetView(ProofDocument.GetView());

        exit(NameWith(Report::"Filename Proof Report", Channel::Download, SourceRecRef, ''));
    end;

    local procedure WriteKindMismatchDocument(var ProofDocument: Record "Filename Proof Document"; PatternLanguageCode: Code[10]; DocumentLanguageCode: Code[10])
    begin
        ProofDocument.Reset();
        if not ProofDocument.Get(KindMismatchDocumentNoTok) then begin
            ProofDocument.Init();
            ProofDocument."No." := KindMismatchDocumentNoTok;
            ProofDocument.Insert(false);
        end;

        ProofDocument."Customer Name" := KindMismatchCustomerTok;
        ProofDocument."Language Code" := PatternLanguageCode;
        ProofDocument."Document Language Code" := DocumentLanguageCode;
        ProofDocument.Modify(false);
    end;

    local procedure ForgetKindMismatchDocument()
    var
        ProofDocument: Record "Filename Proof Document";
    begin
        ProofDocument.Reset();
        if ProofDocument.Get(KindMismatchDocumentNoTok) then
            ProofDocument.Delete(false);
    end;

    /// <summary>
    /// A pattern with no report still shows an example, although the report caption cannot be read
    /// until a report runs.
    /// </summary>
    procedure ProveAPatternWithNoReportStillShowsAnExample()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Shaped: Text;
    begin
        ClearPatterns();

        // Report ID left at zero: the pattern applies to every report on this table.
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", CopyStr(CaptionPatternTok, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);

        if not ReportFilenameMgt.TryShapeName(Pattern, Shaped) then
            Shaped := '';

        ProofSupport.LogLine('29 Example for a pattern naming no report', NameOrNone(Shaped));

        if Shaped = '' then
            ProofSupport.LogLine('RESULT a pattern with no report still shows an example', FailNoReportExampleMsg)
        else
            ProofSupport.LogLine('RESULT a pattern with no report still shows an example',
                StrSubstNo(PassNoReportExampleMsg, Shaped));

        Done();
    end;

    /// <returns>Empty when nothing named the run.</returns>
    local procedure NameForInvoice(InvoiceNo: Code[20]): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        SalesInvoiceHeader.SetRecFilter();
        SourceRecRef.GetTable(SalesInvoiceHeader);
        SourceRecRef.SetView(SalesInvoiceHeader.GetView());

        exit(NameWith(Report::"Standard Sales - Invoice", Channel::Print, SourceRecRef, ''));
    end;

    /// <summary>
    /// A scheduled financial report export is named the same way. The export renders with SaveAs and
    /// inserts the Report Inbox row itself, so the name is decided on that insert, not by the naming hook.
    /// </summary>
    procedure ProveAScheduledFinancialReportIsNamed()
    var
        FinancialReport: Record "Financial Report";
        ReportInbox: Record "Report Inbox";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SubjectRecRef: RecordRef;
        Expected: Text;
        EntryNo: Integer;
    begin
        ClearPatterns();

        SetPatternFor(Report::"Account Schedule", Database::"Financial Report", FinancialReportPatternTok);

        FinancialReport.Get(TestData.CreateFinancialReport(ScheduledFinancialReportTok, false));
        Expected := ReportFilenameMgt.Sanitise(FinancialReport.Description);

        // Report ID 0, as the export records it: one schedule can produce a PDF and a workbook from
        // two different report objects.
        SubjectRecRef.GetTable(FinancialReport);
        ReportFilenameContext.SetRunSubject(SubjectRecRef, 0);

        EntryNo := InsertScheduledInboxEntry();

        ReportInbox.Get(EntryNo);
        ProofSupport.LogLine('27 Scheduled financial report is named', NameOrNone(ReportInbox."File Name"));

        if ReportInbox."File Name" <> Expected then
            ProofSupport.LogLine('RESULT a scheduled financial report is named',
                StrSubstNo(FailScheduledFinancialMsg, Expected, NameOrNone(ReportInbox."File Name")))
        else
            ProofSupport.LogLine('RESULT a scheduled financial report is named',
                StrSubstNo(PassScheduledFinancialMsg, ReportInbox."File Name"));

        ReportInbox.Delete();
        ReportFilenameContext.ClearRunSubject();
        Done();
    end;

    /// <summary>
    /// Shaped as the financial report export inserts it: report 25, no file name, inserted directly.
    /// </summary>
    local procedure InsertScheduledInboxEntry(): Integer
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.Init();
        ReportInbox."Entry No." := 0;
        ReportInbox."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Report ID" := Report::"Account Schedule";
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Created Date-Time" := CurrentDateTime();
        ReportInbox.Insert(true);
        exit(ReportInbox."Entry No.");
    end;

    /// <summary>
    /// As the print action does: record the subject, then render.
    /// </summary>
    /// <returns>Empty when nothing named the run.</returns>
    local procedure NameForFinancialReport(var FinancialReport: Record "Financial Report"): Text
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        SubjectRecRef: RecordRef;
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        SubjectRecRef.GetTable(FinancialReport);
        ReportFilenameContext.SetRunSubject(SubjectRecRef, Report::"Account Schedule");

        // SourceRecRef left unopened, so only the recorded subject identifies the run.
        exit(NameWith(Report::"Account Schedule", Channel::Print, SourceRecRef, ''));
    end;

    local procedure ForgetRunSubject()
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.ClearRunSubject();
    end;

    local procedure NameOrNone(Name: Text): Text
    begin
        if Name = '' then
            exit(NoNameLbl);
        exit(Name);
    end;

    /// <summary>
    /// Flushes the buffered verdicts to the log table, where the gate reads them.
    /// </summary>
    local procedure Done()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.Flush();
    end;

    /// <param name="SourceRecRef">May be unopened.</param>
    /// <param name="FilterViews">May be empty.</param>
    /// <returns>Empty when nothing named the run.</returns>
    local procedure NameWith(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var SourceRecRef: RecordRef; FilterViews: Text) Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        if not ReportFilenameMgt.TryResolve(ReportId, Channel, SourceRecRef, FilterViews, Name) then
            exit('');
    end;

    /// <summary>
    /// Posts three invoices for one new customer and returns the alternation filter selecting them.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Left filtered to the three.</param>
    local procedure ThreeInvoices(var SalesInvoiceHeader: Record "Sales Invoice Header"; var InvoiceFilter: Text; var Numbers: List of [Text])
    var
        InvoiceNos: List of [Code[20]];
        InvoiceNo: Code[20];
    begin
        Clear(Numbers);
        InvoiceFilter := '';

        TestData.PostInvoicesOfOneCustomer(3, InvoiceNos);
        foreach InvoiceNo in InvoiceNos do begin
            Numbers.Add(InvoiceNo);
            if InvoiceFilter <> '' then
                InvoiceFilter += '|';
            InvoiceFilter += InvoiceNo;
        end;

        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", InvoiceFilter);
    end;

    local procedure FirstOf(var Numbers: List of [Text]) Value: Text
    begin
        Numbers.Get(1, Value);
    end;

    local procedure LastOf(var Numbers: List of [Text]) Value: Text
    begin
        Numbers.Get(Numbers.Count(), Value);
    end;

    local procedure SetInvoiceLanguage(InvoiceNo: Text; LanguageCode: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(CopyStr(InvoiceNo, 1, MaxStrLen(SalesInvoiceHeader."No.")));
        ProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, LanguageCode);
    end;

    local procedure CompanyDisplayName(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation.Name <> '' then
            exit(CompanyInformation.Name);
        exit(CompanyName());
    end;

    local procedure SetPattern(PatternText: Text)
    begin
        SetPatternFor(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", PatternText);
    end;

    local procedure SetPatternFor(ReportId: Integer; TableNo: Integer; PatternText: Text)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.Init();
        Pattern."Report ID" := ReportId;
        Pattern.Validate("Table No.", TableNo);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        // Two allowed values, so three selected records collapse to first-to-last.
        Pattern."Max. Values Named" := 2;
        Pattern."Separator" := '-';
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    /// <param name="PatternText">Carries no placeholder, so the name itself cannot distinguish the runs.</param>
    local procedure SetConditionedPattern(PatternText: Text; InvoiceNo: Text)
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Pattern.Init();
        Pattern."Report ID" := Report::"Standard Sales - Invoice";
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);

        SalesInvoiceHeader.SetRange("No.", CopyStr(InvoiceNo, 1, MaxStrLen(SalesInvoiceHeader."No.")));
        Pattern.WriteTableFilter(SalesInvoiceHeader.GetView(false));
        Pattern.Modify(true);
    end;

    local procedure ClearPatterns()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        Pattern.DeleteAll(true);
        FilenameProofGuard.SwitchFeatureOn();
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        TestData: Codeunit "Filename Test Data";
        RangeLbl: Label 'Invoices-%1-to-%2', Comment = '%1 first number, %2 last number', Locked = true;
        KindAndNumberPatternTok: Label '[Kind of Document]-[Number]', Locked = true;
        KindMismatchDocumentNoTok: Label 'KIND-LANG', Locked = true;
        KindMismatchCustomerTok: Label 'Kind of document language proof', Locked = true;
        PassKindMismatchMsg: Label 'PASS - matching or blank document languages are named (%1, %2); a conflicting document language produces no name, even if its caption is unchanged (%3).', Comment = '%1 the agreed name, %2 the name for a document with no language, %3 the caption for the conflicting language';
        FailKindAgreedMsg: Label 'FAIL - a document whose language agrees with the pattern''s should be named %1, but the run was named %2.', Comment = '%1 the expected name, %2 the actual name';
        FailKindSilentMsg: Label 'FAIL - a document with no language should use the configured company default and produce %1, but produced %2.', Comment = '%1 the expected name, %2 the actual name';
        FailKindMismatchMsg: Label 'FAIL - conflicting document and pattern languages produced %1 instead of declining; their captions may read %2 and %3 even when the text is identical.', Comment = '%1 the name produced, %2 the document caption, %3 the pattern-language caption';
        ShapeTok: Label 'ABC-01', Locked = true;
        RangeMarkerTok: Label '-to-', Locked = true;
        YesNoLbl: Label '%1', Comment = '%1 yes or no', Locked = true;
        PassExampleMsg: Label 'PASS - one record shows %1 and a run of several shows %2, both built from shapes rather than read from any record.', Comment = '%1 the single-record example, %2 the run example';
        FailNoExampleMsg: Label 'FAIL - no example could be built at all: %1', Comment = '%1 the reason given';
        FailNotAShapeMsg: Label 'FAIL - the example should carry the generated shape %1 but reads %2.', Comment = '%1 the shape, %2 the example';
        FailReadARecordMsg: Label 'FAIL - an example carries a real posted invoice number, so it read a record instead of building a shape: %1 / %2.', Comment = '%1 the single-record example, %2 the run example';
        FailNoRunExampleMsg: Label 'FAIL - no example is offered for a run covering several records, so the card still implies every run covers one.';
        FailNoRangeMsg: Label 'FAIL - the example for a run covering several records carries no first-to-last range: %1.', Comment = '%1 the example';
        FailComputedCollapsedMsg: Label 'FAIL - a pattern built only from computed values offered a second example (%1), but nothing in it changes with the size of the run.', Comment = '%1 the second example';
        AccountRangeLbl: Label 'Accounts-%1-to-%2', Comment = '%1 first account, %2 last account', Locked = true;
        NotEnoughAccountsMsg: Label 'this company has fewer than three G/L accounts, so there is no filtered run to test.';
        NoReportsMsg: Label 'Report Metadata returned no rows, so nothing could be checked.';
        PayloadLbl: Label '{"filterviews":%1,"intent":"Preview"}', Comment = '%1 the filterviews array', Locked = true;
        InvoiceCaptionLbl: Label 'Sales - Invoice', Locked = true;
        FinancialReportPatternTok: Label '[Description]', Locked = true;
        NoNameLbl: Label '(no name)';
        FirstFinancialReportTok: Label 'Proof Balance Sheet', Locked = true;
        SecondFinancialReportTok: Label 'Proof Income Statement', Locked = true;
        UnidentifiedFinancialReportTok: Label 'Proof Cash Flow', Locked = true;
        ScheduledFinancialReportTok: Label 'Proof Scheduled Statement', Locked = true;
        PassFinancialNameMsg: Label 'PASS - two financial reports rendered by the same report object are named %1 and %2.', Comment = '%1 the first name, %2 the second name';
        FailFinancialNameMsg: Label 'FAIL - the run should have been named %1 but was named %2.', Comment = '%1 the expected name, %2 the name produced';
        FailFinancialSameMsg: Label 'FAIL - two different financial reports were both named %1, so the name does not say which one ran.', Comment = '%1 the name produced';
        PassUnidentifiedMsg: Label 'PASS - a financial report run that nothing identified is left with Business Central own name.';
        FailUnidentifiedNamedMsg: Label 'FAIL - a financial report run that nothing identified was named %1, which is built from financial reports nobody ran.', Comment = '%1 the name produced';
        PassScheduledFinancialMsg: Label 'PASS - a scheduled financial report reaches its Report Inbox entry named %1.', Comment = '%1 the name produced';
        FailScheduledFinancialMsg: Label 'FAIL - a scheduled financial report should have been named %1 but its Report Inbox entry reads %2.', Comment = '%1 the expected name, %2 the name produced';
        KindPatternTok: Label '[Kind of Document]-[No.]', Locked = true;
        CaptionPatternTok: Label '[Report Name]-[No.]', Locked = true;
        PassKindMsg: Label 'PASS - the same invoice is named %1 in the default language and %2 in Danish, and a chart of accounts run is left to Business Central.', Comment = '%1 the default-language name, %2 the Danish name';
        FailKindDefaultMsg: Label 'FAIL - the name should be %1 but reads %2.', Comment = '%1 the expected name, %2 the name produced';
        FailKindDanishMsg: Label 'FAIL - with the document in Danish the name should be %1 but reads %2.', Comment = '%1 the expected name, %2 the name produced';
        FailKindDeclineMsg: Label 'FAIL - a chart of accounts run has no kind of document, but it was named %1.', Comment = '%1 the name produced';
        PassNoReportExampleMsg: Label 'PASS - a pattern naming no report shows the example %1 instead of reporting a placeholder that does not exist.', Comment = '%1 the example shown';
        FailNoReportExampleMsg: Label 'FAIL - a pattern naming no report produces no example at all, so the card tells whoever set it up that a placeholder names something missing.';
        PdfExtensionLbl: Label '.pdf', Locked = true;
        AlreadyNamedLbl: Label 'SomebodyElseNamedThis.pdf', Locked = true;
        RaisedLbl: Label 'Reporting Triggers.GetFilename, the platform event codeunit 44 subscribes to', Locked = true;
        BadPayloadMsg: Label 'FAIL - the test could not build the platform payload, so nothing was proven.';
        NotAnsweredMsg: Label 'FAIL - the platform event was raised and this feature did not answer it. The subscriber is not reached at all: check the event name, the parameter names and the signature, because a subscriber the platform will not bind to compiles perfectly and does nothing.';
        WrongNameMsg: Label 'FAIL - the hook answered, but with the wrong name. Expected %1, got %2.', Comment = '%1 expected, %2 actual';
        PassSwitchedOffMsg: Label 'PASS - switched off, the naming hook came back unanswered, so Business Central keeps its own name.';
        SwitchedOffButNamedMsg: Label 'FAIL - the feature is switched off, but the file was still named %1.', Comment = '%1 the name produced';
        PassSwitchedOnMsg: Label 'PASS - switched on again, the same pattern named the file %1.', Comment = '%1 the name';
        PassHookMsg: Label 'PASS - the platform event reached this feature through Base Application and came back named %1.', Comment = '%1 the name';
        PassLeftAloneMsg: Label 'PASS - a file somebody else had already named came back untouched as %1. Note: Base Application''s own guard is what stops it first, so this does not exercise this app''s guard.', Comment = '%1 the name';
        FailOverrodeMsg: Label 'FAIL - a file already named %1 was overwritten with %2, so a deliberate decision somebody else made was lost.', Comment = '%1 the original name, %2 what it became';
        FailureLineLbl: Label '%1 %2 (%3); ', Comment = '%1 report id, %2 report caption, %3 the reason', Locked = true;
        NoTableMetadataMsg: Label 'no table metadata';
        NoCaptionMsg: Label 'the kind of record has no name of its own';
        NotOfferedMsg: Label 'not offered in the kinds list';
        NoFieldsMsg: Label 'no field a name could be built from';
        PassFitMsg: Label 'PASS - all %1 installed reports land somewhere handled: %2 produce no file, %3 are about their first data item, %4 about a subject found by descending, %5 about no record at all and named from computed values only.', Comment = '%1 total, %2 no file, %3 first data item, %4 deeper, %5 no record';
        FailFitMsg: Label 'FAIL - %1 reports produce a file and are about a kind of record an administrator cannot set up: %2', Comment = '%1 how many, %2 the list';
        PassFilterMsg: Label 'PASS - a run over %1 accounts, set as a filter rather than a record, was named %2 and attributed to this pattern.', Comment = '%1 how many accounts, %2 the name';
        FailCountMsg: Label 'FAIL - the run was reported as covering %1 accounts rather than 3.', Comment = '%1 the count';
        FailFilterNameMsg: Label 'FAIL - expected %1 but the filtered run was named %2.', Comment = '%1 expected, %2 actual';
        FailNotAttributedMsg: Label 'FAIL - the name was not attributed to the pattern being tested; it said %1.', Comment = '%1 what it said';
        PassEveryMsg: Label 'PASS - an empty filter covers every record: %1 accounts.', Comment = '%1 the count';
        FailEveryMsg: Label 'FAIL - an empty filter should cover all %1 accounts but covered %2.', Comment = '%1 the table count, %2 what was covered';
        SkippedMsg: Label 'SKIPPED - %1', Comment = '%1 the reason';
        HopVerdictTok: Label 'RESULT a run pointing at several related records is named after all of them', Locked = true;
        TermsPatternTok: Label 'Terms-', Locked = true;
        TermsPrefixTok: Label 'Terms-', Locked = true;
        // Deliberately not in alphabetical order; creation order is code order.
        FirstTermsDescriptionTok: Label 'Net 30 days', Locked = true;
        SecondTermsDescriptionTok: Label 'Cash on delivery', Locked = true;
        ThirdTermsDescriptionTok: Label 'Monthly', Locked = true;
        PassHopMsg: Label 'PASS - a run whose records point at three different related records is named after all three (%1), and collapses to first-to-last when the pattern names fewer (%2).', Comment = '%1 the listed name, %2 the collapsed name';
        FailHopSameMsg: Label 'FAIL - a run whose records all point at the same related record should be named %1 but was named %2. Naming a single related record is what nearly every run does and it must not change.', Comment = '%1 expected, %2 actual';
        FailHopListedMsg: Label 'FAIL - a run pointing at three different related records should be named %1 but was named %2. A relation placeholder that declines here is applying the rule this design abandoned for fields, one level out.', Comment = '%1 expected, %2 actual';
        FailHopCollapsedMsg: Label 'FAIL - with room to name two, a run pointing at three related records should be named %1 but was named %2.', Comment = '%1 expected, %2 actual';
        PassBothShapesMsg: Label 'PASS - a run covering a few records is shown as %1 and one covering many as %2, so the example no longer claims a range for a run that would be listed.', Comment = '%1 the listed example, %2 the collapsed example';
        FailNoFewMsg: Label 'FAIL - no example is offered for a run covering a few records, so a pattern naming three individually still advertises a range for a run over two.';
        FailNoManyMsg: Label 'FAIL - no example is offered for a run covering many records.';
        PdfExtensionForExampleTok: Label '.pdf', Locked = true;
        FailFewWithoutExtensionMsg: Label 'FAIL - the example for a few records has no extension, unlike the others: %1', Comment = '%1 the example';
        FailFewIsARangeMsg: Label 'FAIL - the example for a few records is a first-to-last range: %1. A few records are listed, not collapsed.', Comment = '%1 the example';
        FailManyIsNotARangeMsg: Label 'FAIL - the example for many records carries no first-to-last range: %1.', Comment = '%1 the example';
        FailBothSameMsg: Label 'FAIL - both examples read %1, so one of the two shapes a run has is not being shown.', Comment = '%1 the example';
        FailOneNamedOfferedFewMsg: Label 'FAIL - a pattern naming one value individually was offered a listed example (%1), but a run over two records collapses for it, so no such name is ever produced.', Comment = '%1 the example';
        RangeTok: Label '..', Locked = true;
        AlternationTok: Label '|', Locked = true;
        ListedInvoicesLbl: Label 'Invoices-', Locked = true;
        PassWholeTableMsg: Label 'PASS - a run covering every account is named after the first and the last there are: %1', Comment = '%1 the name';
        FailWholeTableMsg: Label 'FAIL - expected %1 but a run covering every account produced %2.', Comment = '%1 expected, %2 actual';
        PassOneNameMsg: Label 'PASS - three invoices listed one by one and the same three as a range are both named %1.', Comment = '%1 the name';
        FailTwoNamesMsg: Label 'FAIL - one selection got two names: listed one by one it is %1, and as a range it is %2. The name is being taken from how the run was described rather than from the records it covers.', Comment = '%1 the listed name, %2 the ranged name';
        PassThreeNamesMsg: Label 'PASS - no filter, a closed range and an open range all describe every account, and all three are named %1.', Comment = '%1 the name';
        FailThreeNamesMsg: Label 'FAIL - three ways of saying every account gave three answers: %1, %2 and %3.', Comment = '%1 unfiltered, %2 closed range, %3 open range';
        FailWrongOneNameMsg: Label 'FAIL - the descriptions agree with each other but on the wrong name: expected %1, got %2.', Comment = '%1 expected, %2 actual';
        GuardVerdictTok: Label 'RESULT a name another subscriber set is not overridden by this feature', Locked = true;
        GuardDirectVerdictTok: Label 'RESULT this feature stands down for a file another subscriber already named', Locked = true;
        PassLeftAloneDirectMsg: Label 'PASS - handed a file already named %1, this feature left it alone rather than naming it %2, which its own enabled pattern produces.', Comment = '%1 the name somebody else set, %2 the name this feature would give';
        ReminderUnconfiguredVerdictTok: Label 'RESULT a reminder Base Application does not name is named by its pattern on every route', Locked = true;
        ReminderConfiguredVerdictTok: Label 'RESULT a reminder Base Application names keeps that name on every route', Locked = true;
        ReminderTestPatternVerdictTok: Label 'RESULT Test Pattern says a reminder Base Application names keeps that name', Locked = true;
        PassReminderByPatternMsg: Label 'PASS - with no File Name on the reminder''s attachment text, every route was named by the pattern: %1.', Comment = '%1 the name';
        PassReminderByBaseAppMsg: Label 'PASS - with a File Name on the reminder''s attachment text, Base Application named it %1 on print and email and nothing named it on the routes Base Application leaves alone, so the pattern''s %2 was used nowhere.', Comment = '%1 Base Application''s name, %2 the pattern''s name';
        FailRoutesMsg: Label 'FAIL - %1', Comment = '%1 each route that differed, with what was expected and what came back';
        RouteDifferenceLbl: Label '%1: expected "%2", got "%3". ', Comment = '%1 the route, %2 expected, %3 actual';
        GotAndExpectedLbl: Label 'got "%1", expected "%2"', Comment = '%1 actual, %2 expected';
        RouteRecordHandedOverLbl: Label 'naming event with the reminder handed over (Print, Download)';
        RouteNoRecordLbl: Label 'naming event with no record handed over (Preview)';
        RouteEmailLbl: Label 'email attachment';
        RouteDiskLbl: Label 'Send to Disk';
        RouteAttachLbl: Label 'Attach as PDF';
        PassReminderTestPatternMsg: Label 'PASS - Test Pattern says Business Central names the reminder from its attachment text, and what the pattern would name it with File Name cleared.';
        FailReminderTestPatternMsg: Label 'FAIL - Test Pattern must defer to the reminder attachment text and explain the unused pattern name "%1"; it showed "%2", from "%3", because "%4".', Comment = '%1 unused pattern name, %2 name shown, %3 source shown, %4 reason shown';
        OurReminderPatternTok: Label 'ThisFeatureNamedThis-[No.]', Locked = true;
        OurReminderPrefixTok: Label 'ThisFeatureNamedThis-', Locked = true;
        TheirFileNameTok: Label 'ReminderCommunicationNamedThis', Locked = true;
        IncomingReminderNameTok: Label 'Reminder', Locked = true;
        ReminderCaptionLbl: Label 'Reminder', Locked = true;
        TermsAndLevelLbl: Label '%1, level %2', Comment = '%1 the reminder terms code, %2 the level', Locked = true;
        SuppliedGuardsLbl: Label 'report %1, extension %2, incoming name %3, a positioned reference to %4, and a configured file name of %5', Comment = '%1 report id, %2 the extension, %3 the incoming name, %4 the kind of record, %5 the configured file name';
        FailCouldNotSeedMsg: Label 'FAIL - a configured reminder file name could not be written, so the other subscriber would have declined for a reason that is this test''s fault rather than the code''s: %1', Comment = '%1 the error';
        FailOursDoesNotClaimMsg: Label 'FAIL - this feature does not name this report even with nothing competing: expected %1, got %2. Until it does, a run where both are in play proves nothing, because the other subscriber would win whether this feature had a guard or not.', Comment = '%1 expected, %2 actual';
        FailTheirsDidNotNameMsg: Label 'FAIL - the other subscriber did not name the file even with nothing competing: expected %1, got %2. Its conditions were supplied as %3, so one of them is not met and the guard is not being reached.', Comment = '%1 expected, %2 actual, %3 what was supplied';
        PassGuardMsg: Label 'PASS - another subscriber named the file %1 and this feature stood down rather than replacing it with %2, which is the name its own enabled pattern produces.', Comment = '%1 the other subscriber''s name, %2 the name this feature would have given';
        FailWeWentFirstMsg: Label 'FAIL - this feature named the file %1, and the other subscriber - which names it %2 when nothing competes - did not get it. Whichever order the platform ran the two subscribers in, this is a defect: run first, this feature must leave a reminder Base Application names to it (Report Filename Mgt.IsNamedByReminderCommunication); run second, its guard must stand down.', Comment = '%1 this feature''s name, %2 the other subscriber''s name';
        FailNeitherMsg: Label 'FAIL - the chain came back with %1, which is neither the other subscriber''s name %2 nor this feature''s %3, so something else named the file.', Comment = '%1 what came back, %2 the other name, %3 this feature''s name';
        LanguageDocumentOneTok: Label 'PROOF-LANG-1', Locked = true;
        LanguageDocumentTwoTok: Label 'PROOF-LANG-2', Locked = true;
        LanguageCustomerTok: Label 'Language run', Locked = true;
        ReportCaptionOnlyTok: Label '[Report Name]', Locked = true;
        NoAccountsMsg: Label 'this company has no G/L account, so there is no whole-table run to name.';
        NoAssemblyReportMsg: Label 'report Posted Assembly Order is not installed here.';
        PassCollapsedMsg: Label 'PASS - the payload and the record reference both named the whole selection, and agreed: %1', Comment = '%1 the name';
        FailCollapsedMsg: Label 'FAIL - expected %1; the payload gave %2 and the record reference gave %3, so the selection was not kept.', Comment = '%1 expected, %2 from payload, %3 from reference';
        PassNamedMsg: Label 'PASS - a run that narrowed nothing was named %1', Comment = '%1 the name';
        ProducedLbl: Label '%1', Comment = '%1 what the pattern produced, or nothing', Locked = true;
        FailNamedMsg: Label 'FAIL - expected %1 but got %2, so an unfiltered run still cannot be named.', Comment = '%1 expected, %2 actual';
        PassConditionMsg: Label 'PASS - the pattern claimed the run covering only %1, and refused the run covering %2 records.', Comment = '%1 the invoice, %2 how many records';
        FailConditionLostMsg: Label 'FAIL - the pattern no longer claims even the single record its condition names; it produced %1.', Comment = '%1 what it produced';
        FailConditionClaimedMsg: Label 'FAIL - a pattern conditioned on one invoice claimed a run covering %1 records.', Comment = '%1 how many records';
        PassLanguageMsg: Label 'PASS - a run uses its agreed language (%1); mixed runs follow the configured company default (%2, %3), even when the resulting names match.', Comment = '%1 the agreed name, %2 the mixed name with German default, %3 the mixed name with Danish default';
        FailAgreedLanguageMsg: Label 'FAIL - a run whose records all name the same language was not named in it; it produced %1.', Comment = '%1 what it produced';
        FailLanguageOutputMsg: Label 'FAIL - expected filename %1 for the selected language, but got %2.', Comment = '%1 the expected name, %2 the actual name';
        PassSubjectMsg: Label 'PASS - the first data item is virtual table %1, and the run is correctly about table %2.', Comment = '%1 first data item table, %2 subject table';
        FailNotHiddenMsg: Label 'FAIL - this report no longer hides its subject: its first data item is table %1, so this proof is not testing what it claims.', Comment = '%1 the table';
        FailSubjectMsg: Label 'FAIL - expected the run to be about table %1 but it was about table %2.', Comment = '%1 expected table, %2 actual table';
}
