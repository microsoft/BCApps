// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148949 "BC14 InvPostGroup Data"
{
    Caption = 'BC14 Inventory Posting Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14InventoryPostingGroup; "BC14 Inventory Posting Group")
            {
                AutoSave = false;
                XmlName = 'BC14InventoryPostingGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14InventoryPostingGroup: Record "BC14 Inventory Posting Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14InventoryPostingGroup.Init();
                    NewBC14InventoryPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14InventoryPostingGroup.Code));
                    NewBC14InventoryPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14InventoryPostingGroup.Description));
                    NewBC14InventoryPostingGroup.Insert();

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
