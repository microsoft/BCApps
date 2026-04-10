namespace System.TestTools.TestRunner;

xmlport 130402 "CAL Import Enabled Codeunit"
{
    Caption = 'CAL Import Enabled Codeunit';
    Direction = Import;
    Encoding = UTF16;

    schema
    {
        textelement(CALTests)
        {
            textattribute(Name)
            {
            }
            textattribute(Description)
            {
            }
            tableelement("CAL Test Enabled Codeunit"; "CAL Test Enabled Codeunit")
            {
                XmlName = 'Codeunit';
                fieldattribute(ID; "CAL Test Enabled Codeunit"."Test Codeunit ID")
                {
                }

                trigger OnBeforeInsertRecord()
                var
                    CALTestMgt: Codeunit "CAL Test Management";
                begin
                    if not CALTestMgt.DoesTestCodeunitExist("CAL Test Enabled Codeunit"."Test Codeunit ID") or
                       CodeunitIsEnabled("CAL Test Enabled Codeunit"."Test Codeunit ID")
                    then
                        currXMLport.Skip();
                end;
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

    local procedure CodeunitIsEnabled(CodeunitId: Integer): Boolean
    var
        CALTestEnabledCodeunit: Record "CAL Test Enabled Codeunit";
    begin
        CALTestEnabledCodeunit.SetRange("Test Codeunit ID", CodeunitId);
        exit(not CALTestEnabledCodeunit.IsEmpty);
    end;
}

