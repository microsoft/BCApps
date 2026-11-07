page 130024 "Get Test Codeunits"
{
    Editable = false;
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                }
                field("Object Caption"; "Object Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Feature Tags';
                    Visible = ShowFeatureTags;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ShowFeatureTags := TestSuite."Show Test Details";
        Load();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            CreateLines();
    end;

    var
        TestSuite: Record "Test Suite";
        ShowFeatureTags: Boolean;

    [Scope('OnPrem')]
    procedure CreateLines()
    var
        TestMgt: Codeunit "Test Management";
    begin
        CurrPage.SetSelectionFilter(Rec);
        TestMgt.AddTestCodeunits(TestSuite, Rec);
    end;

    [Scope('OnPrem')]
    procedure SetTestSuite(NewTestSuite: Record "Test Suite")
    begin
        TestSuite := NewTestSuite;
    end;

    local procedure Load()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TagCodeCoverage: Record "Code Coverage" temporary;
        TestLine: Record "Test Line";
        TestManagement: Codeunit "Test Management";
        Window: Dialog;
    begin
        DeleteAll();
        if ShowFeatureTags then
            Window.Open('#1##########\#2####################');
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object Subtype", 'Test');
        if AllObjWithCaption.FindSet() then begin
            repeat
                Rec := AllObjWithCaption;
                if ShowFeatureTags then begin
                    "Object Caption" := '';
                    if not TestManagement.IsOnRunTriggerRead("Object ID") then
                        TestManagement.ReadCALCode("Object ID", true);
                    if TestManagement.FindCALCodeLine("Object ID", 'OnRun', TagCodeCoverage) then
                        TestLine.GetFeatureTags(TagCodeCoverage, "Object Caption");
                    Window.Update(1, "Object ID");
                    Window.Update(2, "Object Caption");
                end;
                Insert();
            until AllObjWithCaption.Next() = 0;
            FindFirst();
        end;
        if ShowFeatureTags then
            Window.Close();
    end;
}

