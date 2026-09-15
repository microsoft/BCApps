page 103225 "WMS QA Menu"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    PageType = Card;

    layout
    {
        area(content)
        {
        }
    }

    actions
    {
        area(processing)
        {
            action("Use Cases")
            {
                Caption = 'Use Cases';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Whse. Use Case";
            }
            action("Test Cases")
            {
                Caption = 'Test Cases';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Whse. Test Case";
            }
            action("Copy Reference Data")
            {
                Caption = 'Copy Reference Data';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Whse. Copy Reference Data";
            }
            action("Create Reference Mgmt")
            {
                Caption = 'Create Reference Mgmt';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "WMS Create Reference Mgt";
            }
            action("Create Use Cases")
            {
                Caption = 'Create Use Cases';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CODEUNIT.Run(CODEUNIT::"WMS TestSetupManagement");
                end;
            }
            action("Delete QA Tables")
            {
                Caption = 'Delete QA Tables';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TestscriptMgmt: Codeunit "WMS TestscriptManagement";
                begin
                    TestscriptMgmt.DeleteQATables(true);
                end;
            }
            action("WMS Set Global Preconditions")
            {
                Caption = 'WMS Set Global Preconditions';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "WMS Set Global Preconditions";
            }
            action("Run Testscript")
            {
                Caption = 'Run Testscript';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "WMS Testscript";
            }
            action("Show Test Results")
            {
                Caption = 'Show Test Results';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Whse. Testscript Results";
            }
            action("Test Log")
            {
                Caption = 'Test Log';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Whse. Test Log";

                trigger OnAction()
                var
                    WhseTestLog: Report "Whse. Test Log";
                begin
                    Clear(WhseTestLog);
                    WhseTestLog.SetProjectCode('WMS');
                    WhseTestLog.RunModal();
                end;
            }
            action(Setup)
            {
                Caption = 'Setup';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Whse. QA Setup";
            }
        }
    }
}

