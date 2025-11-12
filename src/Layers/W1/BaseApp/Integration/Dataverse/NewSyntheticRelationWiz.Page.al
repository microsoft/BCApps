// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;
using System.Reflection;
using System.Utilities;
using System.Environment;

page 5374 "New Synthetic Relation Wiz."
{
    PageType = NavigatePage;
    Caption = 'New Synthetic Relation';
    SourceTable = "Synth. Relation Mapping Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(BannerStandard)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and (Step <> 3);
                field(MediaResourceStandardReference; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(BannerDone)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and (Step = 3);
                field(MediaResourceDoneReference; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step0)
            {
                Visible = Step = 0;
                ShowCaption = false;
                field(NativeDataverseTable; TempSyntheticRelationToCreate."Syncd. Table Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Native Dataverse Table';
                    ToolTip = 'Specifies the native Dataverse table that will be used to create the relation.';
                    AssistEdit = true;
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        TempNativeDataverseTableSelected, TempSynthRelationMappingBuffer : Record "Synth. Relation Mapping Buffer" temporary;
                        SynthRelationMapping: Page "Synth. Relation Mapping";
                        LookedUp: Boolean;
                    begin
                        SyntheticRelations.GetSynchedIntegrationTables(TempSynthRelationMappingBuffer);
                        SynthRelationMapping.SetSelectingNativeTables();
                        LookedUp := TablesAndFieldsLookup(SynthRelationMapping, TempSynthRelationMappingBuffer, TempNativeDataverseTableSelected);
                        if not LookedUp then
                            exit;
                        TempSyntheticRelationToCreate."Syncd. Table Name" := TempNativeDataverseTableSelected."Syncd. Table Name";
                        TempSyntheticRelationToCreate."Syncd. Table External Name" := TempNativeDataverseTableSelected."Syncd. Table External Name";
                        TempSyntheticRelationToCreate."Syncd. Table Id" := TempNativeDataverseTableSelected."Syncd. Table Id";
                        SetNextActionEnabled();
                    end;
                }
                field(VirtualDataverseTable; TempSyntheticRelationToCreate."Virtual Table Caption")
                {
                    ApplicationArea = Suite;
                    Caption = 'Virtual Dataverse Table';
                    ToolTip = 'Specifies the virtual Dataverse table that will be used to create the relation.';
                    AssistEdit = true;
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        TempVirtualDataverseTableSelected, TempSynthRelationMappingBuffer : Record "Synth. Relation Mapping Buffer" temporary;
                        SynthRelationMapping: Page "Synth. Relation Mapping";
                        PageId: Integer;
                        LookedUp: Boolean;
                    begin
                        SyntheticRelations.LoadVisibleVirtualTables(TempSynthRelationMappingBuffer);
                        SynthRelationMapping.SetSelectingVirtualTables();
                        LookedUp := TablesAndFieldsLookup(SynthRelationMapping, TempSynthRelationMappingBuffer, TempVirtualDataverseTableSelected);
                        if not LookedUp then
                            exit;
                        TempSyntheticRelationToCreate."Virtual Table Caption" := TempVirtualDataverseTableSelected."Virtual Table Caption";
                        TempSyntheticRelationToCreate."Virtual Table Logical Name" := TempVirtualDataverseTableSelected."Virtual Table Logical Name";
                        PageId := SyntheticRelations.TryToGetVirtualTableAPIPageId(TempVirtualDataverseTableSelected);
                        if PageId <> 0 then
                            TempSyntheticRelationToCreate."Virtual Table API Page Id" := PageId;
                        SetNextActionEnabled();
                    end;
                }
                group(AdvancedStep0)
                {
                    Caption = 'Advanced';
                    Visible = ShowingAdvanced;
                    field("Virtual Table API Page Id"; TempSyntheticRelationToCreate."Virtual Table API Page Id")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Virtual Table API Page Id';
                        ToolTip = 'For the selected virtual table, specifies the API page that will be used to browse the related fields.';
                        DrillDown = true;

                        trigger OnDrillDown()
                        var
                            TempSynthRelationMappingBuffer, TempSelectedApiPage : Record "Synth. Relation Mapping Buffer" temporary;
                            SynthRelationMapping: Page "Synth. Relation Mapping";
                            LookedUp: Boolean;
                        begin
                            SyntheticRelations.GetAllAPIPages(TempSynthRelationMappingBuffer);
                            SynthRelationMapping.SetSelectingVirtualTablePageId();
                            LookedUp := TablesAndFieldsLookup(SynthRelationMapping, TempSynthRelationMappingBuffer, TempSelectedApiPage);
                            if not LookedUp then
                                exit;
                            TempSyntheticRelationToCreate."Virtual Table API Page Id" := TempSelectedApiPage."Virtual Table API Page Id";
                            SetNextActionEnabled();
                        end;

                        trigger OnValidate()
                        var
                            PageMetadata: Record "Page Metadata";
                        begin
                            if TempSyntheticRelationToCreate."Virtual Table API Page Id" = 0 then begin
                                SetNextActionEnabled();
                                exit;
                            end;

                            PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
                            PageMetadata.SetRange(ID, TempSyntheticRelationToCreate."Virtual Table API Page Id");
                            if PageMetadata.IsEmpty() then
                                Error(NoApiPageFoundWithThatIDErr);
                            SetNextActionEnabled();
                        end;
                    }
                }
            }
            group(Step1)
            {
                Visible = Step = 1;
                ShowCaption = false;
                label(FieldsMatchingInstructions)
                {
                    ApplicationArea = Suite;
                    CaptionClass = YouShouldSpecifyBothFieldsMsg;
                }
                field(NFieldsMatching; NFieldsMatching)
                {
                    ApplicationArea = Suite;
                    Caption = 'How many fields connect the tables?';
                    ToolTip = 'Specifies the number of fields in the native and virtual tables that will be used to create the relation.';
                    OptionCaption = '1,2,3';

                    trigger OnValidate()
                    begin
                        ResetFieldsMapping();
                    end;
                }
                repeater(FieldsToMatch)
                {
                    field("Syncd. Field 1 Name"; Rec."Syncd. Field 1 Name")
                    {
                        ApplicationArea = Suite;
                        CaptionClass = NativeDataverseFieldCaption;
                        ToolTip = 'Specifies the column in the native Dataverse table that will be used to create the relation.';
                        AssistEdit = true;
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            TempNativeDataverseFieldSelected, TempSynthRelationMappingBuffer : Record "Synth. Relation Mapping Buffer" temporary;
                            SynthRelationMapping: Page "Synth. Relation Mapping";
                            LookedUp: Boolean;
                        begin
                            SyntheticRelations.GetSynchedIntegrationFields(TempSynthRelationMappingBuffer, TempSyntheticRelationToCreate);
                            SynthRelationMapping.SetSelectingNativeFields();
                            LookedUp := TablesAndFieldsLookup(SynthRelationMapping, TempSynthRelationMappingBuffer, TempNativeDataverseFieldSelected);
                            if not LookedUp then
                                exit;
                            case Rec."Syncd. Table Id" of
                                NFieldsMatching::"1":
                                    SetSelectedNativeField(TempSyntheticRelationToCreate."Syncd. Field 1 Name", TempSyntheticRelationToCreate."Syncd. Field 1 Id", TempSyntheticRelationToCreate."Syncd. Field 1 External Name", TempNativeDataverseFieldSelected);
                                NFieldsMatching::"2":
                                    SetSelectedNativeField(TempSyntheticRelationToCreate."Syncd. Field 2 Name", TempSyntheticRelationToCreate."Syncd. Field 2 Id", TempSyntheticRelationToCreate."Syncd. Field 2 External Name", TempNativeDataverseFieldSelected);
                                NFieldsMatching::"3":
                                    SetSelectedNativeField(TempSyntheticRelationToCreate."Syncd. Field 3 Name", TempSyntheticRelationToCreate."Syncd. Field 3 Id", TempSyntheticRelationToCreate."Syncd. Field 3 External Name", TempNativeDataverseFieldSelected);
                            end;
                            Rec."Syncd. Field 1 Name" := TempNativeDataverseFieldSelected."Syncd. Field 1 Name";
                            SetNextActionEnabled();
                        end;

                    }
                    field("Virtual Table Column 1 Name"; Rec."Virtual Table Column 1 Caption")
                    {
                        ApplicationArea = Suite;
                        CaptionClass = VirtualDataverseFieldCaption;
                        Tooltip = 'Specifies the column in the virtual Dataverse table that will be used to create the relation. This must be the logical name of the Dataverse virtual table''s column.';
                        AssistEdit = true;
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            TempVirtualDataverseFieldSelected, TempSynthRelationMappingBuffer : Record "Synth. Relation Mapping Buffer" temporary;
                            SynthRelationMapping: Page "Synth. Relation Mapping";
                            VirtualTableColumnName: Text[100];
                            LookedUp: Boolean;
                        begin
                            SyntheticRelations.GetVirtualTableFields(TempSynthRelationMappingBuffer, TempSyntheticRelationToCreate);
                            SynthRelationMapping.SetSelectingVirtualFields();
                            LookedUp := TablesAndFieldsLookup(SynthRelationMapping, TempSynthRelationMappingBuffer, TempVirtualDataverseFieldSelected);
                            if not LookedUp then
                                exit;
                            VirtualTableColumnName := SyntheticRelations.GetLogicalNameFromAPIPhysicalName(TempVirtualDataverseFieldSelected."Virtual Table Column 1 Name");
                            case Rec."Syncd. Table Id" of
                                NFieldsMatching::"1":
                                    SetSelectedVirtualField(TempSyntheticRelationToCreate."Virtual Table Column 1 Name", TempSyntheticRelationToCreate."Virtual Table Column 1 Caption", VirtualTableColumnName);
                                NFieldsMatching::"2":
                                    SetSelectedVirtualField(TempSyntheticRelationToCreate."Virtual Table Column 2 Name", TempSyntheticRelationToCreate."Virtual Table Column 2 Caption", VirtualTableColumnName);
                                NFieldsMatching::"3":
                                    SetSelectedVirtualField(TempSyntheticRelationToCreate."Virtual Table Column 3 Name", TempSyntheticRelationToCreate."Virtual Table Column 3 Caption", VirtualTableColumnName);
                            end;
                            Rec."Virtual Table Column 1 Caption" := VirtualTableColumnName;
                            SetNextActionEnabled();
                        end;
                    }
                }
            }
            group(Step2)
            {
                Visible = Step = 2;
                ShowCaption = false;
                label(CreatingKeyTxt)
                {
                    ApplicationArea = Suite;
                    Caption = 'We couldn''t find a key for the selected columns of the native Dataverse table selected. A key is being created. Use the action "Refresh" to update the status.';
                }
            }
            group(Step3)
            {
                Visible = Step = 3;
                ShowCaption = false;
                label(ConfirmationTxt)
                {
                    ApplicationArea = Suite;
                    CaptionClass = Confirmation;
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(Finish)
            {
                ApplicationArea = Suite;
                Caption = 'Finish';
                Tooltip = 'Finish the creation of the synthetic relation.';
                Image = NextRecord;
                Visible = Step = 3;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Sleep(5000);
                    SyntheticRelations.CreateSyntheticRelation(TempSyntheticRelationToCreate, NativeTableKey);
                    CurrPage.Close();
                end;
            }
            action(Next)
            {
                ApplicationArea = Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                Visible = Step < 3;
                trigger OnAction()
                begin
                    NextPage();
                    SetNextActionEnabled();
                end;
            }
            action(Back)
            {
                ApplicationArea = Suite;
                Caption = 'Back';
                Visible = Step > 0;
                InFooterBar = true;
                Image = PreviousRecord;
                trigger OnAction()
                begin
                    PreviousPage();
                    SetNextActionEnabled();
                end;
            }
            action(ShowAdvanced)
            {
                ApplicationArea = Suite;
                Caption = 'Advanced';
                Visible = Step = 0;
                Image = Setup;
                InFooterBar = true;
                ToolTip = 'Show advanced settings.';

                trigger OnAction()
                begin
                    ShowingAdvanced := not ShowingAdvanced;
                end;
            }
            action(Refresh)
            {
                ApplicationArea = Suite;
                Caption = 'Refresh';
                Visible = Step = 2;
                InFooterBar = true;
                Image = Refresh;
                trigger OnAction()
                var
                    ExistingKeyNames: List of [Text];
                    NativeFields: array[3] of Text[100];
                    ExistingKeyName: Text[100];
                begin
                    NativeFields[1] := TempSyntheticRelationToCreate."Syncd. Field 1 External Name";
                    NativeFields[2] := TempSyntheticRelationToCreate."Syncd. Field 2 External Name";
                    NativeFields[3] := TempSyntheticRelationToCreate."Syncd. Field 3 External Name";
                    if SyntheticRelations.GetExistingAlternateKeyName(TempSyntheticRelationToCreate."Syncd. Table External Name", NativeFields, ExistingKeyName, ExistingKeyNames) then begin
                        NextActionEnabled := true;
                        NativeTableKey := ExistingKeyName;
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        ResetFieldsMapping();
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        TempSyntheticRelationToCreate, TempExistingBCTableRelations : Record "Synth. Relation Mapping Buffer" temporary;
        SyntheticRelations: Codeunit "Synthetic Relations";
        ClientTypeManagement: Codeunit "Client Type Management";
        NFieldsMatching: Option "1","2","3";
        NativeTableKey: Text[100];
        NativeDataverseFieldCaption, VirtualDataverseFieldCaption : Text;
        Confirmation: Text;
        Step: Integer;
        TopBannerVisible: Boolean;
        NextActionEnabled: Boolean;
        ShowingAdvanced: Boolean;
        FieldInTableLbl: Label 'Field in the "%1" table', Comment = '%1 - table name';
        YouShouldSpecifyBothFieldsMsg: Label 'Specify which columns in the native table and virtual table must match to create a relation between them.';
        FinalizeConfirmTxt: Label 'A synthetic relation between the native table "%1" and the virtual table "%2" will be created. ', Comment = '%1 - native table name, %2 - virtual table name';
        SyntheticRelationExistsErr: Label 'A synthetic relation between the native table "%1" and the virtual table "%2" already exists.', Comment = '%1 - native table name, %2 - virtual table name';
        NoApiPageFoundWithThatIDErr: Label 'No API page found in Business Central with the specified ID. Please specify a valid API page ID.';

    internal procedure SetExistingBCTableRelations(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer")
    begin
        if not TempSynthRelationMappingBuffer.FindSet() then
            exit;
        TempExistingBCTableRelations.DeleteAll();
        repeat
            TempExistingBCTableRelations := TempSynthRelationMappingBuffer;
            TempExistingBCTableRelations.Insert();
        until TempSynthRelationMappingBuffer.Next() = 0;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    local procedure TablesAndFieldsLookup(var SynthRelationMapping: Page "Synth. Relation Mapping"; var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary; var SelectedSynthRelationMapping: Record "Synth. Relation Mapping Buffer"): Boolean
    begin
        SynthRelationMapping.SetTables(TempSynthRelationMappingBuffer);
        SynthRelationMapping.LookupMode(true);
        if SynthRelationMapping.RunModal() <> Action::LookupOK then
            exit(false);
        SynthRelationMapping.GetSelectedTable(TempSynthRelationMappingBuffer);
        SelectedSynthRelationMapping := TempSynthRelationMappingBuffer;
        exit(true);
    end;

    local procedure ResetFieldsMapping()
    begin
        TempSyntheticRelationToCreate."Syncd. Field 1 Name" := '';
        TempSyntheticRelationToCreate."Syncd. Field 1 Id" := 0;
        TempSyntheticRelationToCreate."Syncd. Field 1 External Name" := '';
        TempSyntheticRelationToCreate."Virtual Table Column 1 Caption" := '';
        TempSyntheticRelationToCreate."Virtual Table Column 1 Name" := '';
        TempSyntheticRelationToCreate."Syncd. Field 2 Name" := '';
        TempSyntheticRelationToCreate."Syncd. Field 2 Id" := 0;
        TempSyntheticRelationToCreate."Syncd. Field 2 External Name" := '';
        TempSyntheticRelationToCreate."Virtual Table Column 2 Caption" := '';
        TempSyntheticRelationToCreate."Virtual Table Column 2 Name" := '';
        TempSyntheticRelationToCreate."Syncd. Field 3 Name" := '';
        TempSyntheticRelationToCreate."Syncd. Field 3 Id" := 0;
        TempSyntheticRelationToCreate."Syncd. Field 3 External Name" := '';
        TempSyntheticRelationToCreate."Virtual Table Column 3 Caption" := '';
        TempSyntheticRelationToCreate."Virtual Table Column 3 Name" := '';
        Rec.DeleteAll();
        Clear(Rec);

        Rec."Syncd. Table Id" := NFieldsMatching::"1";
        Rec.Insert();
        Rec."Syncd. Table Id" := NFieldsMatching::"2";
        if (NFieldsMatching = NFieldsMatching::"2") or (NFieldsMatching = NFieldsMatching::"3") then
            Rec.Insert();
        Rec."Syncd. Table Id" := NFieldsMatching::"3";
        if NFieldsMatching = NFieldsMatching::"3" then
            Rec.Insert();
    end;

    local procedure SetSelectedNativeField(var SyncdFieldName: Text[80]; var SyncdFieldId: Integer; var SyncdFieldExternalName: Text[100]; TempNativeDataverseFieldSelected: Record "Synth. Relation Mapping Buffer" temporary)
    begin
        SyncdFieldName := TempNativeDataverseFieldSelected."Syncd. Field 1 Name";
        SyncdFieldId := TempNativeDataverseFieldSelected."Syncd. Field 1 Id";
        SyncdFieldExternalName := TempNativeDataverseFieldSelected."Syncd. Field 1 External Name";
    end;

    local procedure SetSelectedVirtualField(var VirtualTableColumnName: Text[100]; var VirtualTableColumnCaption: Text[200]; NewVirtualTableColumnName: Text[100])
    begin
        VirtualTableColumnName := NewVirtualTableColumnName;
        VirtualTableColumnCaption := NewVirtualTableColumnName;
    end;

    local procedure PreviousPage()
    begin
        if Step <= 0 then begin
            Step := 0;
            exit;
        end;
        Step -= 1;
        if Step = 2 then
            Step -= 1;
    end;

    local procedure NextPage()
    var
        NativeFields: array[3] of Text[100];
        ExistingKeyNames: List of [Text];
        ExistingKeyName: Text[100];
    begin
        if not NextActionEnabled then
            exit;
        case Step of
            0:
                begin
                    if not SelectedRelationDoesntExist() then
                        Error(SyntheticRelationExistsErr, TempSyntheticRelationToCreate."Syncd. Table Name", TempSyntheticRelationToCreate."Virtual Table Caption");
                    NativeDataverseFieldCaption := StrSubstNo(FieldInTableLbl, TempSyntheticRelationToCreate."Syncd. Table Name");
                    VirtualDataverseFieldCaption := StrSubstNo(FieldInTableLbl, TempSyntheticRelationToCreate."Virtual Table Caption");
                end;
            1:
                begin
                    Confirmation := StrSubstNo(FinalizeConfirmTxt, TempSyntheticRelationToCreate."Syncd. Table Name", TempSyntheticRelationToCreate."Virtual Table Caption");
                    NativeFields[1] := TempSyntheticRelationToCreate."Syncd. Field 1 External Name";
                    NativeFields[2] := TempSyntheticRelationToCreate."Syncd. Field 2 External Name";
                    NativeFields[3] := TempSyntheticRelationToCreate."Syncd. Field 3 External Name";
                    if SyntheticRelations.GetExistingAlternateKeyName(TempSyntheticRelationToCreate."Syncd. Table External Name", NativeFields, ExistingKeyName, ExistingKeyNames) then begin
                        Step += 1;
                        NativeTableKey := ExistingKeyName;
                    end else
                        SyntheticRelations.CreateAlternateKeyForColumns(TempSyntheticRelationToCreate."Syncd. Table External Name", NativeFields, ExistingKeyNames)
                end;
        end;
        Step += 1;
    end;

    local procedure SetNextActionEnabled()
    begin
        case Step of
            0:
                NextActionEnabled := NativeTableSelected() and VirtualTableSelected();
            1:
                NextActionEnabled := NativeFieldSelected() and VirtualFieldSelected() and SelectedByPairs();
            2:
                NextActionEnabled := false;
        end;
    end;

    local procedure SelectedRelationDoesntExist(): Boolean
    begin
        TempExistingBCTableRelations.Reset();
        TempExistingBCTableRelations.SetRange("Rel. Native Entity Name", TempSyntheticRelationToCreate."Syncd. Table External Name");
        TempExistingBCTableRelations.SetRange("Rel. Virtual Entity Name", TempSyntheticRelationToCreate."Virtual Table Logical Name");
        exit(TempExistingBCTableRelations.IsEmpty());
    end;

    local procedure SelectedByPairs(): Boolean
    begin
        if (TempSyntheticRelationToCreate."Syncd. Field 1 Name" <> '') or (TempSyntheticRelationToCreate."Virtual Table Column 1 Caption" <> '') then
            if (TempSyntheticRelationToCreate."Syncd. Field 1 Name" = '') or (TempSyntheticRelationToCreate."Virtual Table Column 1 Caption" = '') then
                exit(false);
        if (TempSyntheticRelationToCreate."Syncd. Field 2 Name" <> '') or (TempSyntheticRelationToCreate."Virtual Table Column 2 Caption" <> '') then
            if (TempSyntheticRelationToCreate."Syncd. Field 2 Name" = '') or (TempSyntheticRelationToCreate."Virtual Table Column 2 Caption" = '') then
                exit(false);
        if (TempSyntheticRelationToCreate."Syncd. Field 3 Name" <> '') or (TempSyntheticRelationToCreate."Virtual Table Column 3 Caption" <> '') then
            if (TempSyntheticRelationToCreate."Syncd. Field 3 Name" = '') or (TempSyntheticRelationToCreate."Virtual Table Column 3 Caption" = '') then
                exit(false);
        exit(true);
    end;

    local procedure NativeTableSelected(): Boolean
    begin
        exit((TempSyntheticRelationToCreate."Syncd. Table Name" <> '') and (TempSyntheticRelationToCreate."Syncd. Table External Name" <> '') and (TempSyntheticRelationToCreate."Syncd. Table Id" <> 0));
    end;

    local procedure VirtualTableSelected(): Boolean
    begin
        exit((TempSyntheticRelationToCreate."Virtual Table Caption" <> '') and (TempSyntheticRelationToCreate."Virtual Table Logical Name" <> '') and (TempSyntheticRelationToCreate."Virtual Table API Page Id" <> 0));
    end;

    local procedure NativeFieldSelected(): Boolean
    begin
        exit((TempSyntheticRelationToCreate."Syncd. Field 1 Name" <> '') and (TempSyntheticRelationToCreate."Syncd. Field 1 External Name" <> '') and (TempSyntheticRelationToCreate."Syncd. Field 1 Id" <> 0));
    end;

    local procedure VirtualFieldSelected(): Boolean
    begin
        exit((TempSyntheticRelationToCreate."Virtual Table Column 1 Caption" <> '') and (TempSyntheticRelationToCreate."Virtual Table Column 1 Name" <> ''));
    end;

}
