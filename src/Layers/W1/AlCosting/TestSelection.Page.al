page 103404 "Test Selection"
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
            field(HeaderText; HeaderText)
            {
                Editable = false;
                Style = Strong;
                StyleExpr = true;
            }
            field(TestLevel; TestLevel)
            {
                OptionCaption = 'All,Selected';

                trigger OnValidate()
                begin
                    if TestLevel = TestLevel::Selected then
                        SelectedTestLevelOnValidate();
                    if TestLevel = TestLevel::All then
                        AllTestLevelOnValidate();
                end;
            }
            field(ShowPassTestCheckBox; ShowAlsoPassTests)
            {
                Caption = 'Show also pass tests';
                Visible = ShowPassTestCheckBoxVisible;
            }
            field(Selection1; Selection[1])
            {
                Editable = Selection1Editable;
                Visible = Selection1Visible;
            }
            field(SelectionText1; SelectionText[1])
            {
                Editable = false;
                Visible = SelectionText1Visible;
            }
            field(Selection2; Selection[2])
            {
                Editable = Selection2Editable;
                Visible = Selection2Visible;
            }
            field(SelectionText2; SelectionText[2])
            {
                Editable = false;
                Visible = SelectionText2Visible;
            }
            field(Selection3; Selection[3])
            {
                Editable = Selection3Editable;
                Visible = Selection3Visible;
            }
            field(SelectionText3; SelectionText[3])
            {
                Editable = false;
                Visible = SelectionText3Visible;
            }
            field(Selection4; Selection[4])
            {
                Editable = Selection4Editable;
                Visible = Selection4Visible;
            }
            field(SelectionText4; SelectionText[4])
            {
                Editable = false;
                Visible = SelectionText4Visible;
            }
            field(Selection5; Selection[5])
            {
                Editable = Selection5Editable;
                Visible = Selection5Visible;
            }
            field(SelectionText5; SelectionText[5])
            {
                Editable = false;
                Visible = SelectionText5Visible;
            }
            field(Selection6; Selection[6])
            {
                Editable = Selection6Editable;
                Visible = Selection6Visible;
            }
            field(SelectionText6; SelectionText[6])
            {
                Editable = false;
                Visible = SelectionText6Visible;
            }
            field(Selection7; Selection[7])
            {
                Editable = Selection7Editable;
                Visible = Selection7Visible;
            }
            field(SelectionText7; SelectionText[7])
            {
                Editable = false;
                Visible = SelectionText7Visible;
            }
            field(Selection8; Selection[8])
            {
                Editable = Selection8Editable;
                Visible = Selection8Visible;
            }
            field(SelectionText8; SelectionText[8])
            {
                Editable = false;
                Visible = SelectionText8Visible;
            }
            field(Selection9; Selection[9])
            {
                Editable = Selection9Editable;
                Visible = Selection9Visible;
            }
            field(SelectionText9; SelectionText[9])
            {
                Editable = false;
                Visible = SelectionText9Visible;
            }
            field(Selection10; Selection[10])
            {
                Editable = Selection10Editable;
                Visible = Selection10Visible;
            }
            field(SelectionText10; SelectionText[10])
            {
                Editable = false;
                Visible = SelectionText10Visible;
            }
            field("Select All"; SelectAction)
            {
                OptionCaption = 'Select All,Unselect All';

                trigger OnValidate()
                begin
                    if SelectAction = SelectAction::"Unselect All" then
                        UnselectAllSelectActionOnValid();
                    if SelectAction = SelectAction::"Select All" then
                        SelectAllSelectActionOnValidat();
                end;
            }
            field(Selection11; Selection[11])
            {
                Editable = Selection11Editable;
                Visible = Selection11Visible;
            }
            field(SelectionText11; SelectionText[11])
            {
                Editable = false;
                Visible = SelectionText11Visible;
            }
            field(Selection12; Selection[12])
            {
                Editable = Selection12Editable;
                Visible = Selection12Visible;
            }
            field(SelectionText12; SelectionText[12])
            {
                Editable = false;
                Visible = SelectionText12Visible;
            }
            field(Selection13; Selection[13])
            {
                Editable = Selection13Editable;
                Visible = Selection13Visible;
            }
            field(SelectionText13; SelectionText[13])
            {
                Editable = false;
                Visible = SelectionText13Visible;
            }
            field(Selection14; Selection[14])
            {
                Editable = Selection14Editable;
                Visible = Selection14Visible;
            }
            field(SelectionText14; SelectionText[14])
            {
                Editable = false;
                Visible = SelectionText14Visible;
            }
            field(Selection15; Selection[15])
            {
                Editable = Selection15Editable;
                Visible = Selection15Visible;
            }
            field(SelectionText15; SelectionText[15])
            {
                Editable = false;
                Visible = SelectionText15Visible;
            }
            field(Selection16; Selection[16])
            {
                Editable = Selection16Editable;
                Visible = Selection16Visible;
            }
            field(SelectionText16; SelectionText[16])
            {
                Editable = false;
                Visible = SelectionText16Visible;
            }
            field(Selection17; Selection[17])
            {
                Editable = Selection17Editable;
                Visible = Selection17Visible;
            }
            field(SelectionText17; SelectionText[17])
            {
                Editable = false;
                Visible = SelectionText17Visible;
            }
            field(Selection18; Selection[18])
            {
                Editable = Selection18Editable;
                Visible = Selection18Visible;
            }
            field(SelectionText18; SelectionText[18])
            {
                Editable = false;
                Visible = SelectionText18Visible;
            }
            field(Selection19; Selection[19])
            {
                Editable = Selection19Editable;
                Visible = Selection19Visible;
            }
            field(SelectionText19; SelectionText[19])
            {
                Editable = false;
                Visible = SelectionText19Visible;
            }
            field(Selection20; Selection[20])
            {
                Editable = Selection20Editable;
                Visible = Selection20Visible;
            }
            field(SelectionText20; SelectionText[20])
            {
                Editable = false;
                Visible = SelectionText20Visible;
            }
            field(Selection21; Selection[21])
            {
                Editable = Selection21Editable;
                Visible = Selection21Visible;
            }
            field(Selection22; Selection[22])
            {
                Editable = Selection22Editable;
                Visible = Selection22Visible;
            }
            field(Selection23; Selection[23])
            {
                Editable = Selection23Editable;
                Visible = Selection23Visible;
            }
            field(Selection24; Selection[24])
            {
                Editable = Selection24Editable;
                Visible = Selection24Visible;
            }
            field(Selection25; Selection[25])
            {
                Editable = Selection25Editable;
                Visible = Selection25Visible;
            }
            field(Selection26; Selection[26])
            {
                Editable = Selection26Editable;
                Visible = Selection26Visible;
            }
            field(SelectionText21; SelectionText[21])
            {
                Editable = false;
                Visible = SelectionText21Visible;
            }
            field(SelectionText22; SelectionText[22])
            {
                Editable = false;
                Visible = SelectionText22Visible;
            }
            field(SelectionText23; SelectionText[23])
            {
                Editable = false;
                Visible = SelectionText23Visible;
            }
            field(SelectionText24; SelectionText[24])
            {
                Editable = false;
                Visible = SelectionText24Visible;
            }
            field(SelectionText25; SelectionText[25])
            {
                Editable = false;
                Visible = SelectionText25Visible;
            }
            field(SelectionText26; SelectionText[26])
            {
                Editable = false;
                Visible = SelectionText26Visible;
            }
            field(Selection27; Selection[27])
            {
                Editable = Selection27Editable;
                Visible = Selection27Visible;
            }
            field(SelectionText27; SelectionText[27])
            {
                Editable = false;
                Visible = SelectionText27Visible;
            }
            field(Selection28; Selection[28])
            {
                Editable = Selection28Editable;
                Visible = Selection28Visible;
            }
            field(SelectionText28; SelectionText[28])
            {
                Editable = false;
                Visible = SelectionText28Visible;
            }
            field(Selection29; Selection[29])
            {
                Editable = Selection29Editable;
                Visible = Selection29Visible;
            }
            field(SelectionText29; SelectionText[29])
            {
                Editable = false;
                Visible = SelectionText29Visible;
            }
            field(Selection30; Selection[30])
            {
                Editable = Selection30Editable;
                Visible = Selection30Visible;
            }
            field(SelectionText30; SelectionText[30])
            {
                Editable = false;
                Visible = SelectionText30Visible;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Selection30Editable := true;
        Selection29Editable := true;
        Selection28Editable := true;
        Selection27Editable := true;
        Selection26Editable := true;
        Selection25Editable := true;
        Selection24Editable := true;
        Selection23Editable := true;
        Selection22Editable := true;
        Selection21Editable := true;
        Selection20Editable := true;
        Selection19Editable := true;
        Selection18Editable := true;
        Selection17Editable := true;
        Selection16Editable := true;
        Selection15Editable := true;
        Selection14Editable := true;
        Selection13Editable := true;
        Selection12Editable := true;
        Selection11Editable := true;
        Selection10Editable := true;
        Selection9Editable := true;
        Selection8Editable := true;
        Selection7Editable := true;
        Selection6Editable := true;
        Selection5Editable := true;
        Selection4Editable := true;
        Selection3Editable := true;
        Selection2Editable := true;
        Selection1Editable := true;
        "Unselect AllVisible" := true;
        "Select AllVisible" := true;
        SelectionText30Visible := true;
        SelectionText29Visible := true;
        SelectionText28Visible := true;
        SelectionText27Visible := true;
        SelectionText26Visible := true;
        SelectionText25Visible := true;
        SelectionText24Visible := true;
        SelectionText23Visible := true;
        SelectionText22Visible := true;
        SelectionText21Visible := true;
        SelectionText20Visible := true;
        SelectionText19Visible := true;
        SelectionText18Visible := true;
        SelectionText17Visible := true;
        SelectionText16Visible := true;
        SelectionText15Visible := true;
        SelectionText14Visible := true;
        SelectionText13Visible := true;
        SelectionText12Visible := true;
        SelectionText11Visible := true;
        SelectionText10Visible := true;
        SelectionText9Visible := true;
        SelectionText8Visible := true;
        SelectionText7Visible := true;
        SelectionText6Visible := true;
        SelectionText5Visible := true;
        SelectionText4Visible := true;
        SelectionText3Visible := true;
        SelectionText2Visible := true;
        SelectionText1Visible := true;
        Selection30Visible := true;
        Selection29Visible := true;
        Selection28Visible := true;
        Selection27Visible := true;
        Selection26Visible := true;
        Selection25Visible := true;
        Selection24Visible := true;
        Selection23Visible := true;
        Selection22Visible := true;
        Selection21Visible := true;
        Selection20Visible := true;
        Selection19Visible := true;
        Selection18Visible := true;
        Selection17Visible := true;
        Selection16Visible := true;
        Selection15Visible := true;
        Selection14Visible := true;
        Selection13Visible := true;
        Selection12Visible := true;
        Selection11Visible := true;
        Selection10Visible := true;
        Selection9Visible := true;
        Selection8Visible := true;
        Selection7Visible := true;
        Selection6Visible := true;
        Selection5Visible := true;
        Selection4Visible := true;
        Selection3Visible := true;
        Selection2Visible := true;
        Selection1Visible := true;
        ShowPassTestLabelVisible := true;
        ShowPassTestCheckBoxVisible := true;
    end;

    trigger OnOpenPage()
    begin
        SetVisible();
        SetEditable(false);
        SetSelected(true);
    end;

    var
        TestLevel: Option All,Selected;
        Selection: array[50] of Boolean;
        SelectionText: array[50] of Text[100];
        i: Integer;
        ShowAlsoPassTests: Boolean;
        HeaderText: Text[100];
        SelectAction: Option "Select All","Unselect All";
        ShowPassTestCheckBoxVisible: Boolean;
        ShowPassTestLabelVisible: Boolean;
        Selection1Visible: Boolean;
        Selection2Visible: Boolean;
        Selection3Visible: Boolean;
        Selection4Visible: Boolean;
        Selection5Visible: Boolean;
        Selection6Visible: Boolean;
        Selection7Visible: Boolean;
        Selection8Visible: Boolean;
        Selection9Visible: Boolean;
        Selection10Visible: Boolean;
        Selection11Visible: Boolean;
        Selection12Visible: Boolean;
        Selection13Visible: Boolean;
        Selection14Visible: Boolean;
        Selection15Visible: Boolean;
        Selection16Visible: Boolean;
        Selection17Visible: Boolean;
        Selection18Visible: Boolean;
        Selection19Visible: Boolean;
        Selection20Visible: Boolean;
        Selection21Visible: Boolean;
        Selection22Visible: Boolean;
        Selection23Visible: Boolean;
        Selection24Visible: Boolean;
        Selection25Visible: Boolean;
        Selection26Visible: Boolean;
        Selection27Visible: Boolean;
        Selection28Visible: Boolean;
        Selection29Visible: Boolean;
        Selection30Visible: Boolean;
        SelectionText1Visible: Boolean;
        SelectionText2Visible: Boolean;
        SelectionText3Visible: Boolean;
        SelectionText4Visible: Boolean;
        SelectionText5Visible: Boolean;
        SelectionText6Visible: Boolean;
        SelectionText7Visible: Boolean;
        SelectionText8Visible: Boolean;
        SelectionText9Visible: Boolean;
        SelectionText10Visible: Boolean;
        SelectionText11Visible: Boolean;
        SelectionText12Visible: Boolean;
        SelectionText13Visible: Boolean;
        SelectionText14Visible: Boolean;
        SelectionText15Visible: Boolean;
        SelectionText16Visible: Boolean;
        SelectionText17Visible: Boolean;
        SelectionText18Visible: Boolean;
        SelectionText19Visible: Boolean;
        SelectionText20Visible: Boolean;
        SelectionText21Visible: Boolean;
        SelectionText22Visible: Boolean;
        SelectionText23Visible: Boolean;
        SelectionText24Visible: Boolean;
        SelectionText25Visible: Boolean;
        SelectionText26Visible: Boolean;
        SelectionText27Visible: Boolean;
        SelectionText28Visible: Boolean;
        SelectionText29Visible: Boolean;
        SelectionText30Visible: Boolean;
        "Select AllVisible": Boolean;
        "Unselect AllVisible": Boolean;
        Selection1Editable: Boolean;
        Selection2Editable: Boolean;
        Selection3Editable: Boolean;
        Selection4Editable: Boolean;
        Selection5Editable: Boolean;
        Selection6Editable: Boolean;
        Selection7Editable: Boolean;
        Selection8Editable: Boolean;
        Selection9Editable: Boolean;
        Selection10Editable: Boolean;
        Selection11Editable: Boolean;
        Selection12Editable: Boolean;
        Selection13Editable: Boolean;
        Selection14Editable: Boolean;
        Selection15Editable: Boolean;
        Selection16Editable: Boolean;
        Selection17Editable: Boolean;
        Selection18Editable: Boolean;
        Selection19Editable: Boolean;
        Selection20Editable: Boolean;
        Selection21Editable: Boolean;
        Selection22Editable: Boolean;
        Selection23Editable: Boolean;
        Selection24Editable: Boolean;
        Selection25Editable: Boolean;
        Selection26Editable: Boolean;
        Selection27Editable: Boolean;
        Selection28Editable: Boolean;
        Selection29Editable: Boolean;
        Selection30Editable: Boolean;
        Text666: Label '%1 is not a valid selection.';

    [Scope('OnPrem')]
    procedure SetSelection(NewSelectionText: array[50] of Text[100]; NewShowAlsoPassTests: Boolean; NewUseCaseNo: Integer; NewHeaderText: Text[100])
    begin
        for i := 1 to ArrayLen(Selection) do
            SelectionText[i] := NewSelectionText[i];
        ShowAlsoPassTests := NewShowAlsoPassTests;
        HeaderText := NewHeaderText;
        ShowPassTestCheckBoxVisible := NewUseCaseNo = 0;
        ShowPassTestLabelVisible := NewUseCaseNo = 0;
    end;

    [Scope('OnPrem')]
    procedure GetSelection(var NewTestLevel: Option All,Selected; var NewSelection: array[50] of Boolean; var NewShowAlsoPassTests: Boolean)
    begin
        for i := 1 to ArrayLen(Selection) do
            NewSelection[i] := Selection[i];
        NewShowAlsoPassTests := ShowAlsoPassTests;
        NewTestLevel := TestLevel;
    end;

    [Scope('OnPrem')]
    procedure SetVisible()
    begin
        Selection1Visible := SelectionText[1] <> '';
        Selection2Visible := SelectionText[2] <> '';
        Selection3Visible := SelectionText[3] <> '';
        Selection4Visible := SelectionText[4] <> '';
        Selection5Visible := SelectionText[5] <> '';
        Selection6Visible := SelectionText[6] <> '';
        Selection7Visible := SelectionText[7] <> '';
        Selection8Visible := SelectionText[8] <> '';
        Selection9Visible := SelectionText[9] <> '';
        Selection10Visible := SelectionText[10] <> '';
        Selection11Visible := SelectionText[11] <> '';
        Selection12Visible := SelectionText[12] <> '';
        Selection13Visible := SelectionText[13] <> '';
        Selection14Visible := SelectionText[14] <> '';
        Selection15Visible := SelectionText[15] <> '';
        Selection16Visible := SelectionText[16] <> '';
        Selection17Visible := SelectionText[17] <> '';
        Selection18Visible := SelectionText[18] <> '';
        Selection19Visible := SelectionText[19] <> '';
        Selection20Visible := SelectionText[20] <> '';
        Selection21Visible := SelectionText[21] <> '';
        Selection22Visible := SelectionText[22] <> '';
        Selection23Visible := SelectionText[23] <> '';
        Selection24Visible := SelectionText[24] <> '';
        Selection25Visible := SelectionText[25] <> '';
        Selection26Visible := SelectionText[26] <> '';
        Selection27Visible := SelectionText[27] <> '';
        Selection28Visible := SelectionText[28] <> '';
        Selection29Visible := SelectionText[29] <> '';
        Selection30Visible := SelectionText[30] <> '';

        SelectionText1Visible := SelectionText[1] <> '';
        SelectionText2Visible := SelectionText[2] <> '';
        SelectionText3Visible := SelectionText[3] <> '';
        SelectionText4Visible := SelectionText[4] <> '';
        SelectionText5Visible := SelectionText[5] <> '';
        SelectionText6Visible := SelectionText[6] <> '';
        SelectionText7Visible := SelectionText[7] <> '';
        SelectionText8Visible := SelectionText[8] <> '';
        SelectionText9Visible := SelectionText[9] <> '';
        SelectionText10Visible := SelectionText[10] <> '';
        SelectionText11Visible := SelectionText[11] <> '';
        SelectionText12Visible := SelectionText[12] <> '';
        SelectionText13Visible := SelectionText[13] <> '';
        SelectionText14Visible := SelectionText[14] <> '';
        SelectionText15Visible := SelectionText[15] <> '';
        SelectionText16Visible := SelectionText[16] <> '';
        SelectionText17Visible := SelectionText[17] <> '';
        SelectionText18Visible := SelectionText[18] <> '';
        SelectionText19Visible := SelectionText[19] <> '';
        SelectionText20Visible := SelectionText[20] <> '';
        SelectionText21Visible := SelectionText[21] <> '';
        SelectionText22Visible := SelectionText[22] <> '';
        SelectionText23Visible := SelectionText[23] <> '';
        SelectionText24Visible := SelectionText[24] <> '';
        SelectionText25Visible := SelectionText[25] <> '';
        SelectionText26Visible := SelectionText[26] <> '';
        SelectionText27Visible := SelectionText[27] <> '';
        SelectionText28Visible := SelectionText[28] <> '';
        SelectionText29Visible := SelectionText[29] <> '';
        SelectionText30Visible := SelectionText[30] <> '';
    end;

    [Scope('OnPrem')]
    procedure SetEditable(NewEditable: Boolean)
    begin
        Selection1Editable := NewEditable and (SelectionText[1] <> '');
        Selection2Editable := NewEditable and (SelectionText[2] <> '');
        Selection3Editable := NewEditable and (SelectionText[3] <> '');
        Selection4Editable := NewEditable and (SelectionText[4] <> '');
        Selection5Editable := NewEditable and (SelectionText[5] <> '');
        Selection6Editable := NewEditable and (SelectionText[6] <> '');
        Selection7Editable := NewEditable and (SelectionText[7] <> '');
        Selection8Editable := NewEditable and (SelectionText[8] <> '');
        Selection9Editable := NewEditable and (SelectionText[9] <> '');
        Selection10Editable := NewEditable and (SelectionText[10] <> '');
        Selection11Editable := NewEditable and (SelectionText[11] <> '');
        Selection12Editable := NewEditable and (SelectionText[12] <> '');
        Selection13Editable := NewEditable and (SelectionText[13] <> '');
        Selection14Editable := NewEditable and (SelectionText[14] <> '');
        Selection15Editable := NewEditable and (SelectionText[15] <> '');
        Selection16Editable := NewEditable and (SelectionText[16] <> '');
        Selection17Editable := NewEditable and (SelectionText[17] <> '');
        Selection18Editable := NewEditable and (SelectionText[18] <> '');
        Selection19Editable := NewEditable and (SelectionText[19] <> '');
        Selection20Editable := NewEditable and (SelectionText[20] <> '');
        Selection21Editable := NewEditable and (SelectionText[21] <> '');
        Selection22Editable := NewEditable and (SelectionText[22] <> '');
        Selection23Editable := NewEditable and (SelectionText[23] <> '');
        Selection24Editable := NewEditable and (SelectionText[24] <> '');
        Selection25Editable := NewEditable and (SelectionText[25] <> '');
        Selection26Editable := NewEditable and (SelectionText[26] <> '');
        Selection27Editable := NewEditable and (SelectionText[27] <> '');
        Selection28Editable := NewEditable and (SelectionText[28] <> '');
        Selection29Editable := NewEditable and (SelectionText[29] <> '');
        Selection30Editable := NewEditable and (SelectionText[30] <> '');

        "Select AllVisible" := NewEditable;
        "Unselect AllVisible" := NewEditable;
    end;

    [Scope('OnPrem')]
    procedure SetSelected(Selected: Boolean)
    begin
        for i := 1 to ArrayLen(Selection) do
            Selection[i] := Selected;
    end;

    local procedure AllTestLevelOnPush()
    begin
        SetEditable(false);
        SetSelected(true);
        SelectAction := SelectAction::"Select All";
    end;

    local procedure SelectedTestLevelOnPush()
    begin
        SetEditable(true);
        SetSelected(true);
        SelectAction := SelectAction::"Select All";
    end;

    local procedure SelectAllSelectActionOnPush()
    begin
        SetSelected(true);
    end;

    local procedure UnselectAllSelectActionOnPush()
    begin
        SetSelected(false);
    end;

    local procedure AllTestLevelOnValidate()
    begin
        AllTestLevelOnPush();
    end;

    local procedure SelectedTestLevelOnValidate()
    begin
        SelectedTestLevelOnPush();
    end;

    local procedure SelectAllSelectActionOnValidat()
    begin
        if not "Select AllVisible" then
            Error(Text666, SelectAction);
        SelectAllSelectActionOnPush();
    end;

    local procedure UnselectAllSelectActionOnValid()
    begin
        if not "Unselect AllVisible" then
            Error(Text666, SelectAction);
        UnselectAllSelectActionOnPush();
    end;
}

