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

    [Test]
    procedure SetGetsAndOverwritesCaseInsensitiveName()
    var
        Name: Text;
        Value: Text;
    begin
        Initialize();
        Name := TestName + '-Customer1No';
        DataTools.SetPlaceholder(Name, '00123-Abc');
        Assert.IsTrue(DataTools.GetPlaceholder(LowerCase(Name), Value), 'The name must be case-insensitive.');
        Assert.AreEqual('00123-Abc', Value, 'Values must retain their case and leading zeros.');

        DataTools.SetPlaceholder(UpperCase(Name), 'Updated');
        Assert.IsTrue(DataTools.GetPlaceholder(Name, Value), 'The overwritten entry must exist.');
        Assert.AreEqual('Updated', Value, 'Setting an existing key must overwrite it.');
    end;

    [Test]
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
    procedure ExplicitCompanyDoesNotChangeDefaultLookup()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'other', 'Another company');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');

        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Default lookup must still use the current company.');
        Assert.AreEqual('local', Value, 'Explicit operations must not change the default company.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, 'Another company'), 'Explicit company lookup must succeed.');
        Assert.AreEqual('other', Value, 'Explicit company lookup must select its exact row.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'Explicit shared lookup must succeed.');
        Assert.AreEqual('shared', Value, 'Explicit blank company must select the shared row.');
        Assert.AreEqual('local', DataTools.ResolveText(Token(TestName)), 'Text reads must continue using the current company.');
    end;

    [Test]
    procedure UnqualifiedNameDoesNotMatchAffixedNames()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholderForCompany('PREFIX-' + TestName, 'prefixed', '');
        DataTools.SetPlaceholder(TestName + '-SUFFIX', 'suffixed');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Lookup must not add or remove name affixes.');
        Assert.AreEqual(Token(TestName), DataTools.ResolveText(Token(TestName)), 'The unregistered base name must remain unresolved.');
        Assert.AreEqual(
            'prefixed / suffixed', DataTools.ResolveText(Token('PREFIX-' + TestName) + ' / ' + Token(TestName + '-SUFFIX')),
            'Full prefixed and suffixed names must resolve independently.');
    end;

    [Test]
    procedure AffixedNamesAreCaseInsensitive()
    var
        PrefixedName: Text;
        SuffixedName: Text;
        Value: Text;
    begin
        Initialize();
        PrefixedName := 'Scope-' + TestName;
        SuffixedName := TestName + '-Scope';
        DataTools.SetPlaceholder(LowerCase(PrefixedName), 'prefixed');
        DataTools.SetPlaceholder(LowerCase(SuffixedName), 'suffixed');
        Assert.IsTrue(DataTools.GetPlaceholder(UpperCase(PrefixedName), Value), 'A prefix is part of the case-insensitive name.');
        Assert.AreEqual('prefixed', Value, 'The prefixed name must identify its own value.');
        Assert.IsTrue(DataTools.GetPlaceholder(UpperCase(SuffixedName), Value), 'A suffix is part of the case-insensitive name.');
        Assert.AreEqual('suffixed', Value, 'The suffixed name must identify its own value.');
    end;

    [Test]
    procedure CompanyValueWinsOverSharedValue()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholder(TestName, 'local');
        Assert.AreEqual('local', DataTools.ResolveText(Token(TestName)), 'Current-company values take precedence.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, 'Another company'), 'Other companies use shared fallback.');
        Assert.AreEqual('shared', Value, 'Fallback must select the shared row.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'Explicit shared lookup must succeed.');
        Assert.AreEqual('shared', Value, 'Explicit shared lookup must bypass the local row.');
    end;

    [Test]
    procedure CompanyFallbackDoesNotCrossNames()
    begin
        Initialize();
        DataTools.SetPlaceholderForCompany(TestName, 'selected-shared', '');
        DataTools.SetPlaceholder(TestName + '-other', 'other-local');
        Assert.AreEqual('selected-shared', DataTools.ResolveText(Token(TestName)), 'Company fallback must use the exact full name.');
    end;

    [Test]
    procedure LocalEmptyValueSuppressesFallback()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholder(TestName, '');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'An empty registered value is a match.');
        Assert.AreEqual('', Value, 'An empty local row must not fall back.');
        Assert.AreEqual('beforeafter', DataTools.ResolveText('before' + Token(TestName) + 'after'), 'Empty values remove their token.');
    end;

    [Test]
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
    procedure MaximumKeyLengthsAreAccepted()
    var
        Name: Text;
        Company: Text;
        Value: Text;
    begin
        Initialize();
        Name := PadStr(TestName, 100, 'N');
        Company := PadStr('Company', 30, 'C');
        DataTools.SetPlaceholderForCompany(Name, 'value', Company);
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(Name, Value, Company), 'Maximum-length keys must be accepted.');
        Assert.AreEqual('value', Value, 'Maximum-length keys must round-trip without truncation.');
    end;

    [Test]
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
        Names.Add('bad*name');
        Names.Add('bad|name');
        Names.Add('bad?name');
        Names.Add(' name ');
        Names.Add(PadStr('N', 101, 'N'));
        foreach Name in Names do begin
            asserterror DataTools.SetPlaceholder(Name, 'value');
            Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        end;
    end;

    [Test]
    procedure OverlongFullNameAndCompanyAreRejected()
    var
        Value: Text;
    begin
        Initialize();
        asserterror DataTools.SetPlaceholder('P-' + PadStr(TestName, 99, 'N'), 'value');
        Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        asserterror DataTools.SetPlaceholder(PadStr(TestName, 99, 'N') + '-S', 'value');
        Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        asserterror DataTools.SetPlaceholderForCompany(TestName, 'value', PadStr('C', 31, 'C'));
        Assert.ExpectedError('must not exceed 30 characters');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Validation must not insert a partial row.');
    end;

    [Test]
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
        Found := DataTools.GetPlaceholder(TestName, Value);
        DataTools.DeletePlaceholder(TestName);
        Commit();

        Assert.IsTrue(Found, 'Rejected overwrites must retain the original row.');
        Assert.AreEqual('original', Value, 'Rejected values must not overwrite the BLOB.');
    end;

    [Test]
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
    procedure ResolvesWholeEmbeddedRepeatedAndAdjacentTokens()
    var
        CustomerName: Text;
        ItemName: Text;
    begin
        Initialize();
        CustomerName := TestName + '-Customer1No';
        ItemName := TestName + '-BlockedItem1';
        DataTools.SetPlaceholder(CustomerName, 'C1001');
        DataTools.SetPlaceholder(ItemName, 'I2001');
        Assert.AreEqual('C1001', DataTools.ResolveText(Token(LowerCase(CustomerName))), 'Whole-value names are case-insensitive.');
        Assert.AreEqual(
            'Use C1001/I2001C1001.',
            DataTools.ResolveText('Use ' + Token(CustomerName) + '/' + Token(ItemName) + Token(CustomerName) + '.'),
            'All original occurrences must be resolved.');
    end;

    [Test]
    procedure UnknownTokensDoNotBlockLaterTokens()
    var
        MissingToken: Text;
    begin
        Initialize();
        MissingToken := Token(TestName + '-Missing');
        DataTools.SetPlaceholder(TestName, 'known');
        Assert.AreEqual(
            MissingToken + ' known ' + MissingToken,
            DataTools.ResolveText(MissingToken + ' ' + Token(TestName) + ' ' + MissingToken),
            'Unknown names must remain literal without blocking later matches.');
    end;

    [Test]
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
    procedure ReplacementOutputIsNotScannedAgain()
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName + '-Left', '$Place');
        DataTools.SetPlaceholder(TestName + '-Right', 'holder-' + TestName + '-Other$');
        DataTools.SetPlaceholder(TestName + '-Other', 'must-not-expand');
        Assert.AreEqual(
            Token(TestName + '-Other'), DataTools.ResolveText(Token(TestName + '-Left') + Token(TestName + '-Right')),
            'Adjacent replacement values must not trigger a second resolution pass.');
    end;

    [Test]
    procedure PrefixSpellingRemainsCaseSensitive()
    var
        Template: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'value');
        Template := '$placeholder-' + TestName + '$';
        Assert.AreEqual(Template, DataTools.ResolveText(Template), 'Only the name, not the fixed prefix, is case-insensitive.');
    end;

    [Test]
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
    procedure SuccessiveTurnReadsUseFullName()
    var
        Input: Codeunit "Test Input Json";
        Turns: Codeunit "Test Input Json";
        TurnsTemplateTok: Label '{"turns":[{"message":"%1"},{"message":"%1"}]}', Locked = true;
    begin
        Initialize();
        Input.Initialize(StrSubstNo(TurnsTemplateTok, Token(TestName)));
        DataTools.SetPlaceholder(TestName, 'first');
        Turns := Input.Element('turns');
        Assert.AreEqual('first', Turns.ElementAt(0).Element('message').ValueAsText(), 'First-turn reads must resolve the full name.');
        DataTools.SetPlaceholder(TestName, 'second');
        Assert.AreEqual('second', Turns.ElementAt(1).Element('message').ValueAsText(), 'Later turns must read the current value of the same full name.');
    end;

    [Test]
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
    procedure InvalidDateFormulaStillRaisesError()
    begin
        Initialize();
        asserterror DataTools.ResolveText('$DateFormula-<not-a-formula>$');
        Assert.IsTrue(GetLastErrorText() <> '', 'Invalid date formulas must not silently remain literal.');
    end;

    [Test]
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
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Explicit get remains available while disabled.');
        Assert.AreEqual('value', Value, 'Disabling must not delete registrations.');
        DataTools.SetPlaceholder(TestName, 'updated');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Explicit set remains available while disabled.');
        Assert.AreEqual('updated', Value, 'Disabled state must not suppress writes.');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'Explicit deletion remains available while disabled.');
    end;

    [Test]
    procedure RepeatedEnableAndDisablePreserveValues()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetTextReplacementsEnabled(true);
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Repeated enable must retain the registration.');
        Assert.AreEqual('local', Value, 'Enable must not change the selected value.');
        Assert.AreEqual('local', DataTools.ResolveText(Token(TestName)), 'Repeated enable must keep text replacement enabled.');

        DataTools.SetTextReplacementsEnabled(false);
        DataTools.SetTextReplacementsEnabled(false);
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Repeated disable must retain the registration.');
        Assert.AreEqual('local', Value, 'Disable must not change the selected value.');
        Assert.AreEqual(Token(TestName), DataTools.ResolveText(Token(TestName)), 'Repeated disable must keep text replacement disabled.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'The shared row must survive both switch operations.');
        Assert.AreEqual('shared', Value, 'Switch operations must not clean up table rows.');
        DataTools.SetTextReplacementsEnabled(true);
        Assert.AreEqual('local', DataTools.ResolveText(Token(TestName)), 'Re-enabling must immediately resolve the retained local value.');
    end;

    [Test]
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
    procedure DeleteLocalDoesNotDeleteSharedOrOtherName()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholder(TestName + '-other', 'other');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'The local row must be deleted.');
        Assert.IsFalse(DataTools.DeletePlaceholder(TestName), 'Single deletion must not follow shared fallback.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The shared row must remain.');
        Assert.AreEqual('shared', Value, 'Deleting a local row exposes, but does not delete, its fallback.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName + '-other', Value), 'Other full names must be unaffected.');
        Assert.AreEqual('other', Value, 'Other-name data must remain unchanged.');
    end;

    [Test]
    procedure ExplicitSharedDeletionIsNotWildcard()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, ''), 'Explicit blank company must delete the shared row.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'The shared row must be absent.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The local row must survive shared deletion.');
        Assert.AreEqual('local', Value, 'Explicit shared deletion must not broaden company scope.');
    end;

    [Test]
    procedure DeletionIsCompanyScoped()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholderForCompany(TestName, 'other-company', 'Another company');
        DataTools.SetPlaceholder(TestName + '-other', 'other-name');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'The exact current-company row must be deleted.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Shared fallback must survive current-company cleanup.');
        Assert.AreEqual('shared', Value, 'Only current-company rows are removed.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, 'Another company'), 'Other companies must survive.');
        Assert.AreEqual('other-company', Value, 'Another company must retain its exact value.');

        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, ''), 'The exact shared row must be deleted.');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Explicit shared cleanup removes only the shared row.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName + '-other', Value), 'Other full names must survive both cleanups.');
    end;

    [Test]
    procedure CompanyDeletionTreatsFilterCharactersLiterally()
    var
        LiteralCompany: Text;
        Value: Text;
    begin
        Initialize();
        LiteralCompany := 'Company*|?';
        DataTools.SetPlaceholderForCompany(TestName, 'literal', LiteralCompany);
        DataTools.SetPlaceholderForCompany(TestName, 'other', 'CompanySuffix');
        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, LiteralCompany), 'The exact literal company row must be deleted.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName, Value, LiteralCompany), 'The exact literal company row must be absent.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, 'CompanySuffix'), 'Company deletion must not interpret filters.');
        Assert.AreEqual('other', Value, 'Wildcard-like company characters must not broaden deletion.');
    end;

    [Test]
    procedure OtherCompanyDeletionPreservesRemainingRows()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholderForCompany(TestName, 'other-company', 'Another company');
        DataTools.SetPlaceholderForCompany(TestName + '-other', 'other-name', '');
        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, 'Another company'), 'The exact other-company row must be deleted.');
        Assert.IsFalse(DataTools.DeletePlaceholderForCompany(TestName, 'Another company'), 'Repeated deletion must not follow shared fallback.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The current-company row must remain.');
        Assert.AreEqual('local', Value, 'Explicit company deletion must preserve the current-company value.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, 'Another company'), 'The other company must now use shared fallback.');
        Assert.AreEqual('shared', Value, 'The shared row must survive exact company deletion.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName + '-other', Value, ''), 'Other full names must remain.');
        Assert.AreEqual('other-name', Value, 'Other-name data must survive company deletion.');
    end;

    [Test]
    procedure DeleteAllClearsAllNamesAndCompaniesWithoutCommit()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholderForCompany(TestName + '-other', 'other', 'Another company');
        DataTools.DeleteAllPlaceholders();
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Delete-all must remove local entries.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'Delete-all must remove shared entries.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName + '-other', Value, 'Another company'), 'Delete-all must remove other names and companies.');
        DataTools.DeleteAllPlaceholders();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RolledBackWritesAreNotCached()
    var
        RollbackProbe: Codeunit "Test Input Rollback Probe";
        ExistingValue: Text;
        InsertedValue: Text;
        DeletedValue: Text;
        ExistingFound: Boolean;
        InsertedFound: Boolean;
        DeletedFound: Boolean;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName + '-Existing', 'original');
        DataTools.SetPlaceholder(TestName + '-Deleted', 'retained');
        Commit();

        RollbackProbe.Configure(TestName + '-Existing', TestName + '-Inserted', TestName + '-Deleted');
        Assert.IsFalse(RollbackProbe.Run(), 'The probe must roll back its transaction.');
        Assert.ExpectedError('Rolling back placeholder probe writes.');
        ExistingFound := DataTools.GetPlaceholder(TestName + '-Existing', ExistingValue);
        InsertedFound := DataTools.GetPlaceholder(TestName + '-Inserted', InsertedValue);
        DeletedFound := DataTools.GetPlaceholder(TestName + '-Deleted', DeletedValue);
        DataTools.DeletePlaceholder(TestName + '-Existing');
        DataTools.DeletePlaceholder(TestName + '-Inserted');
        DataTools.DeletePlaceholder(TestName + '-Deleted');
        Commit();

        Assert.IsTrue(ExistingFound, 'Rollback must retain the original row.');
        Assert.AreEqual('original', ExistingValue, 'A lookup must not return a rolled-back overwrite.');
        Assert.IsFalse(InsertedFound, 'A lookup must not return a rolled-back insertion.');
        Assert.AreEqual('', InsertedValue, 'A rolled-back insertion must not leave a cached value.');
        Assert.IsTrue(DeletedFound, 'A lookup must not retain a miss from a rolled-back deletion.');
        Assert.AreEqual('retained', DeletedValue, 'Rollback must restore the deleted value.');
    end;

    [Test]
    procedure AllowedNameCharactersResolve()
    begin
        Initialize();
        DataTools.SetPlaceholder('1_' + TestName + '-CustomerNo', 'C-001');
        Assert.AreEqual(
            'C-001', DataTools.ResolveText(Token(LowerCase('1_' + TestName + '-CustomerNo'))),
            'Names must support digits, underscores, hyphens, and case-insensitive lookup.');
    end;

    [Test]
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
    procedure ExistingWrappersKeepTheirFullNames()
    var
        Input: Codeunit "Test Input Json";
        PrefixedElement: Codeunit "Test Input Json";
        SuffixedElement: Codeunit "Test Input Json";
        InputObject: JsonObject;
    begin
        Initialize();
        DataTools.SetPlaceholder('PREFIX-' + TestName, 'first');
        DataTools.SetPlaceholder(TestName + '-SUFFIX', 'second');
        InputObject.Add('prefixed', Token('PREFIX-' + TestName));
        InputObject.Add('suffixed', Token(TestName + '-SUFFIX'));
        Input.Initialize(InputObject.AsToken());
        PrefixedElement := Input.Element('prefixed');
        SuffixedElement := Input.Element('suffixed');

        Assert.AreEqual('first', PrefixedElement.ValueAsText(), 'The prefixed full name must select its own value.');
        Assert.AreEqual('second', SuffixedElement.ValueAsText(), 'The suffixed full name must select its own value.');
        DataTools.SetPlaceholder('PREFIX-' + TestName, 'updated');
        Assert.AreEqual('updated', PrefixedElement.ValueAsText(), 'An existing wrapper must observe updates to its full name.');
        Assert.AreEqual('second', SuffixedElement.ValueAsText(), 'Updating a different full name must not affect the wrapper.');
    end;

    [Test]
    procedure ExistingWrapperObservesDeletionAndFallback()
    var
        Input: Codeunit "Test Input Json";
        Element: Codeunit "Test Input Json";
        InputObject: JsonObject;
    begin
        Initialize();
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholder(TestName, 'local');
        InputObject.Add('value', Token(TestName));
        Input.Initialize(InputObject.AsToken());
        Element := Input.Element('value');

        Assert.AreEqual('local', Element.ValueAsText(), 'The exact company value must win initially.');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'The local row must be deleted.');
        Assert.AreEqual('shared', Element.ValueAsText(), 'The wrapper must immediately observe shared fallback.');
        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, ''), 'The shared row must be deleted.');
        Assert.AreEqual(Token(TestName), Element.ValueAsText(), 'Deleting both rows must restore the literal token.');
    end;

    [Test]
    procedure ReplacementOutputDoesNotExpandDateTokens()
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName + '-Left', '$Date');
        DataTools.SetPlaceholder(TestName + '-DateRight', 'Formula-<CD>$');
        DataTools.SetPlaceholder(TestName + '-DateTimeRight', 'TimeFormula-<CD>-12:30:11$');
        Assert.AreEqual(
            '$DateFormula-<CD>$ / $DateTimeFormula-<CD>-12:30:11$',
            DataTools.ResolveText(Token(TestName + '-Left') + Token(TestName + '-DateRight') + ' / ' + Token(TestName + '-Left') + Token(TestName + '-DateTimeRight')),
            'Named replacement output must not be rescanned as date or DateTime tokens.');
    end;

    [Test]
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
            'customer / ' + Format(WorkDate()), Element.ValueAsText(),
            'Re-enabling must resolve both retained named values and dates.');
        DataTools.SetTextReplacementsEnabled(false);
        Assert.AreEqual(Template, Element.ValueAsText(), 'Disabling again must return the original template.');
    end;

    [Test]
    procedure ExplicitCompanyDeletionKeepsDefaultLookup()
    var
        Value: Text;
    begin
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'other', 'Another company');
        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, 'Another company'), 'Explicit deletion must target the specified company.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName, Value, 'Another company'), 'The explicitly selected row must be absent.');
        Assert.AreEqual('local', DataTools.ResolveText(Token(TestName)), 'Explicit deletion must not change the default company.');
    end;

    [Test]
    procedure ReadAndDeleteRejectInvalidKeys()
    var
        Value: Text;
    begin
        Initialize();
        asserterror DataTools.GetPlaceholder('bad name', Value);
        Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        asserterror DataTools.DeletePlaceholder('');
        Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        asserterror DataTools.GetPlaceholderForCompany(TestName, Value, PadStr('C', 31, 'C'));
        Assert.ExpectedError('must not exceed 30 characters');
        asserterror DataTools.DeletePlaceholderForCompany(TestName, PadStr('C', 31, 'C'));
        Assert.ExpectedError('must not exceed 30 characters');
        asserterror DataTools.GetPlaceholderForCompany(PadStr('N', 101, 'N'), Value, '');
        Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
        asserterror DataTools.DeletePlaceholderForCompany('bad*name', '');
        Assert.ExpectedError('The placeholder name must contain between 1 and 100 characters');
    end;

    [Test]
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
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'Indirect permissions must allow explicit company operations.');
        Assert.AreEqual('shared', Value, 'The shared value must be visible through the company API.');
        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, ''), 'Indirect permissions must allow shared deletion.');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'Indirect permissions must allow deletion through the API.');
    end;

    local procedure Initialize()
    begin
        TestName := 'P' + DelChr(Format(CreateGuid()), '=', '{}-');
        DataTools.SetTextReplacementsEnabled(true);
    end;

    local procedure Token(Name: Text): Text
    begin
        exit('$Placeholder-' + Name + '$');
    end;
}
