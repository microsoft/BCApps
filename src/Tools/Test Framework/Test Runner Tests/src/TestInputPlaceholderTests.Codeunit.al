// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 130482 "Test Input Placeholder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DataTools: Codeunit "Test Input Data Tools";
        Assert: Codeunit "Library Assert";
        TestName: Text;
        TestTag: Text;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetGetsAndOverwritesCaseInsensitiveName()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder('Customer1No', '00123-Abc');
        Assert.IsTrue(DataTools.GetPlaceholder('customer1no', Value), 'The name must be case-insensitive.');
        Assert.AreEqual('00123-Abc', Value, 'Values must retain their case and leading zeros.');

        DataTools.SetPlaceholder('CUSTOMER1NO', 'Updated');
        Assert.IsTrue(DataTools.GetPlaceholder('Customer1No', Value), 'The overwritten entry must exist.');
        Assert.AreEqual('Updated', Value, 'Setting an existing key must overwrite it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingValueClearsOutput()
    var
        Value: Text;
    begin
        Initialize();
        Value := 'stale';
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'An absent name must not be found.');
        Assert.AreEqual('', Value, 'A miss must clear the output argument.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExplicitTagDoesNotChangeActiveTag()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'active');
        DataTools.SetPlaceholder(TestName, 'other', TestTag + '-other');
        DataTools.SetPlaceholder(TestName, 'blank', '');

        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The active tag must still be selected.');
        Assert.AreEqual('active', Value, 'Explicit overloads must not change the active tag.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, ''), 'Explicit blank tag must be supported.');
        Assert.AreEqual('blank', Value, 'Explicit blank tag is not the active tag.');
        Assert.AreEqual('active', DataTools.ResolveText(Token(TestName)), 'Reads must continue using the active tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankTagIsNotWildcard()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'tagged', TestTag, '');
        DataTools.SetTag('');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Blank tag must not search other tags.');
        Assert.AreEqual(Token(TestName), DataTools.ResolveText(Token(TestName)), 'A different tag must remain unresolved.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TagsAreCaseInsensitive()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'value', LowerCase(TestTag));
        DataTools.SetTag(UpperCase(TestTag));
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Tags must use Code normalization.');
        Assert.AreEqual('value', Value, 'The same normalized tag must be selected.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompanyValueWinsOverSharedValue()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'shared', TestTag, '');
        DataTools.SetPlaceholder(TestName, 'local');
        Assert.AreEqual('local', DataTools.ResolveText(Token(TestName)), 'Current-company values take precedence.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag, 'Another company'), 'Other companies use shared fallback.');
        Assert.AreEqual('shared', Value, 'Fallback must select the shared row.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag, ''), 'Explicit shared lookup must succeed.');
        Assert.AreEqual('shared', Value, 'Explicit shared lookup must bypass the local row.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompanyFallbackDoesNotCrossTags()
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'selected-shared', TestTag, '');
        DataTools.SetPlaceholder(TestName, 'other-local', TestTag + '-other');
        Assert.AreEqual('selected-shared', DataTools.ResolveText(Token(TestName)), 'Company precedence applies only within the selected tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LocalEmptyValueSuppressesFallback()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'shared', TestTag, '');
        DataTools.SetPlaceholder(TestName, '');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'An empty registered value is a match.');
        Assert.AreEqual('', Value, 'An empty local row must not fall back.');
        Assert.AreEqual('beforeafter', DataTools.ResolveText('before' + Token(TestName) + 'after'), 'Empty values remove their token.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlobPreservesLongMultilineUnicodeText()
    var
        Builder: TextBuilder;
        Expected: Text;
        Value: Text;
        UnicodeCharacter: Char;
    begin
        Initialize();
        UnicodeCharacter := 9731;
        Builder.AppendLine('  00123 "quoted" \backslash ');
        Builder.AppendLine('');
        Builder.Append(Format(UnicodeCharacter));
        Builder.Append(PadStr('x', 32768, 'y'));
        Builder.AppendLine();
        Builder.Append('  trailing spaces  ');
        Expected := Builder.ToText();

        DataTools.SetPlaceholder(TestName, Expected);
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The BLOB value must exist.');
        Assert.AreEqual(Expected, Value, 'BLOB storage must preserve the complete text.');
        Assert.AreEqual(Expected, DataTools.ResolveText(Token(TestName)), 'Resolution must not format or trim the value.');

        DataTools.SetPlaceholder(TestName, 'short');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The overwritten BLOB must exist.');
        Assert.AreEqual('short', Value, 'An overwrite must not retain the old BLOB suffix.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaximumKeyLengthsAreAccepted()
    var
        Name: Text;
        Tag: Text;
        Company: Text;
        Value: Text;
    begin
        Initialize();
        Name := PadStr(TestName, 100, 'N');
        Tag := PadStr(TestTag, 100, 'T');
        Company := PadStr('Company', 30, 'C');
        DataTools.SetPlaceholder(Name, 'value', Tag, Company);
        Assert.IsTrue(DataTools.GetPlaceholder(Name, Value, Tag, Company), 'Maximum-length keys must be accepted.');
        Assert.AreEqual('value', Value, 'Maximum-length keys must round-trip without truncation.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvalidNamesAreRejected()
    var
        Names: List of [Text];
        Name: Text;
    begin
        Initialize();
        Names.Add('');
        Names.Add('bad name');
        Names.Add('bad$name');
        Names.Add('bad.name');
        Names.Add(' name ');
        Names.Add(PadStr('N', 101, 'N'));
        foreach Name in Names do begin
            asserterror DataTools.SetPlaceholder(Name, 'value');
            Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverlongTagAndCompanyAreRejected()
    var
        Value: Text;
    begin
        Initialize();
        asserterror DataTools.SetTag(PadStr('T', 101, 'T'));
        Assert.ExpectedError('must not exceed 100 characters');
        asserterror DataTools.SetPlaceholder(TestName, 'value', PadStr('T', 101, 'T'));
        Assert.ExpectedError('must not exceed 100 characters');
        asserterror DataTools.SetPlaceholder(TestName, 'value', TestTag, PadStr('C', 31, 'C'));
        Assert.ExpectedError('must not exceed 30 characters');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Validation must not insert a partial row.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegistrationRejectsEverySupportedTokenType()
    var
        Values: List of [Text];
        Value: Text;
    begin
        Initialize();
        Values.Add('$Placeholder-Unknown$');
        Values.Add('before $DateFormula-<CD>$ after');
        Values.Add('$DateTimeFormula-<CD>-12:30:11$');
        foreach Value in Values do begin
            asserterror DataTools.SetPlaceholder(TestName, Value);
            Assert.ExpectedError('must not contain placeholder tokens');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RejectedOverwritePreservesPreviousValue()
    var
        Value: Text;
        Found: Boolean;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'original');
        Commit();

        asserterror DataTools.SetPlaceholder(TestName, '$Placeholder-Unknown$');
        Assert.ExpectedError('must not contain placeholder tokens');
        Found := DataTools.GetPlaceholder(TestName, Value, TestTag);
        DataTools.DeletePlaceholder(TestName, TestTag);
        Commit();

        Assert.IsTrue(Found, 'Rejected overwrites must retain the original row.');
        Assert.AreEqual('original', Value, 'Rejected values must not overwrite the BLOB.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LiteralDollarsAreAllowed()
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'Pay $5; ordinary $ signs and $Unknown-tool$ are literal.');
        Assert.AreEqual(
            'Pay $5; ordinary $ signs and $Unknown-tool$ are literal.',
            DataTools.ResolveText(Token(TestName)),
            'Only supported placeholder tokens are forbidden in a value.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolvesWholeEmbeddedRepeatedAndAdjacentTokens()
    begin
        Initialize();
        DataTools.SetPlaceholder('Customer1No', 'C1001');
        DataTools.SetPlaceholder('BlockedItem1', 'I2001');
        Assert.AreEqual('C1001', DataTools.ResolveText('$Placeholder-customer1no$'), 'Whole-value names are case-insensitive.');
        Assert.AreEqual(
            'Use C1001/I2001C1001.',
            DataTools.ResolveText('Use $Placeholder-Customer1No$/$Placeholder-BlockedItem1$$Placeholder-Customer1No$.'),
            'All original occurrences must be resolved.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownTokensDoNotBlockLaterTokens()
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'known');
        Assert.AreEqual(
            '$Placeholder-Missing$ known $Placeholder-Missing$',
            DataTools.ResolveText('$Placeholder-Missing$ ' + Token(TestName) + ' $Placeholder-Missing$'),
            'Unknown names must remain literal without blocking later matches.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MalformedTokensDoNotBlockLaterTokens()
    var
        Prefix: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'known');
        Prefix := '$Placeholder-$ $Placeholder-bad name$ $Placeholder-unclosed ';
        Assert.AreEqual(Prefix + 'known', DataTools.ResolveText(Prefix + Token(TestName)), 'Malformed tokens must not consume a later valid token.');
        Assert.AreEqual('$Placeholder-unclosed', DataTools.ResolveText('$Placeholder-unclosed'), 'An incomplete token remains literal.');
        Assert.AreEqual('$', DataTools.ResolveText('$'), 'A trailing delimiter must not cause an out-of-range search.');
        Assert.AreEqual('', DataTools.ResolveText(''), 'Empty text remains empty.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverlongInputNameRemainsLiteral()
    var
        InputText: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'known');
        InputText := Token(PadStr('N', 101, 'N'));
        Assert.AreEqual(InputText + 'known', DataTools.ResolveText(InputText + Token(TestName)), 'An overlong input name is not a truncated key.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReplacementOutputIsNotScannedAgain()
    begin
        Initialize();
        DataTools.SetPlaceholder('Left', '$Place');
        DataTools.SetPlaceholder('Right', 'holder-Other$');
        DataTools.SetPlaceholder('Other', 'must-not-expand');
        Assert.AreEqual(
            '$Placeholder-Other$', DataTools.ResolveText('$Placeholder-Left$$Placeholder-Right$'),
            'Adjacent replacement values must not trigger a second resolution pass.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrefixSpellingRemainsCaseSensitive()
    begin
        Initialize();
        DataTools.SetPlaceholder('Customer', 'value');
        Assert.AreEqual('$placeholder-Customer$', DataTools.ResolveText('$placeholder-Customer$'), 'Only the name, not the fixed prefix, is case-insensitive.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingWrapperObservesLateRegistrationAndOverwrite()
    var
        Input: Codeunit "Test Input Json";
        Element: Codeunit "Test Input Json";
        InputObject: JsonObject;
        FirstRead: Text;
    begin
        Initialize();
        InputObject.Add('message', Token(TestName));
        Input.Initialize(InputObject.AsToken());
        Element := Input.Element('message');
        Assert.AreEqual(Token(TestName), Element.ValueAsText(), 'A missing value starts unresolved.');

        DataTools.SetPlaceholder(TestName, 'first');
        FirstRead := Element.ValueAsText();
        DataTools.SetPlaceholder(TestName, 'second');
        Assert.AreEqual('first', FirstRead, 'An already returned Text is a snapshot.');
        Assert.AreEqual('second', Element.ValueAsText(), 'A wrapper must read the current registration.');
        Assert.AreEqual(Token(TestName), Element.ElementValue().AsText(), 'Resolution must not mutate the template.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RawExportsKeepTemplates()
    var
        Input: Codeunit "Test Input Json";
        InputObject: JsonObject;
        ExportedObject: JsonObject;
        ExportedToken: JsonToken;
        Serialized: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'resolved');
        InputObject.Add(Token(TestName), Token(TestName));
        Input.Initialize(InputObject.AsToken());
        Assert.AreEqual('resolved', Input.Element(Token(TestName)).ValueAsText(), 'Property names remain literal while text values resolve.');
        Assert.AreEqual(Token(TestName), Input.Element(Token(TestName)).ToText(), 'ToText remains raw.');

        ExportedObject := Input.ValueAsJsonObject();
        ExportedObject.Get(Token(TestName), ExportedToken);
        Assert.AreEqual(Token(TestName), ExportedToken.AsValue().AsText(), 'JSON object exports remain raw.');
        ExportedToken := Input.AsJsonToken();
        ExportedToken.AsObject().Get(Token(TestName), ExportedToken);
        Assert.AreEqual(Token(TestName), ExportedToken.AsValue().AsText(), 'JSON token exports remain raw.');
        InputObject.WriteTo(Serialized);
        Assert.AreEqual(Serialized, Input.ToText(), 'Object serialization must not rewrite the input.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NativeNumericAndBooleanReadersAreUnchanged()
    var
        Input: Codeunit "Test Input Json";
    begin
        Initialize();
        Input.Initialize('{"integer":42,"decimal":12.5,"boolean":true}');
        Assert.AreEqual(42, Input.Element('integer').ValueAsInteger(), 'Native integers must be unchanged.');
        Assert.AreEqual(12.5, Input.Element('decimal').ValueAsDecimal(), 'Native decimals must be unchanged.');
        Assert.IsTrue(Input.Element('boolean').ValueAsBoolean(), 'Native booleans must be unchanged.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SuccessiveTurnReadsKeepActiveTag()
    var
        Input: Codeunit "Test Input Json";
        Turns: Codeunit "Test Input Json";
    begin
        Initialize();
        Input.Initialize('{"turns":[{"message":"$Placeholder-Customer$"},{"message":"$Placeholder-Customer$"}]}');
        DataTools.SetPlaceholder('Customer', 'first');
        Turns := Input.Element('turns');
        Assert.AreEqual('first', Turns.ElementAt(0).Element('message').ValueAsText(), 'First-turn reads use the active tag.');
        DataTools.SetPlaceholder('Customer', 'second');
        Assert.AreEqual('second', Turns.ElementAt(1).Element('message').ValueAsText(), 'Moving through input must not clear the tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolvesMixedDateDateTimeAndNamedTokens()
    var
        Expected: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'customer');
        Expected := Format(WorkDate()) + ' / ' + Format(CreateDateTime(WorkDate(), 123011T)) + ' / customer';
        Assert.AreEqual(
            Expected,
            DataTools.ResolveText('$DateFormula-<CD>$ / $DateTimeFormula-<CD>-12:30:11$ / ' + Token(TestName)),
            'All supported token types must use the same text resolver.');
        Assert.AreEqual(Format(CalcDate('<1D>', WorkDate())), DataTools.ResolveText('$DateFormula-<1D>$'), 'Relative date formulas must be preserved.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DateTimeSupportsDefaultAndFractionalTime()
    var
        ExpectedTime: Time;
    begin
        Initialize();
        Assert.AreEqual(
            Format(CreateDateTime(WorkDate(), 0T)), DataTools.ResolveText('$DateTimeFormula-<CD>$'),
            'DateTime formulas without a time default to midnight.');
        ExpectedTime := 123011.130T;
        Assert.AreEqual(
            CreateDateTime(WorkDate(), ExpectedTime), DataTools.ResolveAsDateTime('$DateTimeFormula-<CD>-12:30:11.130$'),
            'Typed conversion must preserve milliseconds.');
        Assert.AreEqual(
            Format(CreateDateTime(WorkDate(), ExpectedTime)), DataTools.ResolveText('$DateTimeFormula-<CD>-12:30:11.130$'),
            'Fractional times must retain the existing conversion behavior.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvalidDateFormulaStillRaisesError()
    begin
        Initialize();
        asserterror DataTools.ResolveText('$DateFormula-<not-a-formula>$');
        Assert.IsTrue(GetLastErrorText() <> '', 'Invalid date formulas must not silently remain literal.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisableAffectsAllTextButNotExplicitValueOperations()
    var
        Value: Text;
        InputText: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'value');
        InputText := Token(TestName) + ' $DateFormula-<CD>$ $DateTimeFormula-<CD>$';
        DataTools.SetTextReplacementsEnabled(false);
        Assert.AreEqual(InputText, DataTools.ResolveText(InputText), 'Disabled text resolution must bypass every token type.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag), 'Explicit get remains available while disabled.');
        Assert.AreEqual('value', Value, 'Disabling must not delete registrations.');
        DataTools.SetPlaceholder(TestName, 'updated', TestTag);
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag), 'Explicit set remains available while disabled.');
        Assert.AreEqual('updated', Value, 'Disabled state must not suppress writes.');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName, TestTag), 'Explicit deletion remains available while disabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepeatedEnableAndDisableBothClearTag()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'tagged');
        DataTools.SetPlaceholder(TestName, 'blank', '');
        DataTools.SetTextReplacementsEnabled(true);
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Enable must reset the active tag even when already enabled.');
        Assert.AreEqual('blank', Value, 'Enable must select the blank-tag namespace.');

        DataTools.SetTextReplacementsEnabled(false);
        DataTools.SetTag(TestTag);
        DataTools.SetTextReplacementsEnabled(false);
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Repeated disable must reset the active tag.');
        Assert.AreEqual('blank', Value, 'Disable must clear the tag without deleting values.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag), 'The tagged row must survive both switch operations.');
        Assert.AreEqual('tagged', Value, 'Switch operations must not clean up table rows.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TypedDatesWorkWithTextReplacementDisabled()
    var
        Input: Codeunit "Test Input Json";
    begin
        Initialize();
        DataTools.SetTextReplacementsEnabled(false);
        Input.Initialize('{"date":"$DateFormula-<CD>$","datetime":"$DateTimeFormula-<CD>-12:30:11$"}');
        Assert.AreEqual('$DateFormula-<CD>$', Input.Element('date').ValueAsText(), 'Disabled text readers return the template.');
        Assert.AreEqual(WorkDate(), Input.Element('date').ValueAsDate(), 'Typed dates remain supported.');
        Assert.AreEqual(CreateDateTime(WorkDate(), 123011T), Input.Element('datetime').ValueAsDateTime(), 'Typed datetimes remain supported.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteLocalDoesNotDeleteSharedOrOtherTag()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholder(TestName, 'shared', TestTag, '');
        DataTools.SetPlaceholder(TestName, 'other', TestTag + '-other');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'The local row must be deleted.');
        Assert.IsFalse(DataTools.DeletePlaceholder(TestName), 'Single deletion must not follow shared fallback.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The shared row must remain.');
        Assert.AreEqual('shared', Value, 'Deleting a local row exposes, but does not delete, its fallback.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag + '-other'), 'Other tags must be unaffected.');
        Assert.AreEqual('other', Value, 'Other-tag data must remain unchanged.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExplicitSharedDeletionIsNotWildcard()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholder(TestName, 'shared', TestTag, '');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName, TestTag, ''), 'Explicit blank company must delete the shared row.');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value, TestTag, ''), 'The shared row must be absent.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The local row must survive shared deletion.');
        Assert.AreEqual('local', Value, 'Explicit shared deletion must not broaden company scope.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TagCleanupIsCompanyScoped()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholder(TestName, 'shared', TestTag, '');
        DataTools.SetPlaceholder(TestName, 'other-company', TestTag, 'Another company');
        DataTools.SetPlaceholder(TestName, 'other-tag', TestTag + '-other');
        DataTools.DeletePlaceholdersByTag(TestTag);
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Shared fallback must survive current-company cleanup.');
        Assert.AreEqual('shared', Value, 'Only current-company rows are removed.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag, 'Another company'), 'Other companies must survive.');
        Assert.AreEqual('other-company', Value, 'Another company must retain its exact value.');

        DataTools.DeletePlaceholdersByTag(TestTag, '');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Explicit shared cleanup removes only the shared row.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag + '-other'), 'Other tags must survive both cleanups.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TagCleanupTreatsFilterCharactersLiterally()
    var
        LiteralTag: Text;
        Value: Text;
    begin
        Initialize();
        LiteralTag := TestTag + '*|?';
        DataTools.SetPlaceholder(TestName, 'literal', LiteralTag);
        DataTools.SetPlaceholder(TestName, 'other', TestTag + 'suffix');
        DataTools.DeletePlaceholdersByTag(LiteralTag);
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value, LiteralTag), 'The exact literal tag must be deleted.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag + 'suffix'), 'Tag cleanup must not interpret filters.');
        Assert.AreEqual('other', Value, 'Wildcard-like tag characters must not broaden deletion.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcrossCompanyTagCleanupKeepsOtherTags()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholder(TestName, 'shared', TestTag, '');
        DataTools.SetPlaceholder(TestName, 'other-company', TestTag, 'Another company');
        DataTools.SetPlaceholder(TestName, 'other-tag', TestTag + '-other', '');
        DataTools.DeletePlaceholdersByTagAcrossCompanies(TestTag);
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Current-company and shared entries must be removed.');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value, TestTag, 'Another company'), 'All companies for the exact tag must be removed.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag + '-other', ''), 'Other tags must remain.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteAllClearsAllScopesWithoutCommit()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholder(TestName, 'shared', '', '');
        DataTools.SetPlaceholder(TestName, 'other', TestTag + '-other', 'Another company');
        DataTools.DeleteAllPlaceholders();
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Delete-all must remove local entries.');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value, '', ''), 'Delete-all must remove shared blank-tag entries.');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value, TestTag + '-other', 'Another company'), 'Delete-all must remove other scopes.');
        DataTools.DeleteAllPlaceholders();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RolledBackWritesAreNotCached()
    var
        ExistingValue: Text;
        InsertedValue: Text;
        DeletedValue: Text;
        ExistingFound: Boolean;
        InsertedFound: Boolean;
        DeletedFound: Boolean;
    begin
        Initialize();
        DataTools.SetPlaceholder('RollbackExisting', 'original');
        DataTools.SetPlaceholder('RollbackDeleted', 'retained');
        Commit();

        Assert.IsFalse(Codeunit.Run(Codeunit::"Test Input Rollback Probe"), 'The probe must roll back its transaction.');
        Assert.ExpectedError('Rolling back placeholder probe writes.');
        ExistingFound := DataTools.GetPlaceholder('RollbackExisting', ExistingValue, TestTag);
        InsertedFound := DataTools.GetPlaceholder('RollbackInserted', InsertedValue, TestTag);
        DeletedFound := DataTools.GetPlaceholder('RollbackDeleted', DeletedValue, TestTag);
        DataTools.DeletePlaceholdersByTag(TestTag);
        Commit();

        Assert.IsTrue(ExistingFound, 'Rollback must retain the original row.');
        Assert.AreEqual('original', ExistingValue, 'A lookup must not return a rolled-back overwrite.');
        Assert.IsFalse(InsertedFound, 'A lookup must not return a rolled-back insertion.');
        Assert.AreEqual('', InsertedValue, 'A rolled-back insertion must not leave a cached value.');
        Assert.IsTrue(DeletedFound, 'A lookup must not retain a miss from a rolled-back deletion.');
        Assert.AreEqual('retained', DeletedValue, 'Rollback must restore the deleted value.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllowedNameCharactersResolve()
    begin
        Initialize();
        DataTools.SetPlaceholder('1_Customer-No', 'C-001');
        Assert.AreEqual(
            'C-001', DataTools.ResolveText('$Placeholder-1_customer-no$'),
            'Names must support digits, underscores, hyphens, and case-insensitive lookup.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaximumLengthNameResolves()
    var
        Name: Text;
    begin
        Initialize();
        Name := PadStr(TestName, 100, 'N');
        DataTools.SetPlaceholder(Name, 'maximum-length');
        Assert.AreEqual(
            'maximum-length', DataTools.ResolveText(Token(LowerCase(Name))),
            'The token parser must accept the full 100-character name without truncation.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingWrapperUsesCurrentTag()
    var
        Input: Codeunit "Test Input Json";
        Element: Codeunit "Test Input Json";
        InputObject: JsonObject;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'first');
        DataTools.SetPlaceholder(TestName, 'second', TestTag + '-other');
        InputObject.Add('value', Token(TestName));
        Input.Initialize(InputObject.AsToken());
        Element := Input.Element('value');

        Assert.AreEqual('first', Element.ValueAsText(), 'The initial tag must be selected.');
        DataTools.SetTag(TestTag + '-other');
        Assert.AreEqual('second', Element.ValueAsText(), 'An existing wrapper must use the currently selected tag.');
        DataTools.SetTag(TestTag);
        Assert.AreEqual('first', Element.ValueAsText(), 'Changing back must not reuse another tag''s value.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingWrapperObservesDeletionAndFallback()
    var
        Input: Codeunit "Test Input Json";
        Element: Codeunit "Test Input Json";
        InputObject: JsonObject;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'shared', TestTag, '');
        DataTools.SetPlaceholder(TestName, 'local');
        InputObject.Add('value', Token(TestName));
        Input.Initialize(InputObject.AsToken());
        Element := Input.Element('value');

        Assert.AreEqual('local', Element.ValueAsText(), 'The exact company value must win initially.');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'The local row must be deleted.');
        Assert.AreEqual('shared', Element.ValueAsText(), 'The wrapper must immediately observe shared fallback.');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName, TestTag, ''), 'The shared row must be deleted.');
        Assert.AreEqual(Token(TestName), Element.ValueAsText(), 'Deleting both rows must restore the literal token.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReplacementOutputDoesNotExpandDateTokens()
    begin
        Initialize();
        DataTools.SetPlaceholder('Left', '$Date');
        DataTools.SetPlaceholder('DateRight', 'Formula-<CD>$');
        DataTools.SetPlaceholder('DateTimeRight', 'TimeFormula-<CD>-12:30:11$');
        Assert.AreEqual(
            '$DateFormula-<CD>$ / $DateTimeFormula-<CD>-12:30:11$',
            DataTools.ResolveText('$Placeholder-Left$$Placeholder-DateRight$ / $Placeholder-Left$$Placeholder-DateTimeRight$'),
            'Named replacement output must not be rescanned as date or DateTime tokens.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingWrapperFollowsTextReplacementSwitch()
    var
        Input: Codeunit "Test Input Json";
        Element: Codeunit "Test Input Json";
        InputObject: JsonObject;
        Template: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'customer');
        Template := Token(TestName) + ' / $DateFormula-<CD>$';
        InputObject.Add('value', Template);
        Input.Initialize(InputObject.AsToken());
        Element := Input.Element('value');

        DataTools.SetTextReplacementsEnabled(false);
        Assert.AreEqual(Template, Element.ValueAsText(), 'An existing wrapper must bypass all text replacements when disabled.');
        DataTools.SetTextReplacementsEnabled(true);
        Assert.AreEqual(
            Token(TestName) + ' / ' + Format(WorkDate()), Element.ValueAsText(),
            'Re-enabling must resolve dates but clear the active tag.');
        DataTools.SetTag(TestTag);
        Assert.AreEqual('customer / ' + Format(WorkDate()), Element.ValueAsText(), 'Selecting the tag must resolve the named value again.');
        DataTools.SetTextReplacementsEnabled(false);
        Assert.AreEqual(Template, Element.ValueAsText(), 'Disabling again must return the original template.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExplicitTagDeletionKeepsActiveTag()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'active');
        DataTools.SetPlaceholder(TestName, 'other', TestTag + '-other');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName, TestTag + '-other'), 'Explicit deletion must target the specified tag.');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value, TestTag + '-other'), 'The explicitly selected row must be absent.');
        Assert.AreEqual('active', DataTools.ResolveText(Token(TestName)), 'Explicit deletion must not change the active tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadAndDeleteRejectInvalidKeys()
    var
        Value: Text;
    begin
        Initialize();
        asserterror DataTools.GetPlaceholder('bad name', Value);
        Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        asserterror DataTools.DeletePlaceholder('');
        Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        asserterror DataTools.GetPlaceholder(TestName, Value, PadStr('T', 101, 'T'));
        Assert.ExpectedError('must not exceed 100 characters');
        asserterror DataTools.DeletePlaceholder(TestName, TestTag, PadStr('C', 31, 'C'));
        Assert.ExpectedError('must not exceed 30 characters');
        asserterror DataTools.DeletePlaceholdersByTag(PadStr('T', 101, 'T'));
        Assert.ExpectedError('must not exceed 100 characters');
        asserterror DataTools.DeletePlaceholdersByTag(TestTag, PadStr('C', 31, 'C'));
        Assert.ExpectedError('must not exceed 30 characters');
        asserterror DataTools.DeletePlaceholdersByTagAcrossCompanies(PadStr('T', 101, 'T'));
        Assert.ExpectedError('must not exceed 100 characters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PlaceholderApiWorksWithExactRunnerPermissions()
    var
        PermissionsMock: Codeunit "Permissions Mock";
        Value: Text;
    begin
        PermissionsMock.Stop();
        Initialize();
        PermissionsMock.Start();
        PermissionsMock.SetExactPermissionSet('Test Runner Tests');

        DataTools.SetPlaceholder(TestName, 'value');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Indirect runner permissions must allow reads through the API.');
        Assert.AreEqual('value', DataTools.ResolveText(Token(TestName)), 'The shared resolver needs execute permission.');
        DataTools.SetPlaceholder(TestName, 'updated');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Indirect permissions must allow updates.');
        Assert.AreEqual('updated', Value, 'The updated value must be visible.');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'Indirect permissions must allow deletion through the API.');
    end;

    local procedure Initialize()
    begin
        TestTag := DelChr(Format(CreateGuid()), '=', '{}-');
        TestName := 'P' + TestTag;
        DataTools.SetTextReplacementsEnabled(true);
        DataTools.SetTag(TestTag);
    end;

    local procedure Token(Name: Text): Text
    begin
        exit('$Placeholder-' + Name + '$');
    end;
}
