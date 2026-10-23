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
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DataTools: Codeunit "Test Input Data Tools";
        Assert: Codeunit "Library Assert";
        TestName: Text;
        RollbackErr: Label 'Rolling back placeholder probe writes.';
        TurnsTemplateTok: Label '{"turns":[{"message":"%1"},{"message":"%1"}]}', Comment = '%1 = Placeholder token repeated in both turn messages.', Locked = true;

    [Test]
    procedure SetGetsAndOverwritesCaseInsensitiveName()
    var
        Name: Text;
        Value: Text;
    begin
        // [SCENARIO] Registering the same name with different casing overwrites one value without changing its text.

        // [GIVEN] A full placeholder name with mixed casing.
        Initialize();
        Name := TestName + '-Customer1No';

        // [WHEN] A value containing significant casing and leading zeros is registered.
        DataTools.SetPlaceholder(Name, '00123-Abc');

        // [THEN] Name lookup ignores casing without changing the stored value.
        Assert.IsTrue(DataTools.GetPlaceholder(LowerCase(Name), Value), 'The name must be case-insensitive.');
        Assert.AreEqual('00123-Abc', Value, 'Values must retain their case and leading zeros.');

        // [WHEN] The same name is registered again using different casing.
        DataTools.SetPlaceholder(UpperCase(Name), 'Updated');

        // [THEN] The existing registration is replaced.
        Assert.IsTrue(DataTools.GetPlaceholder(Name, Value), 'The overwritten entry must exist.');
        Assert.AreEqual('Updated', Value, 'Setting an existing key must overwrite it.');
    end;

    [Test]
    procedure DefinitionNameRemainsRawAfterRegistrationAndOverwrite()
    var
        Input: Codeunit "Test Input Json";
        Definition: Codeunit "Test Input Json";
        InputObject: JsonObject;
        Name: Text;
    begin
        // [SCENARIO] A raw definition identifies the same name before registration and after its value is overwritten.

        // [GIVEN] An unregistered full-token definition.
        Initialize();
        Name := TestName + '-Customer1No';
        InputObject.Add('definition', Token(Name));
        Input.Initialize(InputObject.AsToken());
        Definition := Input.Element('definition');
        Assert.AreEqual(Name, DataTools.GetPlaceholderName(Definition), 'A definition must identify its name before registration.');

        // [WHEN] The definition's name receives a runtime value.
        DataTools.SetPlaceholder(Name, 'first');

        // [THEN] Normal reads resolve while definition parsing still returns the raw name.
        Assert.AreEqual('first', Definition.ValueAsText(), 'A normal read must resolve the existing registration.');
        Assert.AreEqual(Name, DataTools.GetPlaceholderName(Definition), 'Reading the definition must not return the registered value.');

        // [WHEN] Setup registers another value through the same definition.
        DataTools.SetPlaceholder(DataTools.GetPlaceholderName(Definition), 'second');

        // [THEN] The value changes without rewriting the definition.
        Assert.AreEqual('second', Definition.ValueAsText(), 'Registration through the raw definition must overwrite the same key.');
        Assert.AreEqual(Token(Name), Definition.ElementValue().AsText(), 'Registration must leave the definition unchanged.');
    end;

    [Test]
    procedure InvalidPlaceholderDefinitionsAreRejected()
    var
        Input: Codeunit "Test Input Json";
        Definitions: List of [Text];
        Definition: Text;
    begin
        // [SCENARIO] A placeholder definition must contain exactly one complete named token with a valid name.

        // [GIVEN] Invalid scalar shapes, token syntax, and names beyond the supported boundary.
        Definitions.Add('null');
        Definitions.Add('{}');
        Definitions.Add('[]');
        Definitions.Add('true');
        Definitions.Add('42');
        Definitions.Add('""');
        Definitions.Add('"Customer1No"');
        Definitions.Add('"$Placeholder-Customer1No"');
        Definitions.Add('"$placeholder-Customer1No$"');
        Definitions.Add('"before $Placeholder-Customer1No$"');
        Definitions.Add('"$Placeholder-Customer1No$ after"');
        Definitions.Add('"$Placeholder-First$$Placeholder-Second$"');
        Definitions.Add('"$Placeholder-$"');
        Definitions.Add('"$Placeholder-bad name$"');
        Definitions.Add('"' + Token(PadStr('N', 251, 'N')) + '"');
        Definitions.Add('"$DateFormula-<CD>$"');

        // [WHEN] Each value is interpreted as a named-placeholder definition.
        foreach Definition in Definitions do begin
            Input.Initialize(Definition);
            asserterror DataTools.GetPlaceholderName(Input);

            // [THEN] It fails definition validation rather than yielding a name.
            Assert.ExpectedError('The placeholder definition must be a single token');
        end;
    end;

    [Test]
    procedure MissingValueClearsOutput()
    var
        Value: Text;
        Found: Boolean;
    begin
        // [SCENARIO] Reading an absent registration returns false and cannot leave a stale output value.

        // [GIVEN] An unregistered name and a previously populated output variable.
        Initialize();
        Value := 'stale';

        // [WHEN] The missing registration is read.
        Found := DataTools.GetPlaceholder(TestName, Value);

        // [THEN] The miss clears the caller's stale value.
        Assert.IsFalse(Found, 'An absent name must not be found.');
        Assert.AreEqual('', Value, 'A miss must clear the output argument.');
    end;

    [Test]
    procedure ExplicitCompanyDoesNotChangeDefaultLookup()
    var
        Value: Text;
    begin
        // [SCENARIO] Explicit company operations do not change the current company used by default reads.

        // [GIVEN] A current-company registration.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');

        // [WHEN] The same name is registered for another company and for shared fallback.
        DataTools.SetPlaceholderForCompany(TestName, 'other', 'Another company');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');

        // [THEN] Explicit operations do not change the company used by default reads.
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
        Found: Boolean;
    begin
        // [SCENARIO] Name prefixes and suffixes are literal key components rather than implicit lookup scopes.

        // [GIVEN] Registrations whose full names have different affixes.
        Initialize();
        DataTools.SetPlaceholderForCompany('PREFIX-' + TestName, 'prefixed', '');
        DataTools.SetPlaceholder(TestName + '-SUFFIX', 'suffixed');

        // [WHEN] The unqualified base name is looked up.
        Found := DataTools.GetPlaceholder(TestName, Value);

        // [THEN] Only the exact affixed names resolve.
        Assert.IsFalse(Found, 'Lookup must not add or remove name affixes.');
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
        // [SCENARIO] Case-insensitive lookup preserves the distinct identity of prefixed and suffixed names.

        // [GIVEN] Different full names containing a prefix and a suffix.
        Initialize();
        PrefixedName := 'Scope-' + TestName;
        SuffixedName := TestName + '-Scope';

        // [WHEN] Both names are registered in lowercase.
        DataTools.SetPlaceholder(LowerCase(PrefixedName), 'prefixed');
        DataTools.SetPlaceholder(LowerCase(SuffixedName), 'suffixed');

        // [THEN] Uppercase lookups retain each full name's identity.
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
        // [SCENARIO] An exact company registration takes precedence over the same name's shared fallback.

        // [GIVEN] A shared registration.
        Initialize();
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');

        // [WHEN] The current company registers the same name.
        DataTools.SetPlaceholder(TestName, 'local');

        // [THEN] Current-company reads prefer the local value while other companies use shared fallback.
        Assert.AreEqual('local', DataTools.ResolveText(Token(TestName)), 'Current-company values take precedence.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, 'Another company'), 'Other companies use shared fallback.');
        Assert.AreEqual('shared', Value, 'Fallback must select the shared row.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'Explicit shared lookup must succeed.');
        Assert.AreEqual('shared', Value, 'Explicit shared lookup must bypass the local row.');
    end;

    [Test]
    procedure CompanyFallbackDoesNotCrossNames()
    begin
        // [SCENARIO] Shared-company fallback cannot select a local registration belonging to a different name.

        // [GIVEN] A name registered only as a shared value.
        Initialize();
        DataTools.SetPlaceholderForCompany(TestName, 'selected-shared', '');

        // [WHEN] A different name is registered in the current company.
        DataTools.SetPlaceholder(TestName + '-other', 'other-local');

        // [THEN] Local data for another name cannot replace the selected name's shared fallback.
        Assert.AreEqual('selected-shared', DataTools.ResolveText(Token(TestName)), 'Company fallback must use the exact full name.');
    end;

    [Test]
    procedure LocalEmptyValueSuppressesFallback()
    var
        Value: Text;
    begin
        // [SCENARIO] An empty local registration is a successful match that suppresses a nonempty shared fallback.

        // [GIVEN] A nonempty shared value.
        Initialize();
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');

        // [WHEN] The current company explicitly registers an empty value.
        DataTools.SetPlaceholder(TestName, '');

        // [THEN] The empty registration is found and suppresses shared fallback.
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
        // [SCENARIO] Long multiline Unicode values round-trip, and shorter overwrites leave no old BLOB suffix.

        // [GIVEN] Long text containing Unicode, line breaks, quotes, and significant whitespace.
        Initialize();
        UnicodeCharacter := 9731;
        Builder.AppendLine('  00123 "quoted" \backslash ');
        Builder.AppendLine('');
        Builder.Append(Format(UnicodeCharacter));
        Builder.Append(PadStr('x', 32768, 'y'));
        Builder.AppendLine();
        Builder.Append('  trailing spaces  ');
        Expected := Builder.ToText();

        // [WHEN] The complete text is registered.
        DataTools.SetPlaceholder(TestName, Expected);

        // [THEN] Storage and resolution preserve it exactly.
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The BLOB value must exist.');
        Assert.AreEqual(Expected, Value, 'BLOB storage must preserve the complete text.');
        Assert.AreEqual(Expected, DataTools.ResolveText(Token(TestName)), 'Resolution must not format or trim the value.');

        // [WHEN] A shorter value replaces the BLOB.
        DataTools.SetPlaceholder(TestName, 'short');

        // [THEN] No suffix from the earlier value remains.
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The overwritten BLOB must exist.');
        Assert.AreEqual('short', Value, 'An overwrite must not retain the old BLOB suffix.');
    end;

    [Test]
    procedure BlobNormalizesLineEndingsAndPreservesEmptyLines()
    var
        ExpectedBuilder: TextBuilder;
        RegisteredValue: Text;
        Value: Text;
        LineFeed: Char;
        CarriageReturn: Char;
    begin
        // [SCENARIO] Multiline reads normalize mixed line endings without losing empty lines or significant spaces.

        // [GIVEN] Mixed LF/CRLF text with leading, consecutive, and trailing empty lines.
        Initialize();
        LineFeed := 10;
        CarriageReturn := 13;
        RegisteredValue := Format(LineFeed) + '  first  ' + Format(LineFeed) + Format(LineFeed) +
            'second' + Format(CarriageReturn) + Format(LineFeed) + Format(LineFeed);
        ExpectedBuilder.AppendLine();
        ExpectedBuilder.AppendLine('  first  ');
        ExpectedBuilder.AppendLine();
        ExpectedBuilder.AppendLine('second');
        ExpectedBuilder.AppendLine();

        // [WHEN] The multiline value is registered and then read.
        DataTools.SetPlaceholder(TestName, RegisteredValue);
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The multiline registration must exist.');

        // [THEN] Direct and resolving reads use standard separators and preserve every empty line.
        Assert.AreEqual(ExpectedBuilder.ToText(), Value, 'Line reading must preserve empty lines and spaces while normalizing separators.');
        Assert.AreEqual(
            ExpectedBuilder.ToText(), DataTools.ResolveText(Token(TestName)),
            'Resolution must use the same multiline value as direct lookup.');
    end;

    [Test]
    procedure MaximumKeyLengthsAreAccepted()
    var
        Name: Text;
        Company: Text;
        Value: Text;
    begin
        // [SCENARIO] Names and company keys at their maximum supported lengths round-trip without truncation.

        // [GIVEN] A 250-character name and a maximum-length company.
        Initialize();
        Name := PadStr(TestName, 250, 'N');
        Company := PadStr('Company', 30, 'C');

        // [WHEN] The exact key is registered.
        DataTools.SetPlaceholderForCompany(Name, 'value', Company);

        // [THEN] Both key components round-trip without truncation.
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(Name, Value, Company), 'Maximum-length keys must be accepted.');
        Assert.AreEqual('value', Value, 'Maximum-length keys must round-trip without truncation.');
    end;

    [Test]
    procedure LongNamesWithSharedPrefixRemainDistinct()
    var
        FirstName: Text;
        SecondName: Text;
        Value: Text;
    begin
        // [SCENARIO] Updating or deleting one maximum-length name cannot affect another that differs only at its end.

        // [GIVEN] Two 250-character names that differ only in their final character.
        Initialize();
        FirstName := PadStr(TestName, 249, 'N') + 'A';
        SecondName := PadStr(TestName, 249, 'N') + 'B';

        // [WHEN] Both are registered and the first is overwritten using different casing.
        DataTools.SetPlaceholder(FirstName, 'first');
        DataTools.SetPlaceholder(SecondName, 'second');
        DataTools.SetPlaceholder(LowerCase(FirstName), 'updated');

        // [THEN] Full-name lookup and resolution do not collide at either the old or new boundary.
        Assert.IsTrue(DataTools.GetPlaceholder(FirstName, Value), 'The first long name must exist.');
        Assert.AreEqual('updated', Value, 'Overwriting the first long name must target its full key.');
        Assert.IsTrue(DataTools.GetPlaceholder(SecondName, Value), 'The second long name must exist.');
        Assert.AreEqual('second', Value, 'The shared prefix must not merge the two registrations.');
        Assert.AreEqual(
            'updated / second', DataTools.ResolveText(Token(LowerCase(FirstName)) + ' / ' + Token(LowerCase(SecondName))),
            'The parser and registry must preserve both complete names.');

        // [WHEN] The first full name is deleted.
        Assert.IsTrue(DataTools.DeletePlaceholder(FirstName), 'The first long name must be deleted.');

        // [THEN] The second registration survives.
        Assert.IsFalse(DataTools.GetPlaceholder(FirstName, Value), 'The deleted full name must be absent.');
        Assert.IsTrue(DataTools.GetPlaceholder(SecondName, Value), 'Deleting a shared prefix must not delete another full name.');
        Assert.AreEqual('second', Value, 'Deletion must preserve the other long name and its value.');
    end;

    [Test]
    procedure InvalidNamesAreRejected()
    var
        Names: List of [Text];
        Name: Text;
    begin
        // [SCENARIO] Registration rejects blank, malformed, and overlong names before writing any value.

        // [GIVEN] Blank names, unsupported characters, and a 251-character name.
        Initialize();
        Names.Add('');
        Names.Add('bad name');
        Names.Add('bad$name');
        Names.Add('bad.name');
        Names.Add('bad*name');
        Names.Add('bad|name');
        Names.Add('bad?name');
        Names.Add(' name ');
        Names.Add(PadStr('N', 251, 'N'));

        // [WHEN] Each invalid name is registered.
        foreach Name in Names do begin
            asserterror DataTools.SetPlaceholder(Name, 'value');

            // [THEN] Name validation rejects it before storage.
            Assert.ExpectedError('The placeholder name must contain between 1 and 250 characters');
        end;
    end;

    [Test]
    procedure OverlongFullNameAndCompanyAreRejected()
    var
        Value: Text;
    begin
        // [SCENARIO] Affixed names and company keys beyond their limits fail without truncation or partial insertion.

        // [GIVEN] Affixes count toward the full-name limit, and company names have their own limit.
        Initialize();

        // [WHEN] An affix or company exceeds its boundary by one character.
        asserterror DataTools.SetPlaceholder('P-' + PadStr(TestName, 249, 'N'), 'value');

        // [THEN] The operation fails without truncation or partial insertion.
        Assert.ExpectedError('The placeholder name must contain between 1 and 250 characters');
        asserterror DataTools.SetPlaceholder(PadStr(TestName, 249, 'N') + '-S', 'value');
        Assert.ExpectedError('The placeholder name must contain between 1 and 250 characters');
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
        // [SCENARIO] Registered values cannot contain complete named, date, or datetime tokens for recursive expansion.

        // [GIVEN] Replacement values containing each supported kind of complete token.
        Initialize();
        Values.Add('$Placeholder-Unknown$');
        Values.Add('before $DateFormula-<CD>$ after');
        Values.Add('$DateTimeFormula-<CD>-12:30:11$');

        // [WHEN] Each value is registered.
        foreach Value in Values do begin
            asserterror DataTools.SetPlaceholder(TestName, Value);

            // [THEN] Registration rejects recursive replacement content.
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
        // [SCENARIO] Rejecting an overwrite containing a token preserves the previously committed registration.

        // [GIVEN] A committed registration that must survive a rejected overwrite.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'original');
        Commit();

        // [WHEN] An overwrite contains a supported token.
        asserterror DataTools.SetPlaceholder(TestName, '$Placeholder-Unknown$');

        // [THEN] Validation fails and the committed value remains unchanged.
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
        // [SCENARIO] Dollar signs and unsupported token prefixes are allowed as literal replacement text.

        // [GIVEN] A fresh name for text containing ordinary dollar signs and an unknown token prefix.
        Initialize();

        // [WHEN] The literal text is registered.
        DataTools.SetPlaceholder(TestName, 'Pay $5; ordinary $ signs and $Unknown-tool$ are literal.');

        // [THEN] Resolution returns the exact literal content.
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
        // [SCENARIO] One resolution pass replaces whole, embedded, repeated, and adjacent registered names.

        // [GIVEN] Two distinct full names referenced in whole and embedded input values.
        Initialize();
        CustomerName := TestName + '-Customer1No';
        ItemName := TestName + '-BlockedItem1';

        // [WHEN] Values are registered for both names.
        DataTools.SetPlaceholder(CustomerName, 'C1001');
        DataTools.SetPlaceholder(ItemName, 'I2001');

        // [THEN] Every original occurrence resolves, including adjacent and repeated tokens.
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
        ResolvedText: Text;
    begin
        // [SCENARIO] Missing registrations remain literal without preventing other tokens from resolving.

        // [GIVEN] Missing references surrounding a known registration.
        Initialize();
        MissingToken := Token(TestName + '-Missing');
        DataTools.SetPlaceholder(TestName, 'known');

        // [WHEN] The mixed input is resolved.
        ResolvedText := DataTools.ResolveText(MissingToken + ' ' + Token(TestName) + ' ' + MissingToken);

        // [THEN] Missing references stay literal without blocking the known name.
        Assert.AreEqual(
            MissingToken + ' known ' + MissingToken,
            ResolvedText,
            'Unknown names must remain literal without blocking later matches.');
    end;

    [Test]
    procedure MalformedTokensDoNotBlockLaterTokens()
    var
        Prefix: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] Malformed or incomplete tokens remain literal and cannot consume a later valid reference.

        // [GIVEN] Malformed named references preceding a valid registered token.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'known');
        Prefix := '$Placeholder-$ $Placeholder-bad name$ $Placeholder-unclosed ';

        // [WHEN] The resolver scans past those malformed references.
        ResolvedText := DataTools.ResolveText(Prefix + Token(TestName));

        // [THEN] Malformed text remains literal and the valid token still resolves.
        Assert.AreEqual(Prefix + 'known', ResolvedText, 'Malformed tokens must not consume a later valid token.');
        Assert.AreEqual('$Placeholder-unclosed', DataTools.ResolveText('$Placeholder-unclosed'), 'An incomplete token remains literal.');
        Assert.IsTrue(
            DataTools.ContainsNamedPlaceholderMarker(DataTools.ResolveText('$Placeholder-unclosed')),
            'Consumers must still be able to reject an incomplete named reference after resolution.');
        Assert.AreEqual('$', DataTools.ResolveText('$'), 'A trailing delimiter must not cause an out-of-range search.');
        Assert.AreEqual('', DataTools.ResolveText(''), 'Empty text remains empty.');
    end;

    [Test]
    procedure OverlongInputNameRemainsLiteral()
    var
        InputText: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] An overlong token name remains literal instead of resolving through a truncated key.

        // [GIVEN] A 251-character input name followed by a registered name.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'known');
        InputText := Token(PadStr('N', 251, 'N'));

        // [WHEN] Both references are resolved together.
        ResolvedText := DataTools.ResolveText(InputText + Token(TestName));

        // [THEN] The overlong name stays literal instead of becoming a truncated lookup.
        Assert.AreEqual(InputText + 'known', ResolvedText, 'An overlong input name is not a truncated key.');
    end;

    [Test]
    procedure ReplacementOutputIsNotScannedAgain()
    var
        ResolvedText: Text;
    begin
        // [SCENARIO] Concatenated replacement values that form a named token are not recursively resolved.

        // [GIVEN] Two replacement values that form another registered token when concatenated.
        Initialize();
        DataTools.SetPlaceholder(TestName + '-Left', '$Place');
        DataTools.SetPlaceholder(TestName + '-Right', 'holder-' + TestName + '-Other$');
        DataTools.SetPlaceholder(TestName + '-Other', 'must-not-expand');

        // [WHEN] The two original tokens are resolved next to each other.
        ResolvedText := DataTools.ResolveText(Token(TestName + '-Left') + Token(TestName + '-Right'));

        // [THEN] The newly assembled token is not expanded again.
        Assert.AreEqual(
            Token(TestName + '-Other'), ResolvedText,
            'Adjacent replacement values must not trigger a second resolution pass.');
    end;

    [Test]
    procedure PrefixSpellingRemainsCaseSensitive()
    var
        Template: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] Case-insensitive placeholder names do not make the fixed token prefix case-insensitive.

        // [GIVEN] A registered name referenced with the wrong prefix casing.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'value');
        Template := '$placeholder-' + TestName + '$';

        // [WHEN] The reference is resolved.
        ResolvedText := DataTools.ResolveText(Template);

        // [THEN] Incorrect prefix spelling remains literal.
        Assert.AreEqual(Template, ResolvedText, 'Only the name, not the fixed prefix, is case-insensitive.');
    end;

    [Test]
    procedure ExistingWrapperObservesLateRegistrationAndOverwrite()
    var
        Input: Codeunit "Test Input Json";
        Element: Codeunit "Test Input Json";
        InputObject: JsonObject;
        FirstRead: Text;
    begin
        // [SCENARIO] A retained wrapper observes late registration and overwrite while previously returned text stays unchanged.

        // [GIVEN] An input wrapper created before its name is registered.
        Initialize();
        InputObject.Add('message', Token(TestName));
        Input.Initialize(InputObject.AsToken());
        Element := Input.Element('message');

        // [WHEN] The wrapper is read before registration.
        FirstRead := Element.ValueAsText();

        // [THEN] The unresolved marker is preserved and detectable.
        Assert.AreEqual(Token(TestName), FirstRead, 'A missing value starts unresolved.');
        Assert.IsTrue(DataTools.ContainsNamedPlaceholderMarker(Element.ValueAsText()), 'An unresolved reference must remain detectable.');

        // [WHEN] A value is registered, read, and then overwritten.
        DataTools.SetPlaceholder(TestName, 'first');
        FirstRead := Element.ValueAsText();
        Assert.IsFalse(DataTools.ContainsNamedPlaceholderMarker(FirstRead), 'A resolved value must no longer contain a placeholder marker.');
        DataTools.SetPlaceholder(TestName, 'second');

        // [THEN] Future reads see the overwrite while returned text and the raw template remain unchanged.
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
        ResolvedText: Text;
    begin
        // [SCENARIO] Resolving a scalar value never rewrites raw exports or JSON property names.

        // [GIVEN] A registered name used as both a property name and its value.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'resolved');
        InputObject.Add(Token(TestName), Token(TestName));
        Input.Initialize(InputObject.AsToken());

        // [WHEN] The scalar is read through the resolving accessor.
        ResolvedText := Input.Element(Token(TestName)).ValueAsText();

        // [THEN] Every raw export preserves the template and its property name.
        Assert.AreEqual('resolved', ResolvedText, 'Property names remain literal while text values resolve.');
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
        IntegerValue: Integer;
        DecimalValue: Decimal;
        BooleanValue: Boolean;
    begin
        // [SCENARIO] Placeholder support leaves native numeric and Boolean input readers unchanged.

        // [GIVEN] Native JSON numeric and Boolean values.
        Initialize();
        Input.Initialize('{"integer":42,"decimal":12.5,"boolean":true}');

        // [WHEN] The typed readers access these non-text values.
        IntegerValue := Input.Element('integer').ValueAsInteger();
        DecimalValue := Input.Element('decimal').ValueAsDecimal();
        BooleanValue := Input.Element('boolean').ValueAsBoolean();

        // [THEN] Placeholder resolution does not change their native types or values.
        Assert.AreEqual(42, IntegerValue, 'Native integers must be unchanged.');
        Assert.AreEqual(12.5, DecimalValue, 'Native decimals must be unchanged.');
        Assert.IsTrue(BooleanValue, 'Native booleans must be unchanged.');
    end;

    [Test]
    procedure SuccessiveTurnReadsUseFullName()
    var
        Input: Codeunit "Test Input Json";
        Turns: Codeunit "Test Input Json";
    begin
        // [SCENARIO] Successive turns resolve the current value of a shared full name without rebuilding the input wrapper.

        // [GIVEN] Two turns referencing the same full name and its initial registration.
        Initialize();
        Input.Initialize(StrSubstNo(TurnsTemplateTok, Token(TestName)));
        DataTools.SetPlaceholder(TestName, 'first');

        // [WHEN] The turn collection is accessed.
        Turns := Input.Element('turns');

        // [THEN] The first turn sees the initial value.
        Assert.AreEqual('first', Turns.ElementAt(0).Element('message').ValueAsText(), 'First-turn reads must resolve the full name.');

        // [WHEN] The same name is overwritten between turn reads.
        DataTools.SetPlaceholder(TestName, 'second');

        // [THEN] The later turn sees the updated value without a new wrapper.
        Assert.AreEqual('second', Turns.ElementAt(1).Element('message').ValueAsText(), 'Later turns must read the current value of the same full name.');
    end;

    [Test]
    procedure ResolvesMixedDateDateTimeAndNamedTokens()
    var
        Expected: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] Named values and date/datetime formulas can be resolved together in the same input.

        // [GIVEN] A runtime name combined with date and datetime formulas.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'customer');
        Expected := Format(WorkDate()) + ' / ' + Format(CreateDateTime(WorkDate(), 123011T)) + ' / customer';

        // [WHEN] The mixed input is resolved in one pass.
        ResolvedText := DataTools.ResolveText('$DateFormula-<CD>$ / $DateTimeFormula-<CD>-12:30:11$ / ' + Token(TestName));

        // [THEN] Named and typed implementations preserve their combined text behavior.
        Assert.AreEqual(
            Expected, ResolvedText,
            'All supported token types must use the same text resolver.');
        Assert.AreEqual(Format(CalcDate('<1D>', WorkDate())), DataTools.ResolveText('$DateFormula-<1D>$'), 'Relative date formulas must be preserved.');
    end;

    [Test]
    procedure DateTimeSupportsDefaultAndExplicitTime()
    var
        ExpectedTime: Time;
        DefaultTimeText: Text;
    begin
        // [SCENARIO] Datetime formulas default to midnight or retain the explicitly supplied hours, minutes, and seconds.

        // [GIVEN] Datetime formulas with no time and with an explicit whole-second time.
        Initialize();
        ExpectedTime := 123011T;

        // [WHEN] A formula omits its time component.
        DefaultTimeText := DataTools.ResolveText('$DateTimeFormula-<CD>$');

        // [THEN] It defaults to midnight, while explicit times retain their hours, minutes, and seconds.
        Assert.AreEqual(
            Format(CreateDateTime(WorkDate(), 0T)), DefaultTimeText,
            'DateTime formulas without a time default to midnight.');
        Assert.AreEqual(
            CreateDateTime(WorkDate(), ExpectedTime), DataTools.ResolveAsDateTime('$DateTimeFormula-<CD>-12:30:11$'),
            'Typed conversion must preserve the explicit time.');
        Assert.AreEqual(
            Format(CreateDateTime(WorkDate(), ExpectedTime)), DataTools.ResolveText('$DateTimeFormula-<CD>-12:30:11$'),
            'Text resolution must preserve the explicit time.');
    end;

    [Test]
    procedure RawTextAndTypedDateReadsAreIndependent()
    var
        Input: Codeunit "Test Input Json";
        ResolvedDate: Text;
    begin
        // [SCENARIO] Raw reads do not disable later text or typed date/datetime resolution or mutate the templates.

        // [GIVEN] Raw date and datetime templates in an input wrapper.
        Initialize();
        Input.Initialize('{"date":"$DateFormula-<CD>$","datetime":"$DateTimeFormula-<CD>-12:30:11$"}');
        Assert.AreEqual('$DateFormula-<CD>$', Input.Element('date').ElementValue().AsText(), 'Raw reads must return the date template.');

        // [WHEN] A resolving text read follows a raw read.
        ResolvedDate := Input.Element('date').ValueAsText();

        // [THEN] Resolving and typed reads work without changing either raw template.
        Assert.AreEqual(Format(WorkDate()), ResolvedDate, 'A normal text read must still resolve the date.');
        Assert.AreEqual(WorkDate(), Input.Element('date').ValueAsDate(), 'Typed dates remain supported.');
        Assert.AreEqual(CreateDateTime(WorkDate(), 123011T), Input.Element('datetime').ValueAsDateTime(), 'Typed datetimes remain supported.');
        Assert.AreEqual(
            '$DateTimeFormula-<CD>-12:30:11$', Input.Element('datetime').ElementValue().AsText(),
            'A typed read must leave the raw datetime template unchanged.');
    end;

    [Test]
    procedure TypedDatesResolveRegisteredNames()
    var
        Input: Codeunit "Test Input Json";
        InputObject: JsonObject;
        ResolvedDate: Date;
    begin
        // [SCENARIO] Typed date readers resolve named values and immediately observe subsequent overwrites.

        // [GIVEN] A named definition whose registered value is ordinary date text.
        Initialize();
        DataTools.SetPlaceholder(TestName, Format(WorkDate()));
        InputObject.Add('date', Token(TestName));
        Input.Initialize(InputObject.AsToken());

        // [WHEN] The date implementation resolves the name through the shared registry.
        ResolvedDate := Input.Element('date').ValueAsDate();

        // [THEN] Date and datetime readers convert the registered text without rewriting the input.
        Assert.AreEqual(WorkDate(), ResolvedDate, 'Typed date reads must resolve registered names before conversion.');
        Assert.AreEqual(
            CreateDateTime(WorkDate(), 0T), Input.Element('date').ValueAsDateTime(),
            'Named date values must retain the midnight datetime conversion.');
        Assert.AreEqual(Token(TestName), Input.Element('date').ElementValue().AsText(), 'Typed reads must leave the raw named token intact.');

        // [WHEN] The registered date is overwritten after the wrapper was created.
        DataTools.SetPlaceholder(TestName, Format(WorkDate() + 1));

        // [THEN] Both typed readers use the current registration.
        Assert.AreEqual(WorkDate() + 1, Input.Element('date').ValueAsDate(), 'Typed date reads must observe an overwritten registration.');
        Assert.AreEqual(
            CreateDateTime(WorkDate() + 1, 0T), Input.Element('date').ValueAsDateTime(),
            'Typed datetime reads must observe an overwritten registration.');
    end;

    [Test]
    procedure DeleteLocalDoesNotDeleteSharedOrOtherName()
    var
        Value: Text;
        Deleted: Boolean;
    begin
        // [SCENARIO] Deleting a local value exposes shared fallback without deleting it or another name's value.

        // [GIVEN] Local, shared, and unrelated-name registrations.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholder(TestName + '-other', 'other');

        // [WHEN] The current-company registration is deleted.
        Deleted := DataTools.DeletePlaceholder(TestName);

        // [THEN] Exact deletion preserves shared fallback and unrelated names.
        Assert.IsTrue(Deleted, 'The local row must be deleted.');
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
        Deleted: Boolean;
    begin
        // [SCENARIO] Deletion with an explicitly blank company removes only the shared registration.

        // [GIVEN] Local and shared registrations for the same name.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');

        // [WHEN] Deletion explicitly targets the blank company.
        Deleted := DataTools.DeletePlaceholderForCompany(TestName, '');

        // [THEN] Only the shared row is removed.
        Assert.IsTrue(Deleted, 'Explicit blank company must delete the shared row.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'The shared row must be absent.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The local row must survive shared deletion.');
        Assert.AreEqual('local', Value, 'Explicit shared deletion must not broaden company scope.');
    end;

    [Test]
    procedure DeletionIsCompanyScoped()
    var
        Value: Text;
        Deleted: Boolean;
    begin
        // [SCENARIO] Deleting local and shared values separately preserves other companies and unrelated names.

        // [GIVEN] The same name in multiple companies and a separate local name.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholderForCompany(TestName, 'other-company', 'Another company');
        DataTools.SetPlaceholder(TestName + '-other', 'other-name');

        // [WHEN] The current-company row is deleted.
        Deleted := DataTools.DeletePlaceholder(TestName);

        // [THEN] Shared and other-company rows survive.
        Assert.IsTrue(Deleted, 'The exact current-company row must be deleted.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Shared fallback must survive current-company cleanup.');
        Assert.AreEqual('shared', Value, 'Only current-company rows are removed.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, 'Another company'), 'Other companies must survive.');
        Assert.AreEqual('other-company', Value, 'Another company must retain its exact value.');

        // [WHEN] The shared row is deleted separately.
        Deleted := DataTools.DeletePlaceholderForCompany(TestName, '');

        // [THEN] Default lookup misses without affecting another name.
        Assert.IsTrue(Deleted, 'The exact shared row must be deleted.');
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Explicit shared cleanup removes only the shared row.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName + '-other', Value), 'Other full names must survive both cleanups.');
    end;

    [Test]
    procedure CompanyDeletionTreatsFilterCharactersLiterally()
    var
        LiteralCompany: Text;
        Value: Text;
        Deleted: Boolean;
    begin
        // [SCENARIO] Filter-like characters in a company key are treated literally during exact deletion.

        // [GIVEN] A company containing filter characters and another similarly named company.
        Initialize();
        LiteralCompany := 'Company*|?';
        DataTools.SetPlaceholderForCompany(TestName, 'literal', LiteralCompany);
        DataTools.SetPlaceholderForCompany(TestName, 'other', 'CompanySuffix');

        // [WHEN] The literal company key is deleted.
        Deleted := DataTools.DeletePlaceholderForCompany(TestName, LiteralCompany);

        // [THEN] Filter-like characters do not broaden deletion.
        Assert.IsTrue(Deleted, 'The exact literal company row must be deleted.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName, Value, LiteralCompany), 'The exact literal company row must be absent.');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, 'CompanySuffix'), 'Company deletion must not interpret filters.');
        Assert.AreEqual('other', Value, 'Wildcard-like company characters must not broaden deletion.');
    end;

    [Test]
    procedure OtherCompanyDeletionPreservesRemainingRows()
    var
        Value: Text;
        Deleted: Boolean;
    begin
        // [SCENARIO] Deleting another company's exact row preserves all remaining rows and exposes its shared fallback.

        // [GIVEN] Local, shared, other-company, and other-name registrations.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholderForCompany(TestName, 'other-company', 'Another company');
        DataTools.SetPlaceholderForCompany(TestName + '-other', 'other-name', '');

        // [WHEN] The explicitly selected other-company row is deleted.
        Deleted := DataTools.DeletePlaceholderForCompany(TestName, 'Another company');

        // [THEN] Only that exact row disappears and its lookup now falls back to shared data.
        Assert.IsTrue(Deleted, 'The exact other-company row must be deleted.');
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
        // [SCENARIO] Explicit delete-all clears registrations across all names and companies within the current transaction.

        // [GIVEN] Registrations spanning names and companies in the test transaction.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholderForCompany(TestName + '-other', 'other', 'Another company');

        // [WHEN] Explicit registry-wide cleanup runs.
        DataTools.DeleteAllPlaceholders();

        // [THEN] Every scope is empty and repeated cleanup is harmless.
        Assert.IsFalse(DataTools.GetPlaceholder(TestName, Value), 'Delete-all must remove local entries.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'Delete-all must remove shared entries.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName + '-other', Value, 'Another company'), 'Delete-all must remove other names and companies.');
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
        // [SCENARIO] After rollback, reads reflect restored rows rather than cached insertions, updates, deletions, or misses.

        // [GIVEN] Committed baseline registrations for updates and deletions.
        Initialize();
        DataTools.SetPlaceholder(TestName + '-Existing', 'original');
        DataTools.SetPlaceholder(TestName + '-Deleted', 'retained');
        Commit();

        // [WHEN] A transaction updates, inserts, deletes, and reads registrations, then fails.
        DataTools.SetPlaceholder(TestName + '-Existing', 'uncommitted');
        DataTools.SetPlaceholder(TestName + '-Inserted', 'uncommitted');
        DataTools.DeletePlaceholder(TestName + '-Deleted');
        DataTools.GetPlaceholder(TestName + '-Existing', ExistingValue);
        DataTools.GetPlaceholder(TestName + '-Inserted', InsertedValue);
        DataTools.GetPlaceholder(TestName + '-Deleted', DeletedValue);
        asserterror Error(RollbackErr);

        // [THEN] The intended rollback error is raised and subsequent reads reflect restored storage.
        Assert.ExpectedError(RollbackErr);
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
        // [SCENARIO] Names containing supported digits, underscores, and hyphens resolve independently of letter casing.

        // [GIVEN] A full name containing digits, an underscore, and a hyphen.
        Initialize();

        // [WHEN] Its value is registered.
        DataTools.SetPlaceholder('1_' + TestName + '-CustomerNo', 'C-001');

        // [THEN] Lowercase references resolve the complete allowed name.
        Assert.AreEqual(
            'C-001', DataTools.ResolveText(Token(LowerCase('1_' + TestName + '-CustomerNo'))),
            'Names must support digits, underscores, hyphens, and case-insensitive lookup.');
    end;

    [Test]
    procedure MaximumLengthNameResolves()
    var
        Input: Codeunit "Test Input Json";
        InputObject: JsonObject;
        Name: Text;
    begin
        // [SCENARIO] Maximum-length names work consistently in definitions, registration, and resolving reads.

        // [GIVEN] A full-token definition containing a 250-character name.
        Initialize();
        Name := PadStr(TestName, 250, 'N');
        InputObject.Add('definition', Token(Name));
        Input.Initialize(InputObject.AsToken());

        // [WHEN] Setup registers a value through the raw definition.
        DataTools.SetPlaceholder(DataTools.GetPlaceholderName(Input.Element('definition')), 'maximum-length');

        // [THEN] Both definition parsing and resolving reads preserve the complete name.
        Assert.AreEqual(Name, DataTools.GetPlaceholderName(Input.Element('definition')), 'A maximum-length definition must retain its full name.');
        Assert.AreEqual(
            'maximum-length', DataTools.ResolveText(Token(LowerCase(Name))),
            'The token parser must accept the full 250-character name without truncation.');
    end;

    [Test]
    procedure ExistingWrappersKeepTheirFullNames()
    var
        Input: Codeunit "Test Input Json";
        PrefixedElement: Codeunit "Test Input Json";
        SuffixedElement: Codeunit "Test Input Json";
        InputObject: JsonObject;
    begin
        // [SCENARIO] Retained wrappers keep independent full-name identities when one affixed registration changes.

        // [GIVEN] Input elements for separately registered prefixed and suffixed names.
        Initialize();
        DataTools.SetPlaceholder('PREFIX-' + TestName, 'first');
        DataTools.SetPlaceholder(TestName + '-SUFFIX', 'second');
        InputObject.Add('prefixed', Token('PREFIX-' + TestName));
        InputObject.Add('suffixed', Token(TestName + '-SUFFIX'));
        Input.Initialize(InputObject.AsToken());

        // [WHEN] Both element wrappers are retained.
        PrefixedElement := Input.Element('prefixed');
        SuffixedElement := Input.Element('suffixed');

        // [THEN] Each wrapper resolves its own full name.
        Assert.AreEqual('first', PrefixedElement.ValueAsText(), 'The prefixed full name must select its own value.');
        Assert.AreEqual('second', SuffixedElement.ValueAsText(), 'The suffixed full name must select its own value.');

        // [WHEN] Only the prefixed name is overwritten.
        DataTools.SetPlaceholder('PREFIX-' + TestName, 'updated');

        // [THEN] The retained wrappers remain independent.
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
        // [SCENARIO] A retained wrapper observes local deletion, shared fallback, and then the unresolved token.

        // [GIVEN] A retained wrapper with both current-company and shared registrations.
        Initialize();
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        DataTools.SetPlaceholder(TestName, 'local');
        InputObject.Add('value', Token(TestName));
        Input.Initialize(InputObject.AsToken());
        Element := Input.Element('value');

        Assert.AreEqual('local', Element.ValueAsText(), 'The exact company value must win initially.');

        // [WHEN] The current-company row is removed.
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'The local row must be deleted.');

        // [THEN] The same wrapper immediately reads the shared fallback.
        Assert.AreEqual('shared', Element.ValueAsText(), 'The wrapper must immediately observe shared fallback.');

        // [WHEN] The shared row is removed too.
        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, ''), 'The shared row must be deleted.');

        // [THEN] The original unresolved token is returned.
        Assert.AreEqual(Token(TestName), Element.ValueAsText(), 'Deleting both rows must restore the literal token.');
    end;

    [Test]
    procedure ReplacementOutputDoesNotExpandDateTokens()
    var
        ResolvedText: Text;
    begin
        // [SCENARIO] Date and datetime tokens assembled from replacement fragments are not evaluated in a second pass.

        // [GIVEN] Replacement fragments that form date and datetime tokens when joined.
        Initialize();
        DataTools.SetPlaceholder(TestName + '-Left', '$Date');
        DataTools.SetPlaceholder(TestName + '-DateRight', 'Formula-<CD>$');
        DataTools.SetPlaceholder(TestName + '-DateTimeRight', 'TimeFormula-<CD>-12:30:11$');

        // [WHEN] The original named tokens are resolved.
        ResolvedText := DataTools.ResolveText(
            Token(TestName + '-Left') + Token(TestName + '-DateRight') + ' / ' + Token(TestName + '-Left') + Token(TestName + '-DateTimeRight'));

        // [THEN] Tokens assembled from replacement text are not evaluated.
        Assert.AreEqual(
            '$DateFormula-<CD>$ / $DateTimeFormula-<CD>-12:30:11$',
            ResolvedText,
            'Named replacement output must not be rescanned as date or DateTime tokens.');
    end;

    [Test]
    procedure ExistingWrapperSupportsAlternatingRawAndResolvedReads()
    var
        Input: Codeunit "Test Input Json";
        Element: Codeunit "Test Input Json";
        InputObject: JsonObject;
        Template: Text;
        RawText: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] Alternating raw and resolved reads preserves each accessor's contract without an enable/disable switch.

        // [GIVEN] A retained wrapper containing both a registered name and a date formula.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'customer');
        Template := Token(TestName) + ' / $DateFormula-<CD>$';
        InputObject.Add('value', Template);
        Input.Initialize(InputObject.AsToken());
        Element := Input.Element('value');

        // [WHEN] Raw and resolving reads are performed on the same wrapper.
        RawText := Element.ElementValue().AsText();
        ResolvedText := Element.ValueAsText();

        // [THEN] Each accessor keeps its own contract across alternating reads.
        Assert.AreEqual(Template, RawText, 'An explicit raw read must bypass all text replacements.');
        Assert.AreEqual(
            'customer / ' + Format(WorkDate()), ResolvedText,
            'A normal read must resolve named values and dates without enabling anything.');
        Assert.AreEqual(Template, Element.ElementValue().AsText(), 'A resolving read must not change the raw template.');
        Assert.AreEqual(
            'customer / ' + Format(WorkDate()), Element.ValueAsText(),
            'Reading the raw value must not disable subsequent resolution.');
    end;

    [Test]
    procedure ExplicitCompanyDeletionKeepsDefaultLookup()
    var
        Value: Text;
        Deleted: Boolean;
    begin
        // [SCENARIO] Explicit deletion in another company does not change the company used by default resolution.

        // [GIVEN] Current-company and other-company values for the same name.
        Initialize();
        DataTools.SetPlaceholder(TestName, 'local');
        DataTools.SetPlaceholderForCompany(TestName, 'other', 'Another company');

        // [WHEN] An explicit company is selected for deletion.
        Deleted := DataTools.DeletePlaceholderForCompany(TestName, 'Another company');

        // [THEN] Default lookup still uses the current company.
        Assert.IsTrue(Deleted, 'Explicit deletion must target the specified company.');
        Assert.IsFalse(DataTools.GetPlaceholderForCompany(TestName, Value, 'Another company'), 'The explicitly selected row must be absent.');
        Assert.AreEqual('local', DataTools.ResolveText(Token(TestName)), 'Explicit deletion must not change the default company.');
    end;

    [Test]
    procedure ReadAndDeleteRejectInvalidKeys()
    var
        Value: Text;
    begin
        // [SCENARIO] Read and delete operations reject invalid keys using the same boundaries as registration.

        // [GIVEN] Invalid names and company keys supplied to non-writing API operations.
        Initialize();

        // [WHEN] A read or delete is attempted with one of those keys.
        asserterror DataTools.GetPlaceholder('bad name', Value);

        // [THEN] Every operation enforces the same name and company boundaries as registration.
        Assert.ExpectedError('The placeholder name must contain between 1 and 250 characters');
        asserterror DataTools.DeletePlaceholder('');
        Assert.ExpectedError('The placeholder name must contain between 1 and 250 characters');
        asserterror DataTools.GetPlaceholderForCompany(TestName, Value, PadStr('C', 31, 'C'));
        Assert.ExpectedError('must not exceed 30 characters');
        asserterror DataTools.DeletePlaceholderForCompany(TestName, PadStr('C', 31, 'C'));
        Assert.ExpectedError('must not exceed 30 characters');
        asserterror DataTools.GetPlaceholderForCompany(PadStr('N', 251, 'N'), Value, '');
        Assert.ExpectedError('The placeholder name must contain between 1 and 250 characters');
        asserterror DataTools.DeletePlaceholder(PadStr('N', 251, 'N'));
        Assert.ExpectedError('The placeholder name must contain between 1 and 250 characters');
        asserterror DataTools.DeletePlaceholderForCompany('bad*name', '');
        Assert.ExpectedError('The placeholder name must contain between 1 and 250 characters');
    end;

    [Test]
    procedure PlaceholderApiWorksWithInherentPermissions()
    var
        PermissionsMock: Codeunit "Permissions Mock";
        Value: Text;
    begin
        // [SCENARIO] Public placeholder operations work without assigning registry table-data permissions to the caller.

        // [GIVEN] Only object execution rights, with no assigned registry table-data permissions.
        PermissionsMock.Stop();
        Initialize();
        PermissionsMock.Start();
        PermissionsMock.SetExactPermissionSet('All Objects');

        // [WHEN] The public API creates a registration under that restricted context.
        DataTools.SetPlaceholder(TestName, 'value');

        // [THEN] Inherent registry access supports reads, updates, company operations, and deletion.
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Inherent registry permissions must allow reads through the API.');
        Assert.AreEqual('value', DataTools.ResolveText(Token(TestName)), 'The shared resolver needs execute permission.');
        DataTools.SetPlaceholder(TestName, 'updated');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'Inherent registry permissions must allow updates.');
        Assert.AreEqual('updated', Value, 'The updated value must be visible.');
        DataTools.SetPlaceholderForCompany(TestName, 'shared', '');
        Assert.IsTrue(DataTools.GetPlaceholderForCompany(TestName, Value, ''), 'Inherent registry permissions must allow explicit company operations.');
        Assert.AreEqual('shared', Value, 'The shared value must be visible through the company API.');
        Assert.IsTrue(DataTools.DeletePlaceholderForCompany(TestName, ''), 'Inherent registry permissions must allow shared deletion.');
        Assert.IsTrue(DataTools.DeletePlaceholder(TestName), 'Inherent registry permissions must allow deletion through the API.');
    end;

    local procedure Initialize()
    begin
        TestName := 'P' + DelChr(Format(CreateGuid()), '=', '{}-');
    end;

    local procedure Token(Name: Text): Text
    begin
        exit('$Placeholder-' + Name + '$');
    end;
}
