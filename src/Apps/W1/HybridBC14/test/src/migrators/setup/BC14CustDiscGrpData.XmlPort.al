// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148941 "BC14 CustDiscGrp Data"
{
    Caption = 'BC14 Customer Discount Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14CustomerDiscountGroup; "BC14 Customer Discount Group")
            {
                AutoSave = false;
                XmlName = 'BC14CustomerDiscountGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14CustomerDiscountGroup: Record "BC14 Customer Discount Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14CustomerDiscountGroup.Init();
                    NewBC14CustomerDiscountGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14CustomerDiscountGroup.Code));
                    NewBC14CustomerDiscountGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14CustomerDiscountGroup.Description));
                    NewBC14CustomerDiscountGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
    end;

    var
        CaptionRow: Boolean;
}
