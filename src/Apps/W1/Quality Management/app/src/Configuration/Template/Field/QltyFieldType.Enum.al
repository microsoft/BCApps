// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Field;

/// <summary>
/// A field type is the type of data field for a quality inspection field.
/// </summary>
enum 20415 "Qlty. Field Type"
{
    Caption = 'Quality Field Type', Locked = true;
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Field Type Decimal")
    {
        Caption = 'Decimal';
    }
    value(1; "Field Type Integer")
    {
        Caption = 'Integer';
    }
    value(2; "Field Type Boolean")
    {
        Caption = 'Boolean';
    }
    value(3; "Field Type Text")
    {
        Caption = 'Text';
    }
    value(4; "Field Type Option")
    {
        Caption = 'Option';
    }
    value(5; "Field Type Table Lookup")
    {
        Caption = 'Table Lookup';
    }
    value(6; "Field Type DateTime")
    {
        Caption = 'Date and Time';
    }
    value(7; "Field Type Date")
    {
        Caption = 'Date';
    }
    value(8; "Field Type Label")
    {
        Caption = 'Label';
    }
    value(10; "Field Type Text Expression")
    {
        Caption = 'Text Expression';
    }
}
