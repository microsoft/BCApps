// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DataMigration.SL;

xmlport 147678 "SL AP Balances Data"
{
    Caption = 'SL AP Balances data for import/export';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;

    schema
    {
        textelement(root)
        {
            tableelement("SL AP Balances"; "SL AP_Balances")
            {
                AutoSave = false;
                XmlName = 'SLAPBalances';

                textelement(VendID)
                {
                }
                textelement(CpnyID)
                {
                }
                textelement(CYBox00)
                {
                }
                textelement(CYBox01)
                {
                }
                textelement(CYBox02)
                {
                }
                textelement(CYBox03)
                {
                }
                textelement(CYBox04)
                {
                }
                textelement(CYBox05)
                {
                }
                textelement(CYBox06)
                {
                }
                textelement(CYBox07)
                {
                }
                textelement(CYBox08)
                {
                }
                textelement(CYBox09)
                {
                }
                textelement(CYBox10)
                {
                }
                textelement(CYBox11)
                {
                }
                textelement(CYBox12)
                {
                }
                textelement(CYBox13)
                {
                }
                textelement(CYBox14)
                {
                }
                textelement(CYBox15)
                {
                }
                textelement(NYBox00)
                {
                }
                textelement(NYBox01)
                {
                }
                textelement(NYBox02)
                {
                }
                textelement(NYBox03)
                {
                }
                textelement(NYBox04)
                {
                }
                textelement(NYBox05)
                {
                }
                textelement(NYBox06)
                {
                }
                textelement(NYBox07)
                {
                }
                textelement(NYBox08)
                {
                }
                textelement(NYBox09)
                {
                }
                textelement(NYBox10)
                {
                }
                textelement(NYBox11)
                {
                }
                textelement(NYBox12)
                {
                }
                textelement(NYBox13)
                {
                }
                textelement(NYBox14)
                {
                }
                textelement(NYBox15)
                {
                }

                trigger OnPreXmlItem()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                    end;
                end;

                trigger OnBeforeInsertRecord()
                var
                    SLAPBalances: Record "SL AP_Balances";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                    end;

                    SLAPBalances.VendID := VendID;
                    SLAPBalances.CpnyID := CopyStr(CompanyName(), 1, MaxStrLen(SLAPBalances.CpnyID));
                    Evaluate(SLAPBalances.CYBox00, CYBox00);
                    Evaluate(SLAPBalances.CYBox01, CYBox01);
                    Evaluate(SLAPBalances.CYBox02, CYBox02);
                    Evaluate(SLAPBalances.CYBox03, CYBox03);
                    Evaluate(SLAPBalances.CYBox04, CYBox04);
                    Evaluate(SLAPBalances.CYBox05, CYBox05);
                    Evaluate(SLAPBalances.CYBox06, CYBox06);
                    Evaluate(SLAPBalances.CYBox07, CYBox07);
                    Evaluate(SLAPBalances.CYBox08, CYBox08);
                    Evaluate(SLAPBalances.CYBox09, CYBox09);
                    Evaluate(SLAPBalances.CYBox10, CYBox10);
                    Evaluate(SLAPBalances.CYBox11, CYBox11);
                    Evaluate(SLAPBalances.CYBox12, CYBox12);
                    Evaluate(SLAPBalances.CYBox13, CYBox13);
                    Evaluate(SLAPBalances.CYBox14, CYBox14);
                    Evaluate(SLAPBalances.CYBox15, CYBox15);
                    Evaluate(SLAPBalances.NYBox00, NYBox00);
                    Evaluate(SLAPBalances.NYBox01, NYBox01);
                    Evaluate(SLAPBalances.NYBox02, NYBox02);
                    Evaluate(SLAPBalances.NYBox03, NYBox03);
                    Evaluate(SLAPBalances.NYBox04, NYBox04);
                    Evaluate(SLAPBalances.NYBox05, NYBox05);
                    Evaluate(SLAPBalances.NYBox06, NYBox06);
                    Evaluate(SLAPBalances.NYBox07, NYBox07);
                    Evaluate(SLAPBalances.NYBox08, NYBox08);
                    Evaluate(SLAPBalances.NYBox09, NYBox09);
                    Evaluate(SLAPBalances.NYBox10, NYBox10);
                    Evaluate(SLAPBalances.NYBox11, NYBox11);
                    Evaluate(SLAPBalances.NYBox12, NYBox12);
                    Evaluate(SLAPBalances.NYBox13, NYBox13);
                    Evaluate(SLAPBalances.NYBox14, NYBox14);
                    Evaluate(SLAPBalances.NYBox15, NYBox15);
                    SLAPBalances.Insert();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        SLAPBalances.DeleteAll(true);
        CaptionRow := true;
    end;

    var
        SLAPBalances: Record "SL AP_Balances";
        CaptionRow: Boolean;
}
