// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148943 "BC14 CustPriceGrp Data"
{
    Caption = 'BC14 Customer Price Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14CustomerPriceGroup; "BC14 Cust. Price Group")
            {
                AutoSave = false;
                XmlName = 'BC14CustomerPriceGroup';

                textelement(Code) { }
                textelement(Description) { }
                textelement(AllowInvoiceDisc) { }
                textelement(PriceIncludesVAT) { }
                textelement(VATBusPostingGrPrice) { }
                textelement(AllowLineDisc) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14CustomerPriceGroup: Record "BC14 Cust. Price Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14CustomerPriceGroup.Init();
                    NewBC14CustomerPriceGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14CustomerPriceGroup.Code));
                    NewBC14CustomerPriceGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14CustomerPriceGroup.Description));
                    Evaluate(NewBC14CustomerPriceGroup."Allow Invoice Disc.", AllowInvoiceDisc);
                    Evaluate(NewBC14CustomerPriceGroup."Price Includes VAT", PriceIncludesVAT);
                    NewBC14CustomerPriceGroup."VAT Bus. Posting Gr. (Price)" := CopyStr(VATBusPostingGrPrice, 1, MaxStrLen(NewBC14CustomerPriceGroup."VAT Bus. Posting Gr. (Price)"));
                    Evaluate(NewBC14CustomerPriceGroup."Allow Line Disc.", AllowLineDisc);
                    NewBC14CustomerPriceGroup.Insert();

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
