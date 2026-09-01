xmlport 130020 "Export/Import Test Suite"
{
    Encoding = UTF8;

    schema
    {
        textelement("<testsuites>")
        {
            XmlName = 'TestSuites';
            tableelement("test suite"; "Test Suite")
            {
                MinOccurs = Zero;
                XmlName = 'TestSuite';
                fieldelement(Name; "Test Suite".Name)
                {
                }
                fieldelement(Description; "Test Suite".Description)
                {
                }
                fieldelement(Export; "Test Suite".Export)
                {
                }
                textelement(TestLines)
                {
                    tableelement("<test line>"; "Test Line")
                    {
                        LinkFields = "Test Suite" = field(Name);
                        LinkTable = "Test Suite";
                        MinOccurs = Zero;
                        XmlName = 'TestLine';
                        fieldelement(TestTestSuite; "<Test Line>"."Test Suite")
                        {
                        }
                        fieldelement(LineType; "<Test Line>"."Line Type")
                        {
                        }
                        fieldelement(Name; "<Test Line>".Name)
                        {
                            FieldValidate = no;
                        }
                        fieldelement(TestCodeunit; "<Test Line>"."Test Codeunit")
                        {
                        }
                        fieldelement(Function; "<Test Line>".Function)
                        {
                        }
                        fieldelement(Run; "<Test Line>".Run)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "<Test Line>"."Function" = '' then begin
                                if "<Test Line>"."Test Codeunit" <> 0 then
                                    TestLine := "<Test Line>";
                            end else begin
                                if "<Test Line>".Run then
                                    currXMLport.Skip();
                                if not TestLine.Run and (TestLine."Test Codeunit" = "<Test Line>"."Test Codeunit") then
                                    currXMLport.Skip();
                            end;
                        end;

                        trigger OnAfterInsertRecord()
                        var
                            CopyOfTestLine: Record "Test Line";
                        begin
                            if ("<Test Line>"."Test Codeunit" <> 0) and
                               ("<Test Line>"."Function" = '')
                            then begin
                                CopyOfTestLine.Copy("<Test Line>");
                                "<Test Line>".SetRecFilter();

                                TestMgt.SETPUBLISHMODE();
                                CODEUNIT.Run(CODEUNIT::"Test Runner", "<Test Line>");

                                "<Test Line>".Copy(CopyOfTestLine);
                            end;
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            if "<Test Line>"."Function" = '' then begin
                                TestLine.SetRange("Test Suite", "<Test Line>"."Test Suite");
                                TestLine.SetRange("Function", '');
                                "<Test Line>"."Line No." := 10000;
                                if TestLine.FindLast() then
                                    "<Test Line>"."Line No." := TestLine."Line No." + 10000;
                                TestLine.SetFilter("Line No.", '>=%1', "<Test Line>"."Line No.");
                            end else begin
                                TestLine.SetRange("Function", "<Test Line>"."Function");
                                if not TestLine.FindFirst() then
                                    currXMLport.Skip();
                                TestLine.Delete();
                                "<Test Line>"."Line No." := TestLine."Line No.";

                                TestLine.SetRange("Function", '');
                                TestLine.FindLast();
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
        TestLine: Record "Test Line";
        TestMgt: Codeunit "Test Management";
}

