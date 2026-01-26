// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Utilities;

xmlport 10720 "G/L Importing Tool"
{
    Caption = 'G/L Importing Tool';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '<TAB>';
    Format = VariableText;
    TableSeparator = '.<NewLine>';

    schema
    {
        textelement(Root)
        {
            tableelement(Integer; Integer)
            {
                XmlName = 'Integer';
                SourceTableView = sorting(Number) where(Number = const(1));
                UseTemporary = true;
                textelement(Header)
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPostXmlPort()
    begin
        if RegNo = 0 then
            Error(Text1100002, RegNo);

        Message(Text1100003, RegNo);
    end;

    var
        RegNo: Integer;
        Text1100002: Label '%1 records have been imported. Please check that the file contained registers and try again.';
        Text1100003: Label 'The importing process has finished. %1 records have been imported.';
}
