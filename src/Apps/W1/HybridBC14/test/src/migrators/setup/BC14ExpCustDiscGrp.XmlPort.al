// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Sales.Pricing;

xmlport 148942 "BC14 Exp CustDiscGrp"
{
    Caption = 'Expected Customer Discount Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(CustomerDiscountGroup; "Customer Discount Group")
            {
                AutoSave = false;
                XmlName = 'CustomerDiscountGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempCustomerDiscountGroup.Init();
                    TempCustomerDiscountGroup.Code := CopyStr(Code, 1, MaxStrLen(TempCustomerDiscountGroup.Code));
                    TempCustomerDiscountGroup.Description := CopyStr(Description, 1, MaxStrLen(TempCustomerDiscountGroup.Description));
                    TempCustomerDiscountGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempCustomerDiscountGroup.Reset();
        TempCustomerDiscountGroup.DeleteAll();
    end;

    procedure GetExpectedCustomerDiscountGroups(var Dest: Record "Customer Discount Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempCustomerDiscountGroup.FindSet() then
            repeat
                Dest := TempCustomerDiscountGroup;
                Dest.Insert();
            until TempCustomerDiscountGroup.Next() = 0;
    end;

    var
        TempCustomerDiscountGroup: Record "Customer Discount Group" temporary;
        CaptionRow: Boolean;
}
