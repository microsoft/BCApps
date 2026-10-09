// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50110 "Report Filename Mgt."
{
    // WHAT IS SCAFFOLDING AND WHAT IS THE PRODUCT
    //
    // The Report Filename Manager ships as a Microsoft app alongside Base Application and reaches
    // every naming point through Base Application's events. Nearly every object here is therefore
    // the product as it stands. The exceptions exist only because Base Application raises no event
    // at a point the app has to reach today; each of them says so in its own header and names the
    // Base Application event that replaces it - the asks to Microsoft on the Jira case. Silence
    // therefore means something: an object carrying no such note is the product. This codeunit is
    // one of those.
    //
    // Scaffolding, until Base Application raises the event:
    //   Report Filename Fin. Rep. Ov. and Report Filename Excel Sub.
    //                                    -> a file name event in report 29 Export Acc. Sched. to
    //                                       Excel, carrying the financial report and the name
    //   Report Filename Inbox Sub., the download half
    //                                    -> a file name event in Report Inbox.GetFileNameWithoutExtension
    //   Report Filename Subscribers, the vendor half of Send to Disk
    //                                    -> a naming event in Report Selections.SendToDiskForVend, the
    //                                       twin of OnSendToDiskForCustOnBeforeDownloadAttachment
    //   IsNamedByReminderCommunication, below
    //                                    -> a public way to ask Reminder Communication for the name
    //                                       it gives a reminder
    //
    // There is no upgrade codeunit. The app has never been released, so there is nothing saved by
    // an earlier version to carry forward; a development database is reseeded instead.
    //
    // Report Filename Inbox Mgt. keeps its logic; its integration event is there for the proof and
    // should only survive if a partner needs it.

    // Public: this is the surface the delivery paths call.
    Access = Public;

    // Read under the inherent permissions TryResolve grants - see there. Microsoft's own example of
    // inherent permissions, LogInManagement, pairs the method attribute with this property in the
    // same way: the attribute gives the user indirect read for the length of the call, and indirect
    // read is honoured only by an object that declares it.
    Permissions = tabledata "Report Filename Pattern" = r,
        tabledata "Report Filename Setup" = r;

    // The manager decides the name. The caller applies it.
    //
    // Resolution never depends on how the report was delivered. The caller's record is used
    // when it carries one, and the data item filter the platform supplies is the fallback
    // that behaves the same on every route - which matters because Business Central leaves
    // the record reference empty on the Preview route.

    var
        BindStartTok: Label '{', Locked = true;
        BindEndTok: Label '}', Locked = true;
        PlaceholderStartTok: Label '[', Locked = true;
        PlaceholderEndTok: Label ']', Locked = true;
        FieldPrefixTok: Label 'f:', Locked = true;
        ComputedPrefixTok: Label 'c:', Locked = true;
        HopPrefixTok: Label 'r:', Locked = true;
        HopBindSeparatorTok: Label ':', Locked = true;
        HopSeparatorTok: Label ':', Locked = true;
        InvariantAmountTok: Label '<Precision,%1><Standard Format,9>', Comment = '%1 the decimal places, as Business Central writes them, such as 2:2', Locked = true;
        DefaultDecimalPlacesTok: Label '2:2', Locked = true;
        SortingLbl: Label 'SORTING(Field%1)', Comment = '%1 the field number the run is read in the order of', Locked = true;
        WhereTok: Label ' WHERE(', Locked = true;
        GreaterThanTok: Label '>%1', Comment = '%1 the last value already seen', Locked = true;
        // Invalid on Windows, plus # and % which SharePoint and OneDrive reject - report
        // output commonly lands there. Used to judge a separator an administrator types, and
        // named in the message that refuses one; a resolved name is cleaned by Sanitise.
        InvalidCharsTok: Label '"#%*:<>?\/|', Locked = true;
        SampleDecimalTok: Label '1234.50', Locked = true;
        SampleDecimalLastTok: Label '9876.50', Locked = true;
        SampleRangeSpanTok: Label '<+1M>', Locked = true;
        // Windows' reserved names, superscript digits included: Windows reads ¹ ² ³ as digits of a
        // device name (Microsoft Learn, Naming Files, Paths, and Namespaces).
        ReservedNamesTok: Label 'CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9,COM¹,COM²,COM³,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9,LPT¹,LPT²,LPT³', Locked = true;
        ReminderAnswerKeyTok: Label '%1|%2|%3', Comment = '%1 reminder terms, %2 reminder level, %3 language code', Locked = true;
        SwitchedOffMsg: Label 'File name patterns are turned off, so every report gets Business Central''s own file name. Turn them on in the setup.';
        OpenSetupLbl: Label 'Open Setup';

    /// <summary>
    /// Resolves a file name for a report delivery. Returns false when no pattern applies or
    /// any placeholder cannot be resolved, in which case the caller keeps the name it already had.
    /// </summary>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="Channel">Which delivery this is.</param>
    /// <param name="SourceRecRef">The document, when the caller has one. May be unopened.</param>
    /// <param name="FilterViews">The payload's filterviews array, when there is one.</param>
    /// <param name="Filename">Set to the resolved name when the function returns true.</param>
    /// <returns>True when a name was resolved.</returns>
    // Every user who prints, emails or sends a report runs this, because the naming happens inside
    // the delivery - and only the people who set patterns up hold Report Filename Mgr. So reading the
    // patterns and the setup is granted to this code rather than to the user, the way Microsoft
    // documents inherent permissions for a small system task that reads configuration rather than
    // business data. Without it, a user with no Report Filename Mgr. set got a permission error out of
    // an ordinary print: measured with Filename Permission Tests, run as a user holding only
    // D365 BUS FULL ACCESS. The records the name is built FROM are still read under the user's own
    // permissions, so nobody is named from data they could not read themselves.
    [InherentPermissions(PermissionObjectType::TableData, Database::"Report Filename Pattern", 'r')]
    [InherentPermissions(PermissionObjectType::Table, Database::"Report Filename Pattern", 'X')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Report Filename Setup", 'r')]
    [InherentPermissions(PermissionObjectType::Table, Database::"Report Filename Setup", 'X')]
    procedure TryResolve(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var SourceRecRef: RecordRef; FilterViews: Text; var Filename: Text): Boolean
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        Resolved: Boolean;
    begin
        Resolved := TryResolveOnce(PatternReportFor(ReportId), Channel, SourceRecRef, FilterViews, Filename);

        // A financial report's period is handed over for one name - the one being decided now -
        // and forgotten whichever way that went, so it can never reach the next.
        ReportFilenameContext.ClearNamingPeriod();
        exit(Resolved);
    end;

    /// <summary>
    /// The report whose patterns name this report's output. A financial report's Excel workbook
    /// is written by Export Acc. Sched. to Excel, a processing-only report that cannot have a
    /// pattern and that nobody runs or knows by name; it is the same financial report as the PDF,
    /// so it is named by the financial report's own pattern, and differs only in its extension.
    /// </summary>
    /// <param name="ReportId">The report producing the output.</param>
    /// <returns>The report to look patterns up for.</returns>
    local procedure PatternReportFor(ReportId: Integer): Integer
    begin
        if ReportId = Report::"Export Acc. Sched. to Excel" then
            exit(Report::"Account Schedule");
        exit(ReportId);
    end;

    // Covered by TryResolve's inherent permissions: they hold for everything it calls, which the
    // permission test measures - the pattern is read two calls further down than this.
    local procedure TryResolveOnce(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var SourceRecRef: RecordRef; FilterViews: Text; var Filename: Text): Boolean
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        // Switched off - which is how the feature starts - means every route keeps Business
        // Central's own name, whatever patterns exist. Read here rather than through the table's
        // GetSettings, because a read inside the table's own code is not covered by this
        // codeunit's Permissions.
        if not ReportFilenameSetup.Get() then
            ReportFilenameSetup.Init();
        if not ReportFilenameSetup.Enabled then
            exit(false);

        // With no patterns configured this is the whole cost of the feature on every report
        // render, so it comes before any record or JSON work.
        if Pattern.IsEmpty() then
            exit(false);

        // Wrapped so that no defect in here can ever fail a print. The promise this design
        // makes is that a name which cannot be resolved leaves the caller's own name in place,
        // and an error would break that promise in the worst possible way - by stopping the
        // report rather than by naming its output badly.
        if not TryResolveInner(ReportId, Channel, SourceRecRef, FilterViews, Filename) then begin
            Clear(Filename);
            exit(false);
        end;

        exit(Filename <> '');
    end;

    /// <summary>
    /// The name a document would actually be given, together with the pattern that produced it.
    ///
    /// TryResolve answers "what is the name"; this also answers "who decided it", which is what
    /// somebody testing a pattern needs. A pattern is one candidate among several and a more
    /// specific one wins, so an administrator whose pattern is being beaten needs to be told
    /// that rather than left thinking their pattern is broken.
    /// </summary>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="Channel">The delivery route.</param>
    /// <param name="DocumentRecRef">The document to name.</param>
    /// <param name="Winner">Receives the pattern that produced the name.</param>
    /// <param name="Filename">Receives the name.</param>
    /// <returns>True when some pattern named the document.</returns>
    internal procedure TryResolveNaming(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var Winner: Record "Report Filename Pattern"; var Filename: Text): Boolean
    var
        LanguageCode: Code[10];
        LanguageKnown: Boolean;
    begin
        Clear(Filename);

        if not SelectPattern(ReportId, Channel, DocumentRecRef, Winner, LanguageCode, LanguageKnown) then
            exit(false);

        exit(TryResolveInLanguage(Winner, ReportId, DocumentRecRef, DocumentLanguage(Winner, DocumentRecRef), Filename));
    end;

    /// <summary>
    /// What Business Central would call the file if no pattern named it - the report's own
    /// caption, which is the name the delivery routes fall back to when this feature declines.
    /// </summary>
    /// <param name="ReportId">The report being delivered.</param>
    /// <returns>The fallback name, or blank when no report is known.</returns>
    internal procedure FallbackName(ReportId: Integer): Text
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportId = 0 then
            exit('');
        if not ReportMetadata.Get(ReportId) then
            exit('');
        exit(ReportMetadata.Caption);
    end;

    /// <summary>
    /// Whether Base Application names a reminder in this run itself, in which case this feature
    /// leaves every reminder of the run to it, on every route.
    ///
    /// Base Application's Reminder Communication names a reminder from the File Name on the
    /// attachment text of its reminder level, or of its reminder terms, and it subscribes to the
    /// same two naming events this feature does: ReportManagement.OnGetFilename and
    /// Document-Mailing.OnBeforeGetAttachmentFileName. Microsoft documents the order of subscribers
    /// as unspecified, so which of the two named a printed reminder used to depend on which the
    /// platform happened to run first - and on the email route Reminder Communication overwrites the
    /// name whatever came before, so there it always won. Yielding here makes the answer the same in
    /// either order and the same on every route: a reminder Base Application names keeps exactly the
    /// name it has without this feature, and every other reminder is named by its pattern. Existing
    /// reminder file names therefore never change, and an administrator who wants a pattern to name
    /// reminders clears File Name on the attachment text - Test Pattern says so.
    ///
    /// The rule is Reminder Communication's own (FindFileName and GetReminderAttachmentText, Base
    /// Application 28.4): the level's attachment text in the language it looks for, then the terms',
    /// and a File Name that is not blank. Where it would raise an error of its own - a reminder level
    /// or terms that no longer exist - it is equally left to Base Application, so that error is not
    /// lost behind a name. A new attachment text starts with a File Name, so a company that uses
    /// reminder attachment texts has this on unless somebody cleared it.
    ///
    /// Until Base Application offers a way to ask for its reminder name, this is the one place that
    /// knows its rule; the application ask on the Jira case proposes that Reminder Communication make it
    /// public, so the manager can give Base Application's reminder name on every route instead.
    /// </summary>
    /// <param name="DocumentRecRef">The run's selection.</param>
    /// <returns>True when any reminder in the run is named by Base Application.</returns>
    internal procedure IsNamedByReminderCommunication(var DocumentRecRef: RecordRef): Boolean
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        RunRecRef: RecordRef;
        Answers: Dictionary of [Text, Boolean];
    begin
        if DocumentRecRef.Number() <> Database::"Issued Reminder Header" then
            exit(false);

        RunRecRef := DocumentRecRef.Duplicate();
        RunRecRef.SetLoadFields(IssuedReminderHeader.FieldNo("Customer No."), IssuedReminderHeader.FieldNo("Reminder Terms Code"),
            IssuedReminderHeader.FieldNo("Reminder Level"));
        if not RunRecRef.FindSet() then
            exit(false);

        repeat
            RunRecRef.SetTable(IssuedReminderHeader);
            if ReminderCommunicationNames(IssuedReminderHeader, Answers) then
                exit(true);
        until RunRecRef.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Whether Reminder Communication names this one reminder. A run of many reminders usually
    /// shares a few terms, levels and languages, so each combination is looked up once.
    /// </summary>
    /// <param name="IssuedReminderHeader">The reminder.</param>
    /// <param name="Answers">The combinations already looked up in this run.</param>
    /// <returns>True when Reminder Communication names it, or would raise an error of its own.</returns>
    local procedure ReminderCommunicationNames(var IssuedReminderHeader: Record "Issued Reminder Header"; var Answers: Dictionary of [Text, Boolean]) Names: Boolean
    var
        LanguageCode: Code[10];
        AnswerKey: Text;
    begin
        if (IssuedReminderHeader."Reminder Level" = 0) or (IssuedReminderHeader."Reminder Terms Code" = '') then
            exit(false);

        LanguageCode := ReminderCommunicationLanguage(IssuedReminderHeader."Customer No.");
        AnswerKey := StrSubstNo(ReminderAnswerKeyTok, IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level", LanguageCode);
        if Answers.Get(AnswerKey, Names) then
            exit(Names);

        Names := ReminderFileNameIsSet(IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level", LanguageCode);
        Answers.Add(AnswerKey, Names);
    end;

    /// <summary>
    /// The attachment text Reminder Communication reads for a reminder level, in the order it reads
    /// them: the level's own, then the terms'. The first one found decides, even when its File Name
    /// is blank - Reminder Communication does not go on to the terms in that case either.
    /// </summary>
    /// <param name="TermsCode">The reminder terms.</param>
    /// <param name="Level">The reminder level.</param>
    /// <param name="LanguageCode">The language the attachment text is looked up in.</param>
    /// <returns>True when a File Name is set, or when the level or terms are missing.</returns>
    local procedure ReminderFileNameIsSet(TermsCode: Code[10]; Level: Integer; LanguageCode: Code[10]): Boolean
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        ReminderLevel.SetLoadFields("Reminder Attachment Text");
        if not ReminderLevel.Get(TermsCode, Level) then
            exit(true);

        ReminderAttachmentText.SetLoadFields("File Name");
        if ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", LanguageCode) then
            exit(ReminderAttachmentText."File Name" <> '');

        ReminderTerms.SetLoadFields("Reminder Attachment Text");
        if not ReminderTerms.Get(TermsCode) then
            exit(true);

        if ReminderAttachmentText.Get(ReminderTerms."Reminder Attachment Text", LanguageCode) then
            exit(ReminderAttachmentText."File Name" <> '');

        exit(false);
    end;

    /// <summary>
    /// The language Reminder Communication looks an attachment text up in: the customer's, then the
    /// user's, then the application's default. Not the company default this feature names documents
    /// in - the question here is what Reminder Communication will find, so it is asked its way.
    /// </summary>
    /// <param name="CustomerNo">The reminder's customer.</param>
    /// <returns>The language code.</returns>
    local procedure ReminderCommunicationLanguage(CustomerNo: Code[20]) LanguageCode: Code[10]
    var
        Customer: Record Customer;
        LanguageMgt: Codeunit Language;
    begin
        Customer.SetLoadFields("Language Code");
        if Customer.Get(CustomerNo) then
            LanguageCode := Customer."Language Code";

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetUserLanguageCode();

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetLanguageCode(LanguageMgt.GetDefaultApplicationLanguageId());
    end;

    [TryFunction]
    local procedure TryResolveInner(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var SourceRecRef: RecordRef; FilterViews: Text; var Filename: Text)
    var
        Pattern: Record "Report Filename Pattern";
        DocumentRecRef: RecordRef;
        LanguageCode: Code[10];
        LanguageKnown: Boolean;
    begin
        Clear(Filename);

        if not FindDocument(ReportId, SourceRecRef, FilterViews, DocumentRecRef) then
            exit;

        if IsNamedByReminderCommunication(DocumentRecRef) then
            exit;

        if not SelectPattern(ReportId, Channel, DocumentRecRef, Pattern, LanguageCode, LanguageKnown) then
            exit;

        // Read from the pattern that won, rather than carried out of selection. Selection reads
        // the language too - it must, to reject a candidate naming a different one - but it
        // reads it through the field THAT candidate designates, and candidates need not
        // designate the same field. Reading it here costs one field read and removes the
        // question entirely.
        LanguageCode := DocumentLanguage(Pattern, DocumentRecRef);

        if not TryResolveInLanguage(Pattern, ReportId, DocumentRecRef, LanguageCode, Filename) then
            Clear(Filename);
    end;

    /// <summary>
    /// Produces the name for one particular pattern, without choosing between patterns. The
    /// setup preview needs this: it has to show what the row being edited would produce, not
    /// what the manager would pick if the report ran now.
    /// </summary>
    /// <param name="Pattern">The pattern to apply.</param>
    /// <param name="ReportId">The report being delivered, which computed placeholders can name.</param>
    /// <param name="DocumentRecRef">The document, already identified.</param>
    /// <param name="Filename">Set to the resolved name when the function returns true.</param>
    /// <returns>True when the pattern produced a name.</returns>
    internal procedure TryResolveWithPattern(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; var Filename: Text): Boolean
    begin
        exit(TryResolveInLanguage(Pattern, ReportId, DocumentRecRef, DocumentLanguage(Pattern, DocumentRecRef), Filename));
    end;

    /// <summary>
    /// Produces the name in a language the caller has already established. Every placeholder that has
    /// a language-dependent form has to use the document's language rather than the session's,
    /// or the same document would be named differently by two people - so the language is
    /// settled once, above, and passed down rather than read again here.
    /// </summary>
    /// <param name="Pattern">The pattern to apply.</param>
    /// <param name="ReportId">The report being delivered, which computed placeholders can name.</param>
    /// <param name="DocumentRecRef">The document, already identified.</param>
    /// <param name="LanguageCode">The language the document is rendered in.</param>
    /// <param name="Filename">Set to the resolved name when the function returns true.</param>
    /// <returns>True when the pattern produced a name.</returns>
    local procedure TryResolveInLanguage(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var Filename: Text): Boolean
    var
        Resolved: Text;
    begin
        if not TryEvaluate(Pattern, ReportId, DocumentRecRef, LanguageCode, false, Resolved) then
            exit(false);

        exit(TryFinishName(Resolved, Filename));
    end;

    /// <summary>
    /// Finds the selection the run covered - none, one record, or many. Three sources are tried
    /// in the order of how well each behaves across the delivery routes.
    ///
    /// The payload's filter comes first because it is the platform's own statement of what the
    /// run selected, and it is present on every route that carries a payload. The caller's
    /// reference comes second: it carries the selection too, but only the routes that hand one
    /// over have it - the email route has nothing else, and Preview hands over none at all.
    /// Selecting everything comes last, and is a real answer rather than a failure.
    /// </summary>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="SourceRecRef">The caller's reference, when it has one. May be unopened.</param>
    /// <param name="FilterViews">The payload's filterviews array, when there is one.</param>
    /// <param name="DocumentRecRef">Receives the run's selection, filters intact.</param>
    /// <returns>True when the selection was established.</returns>
    local procedure FindDocument(ReportId: Integer; var SourceRecRef: RecordRef; FilterViews: Text; var DocumentRecRef: RecordRef): Boolean
    var
        TableNo: Integer;
        ViewText: Text;
    begin
        TableNo := SubjectTableNo(ReportId);

        // What the action that started the render said it was about. Only Financial Reporting
        // uses this today, and it has to: every financial report renders through one report
        // object and which one is running is a report variable, so the run itself says nothing.
        // Taken rather than read - see Report Filename Context.
        if TryTakeRunSubject(ReportId, DocumentRecRef) then
            exit(true);

        if (TableNo <> 0) and (FilterViews <> '') then
            if GetViewForTable(FilterViews, TableNo, ViewText) then
                if TryOpenAndApply(TableNo, ViewText, DocumentRecRef) then
                    exit(true);

        // Duplicated WITHOUT SetRecFilter. SetRecFilter kept whichever single row the reference
        // happened to sit on and threw the rest of the run away.
        //
        // Measured on the substitute hook: a run over three invoices arrives with Count 3 and
        // WHERE(Field3=1(103001|103002|103003)), sitting on 103003 - the LAST of the three, not
        // the first - so the row it sits on is arbitrary and naming a file after it was never
        // defensible. An unfiltered Chart of Accounts run arrives with Count 285 and no WHERE
        // clause at all, where SetRecFilter produced a filter on a blank key that matched
        // nothing, which is how the commonest list run came to have no name.
        if TryOpenFromRecRef(SourceRecRef, DocumentRecRef) then
            if not DocumentRecRef.IsEmpty() then
                exit(true);

        if TableNo = 0 then
            exit(false);

        // Neither source named a filter for the subject, which means the run was not narrowed:
        // it selected the whole table. Measured - an unfiltered Chart of Accounts run carries no
        // filterviews entry for its own table, so treating a missing entry as "nothing to name"
        // was what left that run unnamed.
        //
        // That reasoning only holds while the report actually reads the whole table, which it
        // does whenever the subject is one of its own data items. Where the subject was settled
        // some other way it does not hold at all: report 25 is about ONE financial report and
        // reads none of the others, so selecting all of them would name a balance sheet after
        // every report in the company. Nothing recorded the subject, so there is no name.
        if not IteratesTable(ReportId, TableNo) then
            exit(false);

        exit(TryOpenWholeTable(TableNo, DocumentRecRef));
    end;

    /// <summary>
    /// The table a run is about.
    ///
    /// FirstDataItemTableID is the answer for 786 of the 901 reports installed, but for 35 of
    /// them it names a virtual table while the report's real subject sits one or two levels in -
    /// report 910 Posted Assembly Order is the clearest case, whose first data item is the
    /// virtual Integer table and whose subject, Posted Assembly Header, is its child. Reading
    /// only the first data item left those reports with no kind of record and no field placeholders.
    ///
    /// So: the first data item when it names a real table, otherwise the shallowest real table
    /// among the report's data items, otherwise nothing - which is the honest answer for the 80
    /// reports that are genuinely about no record at all.
    /// </summary>
    /// <param name="ReportId">The report being delivered.</param>
    /// <returns>The subject table number, or zero when the run is about no record.</returns>
    internal procedure SubjectTableNo(ReportId: Integer): Integer
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportId = 0 then
            exit(0);

        if ReportMetadata.Get(ReportId) then
            exit(SubjectTableNo(ReportMetadata));

        exit(SubjectFromDataItems(ReportId));
    end;

    /// <summary>
    /// The same rule for a caller that already holds the report's metadata. The kinds list asks
    /// it for all 901 installed reports, and re-reading a row it has in hand for every one of
    /// them is the cost this overload exists to avoid.
    /// </summary>
    /// <param name="ReportMetadata">The report, already read.</param>
    /// <returns>The subject table number, or zero when the run is about no record.</returns>
    internal procedure SubjectTableNo(var ReportMetadata: Record "Report Metadata"): Integer
    begin
        // Financial Reporting is the one place where a report's data items do not name what its
        // run is about. Report 25 is the whole of it: every financial report an administrator
        // sets up renders through that one report, whose first data item is the row definition
        // the report happens to use. What the administrator chose, recognises and would want in
        // a file name is the Financial Report - which appears among its data items nowhere.
        if ReportMetadata.ID = Report::"Account Schedule" then
            exit(Database::"Financial Report");

        if IsNamableTable(ReportMetadata.FirstDataItemTableID) then
            exit(ReportMetadata.FirstDataItemTableID);

        exit(SubjectFromDataItems(ReportMetadata.ID));
    end;

    /// <summary>
    /// The reports a run of which is about this table, by the rule above, as a filter on Report
    /// Metadata's ID - so the Reports lookup for a pattern that names a table but no report offers
    /// only reports that could produce a file about its records.
    ///
    /// Asked the way Report Filename Plh. Mgt.BuildTables asks, and cheaply: the reports whose first
    /// data item is the table are selected by the database, and only those whose first data item is
    /// virtual pay for reading their data items. Report 25 is asked on its own, because its subject
    /// is the one that is not among its data items at all.
    /// </summary>
    /// <param name="TableNo">The table.</param>
    /// <returns>The IDs joined by |, or blank when no report is about the table.</returns>
    internal procedure ReportsAboutTable(TableNo: Integer) IdFilter: Text
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if not IsNamableTable(TableNo) then
            exit('');

        ReportMetadata.SetRange(ProcessingOnly, false);
        ReportMetadata.SetRange(FirstDataItemTableID, TableNo);
        if ReportMetadata.FindSet() then
            repeat
                if SubjectTableNo(ReportMetadata) = TableNo then
                    AddToIdFilter(IdFilter, ReportMetadata.ID);
            until ReportMetadata.Next() = 0;

        ReportMetadata.SetFilter(FirstDataItemTableID, '%1|>=%2', 0, SystemTableFrom());
        if ReportMetadata.FindSet() then
            repeat
                if SubjectTableNo(ReportMetadata) = TableNo then
                    AddToIdFilter(IdFilter, ReportMetadata.ID);
            until ReportMetadata.Next() = 0;

        if SubjectTableNo(Report::"Account Schedule") = TableNo then
            AddToIdFilter(IdFilter, Report::"Account Schedule");
    end;

    local procedure AddToIdFilter(var IdFilter: Text; ReportId: Integer)
    begin
        if IdFilter <> '' then
            IdFilter += '|';
        IdFilter += Format(ReportId, 0, 9);
    end;

    local procedure SystemTableFrom(): Integer
    begin
        exit(2000000000);
    end;

    /// <summary>
    /// The shallowest real table among a report's data items, for the 35 reports whose first
    /// data item is virtual and whose subject sits one or two levels in.
    /// </summary>
    /// <param name="ReportId">The report to inspect.</param>
    /// <returns>The subject table number, or zero when it has no real data item.</returns>
    local procedure SubjectFromDataItems(ReportId: Integer): Integer
    var
        ReportDataItems: Record "Report Data Items";
        Shallowest: Integer;
        Found: Integer;
    begin
        ReportDataItems.SetRange("Report ID", ReportId);
        if not ReportDataItems.FindSet() then
            exit(0);

        Shallowest := -1;
        repeat
            if IsNamableTable(ReportDataItems."Related Table ID") then
                if (Shallowest = -1) or (ReportDataItems."Indentation Level" < Shallowest) then begin
                    Shallowest := ReportDataItems."Indentation Level";
                    Found := ReportDataItems."Related Table ID";
                end;
        until ReportDataItems.Next() = 0;

        exit(Found);
    end;

    /// <summary>
    /// The filter a report puts on its own subject, as the report declares it.
    ///
    /// Sales - Quote reads Sales Header WHERE(Document Type=CONST(Quote)). Without this, anything
    /// offering "records this pattern could be tested against" offers every row of Sales Header -
    /// orders, invoices, credit memos - for a pattern whose report can only ever see quotes. That
    /// is the one thing this feature promises not to do: offer something compiled metadata already
    /// says is impossible.
    ///
    /// Read from Report Data Items."Data Item Table View", beside the "Request Filter Fields" this
    /// design already reads. The shallowest data item over the subject table wins, matching how
    /// SubjectFromDataItems picks the subject in the first place, so a report that reads the same
    /// table again further in is narrowed by the one its subject comes from.
    /// </summary>
    /// <param name="ReportId">The report, or zero for a pattern that names none.</param>
    /// <param name="TableNo">The subject table.</param>
    /// <returns>The view, or an empty text when the report declares none or names no report.</returns>
    internal procedure SubjectViewOf(ReportId: Integer; TableNo: Integer): Text
    var
        ReportDataItems: Record "Report Data Items";
        Shallowest: Integer;
        View: Text;
    begin
        // A pattern that names no report covers every report about this kind of record, and those
        // reports do not agree on a filter. Nothing is applied, which is correct rather than a
        // gap: the administrator really can test it against any record of the kind.
        if (ReportId = 0) or (TableNo = 0) then
            exit('');

        ReportDataItems.SetRange("Report ID", ReportId);
        ReportDataItems.SetRange("Related Table ID", TableNo);
        if not ReportDataItems.FindSet() then
            exit('');

        Shallowest := -1;
        repeat
            if (Shallowest = -1) or (ReportDataItems."Indentation Level" < Shallowest) then begin
                Shallowest := ReportDataItems."Indentation Level";
                View := ReportDataItems."Data Item Table View";
            end;
        until ReportDataItems.Next() = 0;

        exit(View);
    end;

    /// <summary>
    /// Whether a table is one a file could be named after. Anything from 2000000000 up is the
    /// platform's own machinery - Integer above all, which is how a report with no records of
    /// its own is written - and no document is a record of it.
    /// </summary>
    /// <param name="TableNo">The table number to test.</param>
    /// <returns>True when the table is a real one.</returns>
    internal procedure IsNamableTable(TableNo: Integer): Boolean
    begin
        exit((TableNo > 0) and (TableNo < 2000000000));
    end;

    /// <summary>
    /// Whether the report reads this table itself, as one of its data items. A report that does
    /// covers the whole of it when nothing narrowed the run; a report handed its subject from
    /// outside does not, and has no run to read when nobody said which record it is about.
    /// </summary>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="TableNo">The subject table.</param>
    /// <returns>True when the report declares a data item over that table.</returns>
    local procedure IteratesTable(ReportId: Integer; TableNo: Integer): Boolean
    var
        ReportDataItems: Record "Report Data Items";
    begin
        if TableNo = 0 then
            exit(false);

        ReportDataItems.SetRange("Report ID", ReportId);
        // A report whose data items are not readable is left exactly as it behaved before this
        // rule existed. The rule is here to stop one wrong name, not to withdraw names that
        // were already right.
        if ReportDataItems.IsEmpty() then
            exit(true);

        ReportDataItems.SetRange("Related Table ID", TableNo);
        exit(not ReportDataItems.IsEmpty());
    end;

    /// <summary>
    /// Takes the subject the starting action recorded, when it recorded one for this report.
    /// </summary>
    local procedure TryTakeRunSubject(ReportId: Integer; var DocumentRecRef: RecordRef): Boolean
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        exit(ReportFilenameContext.TryTakeRunSubject(ReportId, DocumentRecRef));
    end;

    [TryFunction]
    local procedure TryOpenFromRecRef(var SourceRecRef: RecordRef; var DocumentRecRef: RecordRef)
    begin
        DocumentRecRef := SourceRecRef.Duplicate();
    end;

    /// <summary>
    /// The whole of a table, which is what a run that narrowed nothing selected.
    /// </summary>
    [TryFunction]
    local procedure TryOpenWholeTable(TableNo: Integer; var DocumentRecRef: RecordRef)
    begin
        Clear(DocumentRecRef);
        DocumentRecRef.Open(TableNo);
    end;

    [TryFunction]
    local procedure TryOpenAndApply(TableNo: Integer; ViewText: Text; var DocumentRecRef: RecordRef)
    begin
        Clear(DocumentRecRef);
        DocumentRecRef.Open(TableNo);
        DocumentRecRef.SetView(ViewText);
    end;

    /// <summary>
    /// Reads the view for one table out of the payload's filterviews array.
    /// </summary>
    local procedure GetViewForTable(FilterViews: Text; TableNo: Integer; var ViewText: Text): Boolean
    var
        Views: JsonArray;
        i: Integer;
    begin
        if TableNo = 0 then
            exit(false);
        if not Views.ReadFrom(FilterViews) then
            exit(false);

        for i := 0 to Views.Count() - 1 do
            if TryReadViewForTable(Views, i, TableNo, ViewText) then
                exit(true);

        exit(false);
    end;

    /// <summary>
    /// Reads one entry of the payload's filterviews array, checking the shape at every step.
    /// The payload is the platform's rather than this design's, so a shape it has not observed
    /// has to leave the document unidentified - which leaves the caller's own name in place -
    /// rather than raise an error in the middle of somebody's print.
    /// </summary>
    local procedure TryReadViewForTable(var Views: JsonArray; Index: Integer; TableNo: Integer; var ViewText: Text): Boolean
    var
        Entry: JsonToken;
        Value: JsonToken;
    begin
        if not Views.Get(Index, Entry) then
            exit(false);
        if not Entry.IsObject() then
            exit(false);
        if not Entry.AsObject().Get('tableid', Value) then
            exit(false);
        if not Value.IsValue() then
            exit(false);
        if Value.AsValue().AsInteger() <> TableNo then
            exit(false);
        if not Entry.AsObject().Get('view', Value) then
            exit(false);
        if not Value.IsValue() then
            exit(false);

        ViewText := Value.AsValue().AsText();
        exit(ViewText <> '');
    end;

    /// <summary>
    /// Most specific pattern wins. A blank criterion applies to anything, so a single row
    /// with only a source table covers every report and every channel for that document type.
    /// </summary>
    /// <param name="BestLanguageCode">The winning pattern's document language, when matching it
    /// required reading one.</param>
    /// <param name="BestLanguageKnown">True when BestLanguageCode holds that language, so the
    /// caller does not read it a second time.</param>
    local procedure SelectPattern(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var Best: Record "Report Filename Pattern"; var BestLanguageCode: Code[10]; var BestLanguageKnown: Boolean): Boolean
    var
        Candidate: Record "Report Filename Pattern";
        CandidateLanguageCode: Code[10];
        CandidateLanguageKnown: Boolean;
        BestScore: Integer;
        Score: Integer;
        Found: Boolean;
    begin
        BestScore := 0;
        BestLanguageCode := '';
        BestLanguageKnown := false;
        Candidate.SetCurrentKey(Enabled, "Report ID", "Table No.");
        Candidate.SetRange(Enabled, true);
        Candidate.SetLoadFields("Report ID", "Table No.", "Output Route Filter", "Language Code", "Language Code Field", "File Name Pattern", "Date Format", "Max. Records Named", "Separator");
        if not Candidate.FindSet() then
            exit(false);

        repeat
            if Matches(Candidate, ReportId, Channel, DocumentRecRef, Score, CandidateLanguageCode, CandidateLanguageKnown) then
                if (not Found) or (Score > BestScore) then begin
                    Best := Candidate;
                    BestScore := Score;
                    BestLanguageCode := CandidateLanguageCode;
                    BestLanguageKnown := CandidateLanguageKnown;
                    Found := true;
                end;
        until Candidate.Next() = 0;

        exit(Found);
    end;

    local procedure Matches(var Candidate: Record "Report Filename Pattern"; ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var Score: Integer; var LanguageCode: Code[10]; var LanguageKnown: Boolean): Boolean
    begin
        exit(UnmetCriterion(Candidate, ReportId, Channel, DocumentRecRef, Score, LanguageCode, LanguageKnown) = "Report Filename Criterion"::None);
    end;

    /// <summary>
    /// Which of the pattern's criteria the document does not meet, by the same rules that choose
    /// the pattern when a report is delivered - so Test Pattern can say why a pattern does not
    /// apply, rather than saying it was out-ranked when it never competed.
    /// </summary>
    /// <param name="Candidate">The pattern to check.</param>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="Channel">The delivery route.</param>
    /// <param name="DocumentRecRef">The document, or the run's selection.</param>
    /// <param name="DocumentLanguageCode">Receives the document's language when the pattern has
    /// a language to compare it with; blank otherwise.</param>
    /// <returns>The first criterion not met, in the order naming checks them, or None.</returns>
    internal procedure FirstUnmetCriterion(var Candidate: Record "Report Filename Pattern"; ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var DocumentLanguageCode: Code[10]): Enum "Report Filename Criterion"
    var
        Score: Integer;
        LanguageKnown: Boolean;
    begin
        exit(UnmetCriterion(Candidate, ReportId, Channel, DocumentRecRef, Score, DocumentLanguageCode, LanguageKnown));
    end;

    local procedure UnmetCriterion(var Candidate: Record "Report Filename Pattern"; ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var Score: Integer; var LanguageCode: Code[10]; var LanguageKnown: Boolean): Enum "Report Filename Criterion"
    var
        Criterion: Enum "Report Filename Criterion";
        HasTableFilter: Boolean;
    begin
        Score := 0;
        LanguageCode := '';
        LanguageKnown := false;

        if Candidate."File Name Pattern" = '' then
            exit(Criterion::"File Name Pattern");

        if Candidate."Report ID" <> 0 then
            if Candidate."Report ID" <> ReportId then
                exit(Criterion::Report);

        if Candidate."Table No." <> 0 then
            if Candidate."Table No." <> DocumentRecRef.Number() then
                exit(Criterion::"Table");

        if not Candidate.AppliesToRoute(Channel) then
            exit(Criterion::"Output Route");

        // Language is checked per candidate, because the field holding it is part of the row.
        // What was read is handed back so that resolving the winner does not read it again.
        if Candidate."Language Code" <> '' then begin
            LanguageCode := DocumentLanguage(Candidate, DocumentRecRef);
            LanguageKnown := true;
            if Candidate."Language Code" <> LanguageCode then
                exit(Criterion::Language);
        end;

        // Evaluated last because it is the only criterion that costs a BLOB read and a query.
        HasTableFilter := Candidate.HasTableFilter();
        if HasTableFilter then
            if not DocumentSatisfies(Candidate, DocumentRecRef) then
                exit(Criterion::"Table Filter");

        // Scored by the pattern's own rule, which is also what the list shows as Priority, so the
        // two cannot disagree about which pattern wins.
        Score := Candidate.Specificity(HasTableFilter);
        exit(Criterion::None);
    end;

    /// <summary>
    /// Whether the run meets the pattern's condition. The condition is applied in its own
    /// filter group so that it narrows the selection rather than replacing the filter that
    /// established it - the two combine, as they do everywhere else in Business Central.
    ///
    /// EVERY record in the run must satisfy the condition, not merely one of them.
    ///
    /// Asking whether anything survived the condition - which is what this did - reads as
    /// "does this document meet it" only while the run covers one record. Over a run of two
    /// hundred accounts it reads "does ANY account meet it", so a pattern written for a single
    /// account would claim a whole-chart print and put that account's name on it. The name a
    /// pattern gives is applied to the entire file, so the pattern's claim has to be true of
    /// the entire file.
    ///
    /// It costs two counts rather than one existence check, and no rows are read. For a run
    /// covering exactly one record the two readings coincide, so nothing about naming a single
    /// document changes.
    /// </summary>
    /// <param name="Candidate">The pattern whose condition is being tested.</param>
    /// <param name="DocumentRecRef">The run's selection.</param>
    /// <returns>True when every record in the run satisfies the condition.</returns>
    local procedure DocumentSatisfies(var Candidate: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef): Boolean
    var
        TestRecRef: RecordRef;
        InTheRun: Integer;
        Satisfying: Integer;
    begin
        if not TrySelectionCount(DocumentRecRef, InTheRun) then
            exit(false);

        // An empty run satisfies nothing. Vacuous truth would let every conditioned pattern
        // claim a run that selected no records at all.
        if InTheRun = 0 then
            exit(false);

        TestRecRef := DocumentRecRef.Duplicate();
        if not TryApplyCondition(TestRecRef, Candidate.GetTableFilterView()) then
            exit(false);

        if not TrySelectionCount(TestRecRef, Satisfying) then
            exit(false);

        exit(Satisfying = InTheRun);
    end;

    /// <summary>
    /// How many records a run covers. Counting an unopened reference raises, which is why it
    /// is wrapped rather than guarded.
    /// </summary>
    /// <param name="SelectionRecRef">The selection to count.</param>
    /// <param name="Records">Receives the count.</param>
    [TryFunction]
    local procedure TrySelectionCount(var SelectionRecRef: RecordRef; var Records: Integer)
    var
        CountRecRef: RecordRef;
    begin
        CountRecRef := SelectionRecRef.Duplicate();
        Records := CountRecRef.Count();
    end;

    [TryFunction]
    local procedure TryApplyCondition(var TestRecRef: RecordRef; ViewText: Text)
    begin
        TestRecRef.FilterGroup(10);
        TestRecRef.SetView(ViewText);
        TestRecRef.FilterGroup(0);
    end;

    /// <summary>
    /// The one language a whole run is in, or nothing when it is not in one language.
    ///
    /// A run covering several records has a document language only if every record in it names
    /// the same one. Reading the first record's language and calling it the run's was wrong,
    /// and arbitrarily so: the platform does not even hand over a reference sitting on the
    /// first record. Measured on a run over invoices 103001, 103002 and 103003, the reference
    /// arrives positioned on 103003 - the LAST of the three - so "the first document" was
    /// neither the run's subject nor the one the platform was looking at.
    ///
    /// Reading them all, rather than giving up on the records as soon as a run covers more than
    /// one, keeps the behaviour that matters: a batch of three Danish invoices is still named in
    /// Danish. Only a batch that genuinely disagrees loses its language, and then the company's
    /// default is used, as for a record that names none. Bounded by MaxRecordsToAgree, exactly as ResolveSingleValue is, so naming can never
    /// become expensive on a large run.
    /// </summary>
    /// <param name="DocumentRecRef">The run's selection.</param>
    /// <param name="FieldNo">The field the pattern says holds the language.</param>
    /// <param name="LanguageCode">Receives the language the whole run agrees on.</param>
    /// <returns>True when every record in the run named the same language.</returns>
    local procedure TryReadLanguageForRun(var DocumentRecRef: RecordRef; FieldNo: Integer; var LanguageCode: Code[10]): Boolean
    var
        WorkRecRef: RecordRef;
        LanguageFieldRef: FieldRef;
        AgreedCode: Code[10];
        ThisCode: Code[10];
        Seen: Integer;
        AnyRecords: Boolean;
    begin
        Clear(LanguageCode);

        // Two outcomes, kept apart on purpose: the reference could not be read at all, and the
        // run selected no records. Both decline, but neither is allowed to look like the other.
        if not TryOpenAgreementRead(DocumentRecRef, FieldNo, WorkRecRef, AnyRecords) then
            exit(false);
        if not AnyRecords then
            exit(false);

        repeat
            Seen += 1;

            if not TryReadField(WorkRecRef, FieldNo, LanguageFieldRef) then
                exit(false);
            ThisCode := CopyStr(Format(LanguageFieldRef.Value()), 1, MaxStrLen(ThisCode));

            if Seen = 1 then
                AgreedCode := ThisCode
            else
                if ThisCode <> AgreedCode then
                    exit(false);

            // Stopping early and keeping what was seen would name a five-hundred-document run
            // after the language of its first few records. Beyond what we are willing to read,
            // the run has no one language and says so by declining.
            if Seen > MaxRecordsToAgree() then
                exit(false);
        until WorkRecRef.Next() = 0;

        LanguageCode := AgreedCode;
        exit(LanguageCode <> '');
    end;

    /// <summary>
    /// A copy of the selection positioned on its first record, loading only the field whose
    /// values are about to be compared.
    /// </summary>
    /// <param name="DocumentRecRef">The selection to copy.</param>
    /// <param name="FieldNo">The only field that will be read.</param>
    /// <param name="WorkRecRef">Receives the positioned copy.</param>
    /// <param name="AnyRecords">Set to true when the selection covers at least one record.</param>
    [TryFunction]
    local procedure TryOpenAgreementRead(var DocumentRecRef: RecordRef; FieldNo: Integer; var WorkRecRef: RecordRef; var AnyRecords: Boolean)
    begin
        WorkRecRef := DocumentRecRef.Duplicate();
        WorkRecRef.SetLoadFields(FieldNo);
        AnyRecords := WorkRecRef.FindSet();
    end;

    /// <summary>
    /// The language a pattern writes a run's name in, for Test Pattern's explanation of why
    /// [Kind of Document] has no value. The same rule the name itself is built with.
    /// </summary>
    internal procedure NameLanguage(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef): Code[10]
    begin
        exit(DocumentLanguage(Pattern, DocumentRecRef));
    end;

    /// <summary>
    /// The language the document is rendered in, which is what the file name has to agree
    /// with. Where the document carries no language, Business Central still renders it in a
    /// fallback language rather than none - reports resolve theirs through
    /// GetLanguageIdOrDefault - so naming the file as though the language were unknown would
    /// label a German invoice Invoice. The fallback chain is the document, then the company's
    /// Default Language Code (as Report Distribution Management.GetDocumentLanguageCode falls
    /// back), then the application default.
    /// </summary>
    local procedure DocumentLanguage(var Candidate: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef) LanguageCode: Code[10]
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        LanguageMgt: Codeunit Language;
    begin
        if Candidate."Language Code Field" <> 0 then
            if not TryReadLanguageForRun(DocumentRecRef, Candidate."Language Code Field", LanguageCode) then
                Clear(LanguageCode);

        // A record with no language of its own takes the company's default, which is Microsoft's
        // own rule - Report Distribution Management.GetDocumentLanguageCode ends with exactly this
        // call, and the Kind of Document placeholder already goes through it. It used to fall back
        // to the user's language, so a pattern for DEU applied when a German user produced the
        // file and not when an English one did: the name depended on who pressed the button.
        CompanyInformationMgt.GetLanguageDefault(LanguageCode);

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetLanguageCode(LanguageMgt.GetDefaultApplicationLanguageId());

        exit(LanguageCode);
    end;

    /// <summary>
    /// Replaces every placeholder, reading the canonical binding rather than the pattern text.
    /// Nothing is looked up by name here: the field number was decided when the pattern was
    /// saved, so a renamed field, a translated caption or a typo cannot change what resolves
    /// - a typo cannot even reach this point, because saving the pattern refused it.
    /// Declines the whole pattern if any placeholder has no value, rather than producing a partly
    /// filled name such as Invoice-.pdf.
    /// </summary>
    local procedure TryEvaluate(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; ShapesOnly: Boolean; var Result: Text): Boolean
    begin
        exit(TryEvaluate(Pattern, ReportId, DocumentRecRef, LanguageCode, ShapesOnly, '', Result));
    end;

    /// <summary>
    /// Replaces every placeholder, optionally collapsing each field value into the first-to-last range
    /// a run over many records produces.
    /// </summary>
    /// <param name="Pattern">The pattern being evaluated.</param>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="DocumentRecRef">The run's selection, or an unopened reference when shaping.</param>
    /// <param name="LanguageCode">The language to render language-dependent values in.</param>
    /// <param name="ShapesOnly">True to shape from metadata rather than read any record.</param>
    /// <param name="ValueJoiner">Empty for a run covering one record. Otherwise what goes between
    /// the first value and the last, which is what tells the two shapes of a multi-record name
    /// apart: the separator alone lists them, and the separator with the pattern's range word
    /// between collapses them to first-to-last.</param>
    /// <param name="Result">Receives the name.</param>
    /// <returns>True when every placeholder produced a value.</returns>
    local procedure TryEvaluate(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; ShapesOnly: Boolean; ValueJoiner: Text; var Result: Text): Boolean
    var
        Remaining: Text;
        Placeholder: Text;
        PlaceholderValue: Text;
        LastValue: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        Remaining := Pattern.GetPlaceholderBinding();
        // A pattern with text always has a binding: it is built when the text is validated. One
        // without is not resolved by name here, because resolving by name is exactly what this
        // mechanism replaces.
        if Remaining = '' then
            exit(false);

        while Remaining <> '' do begin
            StartPos := StrPos(Remaining, BindStartTok);
            if StartPos = 0 then begin
                Result += UnescapeLiteral(Remaining);
                Remaining := '';
            end else begin
                Result += UnescapeLiteral(CopyStr(Remaining, 1, StartPos - 1));

                if CopyStr(Remaining, StartPos + 1, 1) = BindStartTok then begin
                    Result += BindStartTok;
                    Remaining := CopyStr(Remaining, StartPos + 2);
                end else begin
                    EndPos := StrPos(CopyStr(Remaining, StartPos), BindEndTok);
                    if EndPos = 0 then
                        exit(false);
                    EndPos += StartPos - 1;

                    Placeholder := CopyStr(Remaining, StartPos + 1, EndPos - StartPos - 1);
                    // The one step that needs a document. Everything else about producing a name
                    // - the literals, the escaping, the sanitiser, the length limit - is the
                    // same whether the values are real or shaped, so the walk is shared and only
                    // this line differs. Duplicating the walk for the preview would have let the
                    // two drift apart, which is the one thing a preview must never do.
                    if ShapesOnly then begin
                        if not ShapeForBoundPlaceholder(Pattern, Placeholder, false, PlaceholderValue) then
                            exit(false);
                        // A computed value does not collapse: the company name and the date the
                        // file was made are one value however many records the run covered. Only
                        // a value read off the records has two ends.
                        if ValueJoiner <> '' then
                            if CollapsesOverARun(Placeholder) then begin
                                if not ShapeForBoundPlaceholder(Pattern, Placeholder, true, LastValue) then
                                    exit(false);
                                if LastValue <> PlaceholderValue then
                                    PlaceholderValue += ValueJoiner + LastValue;
                            end else
                                // A computed value that cannot speak for a run of many takes the
                                // whole pattern down with it, exactly as it does when the report
                                // really runs. Showing its single-record shape instead would put
                                // one document's total into an example of a name that covers
                                // several - a name the pattern will never produce.
                                if not SpeaksForARunOfMany(Placeholder) then
                                    exit(false);
                    end else
                        if not TryResolveBoundPlaceholder(Pattern, ReportId, DocumentRecRef, LanguageCode, Placeholder, PlaceholderValue) then
                            exit(false);
                    if PlaceholderValue = '' then
                        exit(false);

                    Result += PlaceholderValue;
                    Remaining := CopyStr(Remaining, EndPos + 1);
                end;
            end;
        end;

        exit(Result <> '');
    end;

    /// <summary>
    /// The placeholder that stops a pattern producing a name, as the administrator wrote it - so a
    /// reason can say which one rather than "at least one".
    ///
    /// Walks the binding the way TryEvaluate does and stops at the first bound placeholder without a
    /// value: its shape when ShapesOnly (a placeholder that names something no longer there, such
    /// as [Report Caption] after its rename to [Report Name]), or its value for this run otherwise.
    /// The binding holds its placeholders in the order the pattern text holds its placeholders -
    /// Report Filename Plh. Mgt.BuildBinding replaces each in turn - so the placeholder's position gives
    /// the placeholder's text.
    /// </summary>
    /// <param name="Pattern">The pattern.</param>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="DocumentRecRef">The run's selection; not read when ShapesOnly.</param>
    /// <param name="ShapesOnly">True to test each placeholder's shape rather than its value.</param>
    /// <param name="PlaceholderText">Receives the placeholder, brackets included.</param>
    /// <returns>True when a placeholder without a value was found.</returns>
    internal procedure TryFindPlaceholderWithoutValue(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; ShapesOnly: Boolean; var PlaceholderText: Text): Boolean
    var
        LanguageCode: Code[10];
        Remaining: Text;
        Placeholder: Text;
        PlaceholderValue: Text;
        StartPos: Integer;
        EndPos: Integer;
        Position: Integer;
        HasValue: Boolean;
    begin
        PlaceholderText := '';
        Remaining := Pattern.GetPlaceholderBinding();
        if Remaining = '' then
            exit(false);
        if not ShapesOnly then
            LanguageCode := DocumentLanguage(Pattern, DocumentRecRef);

        while Remaining <> '' do begin
            StartPos := StrPos(Remaining, BindStartTok);
            if StartPos = 0 then
                exit(false);
            if CopyStr(Remaining, StartPos + 1, 1) = BindStartTok then
                Remaining := CopyStr(Remaining, StartPos + 2)
            else begin
                EndPos := StrPos(CopyStr(Remaining, StartPos), BindEndTok);
                if EndPos = 0 then
                    exit(false);
                EndPos += StartPos - 1;
                Placeholder := CopyStr(Remaining, StartPos + 1, EndPos - StartPos - 1);
                Position += 1;

                PlaceholderValue := '';
                if ShapesOnly then
                    HasValue := ShapeForBoundPlaceholder(Pattern, Placeholder, false, PlaceholderValue)
                else
                    HasValue := TryResolveBoundPlaceholder(Pattern, ReportId, DocumentRecRef, LanguageCode, Placeholder, PlaceholderValue);
                if not HasValue or (PlaceholderValue = '') then begin
                    PlaceholderText := PlaceholderInText(Pattern."File Name Pattern", Position);
                    exit(PlaceholderText <> '');
                end;

                Remaining := CopyStr(Remaining, EndPos + 1);
            end;
        end;
        exit(false);
    end;

    /// <summary>
    /// The placeholder at a position in the pattern text, found the way BuildBinding finds them:
    /// from each opening bracket to the next closing one.
    /// </summary>
    local procedure PlaceholderInText(PatternText: Text; Position: Integer): Text
    var
        Remaining: Text;
        StartPos: Integer;
        EndPos: Integer;
        Seen: Integer;
    begin
        Remaining := PatternText;
        while StrPos(Remaining, PlaceholderStartTok) > 0 do begin
            StartPos := StrPos(Remaining, PlaceholderStartTok);
            EndPos := StrPos(CopyStr(Remaining, StartPos), PlaceholderEndTok);
            if EndPos = 0 then
                exit('');
            EndPos += StartPos - 1;
            Seen += 1;
            if Seen = Position then
                exit(CopyStr(Remaining, StartPos, EndPos - StartPos + 1));
            Remaining := CopyStr(Remaining, EndPos + 1);
        end;
        exit('');
    end;

    /// <summary>
    /// Gives a literal run of the binding back its braces. Braces are legal in a file name,
    /// so they are doubled when the binding is built and halved again here.
    /// </summary>
    local procedure UnescapeLiteral(LiteralText: Text): Text
    begin
        exit(LiteralText.Replace(BindEndTok + BindEndTok, BindEndTok));
    end;

    /// <summary>
    /// The name a pattern would produce, built from the shape each value takes rather than from
    /// a document. The setup card shows this, for three reasons that all point the same way: a
    /// company that has not entered its first invoice has no document to preview against; an
    /// administrator may have no permission to read one; and reading one would put somebody's
    /// real figures on a setup card, which for a payroll report means a real person's pay.
    ///
    /// The same sanitiser and the same length limit as a real name, so what is shown is a name
    /// this pattern could actually produce - not a decoration.
    /// </summary>
    /// <param name="Pattern">The pattern to shape.</param>
    /// <param name="Filename">Receives the shaped name.</param>
    /// <returns>True when every placeholder in the binding could be shaped.</returns>
    internal procedure TryShapeName(var Pattern: Record "Report Filename Pattern"; var Filename: Text): Boolean
    begin
        exit(TryShapeName(Pattern, false, Filename));
    end;

    /// <summary>
    /// The shape of the name, for a run covering one record or a run covering many.
    ///
    /// The example on the setup card used to show only the single-record form, so a pattern on
    /// a report that prints a list advertised a name that report will never produce: it showed
    /// Invoice-ABC-01.pdf where the real name collapses every field value into a first-to-last
    /// range. Both are now available, and neither reads a document - the example has to work in
    /// a company with no data and for an administrator with no permission to read any.
    /// </summary>
    /// <param name="Pattern">The pattern to shape.</param>
    /// <param name="OverManyRecords">True for the shape a run covering several records produces.</param>
    /// <param name="Filename">Receives the shaped name.</param>
    /// <returns>True when every placeholder could be shaped.</returns>
    internal procedure TryShapeName(var Pattern: Record "Report Filename Pattern"; OverManyRecords: Boolean; var Filename: Text): Boolean
    var
        NoDocument: RecordRef;
        Resolved: Text;
        Joiner: Text;
    begin
        if OverManyRecords then
            Joiner := RangeJoinOf(Pattern);

        if not TryEvaluate(Pattern, Pattern."Report ID", NoDocument, Pattern."Language Code", true, Joiner, Resolved) then
            exit(false);

        exit(TryFinishName(Resolved, Filename));
    end;

    /// <summary>
    /// The shape a run covering a few records produces: the values listed one after another
    /// rather than collapsed to first-to-last.
    ///
    /// Both shapes are real. A run is named by listing its values while there are no more than
    /// the pattern names individually, and by first-to-last beyond that - so an example showing
    /// only the collapsed form tells an administrator with Max. Number Named of three that a run
    /// over two records produces a range, which it does not.
    /// </summary>
    /// <param name="Pattern">The pattern to shape.</param>
    /// <param name="Filename">Receives the shaped name.</param>
    /// <returns>True when every placeholder could be shaped.</returns>
    internal procedure TryShapeNameListed(var Pattern: Record "Report Filename Pattern"; var Filename: Text): Boolean
    var
        NoDocument: RecordRef;
        Resolved: Text;
    begin
        if not TryEvaluate(Pattern, Pattern."Report ID", NoDocument, Pattern."Language Code", true, SeparatorOf(Pattern), Resolved) then
            exit(false);

        exit(TryFinishName(Resolved, Filename));
    end;

    /// <summary>
    /// The shape of one bound placeholder. Mirrors TryResolveBoundPlaceholder case for case, so a binding
    /// the resolver understands is one the preview understands too.
    ///
    /// A placeholder reaching one relation away is shaped from the field on the related TABLE, read
    /// out of metadata - never by following the relation, which would need a record on the
    /// other side and there may not be one.
    /// </summary>
    /// <param name="Pattern">The pattern being shaped.</param>
    /// <param name="Placeholder">The bound placeholder, without its brackets.</param>
    /// <param name="PlaceholderValue">Receives the shape.</param>
    /// <returns>True when the placeholder could be shaped.</returns>
    local procedure ShapeForBoundPlaceholder(var Pattern: Record "Report Filename Pattern"; Placeholder: Text; Last: Boolean; var PlaceholderValue: Text): Boolean
    var
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        FieldNo: Integer;
        LocalFieldNo: Integer;
        RelatedFieldNo: Integer;
        RelatedTableNo: Integer;
        HopText: Text;
        SeparatorPos: Integer;
    begin
        PlaceholderValue := '';

        if CopyStr(Placeholder, 1, StrLen(FieldPrefixTok)) = FieldPrefixTok then begin
            if not Evaluate(FieldNo, CopyStr(Placeholder, StrLen(FieldPrefixTok) + 1)) then
                exit(false);
            PlaceholderValue := FilenamePlaceholderMgt.ShapeForField(Pattern, Pattern."Table No.", FieldNo, Last);
            exit(PlaceholderValue <> '');
        end;

        if CopyStr(Placeholder, 1, StrLen(HopPrefixTok)) = HopPrefixTok then begin
            HopText := CopyStr(Placeholder, StrLen(HopPrefixTok) + 1);
            SeparatorPos := StrPos(HopText, HopBindSeparatorTok);
            if SeparatorPos = 0 then
                exit(false);
            if not Evaluate(LocalFieldNo, CopyStr(HopText, 1, SeparatorPos - 1)) then
                exit(false);
            if not Evaluate(RelatedFieldNo, CopyStr(HopText, SeparatorPos + 1)) then
                exit(false);
            RelatedTableNo := FilenamePlaceholderMgt.RelatedTableOf(Pattern."Table No.", LocalFieldNo);
            if RelatedTableNo = 0 then
                exit(false);
            PlaceholderValue := FilenamePlaceholderMgt.ShapeForField(Pattern, RelatedTableNo, RelatedFieldNo, Last);
            exit(PlaceholderValue <> '');
        end;

        if CopyStr(Placeholder, 1, StrLen(ComputedPrefixTok)) = ComputedPrefixTok then begin
            if not FilenamePlaceholderMgt.ShapeForComputed(Pattern, CopyStr(Placeholder, StrLen(ComputedPrefixTok) + 1), PlaceholderValue) then
                exit(false);
            exit(PlaceholderValue <> '');
        end;

        exit(false);
    end;

    /// <summary>
    /// Whether a placeholder takes a different value at each end of a run. A field read off the
    /// records does; a computed value - the company, the user, the date the file was made -
    /// is one value however many records the run covered.
    /// </summary>
    /// <param name="Placeholder">The bound placeholder, without its brackets.</param>
    /// <returns>True when the placeholder collapses into a range over a run.</returns>
    local procedure CollapsesOverARun(Placeholder: Text): Boolean
    begin
        exit(CopyStr(Placeholder, 1, StrLen(ComputedPrefixTok)) <> ComputedPrefixTok);
    end;

    /// <summary>
    /// Whether a computed placeholder still means something when the run covers more than one record.
    /// A placeholder this design does not recognise is treated as unable to speak for a run, because
    /// declining is the safe answer and a wrong example is worse than none.
    /// </summary>
    /// <param name="Placeholder">The bound placeholder, without its brackets.</param>
    /// <returns>True when the value is one value for the whole run.</returns>
    local procedure SpeaksForARunOfMany(Placeholder: Text): Boolean
    var
        PlaceholderImplementation: Interface "Report Filename Placeholder";
    begin
        if not TryFindComputedPlaceholder(CopyStr(Placeholder, StrLen(ComputedPrefixTok) + 1), PlaceholderImplementation) then
            exit(false);
        exit(PlaceholderImplementation.SpeaksForARunOfManyRecords());
    end;

    /// <summary>
    /// The separator the pattern joins values with, defaulted the same way RenderFilter
    /// defaults it so the example and the real name cannot disagree.
    /// </summary>
    /// <param name="Pattern">The pattern.</param>
    /// <returns>The separator.</returns>
    local procedure SeparatorOf(var Pattern: Record "Report Filename Pattern") Separator: Text
    begin
        Separator := Pattern."Separator";
        if Separator = '' then
            Separator := '-';
    end;

    /// <summary>
    /// What goes between the first and the last value when a run collapses to a range.
    ///
    /// The word in the middle is the administrator's, not this feature's. It used to be an
    /// English label that translation could never reach, which put one word into every file
    /// name that nobody who received the file had chosen and nobody could change.
    ///
    /// A blank word leaves the two values joined by the separator alone, which is a legitimate
    /// choice rather than a missing setting.
    /// </summary>
    /// <param name="Pattern">The pattern.</param>
    /// <returns>The separator, the word and the separator, or just the separator.</returns>
    internal procedure RangeJoinOf(var Pattern: Record "Report Filename Pattern") Joiner: Text
    begin
        Joiner := SeparatorOf(Pattern);
        if Pattern."Range Word" = '' then
            exit(Joiner);
        exit(Joiner + Pattern."Range Word" + Joiner);
    end;

    /// <summary>
    /// Resolves one bound placeholder: a field by its number, or a computed value by its canonical
    /// name.
    /// </summary>
    local procedure TryResolveBoundPlaceholder(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; Placeholder: Text; var PlaceholderValue: Text): Boolean
    var
        FieldRec: Record Field;
        FieldNo: Integer;
    begin
        // Cleared rather than trusted: the caller reuses this variable for every placeholder, and a
        // placeholder that resolves to nothing must not inherit the previous placeholder's value.
        PlaceholderValue := '';

        if CopyStr(Placeholder, 1, StrLen(FieldPrefixTok)) = FieldPrefixTok then begin
            if not Evaluate(FieldNo, CopyStr(Placeholder, StrLen(FieldPrefixTok) + 1)) then
                exit(false);
            // The field the administrator chose, fetched by number. It can still be gone - a
            // field removed from the table in a later version - in which case the pattern
            // declines and the caller keeps its own name.
            if not FieldRec.Get(DocumentRecRef.Number(), FieldNo) then
                exit(false);
            exit(ResolveField(Pattern, DocumentRecRef, FieldRec, PlaceholderValue));
        end;

        if CopyStr(Placeholder, 1, StrLen(HopPrefixTok)) = HopPrefixTok then
            exit(ResolveHop(Pattern, DocumentRecRef, CopyStr(Placeholder, StrLen(HopPrefixTok) + 1), PlaceholderValue));

        if CopyStr(Placeholder, 1, StrLen(ComputedPrefixTok)) = ComputedPrefixTok then
            exit(ResolveComputed(Pattern, ReportId, DocumentRecRef, LanguageCode, CopyStr(Placeholder, StrLen(ComputedPrefixTok) + 1), PlaceholderValue));

        exit(false);
    end;

    /// <summary>
    /// Resolves a computed value through its interface implementation, so that adding one is
    /// an enum extension and nothing here changes. The binding records the canonical name
    /// rather than the enum's ordinal, so a value keeps resolving even if an extension that
    /// declares it is reordered.
    /// </summary>
    local procedure ResolveComputed(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; CanonicalName: Text; var PlaceholderValue: Text): Boolean
    var
        PlaceholderImplementation: Interface "Report Filename Placeholder";
    begin
        if not TryFindComputedPlaceholder(CanonicalName, PlaceholderImplementation) then
            exit(false);

        exit(PlaceholderImplementation.TryResolve(Pattern, ReportId, DocumentRecRef, LanguageCode, PlaceholderValue));
    end;

    /// <summary>
    /// Finds the implementation whose canonical name a binding recorded.
    /// </summary>
    /// <param name="CanonicalName">The name stored in the binding.</param>
    /// <param name="PlaceholderImplementation">Receives the implementation.</param>
    /// <returns>True when a value with that name is declared.</returns>
    internal procedure TryFindComputedPlaceholder(CanonicalName: Text; var PlaceholderImplementation: Interface "Report Filename Placeholder"): Boolean
    begin
        exit(TryFindComputedPlaceholder(CanonicalName, false, PlaceholderImplementation));
    end;

    /// <summary>
    /// Finds the implementation behind a computed value's name. Every value declared on the enum
    /// is visited, including ones an extension added: nothing here knows what they are, which is
    /// what makes the extension point real rather than nominal.
    ///
    /// The one place in this app that walks the placeholder enum looking for a match. Two existed once,
    /// here and on Report Filename Placeholder Mgt., and they drifted in what they would match.
    /// </summary>
    /// <param name="PlaceholderName">The name to match.</param>
    /// <param name="AcceptDisplayName">True to match the name shown in the administrator's own language as well as the canonical one. A binding records the canonical name and is matched on that alone; a pattern the administrator typed may carry either.</param>
    /// <param name="PlaceholderImplementation">Receives the implementation when one matches.</param>
    /// <returns>True when a computed value carries that name.</returns>
    internal procedure TryFindComputedPlaceholder(PlaceholderName: Text; AcceptDisplayName: Boolean; var PlaceholderImplementation: Interface "Report Filename Placeholder"): Boolean
    var
        PlaceholderValue: Enum "Report Filename Placeholder";
        Candidate: Interface "Report Filename Placeholder";
        Ordinal: Integer;
    begin
        foreach Ordinal in PlaceholderValue.Ordinals() do begin
            PlaceholderValue := Enum::"Report Filename Placeholder".FromInteger(Ordinal);
            Candidate := PlaceholderValue;
            if Candidate.CanonicalName() = PlaceholderName then begin
                PlaceholderImplementation := Candidate;
                exit(true);
            end;
            if AcceptDisplayName and (Candidate.DisplayName() = PlaceholderName) then begin
                PlaceholderImplementation := Candidate;
                exit(true);
            end;
        end;
        exit(false);
    end;

    /// <summary>
    /// Resolves a placeholder that reaches one table relation away - a reminder's interest rate,
    /// held on Finance Charge Terms rather than on the reminder. Both field numbers were
    /// decided when the pattern was saved, so nothing is looked up by name and no path is
    /// parsed at render time.
    /// </summary>
    local procedure ResolveHop(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; HopText: Text; var PlaceholderValue: Text): Boolean
    var
        LocalFieldRec: Record Field;
        RelatedFieldRec: Record Field;
        RelatedRecRef: RecordRef;
        LocalFieldRef: FieldRef;
        LocalFieldNo: Integer;
        RelatedFieldNo: Integer;
        RelationValue: Text;
    begin
        if not TrySplitHop(HopText, LocalFieldNo, RelatedFieldNo) then
            exit(false);

        if not LocalFieldRec.Get(DocumentRecRef.Number(), LocalFieldNo) then
            exit(false);
        if LocalFieldRec.RelationTableNo = 0 then
            exit(false);
        if not RelatedFieldRec.Get(LocalFieldRec.RelationTableNo, RelatedFieldNo) then
            exit(false);

        // A placeholder reaching one relation away follows the same rule as one reading the run's own
        // table: the run is named after the records it covers. Three invoices on three different
        // payment terms are named after all three, exactly as three invoice numbers are - it used
        // to leave the whole pattern unnamed unless every record pointed at the same related
        // record, which was the field rule this design had already abandoned, surviving one level
        // out.
        //
        // A calculated local field cannot be ordered on, so those keep the older rule below.
        if LocalFieldRec.Class = LocalFieldRec.Class::Normal then
            if TryHopOverRun(Pattern, DocumentRecRef, LocalFieldRec, RelatedFieldRec, PlaceholderValue) then
                exit(PlaceholderValue <> '');

        // The older rule, kept for the fields the ordered read cannot serve: the value that
        // identifies the related record has to agree across the whole run.
        if not ResolveSingleValue(Pattern, DocumentRecRef, LocalFieldRec, RelationValue) then
            exit(false);
        if RelationValue = '' then
            exit(false);

        if not TryOpenRelated(LocalFieldRec, RelationValue, RelatedRecRef, LocalFieldRef) then
            exit(false);

        exit(ResolveSingleValue(Pattern, RelatedRecRef, RelatedFieldRec, PlaceholderValue));
    end;

    /// <summary>
    /// Names a run from the related records it points at, one relation away.
    ///
    /// The run is read in the order of the field that points at the related record, and the
    /// values that field holds decide what reaches the name: the one related value when every
    /// record points at the same record, each related value listed while there are no more than
    /// the pattern names individually, and first-to-last beyond that.
    ///
    /// BE PRECISE ABOUT WHAT THE TWO ENDS ARE. They are the related values of the FIRST and LAST
    /// values of the pointing field - the description of the first payment terms code in the run
    /// and of the last - not the alphabetically first and last descriptions. Those are not the
    /// same thing, and the difference is deliberate: finding the extremes of the related values
    /// would mean reading every distinct value the run holds, which is unbounded, and this whole
    /// approach exists because naming a run must not cost more as the run grows.
    ///
    /// Wrapped because ordering is the platform's decision, not this feature's, and a field it
    /// will not order on must fall back to the older rule rather than fail the name.
    /// </summary>
    /// <param name="Pattern">The pattern being resolved.</param>
    /// <param name="DocumentRecRef">The run's selection.</param>
    /// <param name="LocalFieldRec">The field on the run's own table that points one relation away.</param>
    /// <param name="RelatedFieldRec">The field being named, on the related table.</param>
    /// <param name="PlaceholderValue">Receives the value, or an empty string.</param>
    [TryFunction]
    local procedure TryHopOverRun(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var LocalFieldRec: Record Field; var RelatedFieldRec: Record Field; var PlaceholderValue: Text)
    var
        PointingValues: List of [Text];
        RelatedValues: List of [Text];
        FirstPointing: Text;
        LastPointing: Text;
        FirstRelated: Text;
        LastRelated: Text;
        RelatedValue: Text;
        PointingValue: Text;
    begin
        PlaceholderValue := '';

        if not ReadEnds(Pattern, DocumentRecRef, LocalFieldRec, FirstPointing, LastPointing) then
            exit;

        // Every record points at the same related record, which is every run that covers one
        // document and many that cover several. Nothing about naming those changes.
        if FirstPointing = LastPointing then begin
            if HopTo(Pattern, LocalFieldRec, RelatedFieldRec, FirstPointing, RelatedValue) then
                PlaceholderValue := RelatedValue;
            exit;
        end;

        if CollectValues(Pattern, DocumentRecRef, LocalFieldRec, PointingValues) then begin
            foreach PointingValue in PointingValues do begin
                // One relation that cannot be followed takes the whole placeholder down, rather than
                // leaving a name with a gap where a description should be.
                if not HopTo(Pattern, LocalFieldRec, RelatedFieldRec, PointingValue, RelatedValue) then
                    exit;

                // Two different records can carry the same description - two payment terms codes
                // both called Net - and a name reading Net-Net would look like a defect.
                if not RelatedValues.Contains(RelatedValue) then
                    RelatedValues.Add(RelatedValue);
            end;

            PlaceholderValue := Joined(RelatedValues, SeparatorOf(Pattern));
            exit;
        end;

        if not HopTo(Pattern, LocalFieldRec, RelatedFieldRec, FirstPointing, FirstRelated) then
            exit;
        if not HopTo(Pattern, LocalFieldRec, RelatedFieldRec, LastPointing, LastRelated) then
            exit;

        if FirstRelated = LastRelated then begin
            PlaceholderValue := FirstRelated;
            exit;
        end;

        PlaceholderValue := FirstRelated + RangeJoinOf(Pattern) + LastRelated;
    end;

    /// <summary>
    /// Reads one field of the related record a value points at.
    /// </summary>
    /// <param name="Pattern">The pattern, which decides how the value is formatted.</param>
    /// <param name="LocalFieldRec">The pointing field, which carries the relation.</param>
    /// <param name="RelatedFieldRec">The field being read on the related table.</param>
    /// <param name="RelationValue">The value that identifies the related record.</param>
    /// <param name="RelatedValue">Receives the related field's value.</param>
    /// <returns>True when the related record was found and the field had a value.</returns>
    local procedure HopTo(var Pattern: Record "Report Filename Pattern"; var LocalFieldRec: Record Field; var RelatedFieldRec: Record Field; RelationValue: Text; var RelatedValue: Text): Boolean
    var
        RelatedRecRef: RecordRef;
        TargetFieldRef: FieldRef;
    begin
        RelatedValue := '';

        if RelationValue = '' then
            exit(false);

        if not TryOpenRelated(LocalFieldRec, RelationValue, RelatedRecRef, TargetFieldRef) then
            exit(false);

        exit(ResolveSingleValue(Pattern, RelatedRecRef, RelatedFieldRec, RelatedValue));
    end;

    /// <summary>
    /// Positions on the related record the document points at. The relation's own target field
    /// is used when the relation names one, and the first primary key field otherwise, which
    /// is what a plain TableRelation means.
    /// </summary>
    [TryFunction]
    local procedure TryOpenRelated(var LocalFieldRec: Record Field; RelationValue: Text; var RelatedRecRef: RecordRef; var TargetFieldRef: FieldRef)
    var
        RelatedKeyRef: KeyRef;
    begin
        RelatedRecRef.Open(LocalFieldRec.RelationTableNo);

        if LocalFieldRec.RelationFieldNo <> 0 then
            TargetFieldRef := RelatedRecRef.Field(LocalFieldRec.RelationFieldNo)
        else begin
            RelatedKeyRef := RelatedRecRef.KeyIndex(1);
            TargetFieldRef := RelatedKeyRef.FieldIndex(1);
        end;

        TargetFieldRef.SetRange(RelationValue);
    end;

    local procedure TrySplitHop(HopText: Text; var LocalFieldNo: Integer; var RelatedFieldNo: Integer): Boolean
    var
        SplitPos: Integer;
    begin
        SplitPos := StrPos(HopText, HopSeparatorTok);
        if SplitPos = 0 then
            exit(false);
        if not Evaluate(LocalFieldNo, CopyStr(HopText, 1, SplitPos - 1)) then
            exit(false);
        exit(Evaluate(RelatedFieldNo, CopyStr(HopText, SplitPos + 1)));
    end;

    /// <summary>
    /// A field placeholder names the run after the records the run actually covers.
    ///
    /// The records are read in the order of the field being named, and what reaches the name
    /// depends on how many different values they hold: the one value when every record shares
    /// it, each value listed while they fit, and first-to-last once there are more than the
    /// pattern names individually.
    ///
    /// THIS DELIBERATELY DOES NOT READ THE FILTER. It used to, and that made the name depend on
    /// how the selection was described rather than on what was selected. The same records could
    /// arrive four ways - as a range, as an open-ended range, as a list of values, or with no
    /// filter at all - and got four different answers, one of which was no name at all. Naming
    /// from the records gives one selection one name, however it was asked for.
    ///
    /// The cost does not grow with the run. One read finds the first record, one finds the
    /// last, and one more finds each further value the name lists - so a run over four hundred
    /// thousand records costs the same as one over four. That is what removed the old limit on
    /// this path: it existed only because the previous rule read records one at a time.
    /// </summary>
    local procedure ResolveField(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var PlaceholderValue: Text): Boolean
    var
        SourceFieldRef: FieldRef;
    begin
        if not TryReadField(DocumentRecRef, FieldRec."No.", SourceFieldRef) then
            exit(false);

        // A FlowFilter has no value on any record - it exists only as the filter a run is given,
        // such as the period on Detail Trial Balance - so it is named from that filter. Read the
        // way every other field is read, it gave nothing on every run, and a placeholder the list
        // offered could never be filled in.
        if FieldRec.Class = FieldRec.Class::FlowFilter then
            exit(ResolveFlowFilter(Pattern, SourceFieldRef, FieldRec, PlaceholderValue));

        // A calculated field is not stored, so it cannot be read in its own order and it cannot
        // be read at all without being worked out first. Both matter here: asking the platform
        // to sort by one does not fail, it simply does not sort by the value, and reading it
        // straight off the record returns zero rather than the amount. Measured: the maximal
        // pattern's Amount Including VAT came back as 0.00 on every route the moment this path
        // took calculated fields as well.
        //
        // So they keep the rule they had before - the one value every record agrees on, worked
        // out record by record - and that is the path the reading limit still applies to, which
        // is where it earns its place.
        if FieldRec.Class <> FieldRec.Class::Normal then
            exit(ResolveSingleValue(Pattern, DocumentRecRef, FieldRec, PlaceholderValue));

        // And a stored field that the platform still will not order on falls back the same way,
        // rather than leaving the run unnamed.
        if not TryNameFromRecords(Pattern, DocumentRecRef, FieldRec, PlaceholderValue) then
            exit(ResolveSingleValue(Pattern, DocumentRecRef, FieldRec, PlaceholderValue));

        exit(PlaceholderValue <> '');
    end;

    /// <summary>
    /// A FlowFilter placeholder names the run after the filter it was given: one value, or the
    /// first and the last of a range joined as a run's range is joined. Anything that is not a
    /// single value or a closed range - a list, an open-ended range, a wildcard - has no one
    /// answer, and the placeholder declines rather than guessing, so the pattern is not used.
    /// No filter at all declines too: a name with a gap where the period should be is worse than
    /// Business Central's own.
    /// </summary>
    /// <param name="Pattern">The pattern, which decides the date format and the range word.</param>
    /// <param name="FilterFieldRef">The FlowFilter, on the run's selection.</param>
    /// <param name="FieldRec">The field's metadata.</param>
    /// <param name="PlaceholderValue">Receives the value.</param>
    /// <returns>True when the filter gave a value.</returns>
    local procedure ResolveFlowFilter(var Pattern: Record "Report Filename Pattern"; var FilterFieldRef: FieldRef; var FieldRec: Record Field; var PlaceholderValue: Text): Boolean
    var
        FirstText: Text;
        LastText: Text;
    begin
        PlaceholderValue := '';
        if FilterFieldRef.GetFilter() = '' then
            exit(false);
        if not TryReadFilterEnds(Pattern, FilterFieldRef, FieldRec, FirstText, LastText) then
            exit(false);
        if (FirstText = '') or (LastText = '') then
            exit(false);

        if FirstText = LastText then
            PlaceholderValue := FirstText
        else
            PlaceholderValue := FirstText + RangeJoinOf(Pattern) + LastText;
        exit(true);
    end;

    /// <summary>
    /// The two ends of a filter. The platform raises an error for a filter that is not a single
    /// value or a range, which is how those are told apart from the ones that can be named.
    /// </summary>
    [TryFunction]
    local procedure TryReadFilterEnds(var Pattern: Record "Report Filename Pattern"; var FilterFieldRef: FieldRef; var FieldRec: Record Field; var FirstText: Text; var LastText: Text)
    begin
        FirstText := FormatFilterValue(Pattern, FieldRec, FilterFieldRef.GetRangeMin());
        LastText := FormatFilterValue(Pattern, FieldRec, FilterFieldRef.GetRangeMax());
    end;

    /// <summary>
    /// One end of a filter, written as the same field's value would be: a date in the pattern's
    /// date format, a code or a number as it reads.
    /// </summary>
    local procedure FormatFilterValue(var Pattern: Record "Report Filename Pattern"; var FieldRec: Record Field; Value: Variant): Text
    var
        AsDate: Date;
    begin
        case FieldRec.Type of
            FieldRec.Type::Date:
                begin
                    AsDate := Value;
                    exit(FormatDate(AsDate, Pattern."Date Format"));
                end;
            FieldRec.Type::Code,
            FieldRec.Type::Text,
            FieldRec.Type::Integer,
            FieldRec.Type::Option:
                exit(Format(Value));
        end;
        exit('');
    end;

    /// <summary>
    /// Builds the value a field placeholder contributes, from the run's own records.
    ///
    /// Wrapped because ordering by an arbitrary field is the platform's decision, not this
    /// feature's, and a field it will not order on must fall back rather than fail the name.
    /// </summary>
    /// <param name="Pattern">The pattern being resolved.</param>
    /// <param name="DocumentRecRef">The run's selection.</param>
    /// <param name="FieldRec">The field being named.</param>
    /// <param name="PlaceholderValue">Receives the value, or an empty string.</param>
    [TryFunction]
    local procedure TryNameFromRecords(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var PlaceholderValue: Text)
    var
        Values: List of [Text];
        FirstText: Text;
        LastText: Text;
    begin
        PlaceholderValue := '';

        if not ReadEnds(Pattern, DocumentRecRef, FieldRec, FirstText, LastText) then
            exit;

        // Read in this field's own order, so first and last holding the same value means every
        // record between them holds it too. Two reads settle it however many records lie in
        // between, which is the whole reason the run no longer has to be walked.
        if FirstText = LastText then begin
            PlaceholderValue := FirstText;
            exit;
        end;

        if CollectValues(Pattern, DocumentRecRef, FieldRec, Values) then begin
            PlaceholderValue := Joined(Values, SeparatorOf(Pattern));
            exit;
        end;

        PlaceholderValue := FirstText + RangeJoinOf(Pattern) + LastText;
    end;

    /// <summary>
    /// The different values the run holds for a field, in that field's order, while they are
    /// few enough for the name to list them.
    ///
    /// Each value after the first is found by asking for the next one greater than the last,
    /// so this costs one read per value named rather than one per record covered. A run of two
    /// hundred thousand invoices for three customers costs three reads.
    /// </summary>
    /// <param name="Pattern">The pattern, which says how many are named individually.</param>
    /// <param name="DocumentRecRef">The run's selection.</param>
    /// <param name="FieldRec">The field being named.</param>
    /// <param name="Values">Receives the values, in order.</param>
    /// <returns>True when every value the run holds was collected; false when there are more
    /// than the name lists, in which case the caller shows first-to-last instead.</returns>
    local procedure CollectValues(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var Values: List of [Text]): Boolean
    var
        WorkRecRef: RecordRef;
        WorkFieldRef: FieldRef;
        LastSeen: Variant;
        ValueText: Text;
        Seen: Integer;
        MaxNamed: Integer;
    begin
        Clear(Values);
        MaxNamed := NamedIndividually(Pattern);

        WorkRecRef := DocumentRecRef.Duplicate();
        WorkRecRef.SetView(OrderedBy(WorkRecRef, FieldRec."No."));

        if not WorkRecRef.FindFirst() then
            exit(false);

        WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
        Values.Add(FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef));
        LastSeen := WorkFieldRef.Value();
        Seen := 1;

        while true do begin
            // The run's own selection stays exactly where it is: this narrowing goes into a
            // filter group of its own, so asking for the next value cannot replace the filter
            // that defines which records the run covers. The same device applies a pattern's
            // condition without disturbing the run.
            WorkRecRef.FilterGroup(NextValueFilterGroup());
            WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
            WorkFieldRef.SetFilter(GreaterThanTok, LastSeen);
            WorkRecRef.FilterGroup(0);

            if not WorkRecRef.FindFirst() then
                exit(true);

            Seen += 1;
            if Seen > MaxNamed then
                exit(false);

            WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
            ValueText := FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef);
            LastSeen := WorkFieldRef.Value();

            // Two values stored differently can be written the same way - amounts in currencies
            // of differing precision, say - and a name reading 100-100 would look like a defect
            // rather than like two records. The value still counts as seen, so this still ends.
            if not Values.Contains(ValueText) then
                Values.Add(ValueText);
        end;
    end;

    /// <summary>
    /// The first and the last value a run holds for a field, read in that field's own order.
    ///
    /// Deliberately not a try function of its own: a field the platform will not order on has to
    /// take the whole attempt down so the caller falls back, and swallowing that here would turn
    /// an unorderable field into an empty name instead.
    /// </summary>
    /// <param name="Pattern">The pattern, which decides how values are formatted.</param>
    /// <param name="DocumentRecRef">The run's selection.</param>
    /// <param name="FieldRec">The field to read.</param>
    /// <param name="FirstText">Receives the first value.</param>
    /// <param name="LastText">Receives the last value.</param>
    /// <returns>True when the run covers at least one record.</returns>
    local procedure ReadEnds(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var FirstText: Text; var LastText: Text): Boolean
    var
        WorkRecRef: RecordRef;
        WorkFieldRef: FieldRef;
    begin
        FirstText := '';
        LastText := '';

        WorkRecRef := DocumentRecRef.Duplicate();
        WorkRecRef.SetView(OrderedBy(WorkRecRef, FieldRec."No."));

        if not WorkRecRef.FindFirst() then
            exit(false);
        WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
        FirstText := FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef);

        if not WorkRecRef.FindLast() then
            exit(false);
        WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
        LastText := FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef);

        exit(true);
    end;

    /// <summary>
    /// The run's selection, to be read in one field's order instead of its own.
    ///
    /// A RecordRef has no SetCurrentKey, so the order is given through the view - which is how
    /// Base Application does it too, in Data Search. The selection half of the existing view is
    /// carried across unchanged, because a view sets both at once and losing the filter would
    /// widen the run to the whole table.
    /// </summary>
    /// <param name="SourceRecRef">The selection whose view is being rewritten.</param>
    /// <param name="FieldNo">The field to read in the order of.</param>
    /// <returns>A view with the new order and the original selection.</returns>
    local procedure OrderedBy(var SourceRecRef: RecordRef; FieldNo: Integer) NewView: Text
    var
        CurrentView: Text;
        WherePos: Integer;
    begin
        CurrentView := SourceRecRef.GetView(false);
        NewView := StrSubstNo(SortingLbl, FieldNo);

        WherePos := StrPos(CurrentView, WhereTok);
        if WherePos > 0 then
            NewView += CopyStr(CurrentView, WherePos);
    end;

    /// <summary>
    /// Joins the values a name lists, in the order they were read.
    /// </summary>
    local procedure Joined(var Values: List of [Text]; Separator: Text) Rendered: Text
    var
        Value: Text;
    begin
        foreach Value in Values do begin
            if Rendered <> '' then
                Rendered += Separator;
            Rendered += Value;
        end;
    end;

    /// <summary>
    /// How many values the name lists before collapsing to first-to-last.
    ///
    /// The field's own validation keeps this at one or more, but a row written without
    /// validation - a configuration package import - could hold zero, and zero would make a
    /// single value render as ACME-to-ACME.
    /// </summary>
    local procedure NamedIndividually(var Pattern: Record "Report Filename Pattern") MaxNamed: Integer
    begin
        MaxNamed := Pattern."Max. Records Named";
        if MaxNamed < 1 then
            MaxNamed := 3;
    end;

    /// <summary>
    /// The filter group the walk to the next value uses, kept away from the run's own filters.
    /// </summary>
    local procedure NextValueFilterGroup(): Integer
    begin
        exit(12);
    end;

    local procedure ResolveSingleValue(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var PlaceholderValue: Text): Boolean
    var
        WorkRecRef: RecordRef;
        WorkFieldRef: FieldRef;
        FirstValue: Text;
        Seen: Integer;
    begin
        WorkRecRef := DocumentRecRef.Duplicate();
        // Every field is loaded when the value is a decimal: formatting it goes through Auto
        // Format, which reads the document's currency from another field on the same row.
        if (FieldRec.Class <> FieldRec.Class::FlowField) and (FieldRec.Type <> FieldRec.Type::Decimal) then
            WorkRecRef.SetLoadFields(FieldRec."No.");
        if not WorkRecRef.FindSet() then
            exit(false);

        repeat
            Seen += 1;
            WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
            if FieldRec.Class = FieldRec.Class::FlowField then
                WorkFieldRef.CalcField();

            if Seen = 1 then
                FirstValue := FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef)
            else
                if FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef) <> FirstValue then
                    exit(false);

            // Reading the whole set would be unbounded, but stopping early and accepting the
            // value seen so far would name a 500-document run after its first few records.
            // Where the set is larger than we are willing to read, the placeholder declines.
            if Seen > MaxRecordsToAgree() then
                exit(false);
        until WorkRecRef.Next() = 0;

        PlaceholderValue := FirstValue;
        exit(PlaceholderValue <> '');
    end;

    /// <summary>
    /// How many records the manager is willing to read to establish that a set agrees on one
    /// value. Beyond this the placeholder declines rather than guessing, so naming can never become
    /// expensive on a large run.
    /// </summary>
    local procedure MaxRecordsToAgree(): Integer
    begin
        exit(100);
    end;

    local procedure FormatFieldRef(var SourceFieldRef: FieldRef; var FieldRec: Record Field; var Pattern: Record "Report Filename Pattern"; var OwnerRecRef: RecordRef): Text
    var
        AsDateTime: DateTime;
        AsDecimal: Decimal;
    begin
        case FieldRec.Type of
            FieldRec.Type::Date:
                exit(FormatDate(SourceFieldRef.Value(), Pattern."Date Format"));
            FieldRec.Type::DateTime:
                begin
                    // Formatted whole, a DateTime carries slashes and colons that the
                    // sanitiser would strip, leaving the digits run together. Only its date
                    // part is nameable.
                    AsDateTime := SourceFieldRef.Value();
                    exit(FormatDate(DT2Date(AsDateTime), Pattern."Date Format"));
                end;
            FieldRec.Type::Decimal:
                begin
                    // To the document's own precision, with an invariant separator, so the
                    // same amount reads the same for everybody who receives the file.
                    AsDecimal := SourceFieldRef.Value();
                    exit(FormatPatternDecimal(AsDecimal, OwnerRecRef));
                end;
            FieldRec.Type::Time:
                // A time has no file-safe form that stays readable, so the placeholder declines.
                exit('');
            FieldRec.Type::BLOB,
            FieldRec.Type::Media,
            FieldRec.Type::MediaSet:
                // A document, an image or a set of them. Nothing about these belongs in a file
                // name, and reading one to find out would be worse.
                exit('');
        end;
        exit(Format(SourceFieldRef.Value()));
    end;

    /// <summary>
    /// Formats an amount for a file name: to the number of decimal places the document's
    /// currency uses, and with an invariant separator.
    ///
    /// The decimal places are the document's - they come from its currency, or from General
    /// Ledger Setup in local currency - so the amount carries the same precision it has on the
    /// document. The separators deliberately are not the document's. A separator in Business
    /// Central comes from the format region of whoever is looking at the screen, and there is
    /// no way to pin it to a document: measured in the container, switching the session
    /// language changes captions and leaves 16,513.50 exactly as it was. Formatting an amount
    /// the way the reader's region writes it would mean the same invoice arrives as
    /// Invoice-16,513.50 for one recipient and Invoice-16.513,50 for another, which is the
    /// route-dependence this whole design exists to remove - and a grouping separator makes
    /// the number ambiguous once it is read back off a file name at all.
    ///
    /// This is the same decision already taken for dates, for the same reasons: a number in a
    /// file name is an identifier rather than presentation, so it has to mean one thing to
    /// everybody who receives the file.
    /// </summary>
    /// <param name="Value">The amount.</param>
    /// <param name="OwnerRecRef">The record the amount is on, which is where its currency is read from.</param>
    /// <returns>The formatted amount.</returns>
    internal procedure FormatPatternDecimal(Value: Decimal; var OwnerRecRef: RecordRef): Text
    begin
        exit(Format(Value, 0, StrSubstNo(InvariantAmountTok, AmountDecimalPlaces(OwnerRecRef))));
    end;

    /// <summary>
    /// The decimal places the document's amounts are shown with: the currency's, or the
    /// company's where the document is in local currency.
    /// </summary>
    local procedure AmountDecimalPlaces(var OwnerRecRef: RecordRef) DecimalPlaces: Text
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        DecimalPlaces := DefaultDecimalPlacesTok;

        if Currency.Get(DocumentCurrencyCode(OwnerRecRef)) then begin
            if Currency."Amount Decimal Places" <> '' then
                DecimalPlaces := Currency."Amount Decimal Places";
            exit(DecimalPlaces);
        end;

        if GeneralLedgerSetup.Get() then
            if GeneralLedgerSetup."Amount Decimal Places" <> '' then
                DecimalPlaces := GeneralLedgerSetup."Amount Decimal Places";
    end;

    /// <summary>
    /// A date in the pattern's chosen format, for a computed value that renders one.
    /// </summary>
    /// <param name="Value">The date.</param>
    /// <param name="DateFormat">The pattern's date format.</param>
    /// <returns>The formatted date.</returns>
    internal procedure FormatPatternDate(Value: Date; DateFormat: Enum "Report Filename Date Format"): Text
    begin
        exit(FormatDate(Value, DateFormat));
    end;

    /// <summary>
    /// The document's currency, found the same way the language field is: from the field that
    /// relates to the Currency table. A table with no such field, or more than one, is in
    /// local currency as far as formatting is concerned - which is what Auto Format does with
    /// a blank code anyway.
    /// </summary>
    local procedure DocumentCurrencyCode(var OwnerRecRef: RecordRef) CurrencyCode: Code[10]
    var
        FieldRec: Record Field;
        CurrencyFieldRef: FieldRef;
    begin
        FieldRec.SetRange(TableNo, OwnerRecRef.Number());
        FieldRec.SetRange(RelationTableNo, Database::Currency);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Enabled, true);
        if FieldRec.Count() <> 1 then
            exit('');

        FieldRec.FindFirst();
        if not TryReadField(OwnerRecRef, FieldRec."No.", CurrencyFieldRef) then
            exit('');

        exit(CopyStr(Format(CurrencyFieldRef.Value()), 1, MaxStrLen(CurrencyCode)));
    end;

    /// <summary>
    /// Shows what a chosen date format produces, so the administrator sees the result rather
    /// than having to read the caption and imagine it.
    /// </summary>
    /// <param name="DateFormat">The format to demonstrate.</param>
    /// <returns>Today's date in that format.</returns>
    internal procedure FormatSampleDate(DateFormat: Enum "Report Filename Date Format"): Text
    begin
        exit(FormatSampleDate(DateFormat, false));
    end;

    /// <summary>
    /// A sample date, at either end of a run. The later one is a month on, which is far enough
    /// to differ in every format this feature offers - a range shown as the same date twice
    /// would read as a defect rather than as a range.
    /// </summary>
    /// <param name="DateFormat">The format the pattern writes dates in.</param>
    /// <param name="Last">True for the later of the two sample dates.</param>
    /// <returns>The formatted sample.</returns>
    internal procedure FormatSampleDate(DateFormat: Enum "Report Filename Date Format"; Last: Boolean): Text
    begin
        if Last then
            exit(FormatDate(CalcDate(SampleRangeSpanTok, Today()), DateFormat));
        exit(FormatDate(Today(), DateFormat));
    end;

    local procedure FormatDate(Value: Date; DateFormat: Enum "Report Filename Date Format"): Text
    begin
        if Value = 0D then
            exit('');

        case DateFormat of
            DateFormat::YearMonthDay:
                exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
            DateFormat::YearMonthDayCompact:
                exit(Format(Value, 0, '<Year4><Month,2><Day,2>'));
            DateFormat::DayMonthYear:
                exit(Format(Value, 0, '<Day,2>-<Month,2>-<Year4>'));
            DateFormat::YearMonth:
                exit(Format(Value, 0, '<Year4>-<Month,2>'));
            DateFormat::Year:
                exit(Format(Value, 0, '<Year4>'));
        end;
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    [TryFunction]
    local procedure TryReadField(var DocumentRecRef: RecordRef; FieldNo: Integer; var ResultFieldRef: FieldRef)
    begin
        ResultFieldRef := DocumentRecRef.Field(FieldNo);
    end;

    /// <summary>
    /// The shape a decimal takes in a file name, for a picker showing what a value will look
    /// like rather than reading somebody's real figure. Defined once here because two callers
    /// need it - the field whose type is Decimal, and the computed document total - and two
    /// literals would drift.
    /// </summary>
    /// <returns>A sample decimal.</returns>
    internal procedure SampleDecimalText(): Text
    begin
        exit(SampleDecimalText(false));
    end;

    /// <summary>
    /// A sample amount, at either end of a run.
    /// </summary>
    /// <param name="Last">True for the larger of the two sample amounts.</param>
    /// <returns>The sample.</returns>
    internal procedure SampleDecimalText(Last: Boolean): Text
    begin
        if Last then
            exit(SampleDecimalLastTok);
        exit(SampleDecimalTok);
    end;

    /// <summary>
    /// Whether a string can serve as the separator between several values of one placeholder. The
    /// test is narrower than Sanitise on purpose: Sanitise judges a whole file name, and a
    /// whole file name may not begin or end with a space or a period. A separator sits in the
    /// middle, so " - " is legal there and is the first thing an administrator types.
    /// </summary>
    /// <param name="Value">The separator to judge.</param>
    /// <returns>True when every character in it is legal inside a file name.</returns>
    internal procedure IsUsableSeparator(Value: Text): Boolean
    begin
        if Value = '' then
            exit(true);
        if DelChr(Value, '=', InvalidCharsTok) <> Value then
            exit(false);
        exit(DelChr(Value, '=', GetControlChars()) = Value);
    end;

    /// <summary>
    /// The characters a file name cannot contain, for a message that has to name them.
    /// </summary>
    /// <returns>The disallowed characters.</returns>
    internal procedure DisallowedCharacters(): Text
    begin
        exit(InvalidCharsTok);
    end;

    /// <summary>
    /// Makes a resolved name safe to use as a file name. Built on Base Application's own
    /// File Management.GetSafeFileName, which removes every character the platform reports as
    /// invalid in a file name - control characters included, so a line break or a tab inside a
    /// value is removed rather than turned into a space. That list is the server's: on a Unix
    /// server .NET reports only the null character and /. So this then removes, whatever the
    /// server, every character a device the file can land on rejects (RemoveCharsEveryDeviceRejects);
    /// collapses repeated spaces; trims spaces and dots from both ends; and refuses a reserved
    /// device name. The length is cut separately, by Truncate.
    ///
    /// Characters that are merely unusual, such as &amp; or ~, are kept. File Management's
    /// StripNotsupportChrInFileName removes those too, which is why it is not the one used:
    /// silently rewriting a customer's name is worse than an odd character in it.
    /// </summary>
    /// <param name="Value">The candidate name.</param>
    /// <returns>A name that is safe to use, or an empty string when nothing usable remains - the pattern then declines.</returns>
    internal procedure Sanitise(Value: Text) Result: Text
    begin
        Result := CleanName(Value);

        if Result = '' then
            exit('');

        if IsReservedName(Result) then
            exit('');
    end;

    /// <summary>
    /// Sanitise's cleaning, before it judges what is left: the characters removed, repeated spaces
    /// collapsed, spaces and dots trimmed from both ends.
    /// </summary>
    local procedure CleanName(Value: Text) Result: Text
    var
        FileManagement: Codeunit "File Management";
    begin
        Result := FileManagement.GetSafeFileName(Value);
        Result := RemoveCharsEveryDeviceRejects(Result);

        while StrPos(Result, '  ') > 0 do
            Result := Result.Replace('  ', ' ');

        Result := DelChr(Result, '<>', ' .');
    end;

    /// <summary>
    /// Why FinishName refuses a name, in the order it judges: nothing usable left after cleaning,
    /// a name Windows reserves, and the same two again after the cut to length. For Test Pattern,
    /// which used to say a placeholder had no value when every placeholder had one and the name
    /// was refused here instead (container client, 8 October: a customer named CON.2026).
    /// </summary>
    /// <param name="Value">The name as the pattern built it, before its extension.</param>
    /// <param name="CutName">Receives the name after the cut, for the two refusals made after it.</param>
    /// <returns>Why the name is refused, or None when FinishName uses it.</returns>
    internal procedure WhyNameIsRefused(Value: Text; var CutName: Text): Enum "Report Filename Refusal"
    var
        Cleaned: Text;
    begin
        CutName := '';
        Cleaned := CleanName(Value);
        if Cleaned = '' then
            exit(Enum::"Report Filename Refusal"::"Nothing Usable");
        if IsReservedName(Cleaned) then
            exit(Enum::"Report Filename Refusal"::Reserved);

        CutName := Truncate(Cleaned, MaxFileNameLength());
        if CutName = '' then
            exit(Enum::"Report Filename Refusal"::"Nothing After Cut");
        if IsReservedName(CutName) then
            exit(Enum::"Report Filename Refusal"::"Reserved After Cut");
        exit(Enum::"Report Filename Refusal"::None);
    end;

    /// <summary>
    /// The name a pattern builds for a run before FinishName makes it safe and cuts it - the same
    /// evaluation as TryResolveWithPattern, stopping short of finishing it.
    /// </summary>
    /// <param name="Pattern">The pattern to apply.</param>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="DocumentRecRef">The run's selection.</param>
    /// <param name="Resolved">Receives the name as built.</param>
    /// <returns>True when every placeholder gave a value.</returns>
    internal procedure TryBuildUnfinishedName(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; var Resolved: Text): Boolean
    begin
        exit(TryEvaluate(Pattern, ReportId, DocumentRecRef, DocumentLanguage(Pattern, DocumentRecRef), false, Resolved));
    end;

    /// <summary>
    /// Max. File Name Length as naming uses it, for a reason that names it.
    /// </summary>
    internal procedure MaxFileNameLengthInUse(): Integer
    begin
        exit(MaxFileNameLength());
    end;

    /// <summary>
    /// Removes every character that a place a report file can land on rejects: Windows' list
    /// (" * : &lt; &gt; ? \ / | and control characters 1 to 31), which FAT32 and exFAT share - SD
    /// cards in phones and cameras; DEL, which Android's own check for FAT names rejects too; and
    /// # and %, which SharePoint and OneDrive reject. On a Windows server File Management.
    /// GetSafeFileName has already removed most of these, and this removes nothing more of them;
    /// on a Unix server it is what removes them.
    /// </summary>
    /// <param name="Value">The candidate name.</param>
    /// <returns>The name without those characters.</returns>
    internal procedure RemoveCharsEveryDeviceRejects(Value: Text): Text
    begin
        exit(DelChr(DelChr(Value, '=', InvalidCharsTok), '=', GetControlChars()));
    end;

    /// <summary>
    /// Whether Windows reserves the name for a device. It does so for the bare name and for the
    /// name followed by any extension - NUL.txt and NUL.tar.gz are both NUL - so the part before
    /// the first period is what counts.
    /// </summary>
    local procedure IsReservedName(Value: Text): Boolean
    var
        Reserved: List of [Text];
    begin
        Reserved := ReservedNamesTok.Split(',');
        if StrPos(Value, '.') > 0 then
            Value := CopyStr(Value, 1, StrPos(Value, '.') - 1);
        exit(Reserved.Contains(UpperCase(Value)));
    end;

    local procedure GetControlChars() Chars: Text
    var
        ControlChar: Char;
        i: Integer;
    begin
        // Assign through a Char so the character itself is appended. Format(i) would append
        // its decimal text instead, which contains every digit - and DelChr would then strip
        // the digits out of every file name.
        for i := 1 to 31 do begin
            ControlChar := i;
            Chars += ControlChar;
        end;
        // DEL, which Android rejects in a name on a FAT-formatted card.
        ControlChar := 127;
        Chars += ControlChar;
    end;

    /// <summary>
    /// The longest a file name may be, before its extension - one value for every pattern, from the
    /// setup, or its default when nobody has opened the setup yet.
    /// </summary>
    /// <returns>The maximum length.</returns>
    local procedure MaxFileNameLength(): Integer
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        if not ReportFilenameSetup.Get() then
            ReportFilenameSetup.Init();
        exit(ReportFilenameSetup."Max. File Name Length");
    end;

    /// <summary>
    /// Tells the administrator, on the page they are on, that file name patterns are turned off in
    /// the setup, with an action that opens it. The patterns list and the pattern card both send it,
    /// so whichever page a pattern is set up from says that no pattern names anything.
    /// </summary>
    /// <returns>True when patterns are turned off and the notification was sent.</returns>
    internal procedure NotifyIfSwitchedOff(): Boolean
    var
        ReportFilenameSetup: Record "Report Filename Setup";
        SwitchedOffNotification: Notification;
    begin
        ReportFilenameSetup.GetSettings();
        if ReportFilenameSetup.Enabled then
            exit(false);

        SwitchedOffNotification.Message(SwitchedOffMsg);
        SwitchedOffNotification.Scope(NotificationScope::LocalScope);
        SwitchedOffNotification.AddAction(OpenSetupLbl, Codeunit::"Report Filename Mgt.", 'OpenSetupFromNotification');
        SwitchedOffNotification.Send();
        exit(true);
    end;

    /// <summary>
    /// What the "switched off" notification says.
    /// </summary>
    internal procedure SwitchedOffMessage(): Text
    begin
        exit(SwitchedOffMsg);
    end;

    /// <summary>
    /// The action on the "switched off" notification: opens the setup, and sends the notification
    /// again when the setup is closed with patterns still turned off. Choosing the action takes the
    /// notification away, and the page it was on does not open again when the setup closes, so
    /// nothing else would bring it back.
    /// </summary>
    /// <param name="SetupNotification">The notification the action was chosen on.</param>
    internal procedure OpenSetupFromNotification(SetupNotification: Notification)
    begin
        Page.RunModal(Page::"Report Filename Setup");
        NotifyIfSwitchedOff();
    end;

    /// <summary>
    /// The finished name: made safe, cut to length, and judged again after the cut. The cut can
    /// undo what Sanitise established - "CON - - - x" cut short and trimmed is CON, which Windows
    /// reserves, and a value that begins with hyphens can be cut to nothing - so the two checks
    /// that end Sanitise are made again on what the cut leaves.
    /// </summary>
    /// <param name="Value">The resolved name, before its extension.</param>
    /// <param name="MaxLength">Max. File Name Length.</param>
    /// <returns>The name, or an empty string when nothing usable remains - the pattern then declines.</returns>
    internal procedure FinishName(Value: Text; MaxLength: Integer) Result: Text
    begin
        Result := Sanitise(Value);
        if Result = '' then
            exit('');

        Result := Truncate(Result, MaxLength);
        if Result = '' then
            exit('');
        if IsReservedName(Result) then
            exit('');
    end;

    local procedure TryFinishName(Resolved: Text; var Filename: Text): Boolean
    var
        Finished: Text;
    begin
        Finished := FinishName(Resolved, MaxFileNameLength());
        if Finished = '' then
            exit(false);

        Filename := Finished;
        exit(true);
    end;

    /// <summary>
    /// Cuts a resolved name, before its extension, to Max. File Name Length in characters, and
    /// then to what every device stores (FitToDevices), keeping room for the extension and a
    /// number the way the 245-character ceiling does.
    /// </summary>
    local procedure Truncate(Value: Text; MaxLength: Integer): Text
    begin
        if (MaxLength > 0) and (StrLen(Value) > MaxLength) then
            Value := DelChr(CopyStr(Value, 1, MaxLength), '>', ' .-');
        exit(DelChr(FitToDevices(Value, DeviceNameLimit() - ExtensionReserve()), '>', ' .-'));
    end;

    /// <summary>
    /// A name and its ending - an extension, or a number and an extension - with the name shortened
    /// rather than the ending: to a field's length when there is one, and always to what every
    /// device stores. Cutting the joined text instead turned a long name into "....p" or dropped
    /// the extension entirely.
    /// </summary>
    /// <param name="Name">The name without its ending.</param>
    /// <param name="Ending">The ending, kept whole.</param>
    /// <param name="MaxLength">The length of the field the name goes into, or 0 for none.</param>
    /// <returns>The name joined to its ending.</returns>
    internal procedure FitWithEnding(Name: Text; Ending: Text; MaxLength: Integer): Text
    begin
        if (MaxLength > 0) and (StrLen(Name) + StrLen(Ending) > MaxLength) then
            Name := CopyStr(Name, 1, MaxLength - StrLen(Ending));
        exit(FitToDevices(Name, DeviceNameLimit() - DeviceLength(Ending)) + Ending);
    end;

    /// <summary>
    /// Cuts a name from its end until it fits what every device stores. ext4 and F2FS (Android,
    /// Linux) and APFS (Mac, iPhone, iPad) allow 255 bytes of UTF-8 per name; FAT32, exFAT, NTFS and
    /// HFS+ allow 255 UTF-16 characters, and HFS+ counts them after decomposing the name. A character
    /// above 127 is counted as 4: as given it takes at most 3 bytes, and decomposed on HFS+ at most 4
    /// characters. A character pair that encodes one character is never split.
    /// </summary>
    /// <param name="Value">The name.</param>
    /// <param name="Limit">How much of the 255 the name may use.</param>
    /// <returns>The name, cut when it is longer.</returns>
    internal procedure FitToDevices(Value: Text; Limit: Integer): Text
    var
        Used: Integer;
        i: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            Used += DeviceLength(Value[i]);
            if Used > Limit then begin
                Value := CopyStr(Value, 1, i - 1);
                if (StrLen(Value) > 0) and IsFirstOfPair(Value[StrLen(Value)]) then
                    Value := CopyStr(Value, 1, StrLen(Value) - 1);
                exit(Value);
            end;
        end;
        exit(Value);
    end;

    local procedure DeviceLength(Value: Text) Length: Integer
    var
        i: Integer;
    begin
        for i := 1 to StrLen(Value) do
            if Value[i] > 127 then
                Length += 4
            else
                Length += 1;
    end;

    local procedure IsFirstOfPair(Character: Char): Boolean
    begin
        exit((Character >= 55296) and (Character <= 56319));
    end;

    /// <summary>
    /// The most any device the file can land on stores in one name.
    /// </summary>
    local procedure DeviceNameLimit(): Integer
    begin
        exit(255);
    end;

    /// <summary>
    /// What a resolved name leaves of DeviceNameLimit for the extension and a number added later,
    /// often by Base Application: " (1).xlsx" is 9. The same 10 that Max. File Name Length's
    /// ceiling of 245 leaves.
    /// </summary>
    local procedure ExtensionReserve(): Integer
    begin
        exit(10);
    end;
}
