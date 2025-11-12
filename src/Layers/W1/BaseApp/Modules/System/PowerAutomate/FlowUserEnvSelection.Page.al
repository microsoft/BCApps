namespace System.Automation;

#if not CLEAN25
page 6416 "Flow User Env. Selection"
{
    Caption = 'Power Automate User Environment Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Flow User Environment Buffer";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality has been moved to Automate Environment Picker.';
    ObsoleteTag = '25.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Environment Display Name"; Rec."Environment Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Environment Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the environment.';

                    trigger OnDrillDown()
                    begin
                        EnsureOnlyOneSelection();
                    end;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';

                    trigger OnValidate()
                    begin
                        EnsureOnlyOneSelection();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if Rec.IsEmpty() then
            Error(FlowServiceManagement.GetGenericError());

        SortByEnvironmentNameAscending();
        Rec.FindFirst();
    end;

    var
        FlowServiceManagement: Codeunit "Flow Service Management";

    local procedure EnsureOnlyOneSelection()
    begin
        Rec.SetRange(Enabled, true);
        if Rec.Count >= 1 then
            Rec.ModifyAll(Enabled, false);

        Rec.Reset();
        Rec.Enabled := true;

        SortByEnvironmentNameAscending();
        CurrPage.Update();
    end;

    procedure SetFlowEnvironmentBuffer(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    begin
        // clear current REC and shallow copy TempFlowUserEnvironmentBuffer to it
        // ShareTable = TRUE and so since both TempFlowUserEnvironmentBuffer and Rec are temporary, COPY function causes Rec to reference the same
        // table as TempFlowUserEnvironmentBuffer. And so any changes to REC happens to TempFlowUserEnvironmentBuffer

        Rec.DeleteAll();
        Rec.Copy(TempFlowUserEnvironmentBuffer, true);
        Rec.Reset();
    end;

    local procedure SortByEnvironmentNameAscending()
    begin
        Rec.SetCurrentKey("Environment Display Name");
        Rec.SetAscending("Environment Display Name", true);
    end;
}
#endif
