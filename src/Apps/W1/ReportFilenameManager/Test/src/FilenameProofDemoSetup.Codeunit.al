// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50160 "Filename Proof Demo Setup"
{
    // Seeds a representative set of patterns, so the setup can be looked at and photographed
    // as an administrator would meet it rather than as whatever the last proof left behind.
    // Every row is created through Validate, so each one gets its binding built exactly as it
    // would if somebody typed it on the card.

    trigger OnRun()
    begin
        SeedDemoPatterns();
    end;

    procedure SeedDemoPatterns()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofLogMgt.StartNewRun();
        FilenameProofGuard.ClearPatterns();

        // The plain case: every sales invoice, every route, named after the document.
        AddPattern(Report::"Standard Sales - Invoice", 0, InvoicePatternTok, false);

        // The same document by email, in German, named differently - two rows differing only
        // by channel and language, which is how that is expressed without code.
        AddPatternForChannel(Report::"Standard Sales - Invoice", InvoiceGermanPatternTok, GermanLanguageCodeTok, Enum::"Report Filename Output Route"::Email);

        // A credit memo, by source table rather than by report, so it covers every report that
        // names one.
        AddPattern(0, Database::"Sales Cr.Memo Header", CreditMemoPatternTok, false);

        // Reminders, and then reminders at level 3 - the same table, differing only by the
        // condition on the document.
        AddPattern(0, Database::"Issued Reminder Header", ReminderPatternTok, false);
        AddPattern(0, Database::"Issued Reminder Header", ReminderLevel3PatternTok, true);

        // Financial Reporting, which renders every report an administrator sets up through one
        // report object. Named after the financial report itself, because that is the only thing
        // that tells a balance sheet from a trial balance.
        AddPattern(Report::"Account Schedule", 0, FinancialReportPatternTok, false);

        // And the maximal one, using every kind of placeholder there is. Given its own channel so it
        // does not score identically to the first row - two rows with the same criteria are a
        // coin toss, which is the last thing a setup meant to be looked at should show.
        AddPatternForChannel(Report::"Standard Sales - Invoice", MaximalPatternTok, '', Enum::"Report Filename Output Route"::Download);

        ProofSupport.LogLine('Demo setup', StrSubstNo(SeededMsg, Pattern.Count()));
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Installs one pattern naming a sales invoice by its kind of document, so that the placeholder
    /// can be driven from a real client rather than only through the manager.
    ///
    /// On its own, because it replaces the demo set while it is in place: the ordinary demo
    /// patterns already name report 1306 on every channel, and two patterns with the same
    /// criteria would make which one applied a coin toss. Seed the demo patterns again
    /// afterwards.
    /// </summary>
    procedure SeedKindOfDocumentPattern()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofLogMgt.StartNewRun();
        FilenameProofGuard.ClearPatterns();

        AddPattern(Report::"Standard Sales - Invoice", 0, KindOfDocumentPatternTok, false);

        ProofSupport.LogLine('Demo setup', StrSubstNo(SeededMsg, Pattern.Count()));
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Points the financial report demo pattern at the user's [Period] pattern, so a real client print
    /// of a financial report can be named by its period and compared with what the tests prove.
    /// Raised by the user on 28 September. Seed the demo patterns again afterwards.
    /// </summary>
    procedure UseThePeriodPattern()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();

        Pattern.SetRange("Report ID", Report::"Account Schedule");
        Pattern.FindFirst();
        Pattern.Validate("File Name Pattern", FinancialReportPeriodPatternTok);
        Pattern.Modify(true);

        ProofSupport.LogLine('Demo setup', Pattern."File Name Pattern");
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Adds a pattern for report 711 Inventory - Top 10 List, whose default layout is Excel, so a
    /// real client download can show whether an Excel file is named. Raised by the user on
    /// 28 September, over the Max. File Name Length field and Excel's 218-character path limit.
    /// Seed the demo patterns again afterwards.
    /// </summary>
    procedure AddTheExcelPattern()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();
        AddPattern(Report::"Inventory - Top 10 List", 0, ExcelPatternTok, false);
        Pattern.SetRange("Report ID", Report::"Inventory - Top 10 List");
        Pattern.FindFirst();
        ProofSupport.LogLine('Demo setup', Pattern."File Name Pattern");
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Switches the German email pattern off, so the list can be looked at - and photographed -
    /// with a dimmed row in it.
    ///
    /// A switched-off pattern is a state administrators really have, and how the list shows one
    /// is a thing a person has to be able to see. Doing it from here rather than by hand makes
    /// it reproducible: the screenshot in the retest guide can be retaken by anybody without
    /// having to guess which row was clicked.
    /// </summary>
    procedure SwitchTheGermanPatternOff()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();

        Pattern.SetRange("File Name Pattern", InvoiceGermanPatternTok);
        if not Pattern.FindFirst() then begin
            ProofSupport.LogLine('Demo setup', NoGermanPatternMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        Pattern.Validate(Enabled, false);
        Pattern.Modify(true);

        ProofSupport.LogLine('Demo setup', StrSubstNo(SwitchedOffMsg, Pattern."File Name Pattern"));
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Adds a pattern as one saved before [Report Caption] was renamed [Report Name] still holds it:
    /// the old text and a binding recording the old canonical name, saved without the insert
    /// trigger, which would refuse the old text - as Filename Card Tests.AStalePlaceholderIsNamedInTheReason
    /// builds it. The card refuses typing it, so client-pass row C.3 needs it made here. Seed the
    /// demo patterns again afterwards.
    /// </summary>
    procedure AddTheStalePlaceholderPattern()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        BindingOutStream: OutStream;
    begin
        FilenameProofLogMgt.StartNewRun();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern."File Name Pattern" := StalePatternTok;
        Pattern."Placeholder Binding".CreateOutStream(BindingOutStream, TextEncoding::UTF8);
        BindingOutStream.WriteText(StaleBindingTok);
        Pattern.Enabled := true;
        Pattern.Insert(false);
        ProofSupport.LogLine('Demo setup', StrSubstNo(AddedMsg, Pattern."Entry No.", Pattern."File Name Pattern"));
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Adds an assembly quote for client-pass row C.4, which chooses one in Test Pattern's record
    /// lookup. CRONUS has no assembly documents, the Assembly Quotes list offers no New - a quote
    /// comes from a sales quote line for an assemble-to-order item - so it is made here, through
    /// Base Application's own triggers: the number from Assembly Setup, the item validated.
    /// </summary>
    procedure AddAnAssemblyQuote()
    var
        AssemblyHeader: Record "Assembly Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Quote;
        AssemblyHeader.Insert(true);
        AssemblyHeader.Validate("Item No.", AssemblyItemTok);
        AssemblyHeader.Validate(Quantity, 1);
        AssemblyHeader.Modify(true);
        ProofSupport.LogLine('Demo setup', StrSubstNo(AddedQuoteMsg, AssemblyHeader."No.", AssemblyHeader."Item No."));
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Posts a sales invoice with no Language Code, for client-pass row K.4, through Base
    /// Application's own posting. Every customer and posted invoice in CRONUS has a language, so
    /// the row has nothing to print without it. The customer's language is cleared on the invoice
    /// only; the customer is left as it is.
    /// </summary>
    procedure PostAnInvoiceWithNoLanguage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", NoLanguageCustomerTok);
        SalesHeader.Validate("Language Code", '');
        SalesHeader.Modify(true);
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", NoLanguageItemTok);
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
        ProofSupport.LogLine('Demo setup', StrSubstNo(PostedNoLanguageMsg, SalesHeader."Last Posting No."));
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Sets the company's Default Language Code, for client-pass row K.4: blank in CRONUS, so a
    /// document with no language of its own could not show whether the company's default or the
    /// user's language names it. Set it back to blank afterwards.
    /// </summary>
    /// <param name="LanguageCode">The language code, or blank.</param>
    procedure SetCompanyDefaultLanguage(LanguageCode: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Default Language Code", CopyStr(LanguageCode, 1, MaxStrLen(CompanyInformation."Default Language Code")));
        CompanyInformation.Modify(true);
        ProofSupport.LogLine('Demo setup', StrSubstNo(DefaultLanguageMsg, CompanyInformation."Default Language Code"));
    end;

    /// <summary>
    /// Sets the company's Default Language Code back to blank, as CRONUS has it, after K.4. A
    /// procedure of its own because a blank argument does not reach SetCompanyDefaultLanguage:
    /// BcContainerHelper drops it and the server then looks for a procedure without one.
    /// </summary>
    procedure ClearCompanyDefaultLanguage()
    begin
        SetCompanyDefaultLanguage('');
    end;

    /// <summary>
    /// Sets the language of the proofs' issued reminder PROOF-RMDR-1, to show [Kind of Document] on a
    /// reminder whose language differs from the company's (8 October). PROOF-RMDR-1 is in ENG.
    /// </summary>
    procedure SetProofReminderLanguage(LanguageCode: Text)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        IssuedReminderHeader.Get(ProofReminderNoTok);
        IssuedReminderHeader."Language Code" := CopyStr(LanguageCode, 1, MaxStrLen(IssuedReminderHeader."Language Code"));
        IssuedReminderHeader.Modify(false);
    end;

    /// <summary>
    /// A pattern [Kind of Document]-[No.] for the report issued reminders print with, for the same
    /// demonstration. Tied to the report, so it outranks the demo pattern for every issued reminder.
    /// </summary>
    procedure AddKindOfDocumentReminderPattern()
    var
        Pattern: Record "Report Filename Pattern";
        ReportSelections: Record "Report Selections";
    begin
        RemoveKindOfDocumentReminderPattern();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::Reminder);
        ReportSelections.SetFilter("Report ID", '<>%1', 0);
        ReportSelections.FindFirst();
        Pattern.Init();
        Pattern.Validate("Report ID", ReportSelections."Report ID");
        Pattern.Validate("Table No.", Database::"Issued Reminder Header");
        Pattern.Validate("File Name Pattern", KindOfDocumentPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    procedure RemoveKindOfDocumentReminderPattern()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.SetRange("Table No.", Database::"Issued Reminder Header");
        if Pattern.FindSet() then
            repeat
                if Pattern."File Name Pattern" = KindOfDocumentPatternTok then
                    Pattern.Delete(true);
            until Pattern.Next() = 0;
    end;

    /// <summary>
    /// Gives reminder level 1 of the DOMESTIC terms an attachment text with a File Name, in the
    /// language of customer 10000, for client-pass rows R.1 and R.2. CRONUS has no attachment
    /// texts. Written as Filename Proof Run.SeedReminderFileName writes it.
    /// </summary>
    procedure GiveReminderLevelAFileName()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        Customer: Record Customer;
    begin
        ReminderLevel.Get(ReminderTermsTok, 1);
        Customer.Get(NoLanguageCustomerTok);
        ReminderAttachmentText.Init();
        ReminderAttachmentText.Id := CreateGuid();
        ReminderAttachmentText."Language Code" := Customer."Language Code";
        ReminderAttachmentText."File Name" := ReminderFileNameTok;
        ReminderAttachmentText.Insert(false);
        ReminderLevel."Reminder Attachment Text" := ReminderAttachmentText.Id;
        ReminderLevel.Modify(false);
        ProofSupport.LogLine('Demo setup', StrSubstNo(ReminderFileNameMsg, ReminderAttachmentText."File Name", ReminderAttachmentText."Language Code"));
    end;

    /// <summary>
    /// Fills in what the Reminder report reads on the stand-in issued reminder PROOF-RMDR-1, which
    /// was made without it and could not be printed (client-pass row R.1).
    /// </summary>
    procedure CompleteTheProofReminder()
    var
        FilenameProofSeedRmdr: Codeunit "Filename Proof Seed Rmdr";
    begin
        FilenameProofSeedRmdr.CompleteExistingStandIn();
    end;

    /// <summary>
    /// Clears File Name on the attachment text GiveReminderLevelAFileName made, keeping the text,
    /// for client-pass row R.3.
    /// </summary>
    procedure ClearReminderLevelFileName()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        ReminderAttachmentText.SetRange("File Name", ReminderFileNameTok);
        ReminderAttachmentText.ModifyAll("File Name", '', false);
    end;

    /// <summary>
    /// Removes the attachment text GiveReminderLevelAFileName made and points the level at none
    /// again, as CRONUS has it.
    /// </summary>
    procedure RemoveReminderLevelAttachmentText()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        NoText: Guid;
    begin
        ReminderLevel.Get(ReminderTermsTok, 1);
        ReminderAttachmentText.SetRange(Id, ReminderLevel."Reminder Attachment Text");
        ReminderAttachmentText.DeleteAll(false);
        ReminderLevel."Reminder Attachment Text" := NoText;
        ReminderLevel.Modify(false);
    end;

    /// <summary>
    /// Removes the job queue entries the scheduled-route proofs left behind before they removed
    /// their own (Filename Proof Support.RemoveJobQueueEntry) - found by the two descriptions only
    /// those proofs give an entry.
    /// </summary>
    procedure RemoveProofJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Removed: Integer;
    begin
        JobQueueEntry.SetFilter(Description, '%1|%2', ScheduledRunDescriptionTok, MaximalRunDescriptionTok);
        Removed := JobQueueEntry.Count();
        JobQueueEntry.DeleteAll(true);
        ProofSupport.LogLine('Demo setup', StrSubstNo(RemovedEntriesMsg, Removed));
    end;

    /// <summary>
    /// What client-pass row R.5 needs before Start is chosen on Reminder Automation, built as Filename
    /// Reminder Tests builds it but under codes of its own (ZZCLIENT, ZZRM-CLIENT), so the two can never
    /// meet: reminder terms with a level, a second report selection for the invoice, a reminder
    /// automation group with a Send action that emails and attaches every invoice, and an issued
    /// reminder for two posted invoices of one customer. Constructed rather than issued, for the
    /// reason the tests give: issuing one for real posts ledger entries that cannot be removed.
    /// </summary>
    procedure SetUpClientPassReminderAutomation()
    var
        FirstInvoice: Record "Sales Invoice Header";
        SecondInvoice: Record "Sales Invoice Header";
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderAction: Record "Reminder Action";
        SendRemindersSetup: Record "Send Reminders Setup";
        Existing: Record "Report Selections";
        ReportSelections: Record "Report Selections";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        RemoveClientPassReminderAutomation();

        FirstInvoice.SetFilter("Bill-to Customer No.", '<>%1', '');
        if FirstInvoice.FindSet() then
            repeat
                SecondInvoice.Reset();
                SecondInvoice.SetRange("Bill-to Customer No.", FirstInvoice."Bill-to Customer No.");
                SecondInvoice.SetFilter("No.", '<>%1', FirstInvoice."No.");
            until SecondInvoice.FindFirst() or (FirstInvoice.Next() = 0);
        SecondInvoice.TestField("No.");

        ReminderTerms.Init();
        ReminderTerms.Code := ClientPassCodeTok;
        ReminderTerms.Description := ClientPassCodeTok;
        ReminderTerms.Insert(false);
        ReminderLevel.Init();
        ReminderLevel."Reminder Terms Code" := ClientPassCodeTok;
        ReminderLevel."No." := 1;
        ReminderLevel.Insert(false);

        Existing.SetRange(Usage, Existing.Usage::"S.Invoice");
        Existing.FindFirst();
        ReportSelections := Existing;
        ReportSelections.Sequence := ClientPassCodeTok;
        ReportSelections.Insert(false);

        ReminderActionGroup.Init();
        ReminderActionGroup.Code := ClientPassCodeTok;
        ReminderActionGroup.Description := ClientPassCodeTok;
        ReminderActionGroup.Insert(false);
        ReminderActionGroup.SetReminderTermsSelectionFilter(ClientPassCodeTok);

        ReminderAction.Init();
        ReminderAction."Reminder Action Group Code" := ClientPassCodeTok;
        ReminderAction.Code := ClientPassCodeTok;
        ReminderAction.Type := ReminderAction.Type::"Send Reminder";
        ReminderAction.Insert(false);

        SendRemindersSetup.Init();
        SendRemindersSetup.Code := ClientPassCodeTok;
        SendRemindersSetup."Action Group Code" := ClientPassCodeTok;
        SendRemindersSetup."Send by Email" := true;
        SendRemindersSetup."Attach Invoice Documents" := SendRemindersSetup."Attach Invoice Documents"::All;
        SendRemindersSetup.Insert(false);

        Customer.Get(FirstInvoice."Bill-to Customer No.");
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." := ClientPassReminderNoTok;
        IssuedReminderHeader."Customer No." := Customer."No.";
        IssuedReminderHeader.Name := Customer.Name;
        IssuedReminderHeader."Reminder Terms Code" := ClientPassCodeTok;
        IssuedReminderHeader."Reminder Level" := 1;
        IssuedReminderHeader."Posting Date" := WorkDate();
        IssuedReminderHeader."Document Date" := WorkDate();
        IssuedReminderHeader."Due Date" := WorkDate();
        IssuedReminderHeader."Language Code" := Customer."Language Code";
        IssuedReminderHeader."Currency Code" := Customer."Currency Code";
        IssuedReminderHeader."Customer Posting Group" := Customer."Customer Posting Group";
        IssuedReminderHeader."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
        IssuedReminderHeader."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        IssuedReminderHeader.Address := Customer.Address;
        IssuedReminderHeader.City := Customer.City;
        IssuedReminderHeader."Post Code" := Customer."Post Code";
        IssuedReminderHeader."Country/Region Code" := Customer."Country/Region Code";
        IssuedReminderHeader.Insert(false);
        AddClientPassReminderLine(10000, FirstInvoice."No.");
        AddClientPassReminderLine(20000, SecondInvoice."No.");

        ProofSupport.LogLine('Demo setup', StrSubstNo(ClientPassReminderMsg, ClientPassReminderNoTok, Customer."No.", Customer."E-Mail", FirstInvoice."No.", SecondInvoice."No."));
    end;

    local procedure AddClientPassReminderLine(LineNo: Integer; InvoiceNo: Code[20])
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.Init();
        IssuedReminderLine."Reminder No." := ClientPassReminderNoTok;
        IssuedReminderLine."Line No." := LineNo;
        IssuedReminderLine.Type := IssuedReminderLine.Type::"Customer Ledger Entry";
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Document Type" := IssuedReminderLine."Document Type"::Invoice;
        IssuedReminderLine."Document No." := InvoiceNo;
        IssuedReminderLine.Description := InvoiceNo;
        IssuedReminderLine.Insert(false);
    end;

    /// <summary>
    /// Takes down everything SetUpClientPassReminderAutomation made, the rows reminder automation wrote
    /// about its runs, and the job queue entry Start scheduled for the group.
    /// </summary>
    procedure RemoveClientPassReminderAutomation()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderAction: Record "Reminder Action";
        SendRemindersSetup: Record "Send Reminders Setup";
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionGroupLog: Record "Reminder Action Group Log";
        ReminderAutomationError: Record "Reminder Automation Error";
        ReportSelections: Record "Report Selections";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if ReminderActionGroup.Get(ClientPassCodeTok) then begin
            JobQueueEntry.SetRange("Record ID to Process", ReminderActionGroup.RecordId());
            JobQueueEntry.DeleteAll(true);
        end;
        IssuedReminderLine.SetRange("Reminder No.", ClientPassReminderNoTok);
        IssuedReminderLine.DeleteAll(false);
        IssuedReminderHeader.SetRange("No.", ClientPassReminderNoTok);
        IssuedReminderHeader.DeleteAll(false);
        ReminderLevel.SetRange("Reminder Terms Code", ClientPassCodeTok);
        ReminderLevel.DeleteAll(false);
        ReminderTerms.SetRange(Code, ClientPassCodeTok);
        ReminderTerms.DeleteAll(false);
        SendRemindersSetup.SetRange("Action Group Code", ClientPassCodeTok);
        SendRemindersSetup.DeleteAll(false);
        ReminderAction.SetRange("Reminder Action Group Code", ClientPassCodeTok);
        ReminderAction.DeleteAll(false);
        ReminderActionGroup.Reset();
        ReminderActionGroup.SetRange(Code, ClientPassCodeTok);
        ReminderActionGroup.DeleteAll(false);
        ReminderActionLog.SetRange("Reminder Action Group ID", ClientPassCodeTok);
        ReminderActionLog.DeleteAll(false);
        ReminderActionGroupLog.SetRange("Reminder Action Group ID", ClientPassCodeTok);
        ReminderActionGroupLog.DeleteAll(false);
        ReminderAutomationError.SetRange("Reminder Action Group Code", ClientPassCodeTok);
        ReminderAutomationError.DeleteAll(false);
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        ReportSelections.SetRange(Sequence, ClientPassCodeTok);
        ReportSelections.DeleteAll(false);
    end;

    /// <summary>
    /// Clears the VAT registration number an aborted run of an early electronic document proof left on a
    /// customer (8 October). Only that exact value is cleared, so nothing a person entered is touched.
    /// </summary>
    procedure RemoveLeftoverProofVatRegistrationNo()
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("VAT Registration No.", LeftoverVatRegistrationNoTok);
        if Customer.FindSet(true) then
            repeat
                Customer."VAT Registration No." := '';
                Customer.Modify(false);
            until Customer.Next() = 0;
    end;

    /// <summary>
    /// Takes down the default email scenario that deleting the client pass's email account on Email
    /// Accounts leaves pointing at nothing. The email that could not be sent is deleted on Email
    /// Outbox in the client: System Application keeps the fields that identify it internal.
    /// </summary>
    procedure RemoveClientPassEmailScenario()
    var
        EmailScenario: Codeunit "Email Scenario";
    begin
        EmailScenario.UnassignScenario(Enum::"Email Scenario"::Default);
    end;

    /// <summary>
    /// Removes the email messages Filename Batch Measure left behind before it cleaned up after
    /// itself - three, "Duplicate attachment names", from 5 October. Email Message's own cleanup:
    /// it deletes every message in this company that is neither in the outbox nor sent, with its
    /// attachments. In the container those three were the only email messages; run it only where
    /// that has been checked, because it does not tell one orphaned message from another.
    /// </summary>
    procedure RemoveOrphanedEmailMessages()
    var
        EmailMessage: Codeunit "Email Message";
        NextMessageId: Guid;
    begin
        repeat
            NextMessageId := EmailMessage.DeleteOrphanedMessages(NextMessageId, 100);
        until IsNullGuid(NextMessageId);
    end;

    local procedure AddPattern(ReportId: Integer; SourceTableNo: Integer; PatternText: Text; FilterToLevel3: Boolean)
    var
        Pattern: Record "Report Filename Pattern";
        ConditionSource: Record "Issued Reminder Header";
    begin
        Pattern.Init();
        if ReportId <> 0 then
            Pattern.Validate("Report ID", ReportId);
        if SourceTableNo <> 0 then
            Pattern.Validate("Table No.", SourceTableNo);
        Pattern.Validate("Date Format", Pattern."Date Format"::YearMonthDay);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));

        if FilterToLevel3 then begin
            ConditionSource.SetRange("Reminder Level", 3);
            Pattern.WriteTableFilter(ConditionSource.GetView(false));
        end;

        // Said explicitly. A pattern is created as a draft now - Enabled starts off, so an
        // administrator cannot leave an incomplete row switched on - which means code that
        // intends a pattern to be live has to say so, or it would be inert and match nothing.
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    /// <summary>
    /// The row that shows two patterns differing only by delivery and language.
    /// </summary>
    local procedure AddPatternForChannel(ReportId: Integer; PatternText: Text; LanguageCode: Code[10]; Channel: Enum "Report Filename Output Route")
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", ReportId);
        ProofSupport.LimitToRoute(Pattern, Channel);
        Pattern.Validate("Date Format", Pattern."Date Format"::YearMonthDay);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        if LanguageCode <> '' then
            Pattern.Validate("Language Code", LanguageCode);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        InvoicePatternTok: Label 'Invoice-[No.]', Locked = true;
        InvoiceGermanPatternTok: Label 'Rechnung-[No.]', Locked = true;
        NoGermanPatternMsg: Label 'The German email pattern is not there to switch off. Seed the demo patterns first.';
        SwitchedOffMsg: Label 'Switched off %1, so the list shows a dimmed row.', Comment = '%1 the pattern text';
        CreditMemoPatternTok: Label 'CreditMemo-[No.]', Locked = true;
        FinancialReportPatternTok: Label '[Description]-[Report Run Date]', Locked = true;
        ExcelPatternTok: Label 'XLSX-Top10-[Report Run Date]', Locked = true;
        // The user's own pattern from their sandbox, 28 September, so the container run is theirs.
        FinancialReportPeriodPatternTok: Label '[Display Title] [Period] - run [Report Run Date] by [Report Run By]', Locked = true;
        KindOfDocumentPatternTok: Label '[Kind of Document]-[No.]', Locked = true;
        ReminderPatternTok: Label 'Reminder-[No.]-[Posting Date]', Locked = true;
        ReminderLevel3PatternTok: Label 'Reminder-L3-[No.]', Locked = true;
        // Authored with the name the picker offers, not the canonical name the binding
        // records - which is the two-name design doing its job: both are accepted.
        MaximalPatternTok: Label '[Your Company Name]-Invoice-[No.]-[Sell-to Customer No.]-[Payment Terms.Description]-[Amount Including VAT]-[Total Incl. VAT]-[Posting Date]-[Report Name]', Locked = true;
        GermanLanguageCodeTok: Label 'DEU', Locked = true;
        SeededMsg: Label '%1 patterns configured.', Comment = '%1 how many';
        AddedMsg: Label 'Added pattern %1, %2.', Comment = '%1 the entry number, %2 the pattern text';
        StalePatternTok: Label '[Report Caption]-[No.]', Locked = true;
        AddedQuoteMsg: Label 'Added assembly quote %1 for item %2.', Comment = '%1 the quote number, %2 the item number';
        // Conference Bundle 1-6, an assembly item in CRONUS.
        AssemblyItemTok: Label '1925-W', Locked = true;
        PostedNoLanguageMsg: Label 'Posted invoice %1 with no language code.', Comment = '%1 the posted invoice number';
        DefaultLanguageMsg: Label 'Company Default Language Code is now "%1".', Comment = '%1 the language code';
        NoLanguageCustomerTok: Label '10000', Locked = true;
        ReminderTermsTok: Label 'DOMESTIC', Locked = true;
        ClientPassCodeTok: Label 'ZZCLIENT', Locked = true;
        ClientPassReminderNoTok: Label 'ZZRM-CLIENT', Locked = true;
        LeftoverVatRegistrationNoTok: Label 'DK12345678', Locked = true;
        ProofReminderNoTok: Label 'PROOF-RMDR-1', Locked = true;
        ClientPassReminderMsg: Label 'Reminder automation ZZCLIENT set up: issued reminder %1 for customer %2 (%3), lines for invoices %4 and %5.', Comment = '%1 reminder no., %2 customer, %3 its email, %4 and %5 the invoices';
        ScheduledRunDescriptionTok: Label 'Filename proof scheduled run', Locked = true;
        MaximalRunDescriptionTok: Label 'Filename proof maximal scheduled run', Locked = true;
        RemovedEntriesMsg: Label 'Removed %1 job queue entries left by the scheduled-route proofs.', Comment = '%1 the number removed';
        ReminderFileNameTok: Label 'Reminder from attachment text', Locked = true;
        ReminderFileNameMsg: Label 'Reminder level 1 of DOMESTIC now has the attachment text File Name "%1" in %2.', Comment = '%1 the file name, %2 the language code';
        // ATHENS Desk, an item CRONUS sells.
        NoLanguageItemTok: Label '1896-S', Locked = true;
        StaleBindingTok: Label '{c:Report Caption}-{f:3}', Locked = true;
}
