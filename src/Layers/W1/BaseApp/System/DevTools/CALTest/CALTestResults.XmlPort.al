namespace System.TestTools.TestRunner;

xmlport 130401 "CAL Test Results"
{
    Caption = 'CAL Test Results';
    Encoding = UTF8;

    schema
    {
        textelement(TestSuites)
        {
            tableelement("test suite"; "CAL Test Suite")
            {
                CalcFields = "Tests to Execute";
                MinOccurs = Zero;
                XmlName = 'TestSuite';
                fieldelement(Name; "Test Suite".Name)
                {
                }
                fieldelement(Description; "Test Suite".Description)
                {
                }
                textelement(TestLines)
                {
                    tableelement("test line"; "CAL Test Line")
                    {
                        LinkFields = "Test Suite" = field(Name);
                        LinkTable = "Test Suite";
                        MinOccurs = Zero;
                        XmlName = 'TestLine';
                        fieldelement(TestSuite; "Test Line"."Test Suite")
                        {
                        }
                        fieldelement(LineNo; "Test Line"."Line No.")
                        {
                        }
                        fieldelement(LineType; "Test Line"."Line Type")
                        {
                        }
                        fieldelement(Name; "Test Line".Name)
                        {
                            FieldValidate = no;
                        }
                        fieldelement(TestCodeunit; "Test Line"."Test Codeunit")
                        {
                        }
                        fieldelement(Function; "Test Line".Function)
                        {
                        }
                        fieldelement(Run; "Test Line".Run)
                        {
                            FieldValidate = no;
                        }
                        fieldelement(Result; "Test Line".Result)
                        {
                            FieldValidate = no;
                        }
                        fieldelement(FirstError; "Test Line"."First Error")
                        {
                            FieldValidate = no;
                        }
                        fieldelement(StartTime; "Test Line"."Start Time")
                        {
                            FieldValidate = no;
                        }
                        fieldelement(FinishTime; "Test Line"."Finish Time")
                        {
                            FieldValidate = no;
                        }
                        fieldelement(Level; "Test Line".Level)
                        {
                            FieldValidate = no;
                        }
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
}

