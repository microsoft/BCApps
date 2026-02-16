// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;

codeunit 139897 "E-Doc. Description Test"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SetDescriptionOnEDocument()
    var
        EDocument: Record "E-Document";
        DescriptionTxt: Label 'Test E-Document Description';
    begin
        // [FEATURE] [E-Document]
        // [SCENARIO] Setting the Description field on an E-Document persists the value

        // [GIVEN] A new E-Document record
        EDocument.Init();
        EDocument."Entry No" := 0;

        // [WHEN] The Description field is set and the record is inserted
        EDocument.Description := DescriptionTxt;
        EDocument.Insert(false);

        // [THEN] The Description field value is persisted after re-reading the record
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(DescriptionTxt, EDocument.Description, 'Description field should match the value that was set.');
    end;
}
