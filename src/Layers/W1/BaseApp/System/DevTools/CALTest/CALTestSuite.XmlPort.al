namespace System.TestTools.TestRunner;

xmlport 130400 "CAL Test Suite"
{
    Caption = 'CAL Test Suite';
    Encoding = UTF8;

    schema
    {
        textelement("<caltestsuites>")
        {
            XmlName = 'CALTestSuites';
            tableelement("cal test suite"; "CAL Test Suite")
            {
                MinOccurs = Zero;
                XmlName = 'CALTestSuite';
                fieldelement(Name; "CAL Test Suite".Name)
                {
                }
                fieldelement(Description; "CAL Test Suite".Description)
                {
                }
                fieldelement(Export; "CAL Test Suite".Export)
                {
                }
                textelement(CALTestLines)
                {
                    tableelement("<cal test line>"; "CAL Test Line")
                    {
                        LinkFields = "Test Suite" = field(Name);
                        LinkTable = "CAL Test Suite";
                        MinOccurs = Zero;
                        XmlName = 'CALTestLine';
                        fieldelement(TestTestSuite; "<CAL Test Line>"."Test Suite")
                        {
                        }
                        fieldelement(LineType; "<CAL Test Line>"."Line Type")
                        {
                        }
                        fieldelement(Name; "<CAL Test Line>".Name)
                        {
                            FieldValidate = no;
                        }
                        fieldelement(TestCodeunit; "<CAL Test Line>"."Test Codeunit")
                        {
                        }
                        fieldelement(Function; "<CAL Test Line>".Function)
                        {
                        }
                        fieldelement(Run; "<CAL Test Line>".Run)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "<CAL Test Line>"."Function" = '' then begin
                                if "<CAL Test Line>"."Test Codeunit" <> 0 then
                                    CALTestLine := "<CAL Test Line>";
                            end else begin
                                if "<CAL Test Line>".Run then
                                    currXMLport.Skip();
                                if not CALTestLine.Run and (CALTestLine."Test Codeunit" = "<CAL Test Line>"."Test Codeunit") then
                                    currXMLport.Skip();
                            end;
                        end;

                        trigger OnAfterInsertRecord()
                        var
                            CopyOfCALTestLine: Record "CAL Test Line";
                        begin
                            if ("<CAL Test Line>"."Test Codeunit" <> 0) and
                               ("<CAL Test Line>"."Function" = '')
                            then begin
                                CopyOfCALTestLine.Copy("<CAL Test Line>");
                                "<CAL Test Line>".SetRecFilter();

                                CALTestMgt.SETPUBLISHMODE();
                                CODEUNIT.Run(CODEUNIT::"CAL Test Runner", "<CAL Test Line>");

                                "<CAL Test Line>".Copy(CopyOfCALTestLine);
                            end;
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            if "<CAL Test Line>"."Function" = '' then begin
                                CALTestLine.SetRange("Test Suite", "<CAL Test Line>"."Test Suite");
                                CALTestLine.SetRange("Function", '');
                                "<CAL Test Line>"."Line No." := 10000;
                                if CALTestLine.FindLast() then
                                    "<CAL Test Line>"."Line No." := CALTestLine."Line No." + 10000;
                                CALTestLine.SetFilter("Line No.", '>=%1', "<CAL Test Line>"."Line No.");
                            end else begin
                                CALTestLine.SetRange("Function", "<CAL Test Line>"."Function");
                                if not CALTestLine.FindFirst() then
                                    currXMLport.Skip();
                                CALTestLine.Delete();
                                "<CAL Test Line>"."Line No." := CALTestLine."Line No.";

                                CALTestLine.SetRange("Function", '');
                                CALTestLine.FindLast();
                            end;
                        end;
                    }
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

    var
        CALTestLine: Record "CAL Test Line";
        CALTestMgt: Codeunit "CAL Test Management";
}

