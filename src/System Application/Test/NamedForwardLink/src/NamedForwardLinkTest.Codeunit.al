// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Utilities;

using System.TestLibraries.Utilities;
using System.Utilities;
using Microsoft.Utilities;

codeunit 134568 "Named Forward Link Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;

    [Test]
    procedure ForwardLinksAreNotEditable()
    var
        NamedForwardLinkRec: Record "Named Forward Link";
        NamedForwardLink: Codeunit "Named Forward Link";
        ForwardLinks: TestPage "Forward Links";
    begin
        // Setup
        NamedForwardLinkRec.DeleteAll();
        NamedForwardLink.Insert(CopyStr(Any.AlphabeticText(MaxStrLen(NamedForwardLinkRec.Name)), 1, MaxStrLen(NamedForwardLinkRec.Name)), CopyStr(Any.AlphabeticText(MaxStrLen(NamedForwardLinkRec.Description)), 1, MaxStrLen(NamedForwardLinkRec.Description)), 'https://go.microsoft.com/fwlink/?linkid=2208139');

        // Exercise
        ForwardLinks.OpenEdit();

        // Verify
        LibraryAssert.IsFalse(ForwardLinks.Name.Editable(), 'Name should not be editable');
        LibraryAssert.IsTrue(ForwardLinks.Description.Editable(), 'Description should be editable');
        LibraryAssert.IsTrue(ForwardLinks.Link.Editable(), 'Link should be editable');
        asserterror ForwardLinks.New();
        LibraryAssert.ExpectedError('Insert is not allowed. Page = Forward Links, Id = 1431.');
    end;

    [Test]
    procedure ExistingForwardLinkDoesNotGetOverwritten()
    var
        NamedForwardLinkRec: Record "Named Forward Link";
        NamedForwardLink: Codeunit "Named Forward Link";
        Inserted: Boolean;
    begin
        // Setup
        NamedForwardLinkRec.DeleteAll();
        Inserted := NamedForwardLink.Insert('A', 'D', 'L');
        LibraryAssert.IsTrue(Inserted, 'Insert should succeed');

        // Exercise
        Inserted := NamedForwardLink.Insert('A', 'D2', 'L2');

        // Verify
        LibraryAssert.IsFalse(Inserted, 'Insert should fail');
        NamedForwardLinkRec.Get('A');
        NamedForwardLinkRec.Testfield(Description, 'D');
        NamedForwardLinkRec.Testfield(Link, 'L');
    end;
}