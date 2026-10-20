// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Assembly.Document;
using Microsoft.Finance.FinancialReports;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Inventory.Reports;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Reminder;
using System.Email;
using System.Threading;

codeunit 149510 "Filename Proof Demo Setup"
{
    // Seeds a representative set of patterns and data for manual testing in a client.
    // Rows are created through Validate so each gets its binding built as if typed on the card
    // (except the deliberately stale one in AddTheStalePlaceholderPattern).

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

        AddPattern(Report::"Standard Sales - Invoice", 0, InvoicePatternTok, false);

        AddPatternForChannel(Report::"Standard Sales - Invoice", InvoiceGermanPatternTok, GermanLanguageCodeTok, Enum::"Report Filename Output Route"::Email);

        // By source table, so it covers every report that prints one.
        AddPattern(0, Database::"Sales Cr.Memo Header", CreditMemoPatternTok, false);

        AddPattern(0, Database::"Issued Reminder Header", ReminderPatternTok, false);
        AddPattern(0, Database::"Issued Reminder Header", ReminderLevel3PatternTok, true);

        // One report object renders every financial report, so [Description] says which one it was.
        AddPattern(Report::"Account Schedule", 0, FinancialReportPatternTok, false);

        // Own route, so it does not tie with the first row on selection criteria.
        AddPatternForChannel(Report::"Standard Sales - Invoice", MaximalPatternTok, '', Enum::"Report Filename Output Route"::Download);

        ProofSupport.LogLine('Demo setup', StrSubstNo(SeededMsg, Pattern.Count()));
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Replaces the demo set with a single [Kind of Document] pattern, because a demo pattern already
    /// matches report 1306 with the same criteria. Seed the demo patterns again afterwards.
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
    /// Switches the financial report demo pattern to one using [Period]. Seed the demo patterns again afterwards.
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
    /// Adds a pattern for report 711, whose default layout is Excel, to check Excel output naming.
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
    /// Disables the German email pattern so the list shows a dimmed row, reproducibly.
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
    /// Adds a pattern holding a placeholder name that is no longer valid, with its binding. The text is
    /// assigned, not validated, because validation would refuse it. Seed the demo patterns again afterwards.
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
    /// Adds an assembly quote for the Test Pattern record lookup. The demo data has none, and the
    /// Assembly Quote card has InsertAllowed = false.
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
    /// The language is cleared on the invoice only, not on the customer.
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
    /// Blank in CRONUS. Set it back to blank afterwards.
    /// </summary>
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
    /// Sets the company's Default Language Code back to blank, with no argument to pass.
    /// </summary>
    procedure ClearCompanyDefaultLanguage()
    begin
        SetCompanyDefaultLanguage('');
    end;

    procedure SetProofReminderLanguage(LanguageCode: Text)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        IssuedReminderHeader.Get(ProofReminderNoTok);
        IssuedReminderHeader."Language Code" := CopyStr(LanguageCode, 1, MaxStrLen(IssuedReminderHeader."Language Code"));
        IssuedReminderHeader.Modify(false);
    end;

    /// <summary>
    /// Tied to the reminder report, so it outranks the unfiltered table-only demo pattern.
    /// </summary>
    procedure AddKindOfDocumentReminderPattern()
    var
        Pattern: Record "Report Filename Pattern";
        ReportSelections: Record "Report Selections";
    begin
        RemoveKindOfDocumentReminderPattern();
        ReportSelections.SetCurrentKey(Usage, Sequence);
        ReportSelections.SetRange(Usage, ReportSelections.Usage::Reminder);
        ReportSelections.FindSet();
        while ReportSelections."Report ID" = 0 do
            ReportSelections.Next();
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
    /// Points DOMESTIC level 1 at a new attachment text with a File Name, in customer 10000's language.
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
    /// Fills in the fields the Reminder report needs on the stand-in issued reminder PROOF-RMDR-1.
    /// </summary>
    procedure CompleteTheProofReminder()
    var
        FilenameProofSeedRmdr: Codeunit "Filename Proof Seed Rmdr";
    begin
        FilenameProofSeedRmdr.CompleteExistingStandIn();
    end;

    /// <summary>
    /// Keeps the attachment text GiveReminderLevelAFileName made, with File Name blank.
    /// </summary>
    procedure ClearReminderLevelFileName()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        ReminderAttachmentText.SetRange("File Name", ReminderFileNameTok);
        ReminderAttachmentText.ModifyAll("File Name", '', false);
    end;

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
    /// Finds leftover scheduled-route proof entries by the descriptions only those proofs use.
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
    /// Sets up reminder automation that emails an issued reminder with two invoices attached, under codes
    /// that do not collide with Filename Reminder Tests. The reminder is constructed rather than issued,
    /// because issuing writes Reminder/Fin. Charge Entries, and G/L entries when there is an amount.
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
    /// Also removes the automation's logs and the job queue entry its Start action scheduled.
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
    /// Clears only this exact value, so no other VAT registration number is touched.
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
    /// Unassigns the default scenario left pointing at a deleted email account. Unsent emails must be
    /// deleted from Email Outbox in the client: System Application keeps their identifying fields internal.
    /// </summary>
    procedure RemoveClientPassEmailScenario()
    var
        EmailScenario: Codeunit "Email Scenario";
    begin
        EmailScenario.UnassignScenario(Enum::"Email Scenario"::Default);
    end;

    /// <summary>
    /// Deletes every message in the company that is neither in the outbox nor sent. It cannot tell
    /// one orphaned message from another, so run it only where that is acceptable.
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

        // Patterns are created disabled, so a live one must be enabled explicitly.
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

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
        FinancialReportPeriodPatternTok: Label '[Display Title] [Period] - run [Report Run Date] by [Report Run By]', Locked = true;
        KindOfDocumentPatternTok: Label '[Kind of Document]-[No.]', Locked = true;
        ReminderPatternTok: Label 'Reminder-[No.]-[Posting Date]', Locked = true;
        ReminderLevel3PatternTok: Label 'Reminder-L3-[No.]', Locked = true;
        // Uses the display names the picker offers; canonical names are accepted too.
        MaximalPatternTok: Label '[Your Company Name]-Invoice-[No.]-[Sell-to Customer No.]-[Payment Terms.Description]-[Amount Including VAT]-[Total Incl. VAT]-[Posting Date]-[Report Name]', Locked = true;
        GermanLanguageCodeTok: Label 'DEU', Locked = true;
        SeededMsg: Label '%1 patterns configured.', Comment = '%1 how many';
        AddedMsg: Label 'Added pattern %1, %2.', Comment = '%1 the entry number, %2 the pattern text';
        StalePatternTok: Label '[Report Caption]-[No.]', Locked = true;
        AddedQuoteMsg: Label 'Added assembly quote %1 for item %2.', Comment = '%1 the quote number, %2 the item number';
        // Conference Bundle 1-6, which has an assembly BOM in the demo data.
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
        // ATHENS Desk, an item in the demo data.
        NoLanguageItemTok: Label '1896-S', Locked = true;
        StaleBindingTok: Label '{c:Report Caption}-{f:3}', Locked = true;
}
