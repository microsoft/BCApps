page 130020 "Test Suites"
{
    PageType = List;
    SaveValues = true;
    SourceTable = "Test Suite";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Re-run Failing Codeunits"; "Re-run Failing Codeunits")
                {
                    ApplicationArea = All;
                }
                field("Show Test Details"; "Show Test Details")
                {
                    ApplicationArea = All;
                }
                field("Tests to Execute"; "Tests to Execute")
                {
                    ApplicationArea = All;
                }
                field(Failures; Failures)
                {
                    ApplicationArea = All;
                }
                field("Tests not Executed"; "Tests not Executed")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Test &Suite")
            {
                Caption = 'Test &Suite';
                action("&Run All")
                {
                    ApplicationArea = All;
                    Caption = '&Run All';
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+Ctrl+L';

                    trigger OnAction()
                    var
                        TestSuite: Record "Test Suite";
                        TestLine: Record "Test Line";
                    begin
                        if TestSuite.Find('-') then
                            repeat
                                TestLine.SetRange("Test Suite", TestSuite.Name);
                                CODEUNIT.Run(CODEUNIT::"Test Runner", TestLine);
                            until TestSuite.Next() = 0;
                        Commit();
                    end;
                }
                separator(Seperator)
                {
                    Caption = 'Seperator';
                }
                group(Setup)
                {
                    Caption = 'Setup';
                    action("E&xport")
                    {
                        ApplicationArea = All;
                        Caption = 'E&xport';
                        Promoted = true;
                        PromotedCategory = Process;

                        trigger OnAction()
                        begin
                            ExportTestSuiteSetup();
                        end;
                    }
                    action("I&mport")
                    {
                        ApplicationArea = All;
                        Caption = 'I&mport';

                        trigger OnAction()
                        begin
                            ImportTestSuiteSetup();
                        end;
                    }
                }
                separator(Action15)
                {
                    Caption = 'Seperator';
                }
                group(Results)
                {
                    Caption = 'Results';
                    action(Action16)
                    {
                        ApplicationArea = All;
                        Caption = 'E&xport';

                        trigger OnAction()
                        begin
                            ExportTestSuiteResult();
                        end;
                    }
                    action(Action24)
                    {
                        ApplicationArea = All;
                        Caption = 'I&mport';

                        trigger OnAction()
                        begin
                            ImportTestSuiteResult();
                        end;
                    }
                }
            }
        }
    }
}

