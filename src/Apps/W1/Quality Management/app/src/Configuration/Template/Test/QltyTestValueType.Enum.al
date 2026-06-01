// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
/// A test value type is the type of data field for a quality inspection test.
/// </summary>
enum 20415 "Qlty. Test Value Type"
{
    Caption = 'Quality Test Value Type', Locked = true;
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Value Type Decimal")
    {
        Caption = 'Decimal';
    }
    value(1; "Value Type Integer")
    {
        Caption = 'Integer';
    }
    value(2; "Value Type Boolean")
    {
        Caption = 'Boolean';
    }
    value(3; "Value Type Text")
    {
        Caption = 'Text';
    }
    value(4; "Value Type Option")
    {
        Caption = 'Option';
    }
    value(5; "Value Type Table Lookup")
    {
        Caption = 'Table Lookup';
    }
    value(6; "Value Type DateTime")
    {
        Caption = 'Date and Time';
    }
    value(7; "Value Type Date")
    {
        Caption = 'Date';
    }
    value(8; "Value Type Label")
    {
        Caption = 'Label';
    }
    value(10; "Value Type Text Expression")
    {
        Caption = 'Text Expression';
    }
}
