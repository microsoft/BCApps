// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148945 "BC14 ItemDiscGrp Data"
{
    Caption = 'BC14 Item Discount Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14ItemDiscountGroup; "BC14 Item Discount Group")
            {
                AutoSave = false;
                XmlName = 'BC14ItemDiscountGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14ItemDiscountGroup: Record "BC14 Item Discount Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14ItemDiscountGroup.Init();
                    NewBC14ItemDiscountGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14ItemDiscountGroup.Code));
                    NewBC14ItemDiscountGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14ItemDiscountGroup.Description));
                    NewBC14ItemDiscountGroup.Insert();

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
