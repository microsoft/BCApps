// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Sales.Pricing;

xmlport 148944 "BC14 Exp CustPriceGrp"
{
    Caption = 'Expected Customer Price Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(CustomerPriceGroup; "Customer Price Group")
            {
                AutoSave = false;
                XmlName = 'CustomerPriceGroup';

                textelement(Code) { }
                textelement(Description) { }
                textelement(AllowInvoiceDisc) { }
                textelement(PriceIncludesVAT) { }
                textelement(VATBusPostingGrPrice) { }
                textelement(AllowLineDisc) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempCustomerPriceGroup.Init();
                    TempCustomerPriceGroup.Code := CopyStr(Code, 1, MaxStrLen(TempCustomerPriceGroup.Code));
                    TempCustomerPriceGroup.Description := CopyStr(Description, 1, MaxStrLen(TempCustomerPriceGroup.Description));
                    Evaluate(TempCustomerPriceGroup."Allow Invoice Disc.", AllowInvoiceDisc);
                    Evaluate(TempCustomerPriceGroup."Price Includes VAT", PriceIncludesVAT);
                    TempCustomerPriceGroup."VAT Bus. Posting Gr. (Price)" := CopyStr(VATBusPostingGrPrice, 1, MaxStrLen(TempCustomerPriceGroup."VAT Bus. Posting Gr. (Price)"));
                    Evaluate(TempCustomerPriceGroup."Allow Line Disc.", AllowLineDisc);
                    TempCustomerPriceGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempCustomerPriceGroup.Reset();
        TempCustomerPriceGroup.DeleteAll();
    end;

    procedure GetExpectedCustomerPriceGroups(var Dest: Record "Customer Price Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempCustomerPriceGroup.FindSet() then
            repeat
                Dest := TempCustomerPriceGroup;
                Dest.Insert();
            until TempCustomerPriceGroup.Next() = 0;
    end;

    var
        TempCustomerPriceGroup: Record "Customer Price Group" temporary;
        CaptionRow: Boolean;
}
