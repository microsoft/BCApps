// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Team;
using Microsoft.QualityManagement.Utilities;
using System.TestLibraries.Utilities;

codeunit 139977 "Qlty. Tests - Rec. Ops."
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        UnableToSetTableValueFieldNotFoundErr: Label 'Unable to set a value because the field [%1] in table [%2] was not found.', Comment = '%1=the field name, %2=the table name';

    [Test]
    procedure SetTableValue_Simple()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
        QltyRecordOperations: Codeunit "Qlty. Record Operations";
    begin
        // [SCENARIO] Set table field values dynamically

        // [GIVEN] A Salesperson/Purchaser record with initial values
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser."Commission %" := 1;
        SalespersonPurchaser."Job Title" := 'janitor';
        SalespersonPurchaser.Modify(false);
        SalespersonPurchaser.SetRecFilter();

        // [WHEN] SetTableValue is called for decimal and text fields
        QltyRecordOperations.SetTableValue(SalespersonPurchaser.TableCaption(), SalespersonPurchaser.GetView(), SalespersonPurchaser.FieldName("Commission %"), format(1234.56), true);
        QltyRecordOperations.SetTableValue(SalespersonPurchaser.TableCaption(), SalespersonPurchaser.GetView(), SalespersonPurchaser.FieldName("Job Title"), 'manager', true);

        // [THEN] The field values are updated correctly
        SalespersonPurchaser.SetRecFilter();
        SalespersonPurchaser.FindFirst();

        LibraryAssert.AreEqual(1234.56, SalespersonPurchaser."Commission %", 'decimal test');
        LibraryAssert.AreEqual('manager', SalespersonPurchaser."Job Title", 'text test');
    end;

    [Test]
    procedure SetTableValue_Error()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
        QltyRecordOperations: Codeunit "Qlty. Record Operations";
    begin
        // [SCENARIO] Set table value error when field does not exist

        // [GIVEN] A Salesperson/Purchaser record
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser."Commission %" := 1;
        SalespersonPurchaser."Job Title" := 'janitor';
        SalespersonPurchaser.Modify(false);
        SalespersonPurchaser.SetRecFilter();

        // [WHEN] SetTableValue is called with a non-existent field name
        asserterror QltyRecordOperations.SetTableValue(SalespersonPurchaser.TableCaption(), SalespersonPurchaser.GetView(), 'This field does not exist.', format(1234.56), true);

        // [THEN] An error is raised indicating the field was not found
        LibraryAssert.ExpectedError(StrSubstNo(UnableToSetTableValueFieldNotFoundErr, 'This field does not exist.', SalespersonPurchaser.TableCaption()));
    end;

    [Test]
    procedure ReadFieldAsText()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        InteractionLogEntry: Record "Interaction Log Entry";
        LibrarySales: Codeunit "Library - Sales";
        QltyRecordOperations: Codeunit "Qlty. Record Operations";
        Format0: Text;
        Format9: Text;
        Format9NoOfInteractions: Text;
    begin
        // [SCENARIO] Read field values as text with different formats

        // [GIVEN] A Salesperson/Purchaser record with decimal field and calculated flowfield
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser."Commission %" := 12345.67;
        SalespersonPurchaser."Job Title" := 'janitor';
        SalespersonPurchaser.Modify(false);

        InteractionLogEntry.Reset();
        InteractionLogEntry."Salesperson Code" := SalespersonPurchaser.Code;
        InteractionLogEntry.Canceled := false;
        InteractionLogEntry.Postponed := false;
        InteractionLogEntry.InsertRecord();

        // [WHEN] ReadFieldAsText is called with format 0 (locale) and format 9 (ISO)
        Format0 := QltyRecordOperations.ReadFieldAsText(SalespersonPurchaser, SalespersonPurchaser.FieldName("Commission %"), 0);
        Format9 := QltyRecordOperations.ReadFieldAsText(SalespersonPurchaser, SalespersonPurchaser.FieldName("Commission %"), 9);

        Format9NoOfInteractions := QltyRecordOperations.ReadFieldAsText(SalespersonPurchaser, SalespersonPurchaser.FieldName("No. of Interactions"), 9);

        // [THEN] The field values are formatted correctly including flowfields
        SalespersonPurchaser.CalcFields("No. of Interactions");
        LibraryAssert.AreEqual(format(SalespersonPurchaser."Commission %", 0, 0), Format0, 'format0 test');
        LibraryAssert.AreEqual(format(SalespersonPurchaser."Commission %", 0, 9), Format9, 'format9 test');
        LibraryAssert.AreEqual(format(SalespersonPurchaser."No. of Interactions", 0, 9), Format9NoOfInteractions, 'flowfield test');
    end;
}
