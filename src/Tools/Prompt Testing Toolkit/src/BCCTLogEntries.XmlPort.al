// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

xmlport 149030 "BCCT Log Entries"
{
    Caption = 'Export Item Data';
    DefaultFieldsValidation = false;
    Direction = Export;
    FieldDelimiter = '<~>';
    FieldSeparator = '<;>';
    Format = VariableText;
    TextEncoding = UTF16;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            XmlName = 'Root';
            tableelement(logentry; "BCCT Log Entry")
            {
                AutoSave = false;
                AutoUpdate = false;
                RequestFilterFields = "BCCT Code";
                XmlName = 'BCCTLogEntry';
                fieldelement(Entry_No; logentry."Entry No.") { }
                fieldelement(BCCT_Code; logentry."BCCT Code") { }
                fieldelement(BCCT_Line_No; logentry."BCCT Line No.") { }
                fieldelement(Start_Time; logentry."Start Time") { }
                fieldelement(End_Time; logentry."End Time") { }
                fieldelement(Message; logentry."Message") { }
                fieldelement(Codeunit_ID; logentry."Codeunit ID") { }
                fieldelement(Codeunit_Name; logentry."Codeunit Name") { }
                fieldelement(Duration_ms; logentry."Duration (ms)") { }
                fieldelement(Status; logentry."Status") { }
                fieldelement(Tage; logentry.Tag) { }
                fieldelement(Version; logentry.Version) { }
            }
        }
    }
}