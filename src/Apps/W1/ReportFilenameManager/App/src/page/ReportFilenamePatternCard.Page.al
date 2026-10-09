// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50111 "Report Filename Pattern Card"
{
    Caption = 'Report Filename Pattern';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Report Filename Pattern";
    // A title built from what the pattern applies to - "Sales - Invoice · Email" - rather than
    // the default, which is the auto-incremented entry number and read "2" on the second pattern
    // anyone created. It was blank for a while, which left two open cards, or a card paged with
    // Next, with nothing to tell them apart.
    DataCaptionExpression = Rec.DisplayCaption();

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                // Both of these store an object number and show a name. Nothing on this card
                // shows a number: an administrator should never have to know that a sales
                // invoice is table 112, and a pattern that named one by number would be
                // unreadable the moment somebody else opened it.
                field(ReportName; Rec."Report Name")
                {
                    // No Caption: the table captions this field. Repeating it here was redundant
                    // and is how the sibling field came to disagree with the list.
                    ApplicationArea = All;
                    Editable = false;
                    ShowMandatory = false;

                    trigger OnAssistEdit()
                    begin
                        // Saving a new pattern opens a write transaction, and the platform
                        // refuses RunModal while one is open - so the row has to be committed
                        // before the lookup, not merely saved. Every assist-edit on this card
                        // does the same, as Contact Card and the journals do in Base Application.
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupReport();
                        // Update(true), not (false). With (false) the card does not re-read the
                        // record, so after choosing a report every field it fills in - the report
                        // name, the document type, the suggested language field - stayed blank on
                        // screen until the page was reopened, while the row underneath was
                        // correct. The FlowFields also need calculating explicitly.
                        Rec.CalcFields(Rec."Report Name", Rec."Table Caption");
                        CurrPage.Update(true);
                    end;
                }
                field(TableCaption; Rec."Table Caption")
                {
                    // Neither Caption nor ToolTip here: the table carries both, so this page and
                    // the list cannot end up explaining the same field two different ways.
                    ApplicationArea = All;
                    Editable = false;
                    ShowMandatory = false;

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupTable();
                        // Both names are FlowFields. Choosing a report changes the
                        // numbers behind them, and nothing recalculates them on the way
                        // back out, so the card would go on showing the old name - or
                        // nothing at all on a pattern being created.
                        Rec.CalcFields(Rec."Report Name", Rec."Table Caption");
                        CurrPage.Update(true);
                    end;
                }
                // Straight after what the pattern applies to, as on the list, rather than last
                // in the group where it was easy to miss.
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
            // What narrows a pattern down, apart from what it applies to. These were in General,
            // which put seven settings of three different sorts in one group.
            group(Conditions)
            {
                Caption = 'Conditions';

                field(TableFilterText; TableFilterText)
                {
                    // Table Filter, the caption Business Central gives a stored filter on a table
                    // in its own setups. It was "Applies only when", a sentence fragment.
                    Caption = 'Table Filter';
                    ToolTip = 'Specifies a filter the records must match for this pattern to apply, such as a reminder level. Choose the fields and values on the filter page rather than typing a filter.';
                    ApplicationArea = All;
                    Editable = false;
                    ShowMandatory = false;

                    trigger OnAssistEdit()
                    begin
                        // The filter is stored in a Blob and written with Modify, so the row
                        // has to exist first. On a new pattern the user may reach this before
                        // anything has caused an insert.
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupTableFilter();
                        // Update(false): the filter is written to the Blob by the lookup
                        // itself, so there is nothing left to save here. Base Application
                        // keeps (true) for assist-edits that change the record and leave it
                        // unsaved, which this one does not.
                        CurrPage.Update(false);
                    end;
                }
                field(RouteFilterText; RouteFilterText)
                {
                    // Several routes, because a pattern often belongs to more than one: a document
                    // printed, and the same document previewed and downloaded, are two routes.
                    // Chosen with a tick box per route; blank is every route.
                    Caption = 'Output Route Filter';
                    // The table field's tooltip word for word, because this shows that field. Change
                    // them together.
                    ToolTip = 'Specifies which ways out of Business Central this pattern applies to, such as Print|Preview. All routes when it is blank. Choose the field to select routes; each one says what produces a file on it.';
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        // Written with Modify, as the Table Filter is, so the row has to exist.
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupOutputRouteFilter();
                        CurrPage.Update(false);
                    end;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                }
                field(LanguageCodeField; LanguageFieldName)
                {
                    // Shown by name through a variable, because the field stores a field number.
                    // Caption and tooltip are the table field's, word for word, so the two cannot
                    // explain the same setting differently; they drifted once. Additional, because
                    // it is suggested automatically and rarely needs changing.
                    Caption = 'Language Code Field';
                    ToolTip = 'Specifies which field on the table holds the language of the record: a field that relates to the Language table. Where a run covers several records, they must all have the same language, or the run has none. Suggested when the table has one such field.';
                    ApplicationArea = All;
                    Importance = Additional;
                    Editable = false;
                    ShowMandatory = false;

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        Rec.LookupLanguageCodeField();
                        // Update(true), not (false). This was on (false) on the belief that the
                        // lookup persisted the field it sets - it does not: LookupLanguageCodeField
                        // ends with Validate and no Modify, so it changes the record and leaves it
                        // unsaved. That is the mutating case, which Base Application ends with
                        // (true). With (false) the card went on showing the field that choosing a
                        // report had suggested, whatever the administrator picked. Contrast
                        // LookupTableFilter below, which really does persist - it writes the
                        // Blob and calls Modify(true) - and is correctly left on (false).
                        CurrPage.Update(true);
                    end;
                }
            }
            group(FileName)
            {
                Caption = 'File Name';

                field("File Name Pattern"; Rec."File Name Pattern")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field("Date Format"; Rec."Date Format")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateDateExample();
                    end;
                }
                field(DateExample; DateExample)
                {
                    Caption = 'Date Example';
                    ToolTip = 'Specifies how a date is written in the file name with the chosen format. It is the same for every user and every language, so a file name means the same thing to everyone who receives it.';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(SeveralDocuments)
            {
                // Its own group, last, and explained on the page. These two only ever matter
                // when one file has to cover several documents at once, which most patterns
                // never do - and sitting among the everyday fields they read as though they
                // separated one placeholder from the next, which is what somebody reasonably assumed
                // the first time they saw them. Base Application marks a field used less often
                // than its neighbours with Importance = Additional, which folds it behind Show
                // more; that hides a field but cannot say when it applies, and only a group can
                // carry InstructionalText. So the rarity is expressed by putting them apart and
                // the explanation by writing it down.
                //
                // Named for the situation, not the mechanism, and not for documents.
                //
                // It first said "when one token covers several documents", which was wrong
                // twice. "Token" leads with the means rather than the case, and with a word the
                // administrator has only just met. And "document" over-claims: a document in
                // Business Central is a business record with a header, lines and a number - an
                // invoice, a credit memo, a reminder - and plenty of reports render none.
                // Trial Balance, Aged Accounts Receivable and Inventory Valuation have no
                // document behind them, and this feature says so itself when it offers only the
                // computed placeholders for such a report. A pattern may equally name a customer or an
                // item, which are not documents either.
                //
                // Named without naming the thing that is several, because every candidate word
                // for it is taken:
                //
                //   placeholder, value    - the machinery, and to a reader the same thing as each
                //                     other; neither says what the situation is
                //   document, list  - both are kinds of report in Business Central, and this
                //                     pattern may name a customer or an item, which are neither
                //   range, selection- filter words, and this card already has a filter in
                //                     Applies to documents where, so they read as a second one
                //
                // What survives is "record", which is not a kind of report and not a placeholder,
                // and which Business Central puts in front of users constantly - "You cannot
                // delete this record", "multiple records". A first attempt described the
                // situation instead - "Naming More Than One at Once" - which was accurate and
                // read like a chapter heading; card groups in Base Application are captioned
                // with a short noun phrase, as General, Invoicing and Foreign Trade are.
                Caption = 'Multiple Records';
                InstructionalText = 'A file name normally identifies one record. These settings apply only when one file covers several records - for example, when you run the report for a range of invoices or for several customers. They decide how many records are named, what goes between them, and the word that joins the first and the last record when there are too many to name. A report run for a single record never uses them.';

                field("Max. Records Named"; Rec."Max. Records Named")
                {
                    ApplicationArea = All;
                }
                field("Separator"; Rec."Separator")
                {
                    ApplicationArea = All;
                }
                field("Range Word"; Rec."Range Word")
                {
                    ApplicationArea = All;
                }
            }
        }
        area(FactBoxes)
        {
            part(Preview; "Report Filename Preview")
            {
                // The part's caption wins over the page's, so it has to say the same thing:
                // this is an example built from the shape of each value, not a name read off
                // anybody's document.
                Caption = 'Example File Name';
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AvailablePlaceholders)
            {
                Caption = 'Available Placeholders';
                ToolTip = 'Shows the placeholders this report and table can supply, and adds the one you choose to the end of the file name pattern. To put it somewhere else, move it within the file name pattern afterwards.';
                ApplicationArea = All;
                Image = SelectField;

                trigger OnAction()
                var
                    TempChosenPlaceholder: Record "Report Filename Plh. Buffer" temporary;
                    ReportFilenamePlaceholders: Page "Report Filename Placeholders";
                begin
                    // Same reason as the assist-edits above: this opens a modal, and a pattern
                    // being created for the first time still has an open write transaction
                    // behind it until the row is committed.
                    CurrPage.SaveRecord();
                    Commit();

                    ReportFilenamePlaceholders.SetContext(Rec);
                    ReportFilenamePlaceholders.LookupMode(true);
                    if ReportFilenamePlaceholders.RunModal() <> Action::LookupOK then
                        exit;

                    ReportFilenamePlaceholders.GetRecord(TempChosenPlaceholder);
                    AppendPlaceholder(TempChosenPlaceholder.Placeholder);
                end;
            }
            action(TestPattern)
            {
                Caption = 'Test Pattern';
                ToolTip = 'Opens a page where you choose records and see the file name they would get, and whether that name comes from this pattern, from another pattern, or is Business Central''s own file name.';
                ApplicationArea = All;
                Image = TestFile;

                trigger OnAction()
                var
                    TestPatternPage: Page "Report Filename Test";
                begin
                    // Here as well as on the list, because the moment an administrator most wants
                    // to test a pattern is straight after writing it - and going back to the list
                    // to test the row they are already looking at is friction for nothing.
                    //
                    // Saved first so that the pattern being tested is in the table when the page
                    // works out which pattern wins: it decides "this pattern" by comparing entry
                    // numbers against what a query returns, and a row that is not there cannot
                    // win.
                    //
                    // Committed as well, as every assist-edit on this card is: saving opens a write
                    // transaction, and the platform refuses to open a modal page inside one.
                    // Without the commit the action failed in the client with "An error occurred
                    // and the transaction is stopped" - measured on 28 September 2026, from the
                    // server's own stack: RunModal, BeginTransactionWorld. Test pages cannot show
                    // this; they call the page without the client's transaction.
                    CurrPage.SaveRecord();
                    Commit();

                    TestPatternPage.SetPattern(Rec);
                    TestPatternPage.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AvailablePlaceholders_Promoted; AvailablePlaceholders)
                {
                }
                actionref(TestPattern_Promoted; TestPattern)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // The patterns list says the same. A pattern opened straight from search, or from the
        // setup, would otherwise be set up with nothing saying that no pattern names anything.
        ReportFilenameMgt.NotifyIfSwitchedOff();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateDateExample();
        // The two names are FlowFields, so they hold nothing until they are calculated.
        Rec.CalcFields(Rec."Report Name", Rec."Table Caption");
        LanguageFieldName := Rec.LanguageCodeFieldCaption();
        TableFilterText := Rec.GetTableFilterDisplayText();
        if TableFilterText = '' then
            TableFilterText := Rec.NoTableFilterText();
        RouteFilterText := Rec.OutputRouteFilterText();
    end;

    /// <summary>
    /// Adds a chosen placeholder to the end of the file name pattern. It appends rather than inserting at the
    /// cursor because AL exposes no caret position within a text field - there is no such member
    /// on the platform and no Base Application page does it - so the end of the pattern is the
    /// only position that can be named honestly. Validated rather than assigned, so the binding
    /// is rebuilt and a placeholder that somehow could not bind is refused here rather than at save.
    /// </summary>
    /// <param name="Placeholder">The placeholder to add, brackets included.</param>
    local procedure AppendPlaceholder(Placeholder: Text)
    begin
        if Placeholder = '' then
            exit;

        // Refused rather than truncated. A silently shortened pattern would lose the closing
        // bracket and turn into an unterminated placeholder the administrator did not type.
        if StrLen(Rec."File Name Pattern") + StrLen(Placeholder) > MaxStrLen(Rec."File Name Pattern") then
            Error(PatternTooLongErr, Placeholder, MaxStrLen(Rec."File Name Pattern"));

        Rec.Validate("File Name Pattern", CopyStr(Rec."File Name Pattern" + Placeholder, 1, MaxStrLen(Rec."File Name Pattern")));
        CurrPage.Update(true);
    end;

    local procedure UpdateDateExample()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        DateExample := ReportFilenameMgt.FormatSampleDate(Rec."Date Format");
    end;

    var
        DateExample: Text;
        TableFilterText: Text;
        RouteFilterText: Text;
        LanguageFieldName: Text;
        PatternTooLongErr: Label 'Adding %1 would make the file name pattern longer than the %2 characters it can hold. Shorten the file name pattern first.', Comment = '%1 the placeholder that was chosen, %2 the maximum length';
}
